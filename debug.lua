local Queue = require "queue"

local function log(message)
    if global.tycoon_enable_debug_logging == true then
        game.write_file("debug.log", message .. "\n", true)
    end
end

local function logRoadEnds(roadEnds)
    if roadEnds == nil then
        return
    end
    local printable = ''
    for value in Queue.iterate(roadEnds) do
        printable = printable .. " " .. value.coordinates.y .. "/" .. value.coordinates.x
    end
    log(printable)
end

local function logGrid(grid, logFn)
    local hasCustomLogging = true
    if logFn == nil then
        logFn = log
        hasCustomLogging = false
    end
    if global.tycoon_enable_debug_logging or hasCustomLogging then
        if not hasCustomLogging then
            logFn('-- grid --')
        end
        local s = #grid
        for y = 1, s, 1 do
            local printRow = y .. ": "
            local row = grid[y]
            for x = 1, s, 1 do
                local cell = row[x]
                if cell.type == "unused" then
                    printRow = printRow .. " .  "
                elseif cell.type == "building" then
                    printRow = printRow .. "H "
                elseif cell.type == "road" then
                    printRow = printRow .. "R "
                else
                    printRow = printRow .. "_ "
                end
            end
            logFn(printRow)
        end
        if not hasCustomLogging then
            logFn('-- grid --')
        end
    end
end

local DEBUG = {
    log = log,
    logGrid = logGrid,
    logRoadEnds = logRoadEnds
}
return DEBUG