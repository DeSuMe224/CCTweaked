local reactor
local monitor = peripheral.find("monitor")
local size = {
    x=0,
    y=0
}

local graphic_window = {
    xmin=0,
    xmax=0,
    ymin=0,
    ymax=0
}


--Reactor Variables
local Active = false
local Storage = 0
local Capacity = 0
local ControlRodsLevel = 0
local FuelAmount
local DefaultControlRodsValue = 80
local EmergencyControlRodsValue = 10
local Kp = 12.0
local targetCapacity = 0.50 -- 75% target
local Ki=0.0

-- Variables
local lastError = 0 -- Previous error for future improvements if using PID
local integral = 0

size.x,size.y= monitor.getSize()
    graphic_window.xmin=(1)
    graphic_window.xmax=(3/4*size.x)
    graphic_window.ymin=(1)
    graphic_window.ymax=(size.y-11)
    local buttons = {
        { label = "Kp+", x1 = size.x/2+2, y1 = size.y-8, x2 = size.x/2+12, y2 = size.y-6, action = function() Kp = Kp + 0.5 end },
        { label = "Kp-", x1 = size.x/2+13, y1 = size.y-8, x2 = size.x/2+22, y2 = size.y-6, action = function() Kp = math.max(Kp - 0.5, 0) end },
        { label = "TC+", x1 = size.x/2+2, y1 = size.y-4, x2 = size.x/2+12, y2 = size.y-2, action = function() targetCapacity = targetCapacity + 0.05 end },
        { label = "TC-", x1 = size.x/2+13, y1 = size.y-4, x2 = size.x/2+22, y2 = size.y-2, action = function() targetCapacity = math.max(targetCapacity - 0.05, 0) end },
    }


local StartUpMessage = {
    "Das ist mein ReaktorController!",
    "",
    "Huldigt dem BigReactor!"
}

local function constrain(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end


local function initMonitor()
    monitor.clear()
    monitor.setTextScale(0.8)
    monitor.setTextColor(colors.green)
    monitor.setBackgroundColor(colors.black)
    monitor.setCursorPos(1,1)
    return true
end

local function drawRectangle(x1, y1, x2, y2, infill, linestyle, color)
    if x1 > x2 then x1, x2 = x2, x1 end
    if y1 > y2 then y1, y2 = y2, y1 end
    if (linestyle==" ") then
        monitor.setBackgroundColor(colors[color])
    end
    monitor.setTextColor(colors[color])
    if not infill then
        monitor.setCursorPos(x1, y1)
        monitor.write(string.rep(linestyle, x2 - x1 + 1))

        monitor.setCursorPos(x1, y2)
        monitor.write(string.rep(linestyle, x2 - x1 + 1))

        for y = y1 + 1, y2 - 1 do
            monitor.setCursorPos(x1, y)
            monitor.write(linestyle)

            monitor.setCursorPos(x2, y)
            monitor.write(linestyle)
        end
    else
        for y = y1, y2 do
            monitor.setCursorPos(x1, y)
            monitor.write(string.rep(linestyle, x2 - x1 + 1))
        end
    end

    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)
end


