local reactor
local monitor = peripheral.find("monitor")

local function initMonitor()
    monitor.clear()
    monitor.setTextScale(0.8)
    monitor.setCursorPos(1,1)
end

local function findReactor()
    reactor = peripheral.find("BigReactors-Reactor")
    return true 
end

local function main()
    initMonitor()
    findReactor()
    local functions = peripheral.getMethods(peripheral.getName(reactor))
    local y = 2
    for _, func in pairs(functions) do
        monitor.setCursorPos(1,y)
        monitor.write(func)
        y=y+1
    end
end

main()
        
