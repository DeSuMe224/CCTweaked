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
local Active=false
local Storage=0
local Capacity=0
local ControlRodsLevel=0

local StartUpMessage = {
    "Das ist Saschas ReaktorController!",
    "",
    "Huldigt dem BigReactor!"
}


local function initMonitor()
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

local function drawRectangle(x1, y1, x2, y2, infill, color)
    if x1 > x2 then x1, x2 = x2, x1 end
    if y1 > y2 then y1, y2 = y2, y1 end

    monitor.setBackgroundColor(colors[color])

    if not infill then
        monitor.setCursorPos(x1, y1)
        monitor.write(string.rep(" ", x2 - x1 + 1))

        monitor.setCursorPos(x1, y2)
        monitor.write(string.rep(" ", x2 - x1 + 1))

        for y = y1 + 1, y2 - 1 do
            monitor.setCursorPos(x1, y)
            monitor.write(" ")

            monitor.setCursorPos(x2, y)
            monitor.write(" ")
        end
    else
        for y = y1, y2 do
            monitor.setCursorPos(x1, y)
            monitor.write(string.rep(" ", x2 - x1 + 1))
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

end


local function generateGraphs()
    local BufferString = "Energy Storage"
    monitor.setCursorPos((graphic_window.xmax/2)-((#BufferString))/2,1)
    monitor.write(BufferString)

    drawRectangle(2,3,graphic_window.xmax-1,16,true,"gray")
    drawRectangle(3,4,graphic_window.xmax-2,15,true,"red")
    drawRectangle(3,4,(graphic_window.xmax-2)*StoragePercent,15,true,"green")

end

local function controlReactor()
    Capacity = reactor.getEnergyCapacity()
    monitor.clear()
    while (true) do
        Active = reactor.getActive()
        Storage= reactor.getEnergyStored()
        StoragePercent = Storage/Capacity
        ControlRodsLevel=reactor.getControlRodsLevels()
        
        if (StoragePercent > 0.6) then
            reactor.setActive(false)
        end
    
        if (StoragePercent < 0.3) then
            reactor.setActive(true)
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