local function startUpScreen()
    
    local y=size.y/2
    for _, str in pairs(StartUpMessage) do
        monitor.setCursorPos((size.x/2)-((#str))/2,y)
        monitor.write(str)
        y=y+1
    end
end


local function findReactor()
    reactor = peripheral.find("BigReactors-Reactor")
    return true 
end

-- Draw a button
local function drawButton(button)
    drawRectangle(button.x1, button.y1, button.x2, button.y2, true, " ", "gray")
    local centerX = math.floor((button.x1 + button.x2) / 2)
    local centerY = math.floor((button.y1 + button.y2) / 2)
    monitor.setCursorPos(centerX - math.floor(#button.label / 2), centerY)
    monitor.write(button.label)
end

local function postStatusUpdate()
    monitor.clear()
    monitor.setTextColor(colors.white)

    monitor.setCursorPos(1,size.y)
    monitor.write("Reactor Controller; Version 1.1")
    monitor.setCursorPos(2,size.y-1)
    local filledString = string.rep("=", size.x-2)
    monitor.write(filledString)

    monitor.setCursorPos(1,size.y-3)
    monitor.write("Status: ")
    if (Active) then
        monitor.setTextColor(colors.green)
        monitor.write("active")
    end
    if (not Active) then
        monitor.setTextColor(colors.red)
        monitor.write("disabled")
    end
    
    monitor.setTextColor(colors.white)

    monitor.setCursorPos(1,size.y-4)
    monitor.write("Kp: ")
    monitor.write(Kp)

    --monitor.setCursorPos(1,size.y-5)
    --monitor.write("Ki: ")
    --monitor.write(Ki)

    monitor.setCursorPos(1,size.y-6)
    monitor.write("Fuel Status: ")
    monitor.write(string.format("%.2f", FuelPercent))
    monitor.write("%")

    monitor.setCursorPos(1,size.y-7)
    monitor.write("Percentage of Energy Capacity: ")
    monitor.write(string.format("%.2f", StoragePercent))
    monitor.write("%")

    monitor.setCursorPos(1,size.y-8)
    monitor.write("ControlRodsLevel: ")
    monitor.write(ControlRodsLevel[1])

    monitor.setCursorPos(2,size.y-9)
    monitor.write(filledString)

    drawRectangle(graphic_window.xmax, size.y-2,graphic_window.xmax, size.y-8, false, "|", "orange")
    monitor.setCursorPos(graphic_window.xmax+1,size.y-9)
    monitor.setTextColor(colors.orange)
    monitor.write("Warnings:")
    if(FuelAmount<(0.9*FuelCapacity)) then
        monitor.setCursorPos(graphic_window.xmax+1,size.y-8)
        monitor.write("Schaff mal mehr Uran ran alder, langsam wirds knapp")
    end 


    monitor.setTextColor(colors.white)
    drawRectangle(size.x/2, size.y-2,size.x/2, size.y-8, false, "|", "blue")
    monitor.setCursorPos(size.x/2+1,size.y-9)
    monitor.setTextColor(colors.blue)
    monitor.write("Controlparameters:")
    

    -- Draw buttons
    for _, button in ipairs(buttons) do
        drawButton(button)
    end


end



-- Check if a button was pressed
local function isButtonPressed(button, x, y)
    return x >= button.x1 and x <= button.x2 and y <= button.y2 and y >= button.y1
end

-- Handle monitor touch events
local function handleTouch()
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        for _, button in ipairs(buttons) do
            
            if isButtonPressed(button, x, y) then
                button.action()
                postStatusUpdate()
            end
        end
    end
end

local function generateGraphs()
    local BufferString = "Energy Storage"
    monitor.setCursorPos((graphic_window.xmax/2)-((#BufferString))/2,1)
    monitor.write(BufferString)

    --Energylevel
    drawRectangle(2,size.y/13-1,graphic_window.xmax-1,size.y/3.25,true," ","gray")
    drawRectangle(3,size.y/13,graphic_window.xmax-2,size.y/3.25-1,true," ","red")
    if ((graphic_window.xmax-2)*StoragePercent<3) then
        drawRectangle(3,size.y/13,3,size.y/3.25-1,true," ","green")
    else

        drawRectangle(3,size.y/13,(graphic_window.xmax-2)*StoragePercent,size.y/3.25-1,true," ","green")
    end
    drawRectangle((graphic_window.xmax-2)*targetCapacity,size.y/13,(graphic_window.xmax-2)*targetCapacity, size.y/3.25-1,false,"|","blue")


    --FuelLevel
    BufferString = "Fuel Storage"
    monitor.setCursorPos((graphic_window.xmax/2)-((#BufferString)/2),size.y/2.88)
    monitor.write(BufferString)

    drawRectangle(2,size.y/2.6,graphic_window.xmax-1,size.y/1.57,true," ","gray")
    drawRectangle(3,size.y/2.6+1,graphic_window.xmax-2,size.y/1.57-1,true," ","red")
    if (FuelPercent<0.1) then
        drawRectangle(3,size.y/2.47,3,size.y/1.625+1,true," ","yellow")
    else

        drawRectangle(3,size.y/2.47,(graphic_window.xmax-2)*FuelPercent,size.y/1.625+1,true," ","yellow")
    end

    --Controlrods
    BufferString = "ControlRods-Position"
    monitor.setCursorPos((graphic_window.xmax+(((size.x)/4)/2))-((#BufferString))/2,1)
    monitor.write(BufferString)

    drawRectangle(graphic_window.xmax+1,3,size.x-1,graphic_window.ymax-1,true," ","gray")
    drawRectangle(graphic_window.xmax+2,3,size.x-2,graphic_window.ymax-2,true," ","yellow")
    if ((graphic_window.ymax-2)*ControlRodsLevel[1]/100<3) then
        drawRectangle(graphic_window.xmax+4,3,size.x-4,3,true," ","lightGray")
    else

        drawRectangle(graphic_window.xmax+4,3,size.x-4,(graphic_window.ymax-2)*ControlRodsLevel[1]/100,true," ","lightGray")
    end


end

local function controlReactor()
    Capacity = reactor.getEnergyCapacity()
    monitor.clear()
    while (true) do
        Active = reactor.getActive()
        Storage= reactor.getEnergyStored()
        StoragePercent = Storage/Capacity
        ControlRodsLevel=reactor.getControlRodsLevels()
        FuelAmount=reactor.getFuelAmount()
        FuelCapacity=reactor.getFuelAmountMax()
        FuelPercent = FuelAmount/FuelCapacity

        -- Calculate error
        local error = targetCapacity - StoragePercent

        -- Update integral term
        integral = integral + error * 0.1

        -- Calculate PI output
        local controlOutput = (Kp * error) + (Ki * integral)

        -- Convert control output to control rod position (0-100%)
        local controlRodPosition = constrain(controlOutput * 100, 0, 100)

        -- Set control rod position
        reactor.setAllControlRodLevels(100-math.floor(controlRodPosition))

        -- Log for debugging
        --print(string.format(
        --    "Current: %.2f%%, Target: %.2f%%, Error: %.2f, Integral: %.2f, Rod Position: %.2f%%",
        --    StoragePercent * 100, targetCapacity * 100, error, integral, controlRodPosition
        --))
       
        postStatusUpdate()
        generateGraphs()
    sleep(0.1)
    end 
end

local function main()
    initMonitor()
    startUpScreen()
    while (not findReactor()) do 
        print("Reactor not found. Well... damn. I'll try again")
        sleep(1)
    end
    print("Reactor found, this is where the fun begins!")
    sleep(1)    
    parallel.waitForAny(controlReactor, handleTouch)




end

main()

