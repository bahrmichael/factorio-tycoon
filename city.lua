local Queue = require("queue")
local Constants = require("constants")
local Consumption = require("consumption")
local GridUtil = require("grid-util")
local Util = require("util")
local FloorUpgradesQueue = require("floor-upgrades-queue")

--- @class Coordinates
--- @field x number
--- @field y number

--- @alias Direction
---| "south"
---| "east"
---| "north"
---| "west"

--- @alias BuildingType
---| "simple"
---| "residential"
---| "highrise"
---| "tycoon-treasury"
---| "garden"

--- @class BuildingConstruction
--- @field buildingType BuildingType
--- @field constructionTimeInTicks number

--- @class RoadEnd
--- @field direction Direction
--- @field coordinates Coordinates
--- @field additionalWeight number | nil

--- @alias CellType
---| "road"
---| "building"
---| "unused"

--- @class Cell
--- @field type CellType
--- @field roadSockets Direction[] | nil
--- @field entity any | nil
--- @field buildingType BuildingType | nil
--- @field createdAtTick number | nil

--- @alias RoadConnectionCount
---| "1"
---| "2"
---| "3"

--- @class ExcavationPit
--- @field coordinates Coordinates
--- @field createdAtTick number
--- @field buildingConstruction BuildingConstruction

--- @class City
--- @field id number
--- @field roadEnds Queue
--- @field grid (Cell)[][]
--- @field center Coordinates
--- @field buildingLocationQueue Queue
--- @field gardenLocationQueue Queue
--- @field excavationPits ExcavationPit[]
--- @field buildingCounts { BuildingType: number }
--- @field houseLocations Coordinates[]

--- @alias CollidableStatus
---| "free"
---| "only-straight-rail"
---| "blocked"

-- --- @param coordinates Coordinates
-- --- @return string key
-- local function buildCoordinatesKey(coordinates)
--     return coordinates.y .. "/" .. coordinates.x
-- end

-- local cachedDistances = {}

--- @param coordinates Coordinates
--- @return number distanceFromTownHall
local function getCachedDistance(coordinates, offsetY, offsetX, cityCenter)
    -- local key = buildCoordinatesKey(coordinates)
    -- if cachedDistances[key] ~= nil then
    --     return cachedDistances[key]
    -- else
    local distance = Util.calculateDistance({
        y = (coordinates.y + offsetY) * Constants.CELL_SIZE,
        x = (coordinates.x + offsetX) * Constants.CELL_SIZE,
    }, cityCenter)
        -- cachedDistances[key] = distance
    return distance
    -- end
end

--- @param origin Coordinates
--- @param size number
--- @param allowDiagonal boolean
--- @param allowCenter boolean
--- @return Coordinates[] coordinates
local function getSurroundingCoordinates(origin, size, allowDiagonal, allowCenter)
   local c = {}
   if allowCenter then
       table.insert(c, origin)
   end
   for i = -1 * size, size, 1 do
        for j = -1 * size, size, 1 do
            if (allowDiagonal or (math.abs(i) ~= math.abs(j))) then
                if not(i == 0 and j == 0) then
                    table.insert(c, {
                        x = j + origin.x,
                        y = i + origin.y
                    })
                end
            end
        end
   end
   return c
end

--- @param origin Coordinates
--- @param size number
--- @param city City
--- @return any
local function getCircularSurroundingCoordinates(origin, size, city)
    local c = {}
    for i = -1 * size, size, 1 do
        for j = -1 * size, size, 1 do
            -- The first condition excludes the center piece
            -- The second condition excludes the four corners. Open for better solutions to make a circle.
            if not(i == 0 and j == 0) and not(math.abs(i) == size and math.abs(j) == size) then
                local coordinates = {
                    y = i + origin.y,
                    x = j + origin.x
                }
                -- The idea here is to sort the cells in a way that they are built first where it's closer
                -- to the origin and the town center, since this function is currently only used for floor upgrades.
                -- That should give the reconstruction work a more organic look and feel.
                local distance_to_origin = Util.calculateDistance(origin, coordinates)
                local distance_to_center = Util.calculateDistance(city.center, coordinates)
                local key = math.ceil(distance_to_origin * distance_to_center)
                -- We're incrementing the key on conflict, as that's relatively cheap given that "size" won't grow far.
                while c[key] ~= nil do
                    key = key + 1
                end
                -- table.insert won't shift elements as we'd expect it for an array, if the table is not a perfect array-like struture
                -- That may happen because of the distance based insert.
                c[key] = coordinates
            end
        end
    end
    return c
 end

--- @param area any
--- @param surface_index number
--- @param ignorables string[] | nil
local function removeCollidingEntities(area, surface_index, ignorables)
    local printEntities = game.surfaces[surface_index].find_entities_filtered({
        area=area,
        type = {"tree", "simple-entity"}
    })
    for _, entity in pairs(printEntities) do
        if ignorables ~= nil and #ignorables > 0 and Util.indexOf(ignorables, entity.name) ~= nil then
            -- noop, skip ignorables
        else
            entity.destroy()
        end
    end
end

local function hasCliffsOrWater(area, surface_index)
    local water = game.surfaces[surface_index].find_tiles_filtered{
        area = area,
        name = {
            "deepwater",
            "deepwater-green",
            "out-of-map",
            "water",
            "water-green",
            "water-shallow",
            "water-mud",
            "water-wube",
        },
        limit = 1
    }
    local cliffs = game.surfaces[surface_index].find_entities_filtered{
        area = area,
        name = { "cliff" },
        limit = 1
    }
    return #water > 0 or #cliffs > 0
end

--- @param area any
--- @param surface_index number
local function isAreaFree(area, surface_index)
    -- Water / Cliffs
    if hasCliffsOrWater(area, surface_index) then
        return false
    end

    local ignorables = {"huge-rock", "big-rock", "big-sand-rock", "dead-grey-trunk"}

    local entities = game.surfaces[surface_index].find_entities_filtered({
        area=area,
        type={"tree"},
        name=ignorables,
        invert=true,
        limit = 100,
    })
    return #entities == 0
end

--- @param city City
--- @param coordinates Coordinates
--- @param additionalIgnorables string[] | nil
--- @return CollidableStatus
local function checkForCollidables(city, coordinates, additionalIgnorables)
    local startCoordinates = GridUtil.translateCityGridToTileCoordinates(city, coordinates)
    local area = {
        {startCoordinates.x, startCoordinates.y},
        {startCoordinates.x + Constants.CELL_SIZE, startCoordinates.y + Constants.CELL_SIZE}
    }
    -- Water / Cliffs
    if hasCliffsOrWater(area, city.surface_index) then
        return "blocked"
    end

    local ignorables = {"huge-rock", "big-rock", "big-sand-rock", "dead-grey-trunk"}

    if additionalIgnorables ~= nil and #additionalIgnorables >0 then
        for _, value in ipairs(additionalIgnorables) do
            table.insert(ignorables, value)
        end
    end

    -- Too many trees / Other entities
    local entities = game.surfaces[city.surface_index].find_entities_filtered({
        area=area,
        type={"tree"},
        name=ignorables,
        invert=true,
        limit = 100,
    })
    if #entities == 0 then
        return "free"
    end

    local straightRailCount = 0
    for _, entity in ipairs(entities) do
        if entity.name == "straight-rail" then
            straightRailCount = straightRailCount + 1
        end
    end

    if #entities == straightRailCount then
        return "only-straight-rail"
    else
        return "blocked"
    end
