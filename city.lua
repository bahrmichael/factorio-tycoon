DEBUG = require("debug")
local Queue = require("queue")

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

--- @param p1 Coordinates
--- @param p2 Coordinates
--- @return number The distance between the two points.
local function calculateDistance(p1, p2)
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    return math.sqrt(dx * dx + dy * dy)
end

--- @param coordinates Coordinates
--- @param sendWarningForMethod string | nil
--- @return Cell | nil cell
local function safeGridAccess(city, coordinates, sendWarningForMethod)
    local row = city.grid[coordinates.y]
    if row == nil then
        if sendWarningForMethod ~= nil then
            game.print({"", {"tycoon-grid-access-warning", {"tycoon-grid-access-row"}, sendWarningForMethod}})
        end
        return nil
    end
    local cell = row[coordinates.x]
    if cell == nil then
        if sendWarningForMethod ~= nil then
            game.print({"", {"tycoon-grid-access-warning", {"tycoon-grid-access-row"}, sendWarningForMethod}})
        end
        return nil
    end
    return cell
end

-- Each cell has 6x6 tiles
local CELL_SIZE = 6

--- @param grid Cell[][]
local function getGridSize(grid)
    return #grid
end

--- @param city City
local function getOffsetX(city)
    return -1 * (getGridSize(city.grid) - 1) / 2 + city.center.x
end

--- @param city City
local function getOffsetY(city)
    return -1 * (getGridSize(city.grid) - 1) / 2 + city.center.y
end

--- @param coordinates Coordinates
--- @return string key
local function buildCoordinatesKey(coordinates)
    return coordinates.y .. "/" .. coordinates.x
end

local cachedDistances = {}

--- @param coordinates Coordinates
--- @return number distanceFromTownHall
local function getCachedDistance(coordinates, offsetY, offsetX, cityCenter)
    local key = buildCoordinatesKey(coordinates)
    if cachedDistances[key] ~= nil then
        return cachedDistances[key]
    else
        local distance = calculateDistance({
            y = (coordinates.y + offsetY) * CELL_SIZE,
            x = (coordinates.x + offsetX) * CELL_SIZE,
        }, cityCenter)
        cachedDistances[key] = distance
        return distance
    end
end

--- @param y number
--- @param x number
--- @param size number
--- @param allowDiagonal boolean
--- @return Coordinates[] coordinates
local function getSurroundingCoordinates(y, x, size, allowDiagonal)
   local c = {}
   for i = -1 * size, size, 1 do
    for j = -1 * size, size, 1 do
        if (allowDiagonal or (math.abs(i) ~= math.abs(j))) then
            if not(i == 0 and j == 0) then
                table.insert(c, {
                    y = i + y,
                    x = j + x
                })
            end
        end
    end
   end
   return c
end

-- Return the first index with the given value (or nil if not found).
--- @param array any[]
--- @param value any
--- @return number | nil Index The index of the element in the array, or nil if there's no match.
local function indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end

local defaultRemovableEntities = {
    "rock-",
    "sand-rock-",
    "dead-grey-trunk",
    "tree-"
}

--- @param area any
--- @param ignorables string[] | nil
local function removeColldingEntities(area, ignorables)
    local printEntities = game.surfaces[1].find_entities_filtered({area=area})
    for _, entity in pairs(printEntities) do
        for _, removable in pairs(defaultRemovableEntities) do
            if entity.valid and string.find(entity.name, removable, 1, true) then
                if ignorables ~= nil and #ignorables > 0 and indexOf(ignorables, entity.name) ~= nil then
                    -- noop, skip ignorables
                else
                    entity.destroy()
                end
            end
        end
    end
end

local function hasCliffsOrWater(area)
    local tiles = game.surfaces[1].find_tiles_filtered{
        area = area,
        name = {"water", "deepwater", "cliff"},
        limit = 1
    }
    return #tiles > 0
end

--- @param area any
--- @param additionalIgnorables string[] | nil
local function isAreaFree(area, additionalIgnorables)
    -- Water / Cliffs
    if hasCliffsOrWater(area) then
        return false
    end

    local ignorables = {"rock-huge", "rock-big", "sand-rock-big", "dead-grey-trunk"}
    if additionalIgnorables ~= nil and #additionalIgnorables >0 then
        for _, value in ipairs(additionalIgnorables) do
            table.insert(ignorables, value)
        end
    end

    -- Too many trees / Other entities
    local entities = game.surfaces[1].find_entities_filtered({
        area=area,
        type={"tree"},
        name=ignorables,
        invert=true,
        limit = 100,
    })
    return #entities == 0
