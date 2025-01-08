local energizer
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


--Energizer Variables
local Active = false
local Storage = 0
local Capacity = 0
local EnergyInserted = 0
local EnergyExtracted = 0
local State=""



size.x,size.y= monitor.getSize()
graphic_window.xmin=(1)
graphic_window.xmax=(size.x)
graphic_window.ymin=(1)
graphic_window.ymax=(size.y-12)



local StartUpMessage = {
    "Das ist mein EnergizerController!",
    "",
    "Huldigt dem Energizer!"
}

local function formatNumber(num)
    if num >= 1e24 then
        return string.format("%.2fY FE", num / 1e24) -- Yotta (10^24)
    elseif num >= 1e21 then
        return string.format("%.2fZ FE", num / 1e21) -- Zetta (10^21)
    elseif num >= 1e18 then
        return string.format("%.2fE FE", num / 1e18) -- Exa (10^18)
    elseif num >= 1e15 then
        return string.format("%.2fP FE", num / 1e15) -- Peta (10^15)
    elseif num >= 1e12 then
        return string.format("%.2fT FE", num / 1e12) -- Tera (10^12)
    elseif num >= 1e9 then
        return string.format("%.2fG FE", num / 1e9) -- Giga (10^9)
    elseif num >= 1e6 then
        return string.format("%.2fM FE", num / 1e6) -- Mega (10^6)
    elseif num >= 1e3 then
        return string.format("%.2fk FE", num / 1e3) -- Kilo (10^3)
    else
        return string.format("%d FE", num) -- Plain number for values < 1,000
    end
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


local function findEnergizer()
    energizer = peripheral.find("BigReactors-Energizer")
    return true 
end


local function postStatusUpdate()
    monitor.clear()
    monitor.setTextColor(colors.white)

    monitor.setCursorPos(1,size.y)
    monitor.write("Energizer Systen; Version 1.0")
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
    monitor.write("State: ")
    if (State == "Charging") then
        monitor.setTextColor(colors.green)
        monitor.write(State)
    end
    if (State == "Decharging") then
        monitor.setTextColor(colors.red)
        monitor.write(State)
    end



    monitor.setCursorPos(1,size.y-5)
    monitor.write("Avarage Energy Extracted: ")
    monitor.write(formatNumber(averageExtracted))
   

    monitor.setCursorPos(1,size.y-6)
    monitor.write("Avarage Energy Inserted: ")
    monitor.write(formatNumber(averageInserted))


    monitor.setCursorPos(1,size.y-7)
    monitor.write("Total Capacity: ")
    monitor.write(formatNumber(Capacity))

    monitor.setCursorPos(1,size.y-8)
    monitor.write("Total Energy Stored: ")
    monitor.write(formatNumber(Storage))

    monitor.setCursorPos(1,size.y-9)
    monitor.write("Storage Coverd: ")
    monitor.write(string.format("%.2f %", StoragePercent))
    monitor.write("%")

    monitor.setCursorPos(2,size.y-10)
    monitor.write(filledString)

    monitor.setCursorPos(1,size.y-9)
    monitor.setTextColor(colors.lime)
    monitor.write("EnergyStats:")

end


local function generateGraphs()
    local BufferString = "Storage Coverage"
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
    BufferString = "State"
    monitor.setCursorPos((graphic_window.xmax/2)-((#BufferString)/2),size.y/2.88)
    monitor.write(BufferString)

    drawRectangle(2,size.y/2.6,graphic_window.xmax-1,size.y/1.57,true," ","gray")
    drawRectangle(3,size.y/2.6+1,graphic_window.xmax-2,size.y/1.57-1,true," ","red")
    if (State == "Charging") then
        drawRectangle(3,size.y/2.47,(graphic_window.xmax-2),size.y/1.625+1,true,"+","green")
    else

        drawRectangle(3,size.y/2.47,(graphic_window.xmax-2),size.y/1.625+1,true,"-","red")
    end

end

local function controlEnergizer()
    monitor.clear()
    
    local insertedHistory = {}
    local extractedHistory = {}
    local maxHistory = 15 -- Number of values to keep for the running average

    local function calculateRunningAverage(history)
        local sum = 0
        for _, value in ipairs(history) do
            sum = sum + value
        end
        return sum / #history 
    end

    while (true) do
        Stats = energizer.getEnergyStats()
        Capacity = Stats.energyCapacity
        Active = energizer.getActive()
        Storage = Stats.energyStored
        StoragePercent = Storage / Capacity
        EnergyInserted = Stats.energyInsertedLastTick
        EnergyExtracted = Stats.energyExtractedLastTick

        table.insert(insertedHistory, EnergyInserted)
        table.insert(extractedHistory, EnergyExtracted)

        if #insertedHistory > maxHistory then
            table.remove(insertedHistory, 1)
        end
        if #extractedHistory > maxHistory then
            table.remove(extractedHistory, 1)
        end

        averageInserted = calculateRunningAverage(insertedHistory)
        averageExtracted = calculateRunningAverage(extractedHistory)

        local State
        if EnergyInserted > EnergyExtracted then
            State = "Charging"
        else
            State = "Decharging"
        end

    
        postStatusUpdate()
        generateGraphs()

        sleep(0.1)
    end
end

local function main()
    initMonitor()
    startUpScreen()
    while (not findEnergizer()) do 
        print("Energizer not found. Well... damn. I'll try again")
        sleep(1)
    end
    print("Energizer found, this is where the fun begins!")
    sleep(1)    
    controlEnergizer()




end

main()

