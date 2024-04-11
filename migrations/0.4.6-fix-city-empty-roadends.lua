local Segments = require("segments")
local Queue = require("queue")

-- WARN: migrations are run BEFORE any init(), always need this here
if global.tycoon_cities == nil then
    global.tycoon_cities = {}
end

-- check every city
for _, city in pairs(global.tycoon_cities) do
    if Queue.count(city.roadEnds) > 0 then
        goto cont_city
    end

    local possibleRoadEnds = {}
    log(string.format("processing city id: %d grid: %d name: %s", city.id, #city.grid, city.name))

    -- check city grid
    for y = 1, #city.grid, 1 do
        for x = 1, #city.grid, 1 do
            local row = city.grid[y]
            local cell = (row or {})[x]
            -- process only valid and initial cells
            if cell == nil or cell.type ~= "road" or cell.initKey == nil then
                goto continue
            end

            -- ex: "corner.rightToBottom"
            if cell.initKey:sub(1, 6) ~= "corner" then
                goto continue
            end

            local seg = Segments.getObjectForKey(cell.initKey)
            if seg == nil then
                goto continue
            end

            -- sockets are {top, bottom, left, right}, but we need directions here
            local directions = Segments.getEmptySocketDirections(seg.sockets)
            for _, dir in pairs(directions) do
                table.insert(possibleRoadEnds, {
                    coordinates = {x=x, y=y},
                    direction = dir,
                })
            end

            ::continue::
        end
    end

    -- push into queue the same way as CityPlanner::initializeCity() does
    local roadEndCount = city.generator(4, 8)
    for i = 1, roadEndCount, 1 do
        Queue.pushright(city.roadEnds, table.remove(possibleRoadEnds, city.generator(#possibleRoadEnds)))
    end

    log(string.format("city.roadEnds: %d", Queue.count(city.roadEnds)))

    ::cont_city::
end