end

--- @alias Collidable
---| "free"
---| "only-straight-rail"
---| "blocked"

--- @param city City
--- @param coordinates Coordinates
--- @param additionalIgnorables string[] | nil
--- @return Collidable
local function checkForCollidables(city, coordinates, additionalIgnorables)
    local startCoordinates = {
        y = (coordinates.y + getOffsetY(city)) * CELL_SIZE,
        x = (coordinates.x + getOffsetX(city)) * CELL_SIZE,
    }
    local area = {
        {startCoordinates.x, startCoordinates.y},
        {startCoordinates.x + CELL_SIZE, startCoordinates.y + CELL_SIZE}
    }
    -- Water / Cliffs
    if hasCliffsOrWater(area) then
        return "blocked"
    end

    local ignorables = {"rock-huge", "rock-big", "sand-rock-big", "dead-grey-trunk"}
    if additionalIgnorables ~= nil and #additionalIgnorables >0 then
        for _, value in ipairs(additionalIgnorables) do
            table.insert(ignorables, value)
        end
    end

    -- Too many trees / Other entities
    local entities = game.surfaces[1].find_entities_filtered({
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
    local old_size = getGridSize(city.grid)
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
    local surroundsOfUnused = getSurroundingCoordinates(coordinates.y, coordinates.x, 1, false)
    for _, s in ipairs(surroundsOfUnused) do
        local surroundingCell = safeGridAccess(city, s)
        if surroundingCell ~= nil and surroundingCell.type == "road" then
            DEBUG.log("y=" .. coordinates.y .. " x=" .. coordinates.x .. " has road neighbour: y=" .. s.y .. " x=" .. s.x)
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
    local startCoordinates = {
        y = (coordinates.y + getOffsetY(city)) * CELL_SIZE,
        x = (coordinates.x + getOffsetX(city)) * CELL_SIZE,
    }
    local area = {
        {startCoordinates.x, startCoordinates.y},
        {startCoordinates.x + CELL_SIZE, startCoordinates.y + CELL_SIZE}
    }

    -- Too many trees / Other entities
    local entities = game.surfaces[1].find_entities_filtered({
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
    DEBUG.log("Testing directions: " .. table.concat(lookoutDirections, ","))

    -- Test the compatibility of the directions
    for _, direction in ipairs(lookoutDirections) do
        DEBUG.log("Testing direction: " .. direction)
        local neighbourPosition = continueInDirection(roadEnd.coordinates, direction, 1)

        local collidables = checkForCollidables(city, neighbourPosition, streetIgnorables)

        if collidables == "blocked" then
            DEBUG.log("Test result: False, because collidables")
            return false
        elseif collidables == "only-straight-rail" then
             local isCrossing = areStraightRailsOrthogonal(city, neighbourPosition, direction)
             if not isCrossing then
                DEBUG.log("Test result: False, because not a rail crossing")
                return false
             end
        end

        -- This should never be fail, because the upstream function is supposed to expand the grid if the position is on the outsides
        local neighbourCell = safeGridAccess(city, neighbourPosition, "testRoadDirection")
        if neighbourCell == nil then
            return false
        end

        if global.tycoon_enable_debug_logging then
            if neighbourCell.type ~= nil and neighbourCell.type ~= "unused" then
                DEBUG.log("Neighbour: " .. neighbourCell.type)
                if neighbourCell.type == "road" then
                    DEBUG.log("Neighbour(" .. "y=" .. neighbourPosition.y .. " x=" .. neighbourPosition.x  .. ") road sockets: " .. table.concat(neighbourCell.roadSockets, ","))
                end
            end
        end

        -- Streets must not expand into buildings or collidables, but may expand into empty fields or streets
        if neighbourCell.type == "unused" then
            -- noop, cell is free
        elseif neighbourCell.type == "building" then
            DEBUG.log("Test result: False, because building")
            return false
        elseif neighbourCell.type == "road" then
            if indexOf(neighbourCell.roadSockets, invertDirection(direction)) ~= nil then
                DEBUG.log("Test result: False, because road with inverted direction")
                return false
            end
        elseif #neighbourCell == 1 and (neighbourCell[1] == "linear.vertical" or neighbourCell[1] == "linear.horizontal" or neighbourCell[1] == "town-hall" or neighbourCell[1] == "intersection") then
            DEBUG.log("Test result: False, because start field")
            return false
        elseif neighbourCell.type ~= "road" then
            DEBUG.log("---1")
        else
            DEBUG.log("---2")
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
            local cell = safeGridAccess(city, position)
            if cell ~= nil and cell.type == "road" then
                local sockets = cell.roadSockets or {}
                for _, socket in ipairs(sockets) do
                    if socket == direction or socket == invertDirection(direction) then
                        DEBUG.log("Test result: False, because parallel road (" .. socket .. ", y=" .. position.y .. "x=" .. position.x .. ")")
                        return false
                    end
                end
            end
        end
    end

    DEBUG.log("Test result: True")
    return true
end

local weightedRoadConnections

--- @return RoadConnectionCount[] connectionCountOptions
local function getRoadConnectionCountOptions()

    if weightedRoadConnections ~= nil then
        return weightedRoadConnections
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

    weightedRoadConnections = values

    return values
end

local function shuffle(tbl)
    for i = #tbl, 2, -1 do
      local j = global.tycoon_global_generator(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

--- @param city City
--- @param roadEnd RoadEnd
--- @return Direction[] | nil
local function pickRoadExpansion(city, roadEnd)
    DEBUG.log('ENTER pickRoadExpansion')
    local left = getLeftDirection(roadEnd.direction)
    local right = getRightDirection(roadEnd.direction)

    local options = getRoadConnectionCountOptions()
    shuffle(options)

    for _, option in ipairs(options) do
        DEBUG.log('Check connections: ' .. option)
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
                local cell = safeGridAccess(city, previousCell)
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
            DEBUG.log("Should build straight: " .. tostring(shouldBuildStraight) .. " (straight length: " .. straightStreetLength .. ")")
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

--- @param start Coordinates
--- @param map string[]
--- @param tileName string
local function printTiles(start, map, tileName)
    local x, y = start.x, start.y
    local tiles = {}
    for _, value in ipairs(map) do
        for i = 1, #value do
            local char = string.sub(value, i, i)
            if char == "1" then
                table.insert(tiles, {name = tileName, position = {x, y}})
            end
            x = x + 1
        end
        x = start.x
        y = y + 1
    end
    game.surfaces[1].set_tiles(tiles)
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

local totalGardenSprites = 13
local gardenSpriteIterator = 0

local function getIteratedGardenName()
    gardenSpriteIterator = gardenSpriteIterator + 1
    return "tycoon-garden-" .. (gardenSpriteIterator % totalGardenSprites) + 1
end

local totalExcavationPitSprites = 20
local excavationPitSpriteIterator = 0

local function getIteratedExcavationPitName()
    excavationPitSpriteIterator = excavationPitSpriteIterator + 1
    return "tycoon-excavation-pit-" .. (excavationPitSpriteIterator % totalExcavationPitSprites) + 1
end

local totalSimpleHouseSprites = 14
local simpleHouseSpriteIterator = 0

local function getIteratedSimpleHouseName()
    simpleHouseSpriteIterator = simpleHouseSpriteIterator + 1
    return "tycoon-house-simple-" .. (simpleHouseSpriteIterator % totalSimpleHouseSprites) + 1
end

local totalResidentialHouseSprites = 9
local residentialHouseSpriteIterator = 0

local function getIteratedResidentialHouseName()
    residentialHouseSpriteIterator = residentialHouseSpriteIterator + 1
    return "tycoon-house-residential-" .. (residentialHouseSpriteIterator % totalResidentialHouseSprites) + 1
end

local totalHighriseHouseSprites = 8
local highriseHouseSpriteIterator = 0

local function getIteratedHighriseHouseName()
    highriseHouseSpriteIterator = highriseHouseSpriteIterator + 1
    return "tycoon-house-highrise-" .. (highriseHouseSpriteIterator % totalHighriseHouseSprites) + 1
end

--- @param buildingType BuildingType
local function getIteratedHouseName(buildingType)
    if buildingType == "simple" then
        return getIteratedSimpleHouseName()
    elseif buildingType == "residential" then
        return getIteratedResidentialHouseName()
    elseif buildingType == "highrise" then
        return getIteratedHighriseHouseName()
    else
        assert(false, "Expected building type, but received: " .. tostring(buildingType))
    end
end

--- @param city City
--- @param recentCoordinates Coordinates | nil
local function addBuildingLocations(city, recentCoordinates)
    if city.buildingLocationQueue == nil then
        city.buildingLocationQueue = Queue.new()
    end
    if city.gardenLocationQueue == nil then
        city.gardenLocationQueue = Queue.new()
    end

    if recentCoordinates ~= nil then
        local surrounds = getSurroundingCoordinates(recentCoordinates.y, recentCoordinates.x, 1, false)
        for _, value in ipairs(surrounds) do
            if value.x <= 1 or value.y <= 1 or value.x >= #city.grid or value.y >= #city.grid then
                -- Skip locations that are at the edge of the grid or beyond
            else
                    -- Only check cells that are unused and may have a building built there
                local cell = safeGridAccess(city, value)
                local isUnused = cell ~= nil and cell.type == "unused"
                if isUnused then

                    -- Then check if there are any open roadEnds surrounding this unused field
                    local surroundsOfUnused = getSurroundingCoordinates(value.y, value.x, 1, false)
                    local hasSurroundingRoadEnd = false
                    for _, s in ipairs(surroundsOfUnused) do
                        if indexOf(recentCoordinates, s) ~= nil then
                            hasSurroundingRoadEnd = true
                            break
                        end
                    end
                    if not hasSurroundingRoadEnd then
                        if hasSurroundingRoad(city, value) then
                            local offsetY = getOffsetY(city)
                            local offsetX = getOffsetX(city)
                            local cityCenter = {
                                x = city.center.x + CELL_SIZE,
                                y = city.center.y + CELL_SIZE,
                            }
                            local distanceA = getCachedDistance(value, offsetY, offsetX, cityCenter)
                            Queue.insert(city.buildingLocationQueue, value, math.ceil(distanceA))
                        else
                            -- Test if this cell is surrounded by houses, if yes then place a garden
                            -- Because we use getSurroundingCoordinates with allowDiagonal=false above, we only need to count 4 houses or roads
                            local surroundCount = 0
                            for _, s in ipairs(surroundsOfUnused) do
                                local surroundingCell = safeGridAccess(city, s)
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
    local startCoordinates = {
        y = (cellCoordinates.y + getOffsetY(city)) * CELL_SIZE,
        x = (cellCoordinates.x + getOffsetX(city)) * CELL_SIZE,
    }
    local area = {
        {x = startCoordinates.x, y = startCoordinates.y},
        {x = startCoordinates.x + CELL_SIZE, y = startCoordinates.y + CELL_SIZE}
    }
    return isAreaFree(area)
end

--- @param city City
--- @param coordinates Coordinates
--- @return boolean
local function isConnectedToRoad(city, coordinates)
    local surrounds = getSurroundingCoordinates(coordinates.y, coordinates.x, 1, false)
    for _, s in ipairs(surrounds) do
        local c = safeGridAccess(city, s)
        if c ~= nil and c.type == "road" then
            return true
        end
    end
    return false
end

--- @param city City
--- @param buildingConstruction BuildingConstruction
--- @param allowedCoordinates Coordinates[] | nil
--- @return boolean started
local function startConstruction(city, buildingConstruction, queue, allowedCoordinates)
    if queue == nil then
        queue = Queue.new()
    end

    -- Make up to 10 attempts to find a location where we can start a construction site
    local attempts = 10
    if allowedCoordinates ~= nil then
        attempts = #allowedCoordinates
    end
    for i = 1, attempts, 1 do
        local coordinates
        if allowedCoordinates ~= nil then
            coordinates = table.remove(allowedCoordinates)
        else
            coordinates = Queue.popleft(queue)
            if coordinates == nil then
                -- If there are no more entries left in the queue, then abort
                return false
            end
        end

        local startCoordinates = {
            y = (coordinates.y + getOffsetY(city)) * CELL_SIZE,
            x = (coordinates.x + getOffsetX(city)) * CELL_SIZE,
        }
        local area = {
            {x = startCoordinates.x, y = startCoordinates.y},
            {x = startCoordinates.x + CELL_SIZE, y = startCoordinates.y + CELL_SIZE}
        }

        local cell = safeGridAccess(city, coordinates)

        if coordinates.x <= 1 or coordinates.y <= 1 or coordinates.y >= #city.grid or coordinates.x > #city.grid then
            -- If it's at the edge of the grid, then put it back
            Queue.pushright(queue, coordinates)
        elseif cell == nil then
            -- noop, if the grid has not been expanded this far, then don't try to build a building here
            -- this should insert the coordinates at the end of the list, so that
            -- the next iteration will pick a different element from the beginning of the list
            Queue.pushright(queue, coordinates)
        elseif cell.type ~= "unused" then
            -- If this location already has a road or building, then don't attempt to build
            -- here again.
            -- noop
        elseif not isAreaFree(area) then
            -- noop, if there are collidables than retry later
            -- this should insert the coordinates at the end of the list, so that
            -- the next iteration will pick a different element from the beginning of the list
            Queue.pushright(queue, coordinates)
        elseif buildingConstruction.buildingType == "simple" and not isConnectedToRoad(city, coordinates) then
            -- Don't build buildings if there is no road connection yet
            Queue.pushright(queue, coordinates)
        elseif buildingConstruction.buildingType == "garden" and isConnectedToRoad(city, coordinates) then
            -- Don't build gardens if there's a road right next to it
        else
            -- We can start a construction site here
            -- Resource consumption is done outside of this function

            removeColldingEntities(area)

            -- Place an excavation site entity that will be later replaced with the actual building
            local excavationPit = game.surfaces[1].create_entity{
                name = getIteratedExcavationPitName(),
                position = {x = startCoordinates.x - 0.5 + CELL_SIZE / 2, y = startCoordinates.y - 0.5  + CELL_SIZE / 2},
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
    return false
end


--- @param coordinates Coordinates
local function isCharted(city, coordinates)
    local chunkPosition = {
        y = math.floor((coordinates.y + getOffsetY(city)) * CELL_SIZE / 32),
        x = math.floor((coordinates.x + getOffsetX(city)) * CELL_SIZE / 32),
    }
    return game.forces.player.is_chunk_charted(game.surfaces[1], chunkPosition)
end

--- @param coordinates Coordinates
local function incraseCoordinates(coordinates, city)
    -- Debugged a case where the new value would be above the current grid size --> coordinates.x > #city.grid
    coordinates.x = coordinates.x + 1
    coordinates.y = coordinates.y + 1
end

--- @param city City
--- @return Coordinates | nil coordinates
local function growAtRandomRoadEnd(city)

    DEBUG.log("\n\nENTER growAtRandomRoadEnd")
    DEBUG.logGrid(city.grid)

    if city.roadEnds == nil then
        city.roadEnds = Queue.new()
        return
    end
    local roadEnd = Queue.popleft(city.roadEnds)

    if roadEnd == nil then
        return
    end

    DEBUG.log('Coordinates: y=' .. roadEnd.coordinates.y .. " x=" .. roadEnd.coordinates.x)

    if roadEnd.coordinates.x <= 1
     or roadEnd.coordinates.x >= getGridSize(city.grid)
     or roadEnd.coordinates.y <= 1
     or roadEnd.coordinates.y >= getGridSize(city.grid)
     then
        -- We need to put the item back first, so that the expansion is applied to it properly
        Queue.pushleft(city.roadEnds, roadEnd)
        DEBUG.log('Expanding city')
        DEBUG.logRoadEnds(city.roadEnds)
        -- When expanding the grid I noticed that there sometimes were duplicates, which may have multiplied the coordinate shift (e.g. 3 duplicates meant that x/y for each would be shifted by 3 cells)
        -- No idea why there are duplicates or why the multiplication happens, but removing duplicates helped as well
        Queue.removeDuplicates(city.roadEnds)
        expand_grid(city)
        -- Since we extended the grid (and inserted a top/left row/colum) all roadEnd coordinates need to shift one
        if city.roadEnds ~= nil then
            for value in Queue.iterate(city.roadEnds) do
                incraseCoordinates(value.coordinates, city)
            end
        end
        if city.gardenLocationQueue ~= nil then
            for value in Queue.iterate(city.gardenLocationQueue) do
                incraseCoordinates(value, city)
            end
        end
        if city.buildingLocationQueue ~= nil then
            for value in Queue.iterate(city.buildingLocationQueue) do
                incraseCoordinates(value, city)
            end
        end
        if city.excavationPits ~= nil then
            for _, r in ipairs(city.excavationPits) do
                incraseCoordinates(r.coordinates, city)
            end
        end
        if city.houseLocations ~= nil then
            for _, r in ipairs(city.houseLocations) do
                incraseCoordinates(r, city)
            end
        end
        DEBUG.logRoadEnds(city.roadEnds)

        return
    end

    if not isCharted(city, roadEnd.coordinates) then
        DEBUG.log("RoadEnd is not charted: x=" .. roadEnd.coordinates.x .. " y=" .. roadEnd.coordinates.y)
        return
    end

    local pickedExpansionDirections = pickRoadExpansion(city, roadEnd)
    if pickedExpansionDirections ~= nil then
        DEBUG.log('Picked Expansion Directions: ' .. #pickedExpansionDirections .. " (" .. table.concat(pickedExpansionDirections, ",") .. ")")
        -- For each direction, fill the current cell with the direction and the neighbour with the inverse direction
        for _, direction in ipairs(pickedExpansionDirections) do
            local currentCellStartCoordinates = {
                y = (roadEnd.coordinates.y + getOffsetY(city)) * CELL_SIZE,
                x = (roadEnd.coordinates.x + getOffsetX(city)) * CELL_SIZE,
            }

            local currentArea = {
                {currentCellStartCoordinates.x, currentCellStartCoordinates.y},
                {currentCellStartCoordinates.x + CELL_SIZE, currentCellStartCoordinates.y + CELL_SIZE}
            }
            removeColldingEntities(currentArea, streetIgnorables)

            printTiles(currentCellStartCoordinates, getMap(direction), "concrete")
            local currentCell = safeGridAccess(city, roadEnd.coordinates, "processPickedExpansionDirectionCurrent")
            if currentCell == nil then
                return nil
            end

            if currentCell.roadSockets == nil then
                currentCell.roadSockets = {}
            end
            if indexOf(currentCell.roadSockets, direction) == nil then
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
            local neighbourCellStartCoordinates = {
                y = (neighbourPosition.y + getOffsetY(city)) * CELL_SIZE,
                x = (neighbourPosition.x + getOffsetX(city)) * CELL_SIZE,
            }
            
            local neighourArea = {
                {neighbourCellStartCoordinates.x, neighbourCellStartCoordinates.y},
                {neighbourCellStartCoordinates.x + CELL_SIZE, neighbourCellStartCoordinates.y + CELL_SIZE}
            }
            removeColldingEntities(neighourArea, streetIgnorables)
            
            local neighourSocket = invertDirection(direction)
            printTiles(neighbourCellStartCoordinates, getMap(neighourSocket), "concrete")
            local neighbourCell = safeGridAccess(city, neighbourPosition, "processPickedExpansionDirectionNeighbour")
            if neighbourCell == nil then
                return nil
            end

            if neighbourCell.type == "road" then
                if indexOf(neighbourCell.roadSockets, neighourSocket) == nil then
                    table.insert(neighbourCell.roadSockets, neighourSocket)
                end
            elseif neighbourCell.type == "unused" then
                city.grid[neighbourPosition.y][neighbourPosition.x] = {
                    type = "road",
                    roadSockets = {neighourSocket}
                }
                -- When creating a new road cell, then we also mark that as a roadEnd to later continue from
                DEBUG.log('Add roadEnd: ' .. neighbourPosition.y .. "/" .. neighbourPosition.x)
                Queue.pushright(city.roadEnds, {
                    coordinates = neighbourPosition,
                    -- We need to use the original direction, so that the next expansion continues in the same direction
                    direction = direction,
                })
            else
                assert(false, "Road should not be expanding into a cell that's not a road or unused.")
            end
        end
    else
        -- todo: in what cases can't we build here? entity collision? player collision?
        -- buildings should come later to fill empty gaps that have no collisions
        
        -- Add some weight onto this roadEnd, so that it gets processed later (compared to others who are at a similar distance or don't have their weight changed as much)
        -- roadEnd.additionalWeight = (roadEnd.additionalWeight or 1) * 1.2
        Queue.pushright(city.roadEnds, roadEnd)
    end
    DEBUG.logGrid(city.grid)
    return roadEnd.coordinates
end

local function setHouseLight(houseUnitNumber, lightEntity)
    if global.tycoon_house_lights == nil then
        global.tycoon_house_lights = {}
    end

    global.tycoon_house_lights[houseUnitNumber] = lightEntity
end

--- @param excavationPits ExcavationPit[]
--- @param buildingTypes BuildingType[] | nil
--- @return ExcavationPit | nil excavationPit
local function findReadyExcavationPit(excavationPits, buildingTypes)
    local completableBuildingTypes = {"tycoon-treasury", "garden"}
    if buildingTypes ~= nil then
        for _, value in ipairs(buildingTypes) do
            table.insert(completableBuildingTypes, value)
        end
    end

    for i, e in ipairs(excavationPits) do
        if e.createdAtTick + e.buildingConstruction.constructionTimeInTicks < game.tick then
            if indexOf(completableBuildingTypes, e.buildingConstruction.buildingType) ~= nil then
                return table.remove(excavationPits, i)
            end
        end
    end
    return nil
end

--- @param houseUnitNumber number
--- @param mapPosition Coordinates
--- @param buildingType BuildingType
local function createLight(houseUnitNumber, mapPosition, buildingType)
    local light
    if buildingType == "residential" then
        light = game.surfaces[1].create_entity{
            name = "hiddenlight-40",
            position = mapPosition,
            force = "neutral",
        }
    elseif buildingType == "highrise" then
        light = game.surfaces[1].create_entity{
            name = "hiddenlight-60",
            position = mapPosition,
            force = "neutral",
        }
    end
    if light ~= nil then
        setHouseLight(houseUnitNumber, light)
    end
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
    local cell = safeGridAccess(city, coordinates, "completeConstruction")
    if cell ~= nil and cell.entity ~= nil then
        cell.entity.destroy()
    end

    local startCoordinates = {
        y = (coordinates.y + getOffsetY(city)) * CELL_SIZE,
        x = (coordinates.x + getOffsetX(city)) * CELL_SIZE,
    }
    printTiles(startCoordinates, {
        "111111",
        "111111",
        "111111",
        "111111",
        "111111",
        "111111",
    }, "concrete")
    local entityName = excavationPit.buildingConstruction.buildingType
    local entity
    if entityName == "simple" or entityName == "residential" or entityName == "highrise" then
        local xModifier, yModifier = 0, 0
        if entityName == "residential" then
            xModifier = 0
            yModifier = -0.5
        end
        local position = {x = startCoordinates.x + CELL_SIZE / 2 + xModifier, y = startCoordinates.y + CELL_SIZE / 2 + yModifier}
        entity = game.surfaces[1].create_entity{
            name = getIteratedHouseName(entityName),
            position = position,
            force = "player",
            move_stuck_players = true
        }
        createLight(entity.unit_number, position, entityName)
        -- todo: test if the script destroying this entity also fires this hook
        script.register_on_entity_destroyed(entity)

        if city.buildingCounts == nil then
            city.buildingCounts = {
                simple = 0,
                residential = 0,
                highrise = 0,
            }
        end
        city.buildingCounts[entityName] = city.buildingCounts[entityName] + 1

        if city.houseLocations == nil then
            city.houseLocations = {}
        end
        table.insert(city.houseLocations, coordinates)

        local neighboursOfCompletedHouse = getSurroundingCoordinates(coordinates.y, coordinates.x, 1, false)
        for _, n in ipairs(neighboursOfCompletedHouse) do
            local neighbourCell = safeGridAccess(city, n)
            if neighbourCell ~= nil and neighbourCell.type == "unused" then
                local surroundsOfUnused = getSurroundingCoordinates(n.y, n.x, 1, false)
                -- Test if this cell is surrounded by houses, if yes then place a garden
                -- Because we use getSurroundingCoordinates with allowDiagonal=false above, we only need to count 4 houses or roads
                local surroundCount = 0
                for _, s in ipairs(surroundsOfUnused) do
                    local surroundingCell = safeGridAccess(city, s)
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
    elseif entityName == "garden" then
        entity = game.surfaces[1].create_entity{
            name = getIteratedGardenName(),
            position = {x = startCoordinates.x + CELL_SIZE / 2, y = startCoordinates.y  + CELL_SIZE / 2},
            force = "player",
            move_stuck_players = true
        }
    else
        entity = game.surfaces[1].create_entity{
            name = entityName,
            position = {x = startCoordinates.x + CELL_SIZE / 2, y = startCoordinates.y  + CELL_SIZE / 2},
            force = "player",
            move_stuck_players = true
        }
    end

    city.grid[coordinates.y][coordinates.x] = {
        type = "building",
        buildingType = entityName,
        createdAtTick = game.tick,
        entity = entity,
    }
    global.tycoon_city_buildings[entity.unit_number] = {
        cityId = city.id,
        entity_name = entity.name,
        entity = entity,
    }

    if entityName == "tycoon-treasury" and not global.tycoon_intro_message_treasury_displayed then
        game.print({"", "[color=orange]Factorio Tycoon:[/color] ", {"tycooon-info-message-treasury"}})
        global.tycoon_intro_message_treasury_displayed = true
    end

    return entityName
end

local upgradePaths = {
    simple = {
        waitTime = 300,
        previousStage = "simple",
        nextStage = "residential",
        upgradeDurationInSeconds = {30, 60},
        requiresUsedAreaSize = 2
    },
    residential = {
        waitTime = 600,
        previousStage = "residential",
        nextStage = "highrise",
        upgradeDurationInSeconds = {120, 240},
        requiresUsedAreaSize = 3
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
            local cell = safeGridAccess(city, {y = y+i, x = x+j})
            if cell == nil or cell.type == "unused" then
                return true
            end
        end
    end
    return false
end

--- @param city City
--- @param limit number
--- @param upgradeTo BuildingType
local function findUpgradableCells(city, limit, upgradeTo)
    local upgradeCells = {}
    for _, coordinates in ipairs(city.houseLocations) do
        local cell = safeGridAccess(city, coordinates, "findUpgradableCells")
        if cell ~= nil and cell.type == "building" and cell.buildingType ~= nil then
            local upgradePath = upgradePaths[cell.buildingType]
            if upgradePath ~= nil and upgradePath.nextStage == upgradeTo then
                if (cell.createdAtTick + upgradePath.waitTime) < game.tick then

                    -- Check that all surrounding cells are in use. It would be odd to build a skyscraper in open space.
                    local emptySurroundingSpace = hasEmptySurroundingSpace(city, coordinates, upgradePath.requiresUsedAreaSize)

                    if not emptySurroundingSpace then
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

local function sortUpgradeCells(city, upgradeCells)
    local cityCenter = {
        x = city.center.x + CELL_SIZE,
        y = city.center.y + CELL_SIZE,
    }

    local offsetY = getOffsetY(city)
    local offsetX = getOffsetX(city)

    table.sort(upgradeCells, function (a, b)
        local distanceA = getCachedDistance(a.coordinates, offsetY, offsetX, cityCenter)
        local distanceB = getCachedDistance(b.coordinates, offsetY, offsetX, cityCenter)
        return distanceA < distanceB
    end)
end

local function clearCell(city, upgradeCell)
    upgradeCell.cell.entity.destroy()
    -- We need to clear the cell as well, so that the construction has available space
    city.grid[upgradeCell.coordinates.y][upgradeCell.coordinates.x] = {
        type = "unused"
    }
    city.buildingCounts[upgradeCell.upgradePath.previousStage] = city.buildingCounts[upgradeCell.upgradePath.previousStage] - 1
    if city.houseLocations ~= nil then
        table.remove(city.houseLocations, indexOf(city.houseLocations, upgradeCell.coordinates))
    end
end

--- @param city City
--- @return boolean upgradeStarted
local function upgradeHouse(city, newStage)
    -- todo: test if the game destroying an entity also triggers the destroy hook (and change the citizen counter reduction accordingly)
    local upgradeCells = findUpgradableCells(city, 10, newStage)

    if #upgradeCells == 0 then
        return false
    end

    sortUpgradeCells(city, upgradeCells)

    local upgradeCell = upgradeCells[1]
    clearCell(city, upgradeCell)

    local upgradePath = upgradeCell.upgradePath

    startConstruction(city, {
        buildingType = upgradePath.nextStage,
        constructionTimeInTicks = city.generator(upgradePath.upgradeDurationInSeconds[1] * 60, upgradePath.upgradeDurationInSeconds[2] * 60),
    }, city.buildingLocationQueue, {upgradeCell.coordinates})

    return true
end

local CITY = {
    growAtRandomRoadEnd = growAtRandomRoadEnd,
    updatepossibleBuildingLocations = addBuildingLocations,
    completeConstruction = completeConstruction,
    upgradeHouse = upgradeHouse,
    startConstruction = startConstruction,
    isCellFree = isCellFree
}

return CITY