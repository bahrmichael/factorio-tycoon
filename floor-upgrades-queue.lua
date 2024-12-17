local Queue = require("queue")
local Util = require("util")
local GridUtil = require("grid-util")

local function assert_init()
    if storage.tycoon_floor_upgrade_queue == nil then
        storage.tycoon_floor_upgrade_queue = Queue.new()
    end
end

local function push(city, coordinates, newTileType)
    assert_init()
    Queue.pushright(storage.tycoon_floor_upgrade_queue, {city = city, coordinates = coordinates, newTileType = newTileType})
end

local function pop()
    assert_init()
    return Queue.popleft(storage.tycoon_floor_upgrade_queue)
end

-- todo: consolidate with where this was copied from
--- @param direction Direction
--- @return string[] map
local function getMap(direction)
    local result = nil
    if direction == "north" then
        result = {
            "001100",
            "001100",
            "001100",
            "001100",
            "000000",
            "000000",
        }
    elseif direction == "south" then
        result = {
            "000000",
            "000000",
            "001100",
            "001100",
            "001100",
            "001100",
        }
    elseif direction == "west" then
        result = {
            "000000",
            "000000",
            "111100",
            "111100",
            "000000",
            "000000",
        }
    elseif direction == "east" then
        result = {
            "000000",
            "000000",
            "001111",
            "001111",
            "000000",
            "000000",
        }
    end
    assert(result ~= nil, "Invalid direction for getMap")
    return result
end

local function process()
    local current = pop()
    if current == nil then
        return
    end

    local city, coordinates, newTileType = current.city, current.coordinates, current.newTileType
    assert(current.city ~= nil and current.coordinates ~= nil and current.newTileType ~= nil, "Record in tycoon_floor_upgrade_queue doesn't have all required fields.")

    local cell = GridUtil.safeGridAccess(city, coordinates)
    local cell_type = cell.type
    local startCoordinates = GridUtil.translateCityGridToTileCoordinates(city, coordinates)
    if cell_type == "building" then
        Util.printTiles(startCoordinates, {
            "111111",
            "111111",
            "111111",
            "111111",
            "111111",
            "111111",
        }, newTileType, city.surface_index)
    elseif cell_type == "road" then
        for _, direction in ipairs(cell.roadSockets) do
            Util.printTiles(startCoordinates, getMap(direction), newTileType, city.surface_index)
        end
    elseif cell_type ~= "unused" then
        game.print("Would upgrade other cell: " .. cell_type)
    end
end

return {
    push = push,
    pop = pop,
    process = process,
}
