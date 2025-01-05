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
local DefaultControlRodsValue = 85
local EmergencyControlRodsValue = 10

local StartUpMessage = {
    "Das ist Saschas ReaktorController!",
    "",
    "Huldigt dem BigReactor!"
}


local function initMonitor()
    monitor.clear()
    monitor.setTextScale(0.8)
    monitor.setTextColor(colors.green)
    monitor.setBackgroundColor(colors.black)
    size.x,size.y= monitor.getSize()
    graphic_window.xmin=(1)
    graphic_window.xmax=(2/3*size.x)
    graphic_window.ymin=(1)
    graphic_window.ymax=(size.y-10)
    monitor.setCursorPos(1,1)
    return true
end

local function drawRectangle(x1, y1, x2, y2, infill, linestyle, color)
    if x1 > x2 then x1, x2 = x2, x1 end
    if y1 > y2 then y1, y2 = y2, y1 end

    monitor.setBackgroundColor(colors[color])

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

local function postStatusUpdate()
    monitor.clear()
    monitor.setTextColor(colors.white)
    monitor.setCursorPos(1,size.y)
    monitor.write("Reactor Controller; Version 0.2")
    monitor.setCursorPos(2,size.y-1)
    local filledString = string.rep("=", size.x-2)
    monitor.write(filledString)

    monitor.setCursorPos(1,size.y-4)
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

    --monitor.setCursorPos(1,size.y-5)
    --monitor.write("Reactor Capacity: ")
    --monitor.write(Capacity)

    --monitor.setCursorPos(1,size.y-6)
    --monitor.write("Reactor Storage Volume: ")
    --monitor.write(Storage)

    monitor.setCursorPos(1,size.y-7)
    monitor.write("Percentage of used Capacity: ")
    monitor.write(string.format("%.2f", StoragePercent))

    monitor.setCursorPos(1,size.y-8)
    monitor.write("ControlRodsLevel: ")
    monitor.write(ControlRodsLevel[1])

    monitor.setCursorPos(2,size.y-9)
    monitor.write(filledString)

    drawRectangle(size.x/2, size.y-8,size.x/2, size.y-8, false, "||", "white")
    monitor.setCursorPos(size.x/2,size.y-9)
    monitor.setTextColor(colors.orange)
    monitor.write("Warnings:")
    if(FuelAmount<(0.9*FuelCapacity)) then
        monitor.setCursorPos(size.x/2,size.y-8)
        monitor.write("Schaff mal mehr Uran ran alder, langsam wirds knapp")
    end 
    monitor.setTextColor(colors.white)




end


local function generateGraphs()
    local BufferString = "Energy Storage"
    monitor.setCursorPos((graphic_window.xmax/2)-((#BufferString))/2,1)
    monitor.write(BufferString)

    --Energylevel
    drawRectangle(2,3,graphic_window.xmax-1,16,true," ","gray")
    drawRectangle(3,4,graphic_window.xmax-2,15,true," ","red")
    if ((graphic_window.xmax-2)*StoragePercent<3) then
        drawRectangle(3,4,3,15,true," ","green")
    else

        drawRectangle(3,4,(graphic_window.xmax-2)*StoragePercent,15,true," ","green")
    end

    --FuelLevel
    BufferString = "Fuel Storage"
    monitor.setCursorPos((graphic_window.xmax/2)-((#BufferString))/2,18)
    monitor.write(BufferString)

    drawRectangle(2,20,graphic_window.xmax-1,33,true," ","gray")
    drawRectangle(3,21,graphic_window.xmax-2,32,true," ","red")
    if ((graphic_window.xmax-2)*FuelCapacity<3) then
        drawRectangle(3,21,3,32,true," ","yellow")
    else

        drawRectangle(3,21,(graphic_window.xmax-2)*FuelCapacity,32,true," ","yellow")
    end

    --Controlrods
    BufferString = "ControlRods Position"
    monitor.setCursorPos((graphic_window.xmax+(((size.x)/3)/2))-((#BufferString))/2,1)
    monitor.write(BufferString)

    drawRectangle(graphic_window.xmax+1,3,size.x-1,graphic_window.ymax-1,true," ","gray")
    drawRectangle(graphic_window.xmax+2,3,size.x-2,graphic_window.ymax-2,true," ","yellow")
    if ((graphic_window.ymax-2)*ControlRodsLevel/100<3) then
        drawRectangle(graphic_window.xmax+4,3,size.x-4,3,true," ","yellow")
    else

        drawRectangle(graphic_window.xmax+4,3,size.x-4,(graphic_window.ymax-2)*ControlRodsLevel/100,true," ","yellow")
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
        FuelCapacity=reactor.getFuelCapacity()
        FuelPercent = FuelAmount/FuelCapacity
        if (StoragePercent > 0.6) then
            reactor.setActive(false)
            reactor.setAllControlRodLevels(DefaultControlRodsValue)
        end
    
        if (StoragePercent < 0.3) then
            reactor.setActive(true)
        end 

        if (StoragePercent<0.05) then
            reactor.setAllControlRodLevels(EmergencyControlRodsValue)
        end

        
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
    sleep(3)    
    controlReactor()



end

main()