end

 --- @param city City
 local function expand_grid(city)
    local old_size = GridUtil.getGridSize(city.grid)
    local new_size = old_size + 2  -- Expand by 1 on each side

    -- Shift rows downward to keep center
    for y = new_size, 1, -1 do
        city.grid[y] = city.grid[y - 1] or {}
    end

    -- Add new columns at the left and right
    for y = 1, new_size do
        table.insert(city.grid[y], 1, {type = "unused"})
        city.grid[y][new_size] = {type = "unused"}
    end

    -- Fill up any nil fields with type=unused
    for y = 1, #city.grid, 1 do
        for x = 1, #city.grid, 1 do
            if city.grid[y][x] == nil then
                city.grid[y][x] = {type = "unused"}
            end
        end
    end
end

--- @param city City
--- @param coordinates Coordinates
local function hasSurroundingRoad(city, coordinates)
    local surroundsOfUnused = getSurroundingCoordinates(coordinates, 1, false)
    for _, s in ipairs(surroundsOfUnused) do
        local surroundingCell = GridUtil.safeGridAccess(city, s)
        if surroundingCell ~= nil and surroundingCell.type == "road" then
            return true
        end
    end
    return false
end

--- @param coordinates Coordinates
--- @param direction Direction
--- @param distance number
--- @return Coordinates coordinates
local function continueInDirection(coordinates, direction, distance)
    local newCoordinates
    if direction == "south" then
        newCoordinates = {x = coordinates.x, y = coordinates.y + distance}
    elseif direction == "east" then
        newCoordinates = {x = coordinates.x + distance, y = coordinates.y}
    elseif direction == "north" then
        newCoordinates = {x = coordinates.x, y = coordinates.y - distance}
    elseif direction == "west" then
        newCoordinates = {x = coordinates.x - distance, y = coordinates.y}
    end

    assert(newCoordinates ~= nil, "Coordinates must not be nil. Did you add a new direction?")

    return newCoordinates
end

--- @param direction Direction The direction that the road previously extended into.
--- @return Direction direction The inverted direction
local function invertDirection(direction)
    local invertedDirection
    if direction == "north" then
        invertedDirection = "south"
    elseif direction == "south" then
        invertedDirection = "north"
    elseif direction == "east" then
        invertedDirection = "west"
    elseif direction == "west" then
        invertedDirection = "east"
    else
        assert(false, "Invalid direction")
    end
    return invertedDirection
end

--- @param originalDirection Direction
--- @return Direction rightDirection
local function getRightDirection(originalDirection)
    local rightDirection
    if originalDirection == "north" then
        rightDirection = "east"
    elseif originalDirection == "south" then
        rightDirection = "west"
    elseif originalDirection == "east" then
        rightDirection = "south"
    elseif originalDirection == "west" then
        rightDirection = "north"
    else
        assert(false, "Invalid direction")
    end
    return rightDirection
end

--- @param originalDirection Direction
--- @return Direction leftDirection
local function getLeftDirection(originalDirection)
    local leftDirection
    if originalDirection == "north" then
        leftDirection = "west"
    elseif originalDirection == "south" then
        leftDirection = "east"
    elseif originalDirection == "east" then
        leftDirection = "north"
    elseif originalDirection == "west" then
        leftDirection = "south"
    else
        assert(false, "Invalid direction")
    end
    return leftDirection
end

--- @param city City
--- @param coordinates Coordinates
--- @param direction Direction
--- @return boolean
local function areStraightRailsOrthogonal(city, coordinates, direction)
    local startCoordinates = GridUtil.translateCityGridToTileCoordinates(city, coordinates)
    local area = {
        {startCoordinates.x, startCoordinates.y},
        {startCoordinates.x + Constants.CELL_SIZE, startCoordinates.y + Constants.CELL_SIZE}
    }

    -- Too many trees / Other entities
    local entities = game.surfaces[city.surface_index].find_entities_filtered({
        area=area,
        name={"straight-rail"},
        -- Only test 10 rail pieces, that should give us enough info
        -- todo: how many straight rail pieces fit into 6x6 tiles?
        limit = 10,
    })

    local left = getLeftDirection(direction)
    local right = getRightDirection(direction)

    for _, entity in ipairs(entities) do
        if entity.name == "straight-rail" then
            if entity.direction ~= defines.direction[left] and entity.direction ~= defines.direction[right] then
                return false
            end
        end
    end
    return true
end

local streetIgnorables = {"big-electric-pole", "medium-electric-pole", "small-electric-pole", "small-lamp", "pipe-to-ground"}

--- @param city City
--- @param roadEnd RoadEnd
--- @param lookoutDirections Direction[]
--- @return boolean canBuild
local function testRoadDirection(city, roadEnd, lookoutDirections)
    -- Test the compatibility of the directions
    for _, direction in ipairs(lookoutDirections) do
        local neighbourPosition = continueInDirection(roadEnd.coordinates, direction, 1)

        local collidables = checkForCollidables(city, neighbourPosition, streetIgnorables)

        if collidables == "blocked" then
            return false
        elseif collidables == "only-straight-rail" then
             local isCrossing = areStraightRailsOrthogonal(city, neighbourPosition, direction)
             if not isCrossing then
                return false
             end
        end

        -- This should never be fail, because the upstream function is supposed to expand the grid if the position is on the outsides
        local neighbourCell = GridUtil.safeGridAccess(city, neighbourPosition, "testRoadDirection")
        if neighbourCell == nil then
            return false
        end

        -- Streets must not expand into buildings or collidables, but may expand into empty fields or streets
        if neighbourCell.type == "unused" then
            -- noop, cell is free
        elseif neighbourCell.type == "building" then
            return false
        elseif neighbourCell.type == "road" then
            if Util.indexOf(neighbourCell.roadSockets, invertDirection(direction)) ~= nil then
                return false
            end
        elseif #neighbourCell == 1 and (neighbourCell[1] == "linear.vertical" or neighbourCell[1] == "linear.horizontal" or neighbourCell[1] == "town-hall" or neighbourCell[1] == "intersection") then
            return false
        end

        -- Streets must not continue directly next to and parallel to each other
        local neighboursSideDirections = {}
        if direction == "north" or direction == "south" then
            neighboursSideDirections = {"east", "west"}
        elseif direction == "west" or direction == "east" then
            neighboursSideDirections = {"south", "north"}
        end
        local neighboursSideNeighbours = {
            continueInDirection(neighbourPosition, neighboursSideDirections[1], 1),
            continueInDirection(neighbourPosition, neighboursSideDirections[2], 1),
        }
        for _, position in ipairs(neighboursSideNeighbours) do
            local cell = GridUtil.safeGridAccess(city, position)
            if cell ~= nil and cell.type == "road" then
                local sockets = cell.roadSockets or {}
                for _, socket in ipairs(sockets) do
                    if socket == direction or socket == invertDirection(direction) then
                        return false
                    end
                end
            end
        end
    end

    return true
