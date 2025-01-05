-- Reactor Controller with Buttons for Tuning Kp and Ki

-- Initialization
local reactor
local monitor = peripheral.find("monitor")
local size = { x = 0, y = 0 }

local graphic_window = { xmin = 0, xmax = 0, ymin = 0, ymax = 0 }

-- Reactor Variables
local Active = false
local Storage = 0
local Capacity = 0
local ControlRodsLevel = 0
local FuelAmount = 0
local DefaultControlRodsValue = 80
local EmergencyControlRodsValue = 10
local Kp = 1.0
local Ki = 0.1

local StartUpMessage = {
    "Das ist Saschas ReaktorController!",
    "",
    "Huldigt dem BigReactor!"
}

local buttons = {
    { label = "Kp+", x1 = 51, y1 = 9, x2 = 62, y2 = 7, action = function() Kp = Kp + 0.1 end },
    { label = "Kp-", x1 = 63, y1 = 9, x2 = 74, y2 = 7, action = function() Kp = math.max(Kp - 0.1, 0) end },
    { label = "Ki+", x1 = 51, y1 = 6, x2 = 62, y2 = 4, action = function() Ki = Ki + 0.01 end },
    { label = "Ki-", x1 = 63, y1 = 6, x2 = 74, y2 = 4, action = function() Ki = math.max(Ki - 0.01, 0) end },
}

local function initMonitor()
    monitor.clear()
    monitor.setTextScale(0.8)
    monitor.setTextColor(colors.green)
    monitor.setBackgroundColor(colors.black)
    size.x, size.y = monitor.getSize()
    graphic_window.xmin = 1
    graphic_window.xmax = (3 / 4 * size.x)
    graphic_window.ymin = 1
    graphic_window.ymax = (size.y - 11)
    monitor.setCursorPos(1, 1)
    return true
end

local function drawRectangle(x1, y1, x2, y2, infill, linestyle, color)
    if x1 > x2 then x1, x2 = x2, x1 end
    if y1 > y2 then y1, y2 = y2, y1 end
    if linestyle == " " then
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

local function drawButton(button)
    drawRectangle(button.x1, button.y1, button.x2, button.y2, true, " ", "gray")
    local centerX = math.floor((button.x1 + button.x2) / 2)
    local centerY = math.floor((button.y1 + button.y2) / 2)
    monitor.setCursorPos(centerX - math.floor(#button.label / 2), centerY)
    monitor.write(button.label)
end

local function isButtonPressed(button, x, y)
    return x >= button.x1 and x <= button.x2 and y >= button.y2 and y <= button.y1
end

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

local function postStatusUpdate()
    monitor.clear()
    monitor.setTextColor(colors.white)
    monitor.setCursorPos(1, size.y)
    monitor.write("Reactor Controller; Version 1.0")
    monitor.setCursorPos(2, size.y - 1)
    local filledString = string.rep("=", size.x - 2)
    monitor.write(filledString)

    monitor.setCursorPos(1, size.y - 4)
    monitor.write("Kp: " .. string.format("%.2f", Kp))
    monitor.setCursorPos(1, size.y - 5)
    monitor.write("Ki: " .. string.format("%.2f", Ki))
    monitor.setCursorPos(1, size.y - 6)
    monitor.write("Percentage of Fuel Capacity: " .. string.format("%.2f%%", FuelPercent))
    monitor.setCursorPos(1, size.y - 7)
    monitor.write("Percentage of Energy Capacity: " .. string.format("%.2f%%", StoragePercent))
    monitor.setCursorPos(1, size.y - 8)
    monitor.write("Control Rod Level: " .. string.format("%.2f%%", ControlRodsLevel[1]))

    monitor.setCursorPos(2, size.y - 9)
    monitor.write(filledString)

    -- Draw buttons
    for _, button in ipairs(buttons) do
        drawButton(button)
    end
end

-- Reactor Control and Main Logic (same as before)
-- Main function
local function main()
    initMonitor()
    startUpScreen()
    while not findReactor() do
        print("Reactor not found. Well... damn. I'll try again")
        sleep(1)
    end
    print("Reactor found, this is where the fun begins!")
    sleep(1)
    parallel.waitForAny(controlReactor, handleTouch)
end

main()
