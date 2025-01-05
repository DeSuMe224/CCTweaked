local reactor
local monitor = peripheral.find("monitor")
local size = {
    x=0,
    y=0
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
    monitor.clear()
    monitor.setTextScale(0.8)
    monitor.setTextColor(colors.green)
    monitor.setBackgroundColor(colors.black)
    size.x,size.y= monitor.getSize()
    monitor.setCursorPos(1,1)
    return true
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
    monitor.setCursorPos(1,1)
    monitor.write("Reaktor Controller; Version 0.1")
    monitor.setCursorPos(2,2)
    local filledString = string.rep("=", size.x-2)
    monitor.write(filledString)

    monitor.setCursorPos(1,4)
    monitor.write("Reactor Status: ")
    if (Active) then
        monitor.setTextColor(colors.green)
    end
    if (not Active) then
        monitor.setTextColor(colors.red)
    end
    monitor.write(Active)
    monitor.setTextColor(colors.white)

    --monitor.setCursorPos(1,5)
    --monitor.write("Reactor Capacity: ")
    --monitor.write(Capacity)

    --monitor.setCursorPos(1,6)
    --monitor.write("Reactor Storage Volume: ")
    --monitor.write(Storage)

    monitor.setCursorPos(1,7)
    monitor.write("Percentage of used Capacity: ")
    monitor.write(string.format("%.2f", StoragePercent))

    monitor.setCursorPos(1,8)
    monitor.write("ControlRodsLevel: ")
    monitor.write(ControlRodsLevel[1])

    monitor.setCursorPos(2,9)
    local filledString = string.rep("=", size.x-2)
    monitor.write(filledString)

end


local function ControlReactor()
    Capacity = reactor.getEnergyCapacity()
    
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
    sleep(1)
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
    ControlReactor()



end

main()

