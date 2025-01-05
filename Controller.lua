local reactor
local monitor = peripheral.find("monitor")
local size{
    x=0,
    y=0
}

local StartUpMessage = {
    "Das ist Saschas ReaktorController!",
    "Huldigt dem großen Rechner!"
}

local function startUpScreen()
    initMonitor()
    local y=size.y/2
    for _, str in pairs(StartUpMessage) do
        monitor.setCursorPos((size.x/2)-((#str))/2,y)
        monitor.write(str)
        y=y+1
    end

local function initMonitor()
    monitor.clear()
    monitor.setTextScale(0.8)
    monitor.setTextColor(colors.green)
    monitor.setBackgroundColor(colors.black)
    size.x,size.y= monitor.getSize()
    monitor.setCursorPos(1,1)
end

local function findReactor()
    reactor = peripheral.find("BigReactors-Reactor")
    return true 
end



local function main()
    startUpScreen()
    while (not findReactor()) do 
        print("Reactor not found. Well... damn. I'll try again")
        sleep(1)
    end
    print("Reactor found, this is where the fun begins!")
        




end

main()

