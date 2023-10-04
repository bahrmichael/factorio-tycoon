local function log(message)
    if global.tycoon_enable_debug_logging == true then
        game.write_file("debug.log", message .. "\n", true)
    end
end

local function logGrid(grid)
    if global.tycoon_enable_debug_logging then
        log('-- grid --')
        local s = #grid
        for y = 1, s, 1 do
            local printRow = ""
            local row = grid[y]
            for x = 1, s, 1 do
                local cell = row[x]
                if cell.type == "unused" then
                    printRow = printRow .. ". "
                elseif cell.type == "house" then
                    printRow = printRow .. "H "
                elseif cell.type == "road" then
                    printRow = printRow .. "R "
                else
                    printRow = printRow .. "_ "
                end
            end
            log(printRow)
        end
        log('-- grid --')
    end
end

local DEBUG = {
    log = log,
    logGrid = logGrid,
}
return DEBUG