end

--- @return RoadConnectionCount[] connectionCountOptions
local function getRoadConnectionCountOptions()

    if storage.tycoon_weighted_road_connections ~= nil then
        return storage.tycoon_weighted_road_connections
    end

    local weightedValues = {}
    -- Each value describes how many road connections should be built.
    -- weightedValues["0"] = 1
    weightedValues["3"] = 1
    weightedValues["2"] = 2
    -- One connection will later be randomized again if it should be a corner or a straight.
    weightedValues["1"] = 5

    local values = {}
    for value, weight in pairs(weightedValues) do
        for _i = 1, weight, 1 do
            table.insert(values, value)
        end
    end

    storage.tycoon_weighted_road_connections = values

    return values
end

local function shuffle(tbl)
    for i = #tbl, 2, -1 do
      local j = storage.tycoon_global_generator(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

--- @param city City
--- @param roadEnd RoadEnd
--- @return Direction[] | nil
local function pickRoadExpansion(city, roadEnd)
    local left = getLeftDirection(roadEnd.direction)
    local right = getRightDirection(roadEnd.direction)

    local options = getRoadConnectionCountOptions()
    shuffle(options)

    for _, option in ipairs(options) do
        local picked
        if option == "3" then
            picked = {roadEnd.direction, left, right}
            -- If the test doesn't succeed, then continue trying the other options
        elseif option == "2" then
            local sides = {roadEnd.direction, left, right}
            picked = {
                table.remove(sides, city.generator(#sides)),
                table.remove(sides, city.generator(#sides)),
            }
            -- If the test doesn't succeed, then continue trying the other options
        elseif option == "1" then
            -- Start with the default maximum length. The for loop will not update it if the street is longer than 10.
            local straightStreetLength = 10
            for i = 1, straightStreetLength, 1 do
                local previousCell = continueInDirection(roadEnd.coordinates, invertDirection(roadEnd.direction), i)
                local cell = GridUtil.safeGridAccess(city, previousCell)
                if cell == nil then
                    -- We reached the end of the grid. The road doesn't go beyond here.
                    break
                end
                if cell.type ~= "road" then
                    -- We reached the end of the straight street. Record the total distance.
                    straightStreetLength = i
                    break
                end
            end
            local shouldBuildStraight = city.generator() > (straightStreetLength / 10)
            if shouldBuildStraight then
                picked = {roadEnd.direction}
            else
                local sides = {left, right}
                picked = {sides[city.generator(#sides)]}
            end
        elseif option == "0" then
            picked = {}
        else
            assert(false, "pickRoadExpansion doesn't yet handle the new roadConnection: " .. option)
        end

        if testRoadDirection(city, roadEnd, picked) then
            return picked
        end
    end

    return nil
end

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

-- TODO: build this table from prototypes or data-constants
local totalBuildingSprites = {
    ["garden"] = 13,
    ["excavation-pit"] = 20,
    ["house-simple"] = 14,
    ["house-residential"] = 9,
    ["house-highrise"] = 8,
}

--- @param city City
--- @param buildingType BuildingType
local function getRandomBuildingName(city, buildingType)
    assert(city ~= nil, "City instance is nil")
    assert(totalBuildingSprites[buildingType] ~= nil, "Unknown building type: " .. tostring(buildingType))
    local n = totalBuildingSprites[buildingType] or 1
    return "tycoon-" .. buildingType .."-".. city.generator(n)
end

--- @param city City
--- @param recentCoordinates Coordinates | nil
--- @param allowCenter boolean | nil
local function addBuildingLocations(city, recentCoordinates, allowCenter)
    if city.buildingLocationQueue == nil then
        city.buildingLocationQueue = Queue.new()
    end
    if city.gardenLocationQueue == nil then
        city.gardenLocationQueue = Queue.new()
    end

    if recentCoordinates ~= nil then
        local surrounds = getSurroundingCoordinates(recentCoordinates, 1, false, allowCenter)
        for _, value in ipairs(surrounds) do
            -- TODO: this will probably skip corners when called from on_entity_destroyed event
            -- are edges supposed to be roads or what?
            if value.x <= 1 or value.y <= 1 or value.x >= #city.grid or value.y >= #city.grid then
                -- Skip locations that are at the edge of the grid or beyond
            else
                    -- Only check cells that are unused and may have a building built there
                local cell = GridUtil.safeGridAccess(city, value)
                local isUnused = cell ~= nil and cell.type == "unused"
                if isUnused then

                    -- Then check if there are any open roadEnds surrounding this unused field
                    local surroundsOfUnused = getSurroundingCoordinates(value, 1, false)
                    local hasSurroundingRoadEnd = false
                    for _, s in ipairs(surroundsOfUnused) do
                        if Util.indexOf(recentCoordinates, s) ~= nil then
                            hasSurroundingRoadEnd = true
                            break
                        end
                    end
                    if not hasSurroundingRoadEnd then
                        if hasSurroundingRoad(city, value) then
                            local offsetY = GridUtil.getOffsetY(city)
                            local offsetX = GridUtil.getOffsetX(city)
                            local cityCenter = {
                                x = city.center.x + Constants.CELL_SIZE,
                                y = city.center.y + Constants.CELL_SIZE,
                            }
                            local distanceA = getCachedDistance(value, offsetY, offsetX, cityCenter)
                            Queue.insert(city.buildingLocationQueue, value, math.ceil(distanceA))
                        else
                            -- Test if this cell is surrounded by houses, if yes then place a garden
                            -- Because we use getSurroundingCoordinates with allowDiagonal=false above, we only need to count 4 houses or roads
                            local surroundCount = 0
                            for _, s in ipairs(surroundsOfUnused) do
                                local surroundingCell = GridUtil.safeGridAccess(city, s)
                                if surroundingCell ~= nil and surroundingCell.type == "building" then
                                    surroundCount = surroundCount + 1
                                end
                            end
                            -- Sometimes there are also 2 unused cells within a housing group. We probably need a better check, but for now we'll just build gardens when there are 3 houses.
                            if surroundCount >= 3 then
                                Queue.pushright(city.gardenLocationQueue, value)
                            end
                            -- noop, wait until there's a house and let it reattempt later
                        end
                    else
                        -- if there's a surrounding roadEnd, then we'll wait so that the houses don't block road expansion
                    end
                end
            end
        end
    end
end

--- @param cellCoordinates Coordinates
local function isCellFree(city, cellCoordinates)
    local startCoordinates = GridUtil.translateCityGridToTileCoordinates(city, cellCoordinates)
    local area = {
        {x = startCoordinates.x, y = startCoordinates.y},
        {x = startCoordinates.x + Constants.CELL_SIZE, y = startCoordinates.y + Constants.CELL_SIZE}
    }
    return isAreaFree(area, city.surface_index)
end

--- @param city City
--- @param coordinates Coordinates
--- @return boolean
local function isConnectedToRoad(city, coordinates)
    local surrounds = getSurroundingCoordinates(coordinates, 1, false)
    for _, s in ipairs(surrounds) do
        local c = GridUtil.safeGridAccess(city, s)
        if c ~= nil and c.type == "road" then
            return true
        end
    end
    return false
end

--- @param city City
--- @param buildingConstruction BuildingConstruction
--- @param queueIndex string
--- @param allowedCoordinates Coordinates[] | nil
--- @return boolean started
local function startConstruction(city, buildingConstruction, queueIndex, allowedCoordinates)
    if city[queueIndex] == nil then
        city[queueIndex] = Queue.new()
    end

    city[queueIndex] = Queue.removeDuplicates(city[queueIndex], function(v)
        return v.x .. "-" .. v.y
    end)

    local function log_failure(reason)
        log("startConstruction(): unable to construct: ".. tostring(buildingConstruction.buildingType) ..", reason: ".. reason)
    end

    -- Make up to 10 attempts to find a location where we can start a construction site
    local attempts = 10
    local log_reason = "attempts"
    if allowedCoordinates ~= nil then
        attempts = #allowedCoordinates
    end
    for i = 1, attempts, 1 do
        local coordinates
        if allowedCoordinates ~= nil then
            coordinates = table.remove(allowedCoordinates)
        else
            coordinates = Queue.popleft(city[queueIndex])
            if coordinates == nil then
                -- If there are no more entries left in the queue, then abort
                log_failure(log_reason)
                Queue.pushright(city[queueIndex], coordinates)
                return false
            end
        end

        local startCoordinates = GridUtil.translateCityGridToTileCoordinates(city, coordinates)
        local area = {
            {x = startCoordinates.x, y = startCoordinates.y},
            {x = startCoordinates.x + Constants.CELL_SIZE, y = startCoordinates.y + Constants.CELL_SIZE}
        }

        local cell = GridUtil.safeGridAccess(city, coordinates)

        if coordinates.x <= 1 or coordinates.y <= 1 or coordinates.y >= #city.grid or coordinates.x > #city.grid then
            -- If it's at the edge of the grid, then put it back
            Queue.pushright(city[queueIndex], coordinates)
        elseif cell == nil then
            -- noop, if the grid has not been expanded this far, then don't try to build a building here
            -- this should insert the coordinates at the end of the list, so that
            -- the next iteration will pick a different element from the beginning of the list
            Queue.pushright(city[queueIndex], coordinates)
        elseif cell.type ~= "unused" then
            -- If this location already has a road or building, then don't attempt to build
            -- here again.
            -- noop
        elseif not isAreaFree(area, city.surface_index) then
            -- noop, if there are collidables than retry later
            -- this should insert the coordinates at the end of the list, so that
            -- the next iteration will pick a different element from the beginning of the list
            Queue.pushright(city[queueIndex], coordinates)
        elseif buildingConstruction.buildingType == "simple" and not isConnectedToRoad(city, coordinates) then
            -- Don't build buildings if there is no road connection yet
            Queue.pushright(city[queueIndex], coordinates)
        elseif buildingConstruction.buildingType == "garden" and isConnectedToRoad(city, coordinates) then
            -- Don't build gardens if there's a road right next to it
        else
            local construction_materials = Constants.CONSTRUCTION_MATERIALS[buildingConstruction.buildingType]
            local hardwareStores = Util.list_special_city_buildings(city, "tycoon-hardware-store")
            local cost = Consumption.consumeRequired(construction_materials, hardwareStores, city)
            if cost == nil then
                log_reason = "materials"
                log_failure(log_reason)
                Queue.pushright(city[queueIndex], coordinates)
                return false
            end

            -- We can start a construction site here
            removeCollidingEntities(area, city.surface_index)

            -- Place an excavation site entity that will be later replaced with the actual building
            local excavationPit = game.surfaces[city.surface_index].create_entity{
                name = getRandomBuildingName(city, "excavation-pit"),
                position = {x = startCoordinates.x - 0.5 + Constants.CELL_SIZE / 2, y = startCoordinates.y - 0.5  + Constants.CELL_SIZE / 2},
                force = "player",
                move_stuck_players = true
            }
            excavationPit.destructible = false

            city.grid[coordinates.y][coordinates.x] = {
                type = "building",
                entity = excavationPit,
                createdAtTick = game.tick
            }
            if city.excavationPits == nil then
                city.excavationPits = {}
            end
            table.insert(city.excavationPits, {
                coordinates = coordinates,
                createdAtTick = game.tick,
                buildingConstruction = buildingConstruction,
            })
            return true
        end
    end

    log_failure(log_reason)
    return false
end


--- @param coordinates Coordinates
local function isCharted(city, coordinates)
    local chunkPosition = {
        y = math.floor((GridUtil.getOffsetY(city) + coordinates.y * Constants.CELL_SIZE) / Constants.CHUNK_SIZE),
        x = math.floor((GridUtil.getOffsetX(city) + coordinates.x * Constants.CELL_SIZE) / Constants.CHUNK_SIZE),
    }
    return game.forces.player.is_chunk_charted(game.surfaces[city.surface_index], chunkPosition)
end

--- @param coordinates Coordinates
local function increaseCoordinates(coordinates, city)
    -- Debugged a case where the new value would be above the current grid size --> coordinates.x > #city.grid
    coordinates.x = coordinates.x + 1
    coordinates.y = coordinates.y + 1
end

local function clearAreaAndPrintTiles(city, coordinates, map, tileType)
    local currentCellStartCoordinates = GridUtil.translateCityGridToTileCoordinates(city, {
        x = coordinates.x,
        y = coordinates.y,
    })
    Util.printTiles(currentCellStartCoordinates, map, tileType, city.surface_index, {Constants.GROUND_TILE_TYPES.residential, Constants.GROUND_TILE_TYPES.highrise})

    local currentArea = {
        {currentCellStartCoordinates.x, currentCellStartCoordinates.y},
        {currentCellStartCoordinates.x + Constants.CELL_SIZE, currentCellStartCoordinates.y + Constants.CELL_SIZE}
    }
    removeCollidingEntities(currentArea, city.surface_index, streetIgnorables)

end

--- @param city City
--- @return Coordinates | nil coordinates
local function growAtRandomRoadEnd(city)
    if city.roadEnds == nil then
        city.roadEnds = Queue.new()
        return
    end
    local roadEnd = Queue.popleft(city.roadEnds)

    if roadEnd == nil then
        return
    end

    if roadEnd.coordinates.x <= 1
     or roadEnd.coordinates.x >= GridUtil.getGridSize(city.grid)
     or roadEnd.coordinates.y <= 1
     or roadEnd.coordinates.y >= GridUtil.getGridSize(city.grid)
     then
        -- We need to put the item back first, so that the expansion is applied to it properly
        Queue.pushleft(city.roadEnds, roadEnd)
        -- When expanding the grid I noticed that there sometimes were duplicates, which may have multiplied the coordinate shift (e.g. 3 duplicates meant that x/y for each would be shifted by 3 cells)
        -- No idea why there are duplicates or why the multiplication happens, but removing duplicates helped as well
        Queue.removeDuplicates(city.roadEnds, function(v)
            return v.coordinates.x .. "-" .. v.coordinates.y .. "-" .. v.direction
        end)
        expand_grid(city)
        -- Since we extended the grid (and inserted a top/left row/colum) all roadEnd coordinates need to shift one
        if city.roadEnds ~= nil then
            for value in Queue.iterate(city.roadEnds) do
                increaseCoordinates(value.coordinates, city)
            end
        end
        if city.gardenLocationQueue ~= nil then
            for value in Queue.iterate(city.gardenLocationQueue) do
                increaseCoordinates(value, city)
            end
        end
        if city.buildingLocationQueue ~= nil then
            for value in Queue.iterate(city.buildingLocationQueue) do
                increaseCoordinates(value, city)
            end
        end
        if city.excavationPits ~= nil then
            for _, r in ipairs(city.excavationPits) do
                increaseCoordinates(r.coordinates, city)
            end
        end
        if city.houseLocations ~= nil then
            for _, r in ipairs(city.houseLocations) do
                increaseCoordinates(r, city)
            end
        end
        return
    end

    if not isCharted(city, roadEnd.coordinates) then
        return
    end

    local pickedExpansionDirections = pickRoadExpansion(city, roadEnd)
    if pickedExpansionDirections ~= nil then
        -- For each direction, fill the current cell with the direction and the neighbour with the inverse direction
        for _, direction in ipairs(pickedExpansionDirections) do

            clearAreaAndPrintTiles(city, roadEnd.coordinates, getMap(direction), Constants.GROUND_TILE_TYPES.road)

            local currentCell = GridUtil.safeGridAccess(city, roadEnd.coordinates, "processPickedExpansionDirectionCurrent")
            if currentCell == nil then
                return nil
            end

            if currentCell.roadSockets == nil then
                currentCell.roadSockets = {}
            end
            if Util.indexOf(currentCell.roadSockets, direction) == nil then
                table.insert(currentCell.roadSockets, direction)
            end

            local neighbourPosition
            if direction == "south" then
                neighbourPosition = {x = roadEnd.coordinates.x, y = roadEnd.coordinates.y + 1}
            elseif direction == "east" then
                neighbourPosition = {x = roadEnd.coordinates.x + 1, y = roadEnd.coordinates.y}
            elseif direction == "north" then
                neighbourPosition = {x = roadEnd.coordinates.x, y = roadEnd.coordinates.y - 1}
            elseif direction == "west" then
                neighbourPosition = {x = roadEnd.coordinates.x - 1, y = roadEnd.coordinates.y}
            end

            local neighbourSocket = invertDirection(direction)
            clearAreaAndPrintTiles(city, neighbourPosition, getMap(neighbourSocket), Constants.GROUND_TILE_TYPES.road)

            local neighbourCell = GridUtil.safeGridAccess(city, neighbourPosition, "processPickedExpansionDirectionNeighbour")
            if neighbourCell == nil then
                return nil
            end

            if neighbourCell.type == "road" then
                if Util.indexOf(neighbourCell.roadSockets, neighbourSocket) == nil then
                    table.insert(neighbourCell.roadSockets, neighbourSocket)
                end
            elseif neighbourCell.type == "unused" then
                city.grid[neighbourPosition.y][neighbourPosition.x] = {
                    type = "road",
                    roadSockets = {neighbourSocket}
                }
                -- When creating a new road cell, then we also mark that as a roadEnd to later continue from
                Queue.pushright(city.roadEnds, {
                    coordinates = neighbourPosition,
                    -- We need to use the original direction, so that the next expansion continues in the same direction
                    direction = direction,
                })
            else
                assert(false, "Road should not be expanding into a cell that's not a road or unused.")
            end
        end

        city.surrounding_points_cache = nil
    else
        -- todo: in what cases can't we build here? entity collision? player collision?
        -- buildings should come later to fill empty gaps that have no collisions

        -- Add some weight onto this roadEnd, so that it gets processed later (compared to others who are at a similar distance or don't have their weight changed as much)
        -- roadEnd.additionalWeight = (roadEnd.additionalWeight or 1) * 1.2
        Queue.pushright(city.roadEnds, roadEnd)
    end
    return roadEnd.coordinates
end

local function setHouseLight(houseUnitNumber, lightEntity)
    if storage.tycoon_house_lights == nil then
        storage.tycoon_house_lights = {}
    end

    storage.tycoon_house_lights[houseUnitNumber] = lightEntity
end

local function removeHouseLight(houseUnitNumber)
    if storage.tycoon_house_lights == nil then
        storage.tycoon_house_lights = {}
    end

    local entity = storage.tycoon_house_lights[houseUnitNumber]
    if entity ~= nil and entity.valid then
        entity.destroy()
    end
    storage.tycoon_house_lights[houseUnitNumber] = nil
end

--- @param excavationPits ExcavationPit[]
--- @param buildingTypes BuildingType[] | nil
--- @return ExcavationPit | nil excavationPit
local function findReadyExcavationPit(excavationPits, buildingTypes)
    local completableBuildingTypes = {"tycoon-treasury", "garden", "tycoon-bottle-return-station"}
    if buildingTypes ~= nil then
        for _, value in ipairs(buildingTypes) do
            table.insert(completableBuildingTypes, value)
        end
    end

    for i, e in ipairs(excavationPits) do
        if e.createdAtTick + e.buildingConstruction.constructionTimeInTicks < game.tick then
            if Util.indexOf(completableBuildingTypes, e.buildingConstruction.buildingType) ~= nil then
                return table.remove(excavationPits, i)
            end
        end
    end
    return nil
end

--- @param houseUnitNumber number
--- @param mapPosition Coordinates
--- @param buildingType BuildingType
--- @param surface_index number
local function createLight(houseUnitNumber, mapPosition, buildingType, surface_index)
    local light
    if buildingType == "residential" then
        light = game.surfaces[surface_index].create_entity{
            name = "hiddenlight-40",
            position = mapPosition,
            force = "neutral",
        }
    elseif buildingType == "highrise" then
        light = game.surfaces[surface_index].create_entity{
            name = "hiddenlight-60",
            position = mapPosition,
            force = "neutral",
        }
    end
    if light ~= nil then
        setHouseLight(houseUnitNumber, light)
    end
end

local function growCitizenCount(city, count, tier)
    if city.citizens[tier] == nil then
        city.citizens[tier] = 0
    end
    city.citizens[tier] = city.citizens[tier] + count
    if city.citizens[tier] < 0 then
        -- This is just a coding safeguard in case there's buggy code that tries to lower it below 0.
        city.citizens[tier] = 0
    end
    Consumption.updateNeeds(city)
end

--- @param buildingTypes BuildingType[] | nil
--- @return string tileType
local function get_ground_tile_type(buildingType)
    -- "simple"
    -- "residential"
    -- "highrise"
    -- "tycoon-treasury"
    -- "garden"
    return Constants.GROUND_TILE_TYPES[buildingType] or Constants.GROUND_TILE_TYPES.simple
end

--- @param city City
--- @param buildingTypes BuildingType[] | nil
--- @return BuildingType | nil completedConstruction
local function completeConstruction(city, buildingTypes)

    if city.excavationPits == nil or #city.excavationPits == 0 then
        return nil
    end

    local excavationPit = findReadyExcavationPit(city.excavationPits, buildingTypes)
    if excavationPit == nil then
        return nil
    end
    local coordinates = excavationPit.coordinates
    local cell = GridUtil.safeGridAccess(city, coordinates, "completeConstruction")
    if cell ~= nil and cell.entity ~= nil then
        if cell.entity.valid then
            cell.entity.destroy()
        end
        cell.entity = nil
    end

    local startCoordinates = GridUtil.translateCityGridToTileCoordinates(city, coordinates)
    local housingTier = excavationPit.buildingConstruction.buildingType
    Util.printTiles(startCoordinates, {
        "111111",
        "111111",
        "111111",
        "111111",
        "111111",
        "111111",
    }, get_ground_tile_type(housingTier), city.surface_index)
    local entity
    if housingTier == "simple" or housingTier == "residential" or housingTier == "highrise" then
        local xModifier, yModifier = 0, 0
        if housingTier == "simple" then
            -- no shift
        elseif housingTier == "residential" then
            yModifier = -0.5
        end
        local position = {x = startCoordinates.x + Constants.CELL_SIZE / 2 + xModifier, y = startCoordinates.y + Constants.CELL_SIZE / 2 + yModifier}
        entity = game.surfaces[city.surface_index].create_entity{
            -- WARN: prefixing with "house-" because of allowed shorter format
            name = getRandomBuildingName(city, "house-".. housingTier),
            position = position,
            force = "player",
            move_stuck_players = true
        }
        createLight(entity.unit_number, position, housingTier, city.surface_index)

        if city.buildingCounts == nil then
            city.buildingCounts = {
                simple = 0,
                residential = 0,
                highrise = 0,
            }
        end
        city.buildingCounts[housingTier] = city.buildingCounts[housingTier] + 1

        if city.houseLocations == nil then
            city.houseLocations = {}
        end
        table.insert(city.houseLocations, coordinates)

        local sideNeighboursOfCompletedHouse = getSurroundingCoordinates(coordinates, 1, false)
        for _, n in ipairs(sideNeighboursOfCompletedHouse) do
            local neighbourCell = GridUtil.safeGridAccess(city, n)
            if neighbourCell ~= nil and neighbourCell.type == "unused" then
                local surroundsOfUnused = getSurroundingCoordinates(n, 1, false)
                -- Test if this cell is surrounded by houses, if yes then place a garden
                -- Because we use getSurroundingCoordinates with allowDiagonal=false above, we only need to count 4 houses or roads
                local surroundCount = 0
                for _, s in ipairs(surroundsOfUnused) do
                    local surroundingCell = GridUtil.safeGridAccess(city, s)
                    if surroundingCell ~= nil and surroundingCell.type == "building" then
                        surroundCount = surroundCount + 1
                    end
                end
                -- Sometimes there are also 2 unused cells within a housing group. We probably need a better check, but for now we'll just build gardens when there are 3 houses.
                if surroundCount >= 3 then
                    Queue.pushright(city.gardenLocationQueue, n)
                end
            end
        end

        if housingTier == "residential" or housingTier == "highrise" then
            local range = housingTier == "residential" and 2 or 3
            local allNeighboursOfCompletedHouse = getCircularSurroundingCoordinates(coordinates, range, city)
            for _, neighbourCoords in pairs(allNeighboursOfCompletedHouse) do
                if neighbourCoords ~= nil then
                    FloorUpgradesQueue.push(city, neighbourCoords, Constants.GROUND_TILE_TYPES[housingTier])
                end
            end
        end

        growCitizenCount(city, Constants.CITIZEN_COUNTS[housingTier], housingTier)
    elseif housingTier == "garden" then
        entity = game.surfaces[city.surface_index].create_entity{
            name = getRandomBuildingName(city, housingTier),
            position = {x = startCoordinates.x + Constants.CELL_SIZE / 2, y = startCoordinates.y  + Constants.CELL_SIZE / 2},
            force = "player",
            move_stuck_players = true
        }
    else
        local yModifier, xModifier = 0, 0
        if housingTier == "tycoon-treasury" then
            xModifier = -0.5
            yModifier = 0
        end
        entity = game.surfaces[city.surface_index].create_entity{
            name = housingTier,
            position = {x = startCoordinates.x + Constants.CELL_SIZE / 2 + xModifier, y = startCoordinates.y  + Constants.CELL_SIZE / 2 + yModifier},
            force = "player",
            move_stuck_players = true,
            raise_built = true,
        }
    end

    city.grid[coordinates.y][coordinates.x] = {
        type = "building",
        buildingType = housingTier,
        createdAtTick = game.tick,
        entity = entity,
    }
    Util.addGlobalBuilding(entity.unit_number, city.id, entity)
    -- WARN: we must always register
    script.register_on_object_destroyed(entity)

    if housingTier == "tycoon-treasury" and not storage.tycoon_intro_message_treasury_displayed then
        game.print({"", "[color=orange]Factorio Tycoon:[/color] ", {"tycooon-info-message-treasury"}})
        storage.tycoon_intro_message_treasury_displayed = true
    end
    if housingTier == "tycoon-bottle-return-station" and not storage.tycoon_intro_message_bottle_return_station_displayed then
        game.print({"", "[color=orange]Factorio Tycoon:[/color] ", {"tycooon-info-message-bottle-return-station"}})
        storage.tycoon_intro_message_bottle_return_station_displayed = true
    end

    return housingTier
end

local upgrade_paths = {
    simple = {
        waitTime = 300,
        previousStage = "simple",
        nextStage = "residential",
        upgradeDurationInSeconds = {30, 60}
    },
    residential = {
        waitTime = 600,
        previousStage = "residential",
        nextStage = "highrise",
        upgradeDurationInSeconds = {120, 240}
    }
}

--- @param city City
--- @param coordinates Coordinates
local function hasEmptySurroundingSpace(city, coordinates, size)
    local y = coordinates.y
    local x = coordinates.x
    assert(y ~= nil and x ~= nil, "Coordinates must not be nil, but received ".. tostring(coordinates))
    for i = -1 * size, size, 1 do
        for j = -1 * size, size, 1 do
            local cell = GridUtil.safeGridAccess(city, {y = y+i, x = x+j})
            if cell == nil or cell.type == "unused" then
                return true
            end
        end
    end
    return false
end

local function hasPlayerEntities(city, coordinates)
    local startCoordinates = GridUtil.translateCityGridToTileCoordinates(city, coordinates)
    local area = {
        {x = startCoordinates.x, y = startCoordinates.y},
        {x = startCoordinates.x + Constants.CELL_SIZE, y = startCoordinates.y + Constants.CELL_SIZE}
    }
    local playerEntities = game.surfaces[city.surface_index].find_entities_filtered({
        area=area,
        force=game.forces.player,
        limit=1
    })
    local countNonHouses = 0
    for _, v in ipairs(playerEntities) do
        if not string.find(v.name, "tycoon-house-", 1, true) then
            countNonHouses = countNonHouses + 1
        end
    end
    return countNonHouses > 0
end

--- @param city City
--- @param limit number
--- @param upgradeTo BuildingType
local function findUpgradableCells(city, limit, upgradeTo)
    local upgradeCells = {}
    for _, coordinates in ipairs(city.houseLocations or {}) do
        local cell = GridUtil.safeGridAccess(city, coordinates, "findUpgradableCells")
        if cell ~= nil and cell.type == "building" and cell.buildingType ~= nil then
            local upgradePath = upgrade_paths[cell.buildingType]
            if upgradePath ~= nil and upgradePath.nextStage == upgradeTo then
                if (cell.createdAtTick + upgradePath.waitTime) < game.tick then

                    -- Check that all surrounding cells are in use. It would be odd to build a skyscraper in open space.
                    local emptySurroundingSpace = hasEmptySurroundingSpace(city, coordinates, 1)

                    -- If the player has built entities in this cell in the meantime, we can either not upgrade or destroy their entities. Staying safe and not upgrading is probably better.
                    if not emptySurroundingSpace and not hasPlayerEntities(city, coordinates) then
                        table.insert(upgradeCells, {
                            cell = cell,
                            upgradePath = upgradePath,
                            coordinates = coordinates,
                        })
                    end

                    if #upgradeCells >= limit then
                        break
                    end
                end
            end
        end
    end
    return upgradeCells
end

--- NOTE: this function DOES NOT clear city grid cell, must be done manually if needed
--- @param city City | nil
--- @param unit_number number
local function removeBuilding(city, unit_number)
    log("removeBuilding(): unit_number: ".. serpent.line(unit_number))

    -- remove anything related in reverse order
    removeHouseLight(unit_number)

    -- this also checks (unit_number == nil)
    local building = Util.getGlobalBuilding(unit_number)
    if building == nil then
        return
    end
    --log("removeBuilding(): building: ".. serpent.line(building))

    --- NOTE: switch city reference block, common to all the checks below
    city = city or Util.findCityById(building.cityId)
    if city == nil then
        log("removeBuilding(): ERROR: unable to get city reference!")
    end
    -- WARN: this weird case should never happen, but we must always check
    if city ~= nil and city.id ~= building.cityId then
        local msg = string.format("removeBuilding(): ERROR: city.id: %s doesn't match building.cityId: %s, unit_number: %d",
            tostring(city.id), tostring(building.cityId), unit_number)
        log(msg)
        -- shout to players as well!
        game.print("[color=orange]Factorio Tycoon:[/color] ".. msg)

        -- switch city reference in this case
        city = Util.findCityById(building.cityId)
        --assert(city ~= nil, "omg, i'm out...")
    end
    --- end block

    -- buildings may have lots of deps...
    if Util.isHouse(building.entity_name) then
        local housingTier
        if string.find(building.entity_name, "tycoon-house-simple-", 1, true) then
            housingTier = "simple"
        elseif string.find(building.entity_name, "tycoon-house-residential-", 1, true) then
            housingTier = "residential"
        elseif string.find(building.entity_name, "tycoon-house-highrise-", 1, true) then
            housingTier = "highrise"
        end

        assert(housingTier, "removeBuilding(): Unknown housingTier: ".. housingTier)

        -- must still check city...
        if city ~= nil then
            growCitizenCount(city, -1 * Constants.CITIZEN_COUNTS[housingTier], housingTier)

            -- remove from other lists as well
            city.buildingCounts[housingTier] = (city.buildingCounts[housingTier] or 1) - 1
            if city.houseLocations ~= nil then
                local posGrid = GridUtil.translateToGrid(city, building.position)
                table.remove(city.houseLocations, Util.indexOf(city.houseLocations, posGrid))
            end
        end
    else
        log("removeBuilding(): not house: ".. building.entity_name)
    end

    -- remove from global and finally destroy
    Util.removeGlobalBuilding(unit_number)
    if building.entity ~= nil and building.entity.valid then
        building.entity.destroy()
    end
end

--- NOTE: this function DOES NOT re-add this cell to building queue, used for upgrades mostly
local function clearCell(city, upgradeCell)
    --log("clearCell(): upgradeCell: ".. serpent.line(upgradeCell))
    if upgradeCell == nil or upgradeCell.cell == nil then
        log("clearCell(): upgradeCell: ".. serpent.line(upgradeCell))
        return
    end

    local unit_number = nil
    local entity = upgradeCell.cell.entity
    if entity ~= nil and entity.valid then
        unit_number = entity.unit_number
    elseif upgradeCell.unit_number ~= nil then
        -- WARN: unit_number is added only by freeCellAtPosition()
        unit_number = upgradeCell.unit_number
    end
    if unit_number ~= nil then
        removeBuilding(city, unit_number)
    else
        log("clearCell(): ERROR: unable to call removeBuilding(), no unit_number!")
    end

    -- We need to clear the cell as well, so that the construction has available space
    GridUtil.safeGridSet(city, upgradeCell.coordinates, { type = "unused" })
end

--- NOTE: this function DOES re-add cell to building queue! called from event handlers mostly
--- @param city City
--- @param position MapPosition
--- @param unit_number number | nil
local function freeCellAtPosition(city, position, unit_number)
    log("freeCellAtPosition(): position: ".. serpent.line(position))
    local cellCoordinates = GridUtil.translateToGrid(city, position)
    local cell = GridUtil.safeGridAccess(city, cellCoordinates)
    if cell == nil then
        return
    end

    -- check for incorrect cell
    --assert(cell.type == "building")
    if cell.type ~= "building" then
        log(string.format("!!! cell.type: %s pos: %s city: %s", cell.type, serpent.line(cellCoordinates), city.name))
    end

    if cell.type == "building" then
        -- WARN: this can't call removeBuilding() on_entity_destroyed event, so we provide unit_number in ugly way
        clearCell(city, {cell = cell, coordinates = cellCoordinates, unit_number = unit_number})
    end

    -- include actual position itself (allowCenter = true)
    addBuildingLocations(city, cellCoordinates, true)
    -- TODO: test and add already-occupied-cell check in startConstruction()
    -- TODO: city itself should choose locations closest to center, so just add to the end
    --Queue.pushright(city.buildingLocationQueue, cellCoordinates)
end

--- @param city City
--- @param newStage string
local function upgradeHouse(city, newStage)
    -- todo: test if the game destroying an entity also triggers the destroy hook (and change the citizen counter reduction accordingly)
    local upgradeCells = findUpgradableCells(city, 10, newStage)

    if #upgradeCells == 0 then
        return false
    end

    local upgradeCell = upgradeCells[city.generator(#upgradeCells)]

    clearCell(city, upgradeCell)

    local upgradePath = upgradeCell.upgradePath

    local constructionTimeInTicks = city.generator(upgradePath.upgradeDurationInSeconds[1] * 60, upgradePath.upgradeDurationInSeconds[2] * 60)

    startConstruction(city, {
        buildingType = upgradePath.nextStage,
        constructionTimeInTicks = constructionTimeInTicks,
    }, "buildingLocationQueue", {upgradeCell.coordinates})
end

local function construct_priority_buildings()
    for _, city in ipairs(storage.tycoon_cities or {}) do
        local prio_building = table.remove(city.priority_buildings, 1)
        if prio_building ~= nil then
            local is_built = startConstruction(city, {
                buildingType = prio_building.name,
                -- Special buildings should be completed very quickly.
                -- Here we just wait 2 seconds by default.
                constructionTimeInTicks = 120,
            }, "buildingLocationQueue")
            if not is_built then
                table.insert(city.priority_buildings, 1, prio_building)
            end
        end
    end
end

local function construct_gardens()
    for _, city in ipairs(storage.tycoon_cities or {}) do
        if city.gardenLocationQueue ~= nil and city.generator() < 0.25 and Queue.count(city.gardenLocationQueue, true) > 0 then
            startConstruction(city, {
                buildingType = "garden",
                constructionTimeInTicks = city.generator(300, 600)
            }, "gardenLocationQueue")
        end
    end
end

local lower_tiers = {
    highrise = "residential",
    residential = "simple"
}

local house_ratios = {
    residential = Constants.RESIDENTIAL_HOUSE_RATIO,
    highrise = Constants.HIGHRISE_HOUSE_RATIO,
}

local function is_allowed_upgrade_to_tier(city, next_tier)
    if not game.forces.player.technologies["tycoon-" .. next_tier .. "-housing"].researched then
        return false
    end

    local current_tier_count = ((city.buildingCounts or {})[lower_tiers[next_tier]] or 0)
    local next_tier_count = ((city.buildingCounts or {})[next_tier] or 0)
    if Util.countPendingLowerTierHouses(current_tier_count, next_tier_count, house_ratios[next_tier]) > 0 then
        return false
    end

    return true
end


local function getBuildables(hardwareStores)
    local supply = Util.aggregateSupplyBuildingResources(hardwareStores)

    local buildables = {}
    for key, resources in pairs(Constants.CONSTRUCTION_MATERIALS) do
        local anyResourceMissing = false
        for name, required in pairs(resources) do
            if (supply[name] or 0) < required then
                anyResourceMissing = true
                break
            end
        end

        if not anyResourceMissing then
            buildables[key] = resources
        end
    end

    return buildables
end

local function has_time_elapsed_for_construction(city, tier)
    local timer = (city.construction_timers or {})[tier] or {
        last_construction = 0,
        construction_interval = math.huge
    }
    return timer.last_construction + timer.construction_interval < game.tick
end

local function start_house_construction()
    for _, city in ipairs(storage.tycoon_cities or {}) do
        -- Check if resources are available. Without resources no growth is possible.
        local hardware_stores = Util.list_special_city_buildings(city, "tycoon-hardware-store")
        if #hardware_stores > 0 then

            local buildables = getBuildables(hardware_stores)
            -- If there are no hardware stores, then no construction resources are available.
            -- use CITIZEN_COUNTS as housing tiers list
            for tier, _ in pairs(Constants.CITIZEN_COUNTS) do
                if has_time_elapsed_for_construction(city, tier)
                    and buildables[tier] ~= nil then

                    assert((city.construction_timers or {})[tier], "Expected construction timer to be defined by them time the timer check resolves to true.")
                    city.construction_timers[tier].last_construction = game.tick

                    if tier == "simple" then
                        startConstruction(city, {
                            buildingType = "simple",
                            constructionTimeInTicks = city.generator(600, 1200)
                        }, "buildingLocationQueue")
                        city.surrounding_points_cache = nil
                    elseif is_allowed_upgrade_to_tier(city, tier) then
                        upgradeHouse(city, tier)
                    end
                end
            end
        end
    end
end

local function complete_house_construction()
    for _, city in ipairs(storage.tycoon_cities or {}) do
        completeConstruction(city, {"simple", "residential", "highrise", "tycoon-treasury", "garden"})
    end
end

local function isPointWithinCity(city, point)
    local circlePoints = Util.approximateCircleAroundCity(city)
    local n = #circlePoints
    local inside = false

    for i = 1, n do
        local j = i % n + 1
        local vi = circlePoints[i]
        local vj = circlePoints[j]

        if ((vi.y > point.y) ~= (vj.y > point.y)) and
           (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x) then
            inside = not inside
        end
    end

    return inside
end

local function findTriples(city)
    local cornerList = Util.approximateCircleAroundCity(city)

    local triples = {}
    for i = 1, #cornerList do
        -- {X, Y}
        local c1 = cornerList[i]
        local c2 = cornerList[i % #cornerList + 1]
        table.insert(triples, { c1, c2, city.center })
    end

    return triples
end

local CITY = {
    growAtRandomRoadEnd = growAtRandomRoadEnd,
    growCitizenCount = growCitizenCount,
    updatePossibleBuildingLocations = addBuildingLocations,
    completeConstruction = completeConstruction,
    startConstruction = startConstruction,
    isCellFree = isCellFree,
    freeCellAtPosition = freeCellAtPosition,
    construct_priority_buildings = construct_priority_buildings,
    construct_gardens = construct_gardens,
    start_house_construction = start_house_construction,
    complete_house_construction = complete_house_construction,
    findTriples = findTriples,
    is_point_within_city = isPointWithinCity,
}

return CITY
