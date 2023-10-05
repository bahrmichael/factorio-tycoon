DEBUG = require("debug")

--- @class Coordinates
--- @field x number
--- @field y number

--- @alias Direction
---| "south"
---| "east"
---| "north"
---| "west"

--- @alias HouseType
---| "residential"
---| "highrise"

--- @class RoadEnd
--- @field direction Direction
--- @field coordinates Coordinates
--- @field additionalWeight number | nil

--- @alias ConstructionStage
---| "in_progress"
---| "complete"

--- @alias CellType
---| "road"
---| "house"
---| "unused"

--- @class Cell
--- @field type CellType
--- @field roadSockets Direction[] | nil
--- @field constructionStage ConstructionStage | nil
--- @field entity any | nil
--- @field houseType HouseType | nil
--- @field createdAtTick number | nil

--- @alias RoadConnectionCount
---| "1"
---| "2"
---| "3"

--- @class ExcavationPit
--- @field coordinates Coordinates
--- @field createdAtTick number
--- @field buildingType HouseType

--- @class City
--- @field id number
--- @field roadEnds RoadEnd[]
--- @field grid (Cell)[][]
--- @field center Coordinates
--- @field houseOptions Coordinates[]
--- @field housesTryLater Coordinates[]
--- @field excavationPits ExcavationPit[]
--- @field houseCounts { HouseType: number }

--- @param p1 Coordinates
--- @param p2 Coordinates
--- @return number The distance between the two points.
local function calculateDistance(p1, p2)
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    return math.sqrt(dx * dx + dy * dy)
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

function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

local function sortAll(array, offsetY, offsetX, cityCenter)
    table.sort(array, function (a, b)
        local distanceA = getCachedDistance(a.coordinates, offsetY, offsetX, cityCenter)
        local distanceB = getCachedDistance(b.coordinates, offsetY, offsetX, cityCenter)
        return distanceA * (a.additionalWeight or 1) < distanceB * (b.additionalWeight or 1)
    end)
end

local function sortPartially(city, count, offsetY, offsetX, cityCenter)
    local subsection = {}
    for _ = 1, count, 1 do
        table.insert(subsection, table.remove(city.roadEnds, math.random(#city.roadEnds)))
    end
    sortAll(subsection, offsetY, offsetX, cityCenter)
    city.roadEnds = TableConcat(subsection, city.roadEnds)
end

local function sortRoadEnds(city)

    -- This might still be shifted slighty wrong, but it's goo enough for now
    local cityCenter = {
        x = city.center.x + CELL_SIZE,
        y = city.center.y + CELL_SIZE,
    }

    local offsetY = getOffsetY(city)
    local offsetX = getOffsetX(city)

    local threshold = 25
    if #city.roadEnds < threshold then
        sortAll(city.roadEnds, offsetY, offsetX, cityCenter)
    else
        sortPartially(city, threshold, offsetY, offsetX, cityCenter)
    end
end

--- @param city City
--- @return RoadEnd | nil roadEnd
local function getInnerCircleRoadEnd(city)
    if #city.roadEnds == 0 then
        return nil
    end

    return city.roadEnds[1]
end

local unusedFieldWeights = {}

--- @param y number
--- @param x number
--- @param size number
--- @param allowDiagonal boolean
--- @return Coordinates[] coordinates
local function getSurroundingCoordinates(y, x, size, allowDiagonal)
   local c = {}
   for i = -1 * size, size, 1 do
    for j = -1 * size, size, 1 do
        if (allowDiagonal or (i ~= j)) then
            if i ~= 0 and j ~= 0 then
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

local removableEntities = {
    "rock-",
    "sand-rock-",
    "dead-grey-trunk",
    "tree-"
}

local function removeColldingEntities(area) 
    local printEntities = game.surfaces[1].find_entities_filtered({area=area})
    for _, entity in pairs(printEntities) do
        for _, removable in pairs(removableEntities) do
            if entity.valid and string.find(entity.name, removable, 1, true) then
                entity.destroy()
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

local function isAreaFree(area)
    -- Water / Cliffs
    if hasCliffsOrWater(area) then
        return false
    end

    -- Too many trees / Other entities
    local entities = game.surfaces[1].find_entities_filtered({
        area=area,
        type={"tree"},
        name={"rock-huge", "rock-big", "sand-rock-big", "dead-grey-trunk"},
        invert=true,
        limit = 1,
    })
    return #entities == 0
end

--- @param city City
--- @param coordinates Coordinates
--- @return boolean hasCollidables If there are colldiables such as the player, water, cliffs or other entities in that cell.
local function doesCellHaveCollidables(city, coordinates)
    local startCoordinates = {
        y = (coordinates.y + getOffsetY(city)) * CELL_SIZE,
        x = (coordinates.x + getOffsetX(city)) * CELL_SIZE,
    }
    local area = {
        {startCoordinates.x, startCoordinates.y},
        {startCoordinates.x + CELL_SIZE, startCoordinates.y + CELL_SIZE}
    }
    return not isAreaFree(area)
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

--- @param city City
--- @param roadEnd RoadEnd
--- @param lookoutDirections Direction[]
--- @return boolean canBuild
local function testDirections(city, roadEnd, lookoutDirections)
    DEBUG.log("Testing directions: " .. table.concat(lookoutDirections, ","))

    -- Test the compatibility of the directions
    for _, direction in ipairs(lookoutDirections) do
        DEBUG.log("Testing direction: " .. direction)
        local neighbourPosition = continueInDirection(roadEnd.coordinates, direction, 1)


        if doesCellHaveCollidables(city, neighbourPosition) then
            DEBUG.log("Test result: False, because collidables")
            return false
        end

        -- This should never be fail, because the upstream function is supposed to expand the grid if the position is on the outsides
        local neighbourCell = city.grid[neighbourPosition.y][neighbourPosition.x]
        assert(neighbourCell ~= nil, "Cell should always have a type and not be nil.")

        if global.tycoon_enable_debug_logging then
            if neighbourCell ~= nil and neighbourCell.type ~= nil and neighbourCell.type ~= "unused" then
                DEBUG.log("Neighbour: " .. neighbourCell.type)
                if neighbourCell.type == "road" then
                    DEBUG.log("Neighbour(" .. "y=" .. neighbourPosition.y .. " x=" .. neighbourPosition.x  .. ") road sockets: " .. table.concat(neighbourCell.roadSockets, ","))
                end
            end
        end

        -- Streets must not expand into houses or collidables, but may expand into empty fields or streets
        if neighbourCell.type == "unused" then
            -- noop, cell is free
        elseif neighbourCell.type == "house" then
            DEBUG.log("Test result: False, because house")
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
            if city.grid[position.y] ~= nil and city.grid[position.y][position.x] ~= nil then
                local cell = city.grid[position.y][position.x]
                if cell.type == "road" then
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
    end

    DEBUG.log("Test result: True")
    return true
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

--- @return RoadConnectionCount[] connectionCountOptions
local function getRoadConnectionCountOptions()

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

    return values
end

local function shuffle(tbl)
    for i = #tbl, 2, -1 do
      local j = math.random(i)
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
                table.remove(sides, math.random(#sides)),
                table.remove(sides, math.random(#sides)),
            }
            -- If the test doesn't succeed, then continue trying the other options
        elseif option == "1" then
            local straightStreetLength = 0
            for i = 1, 10, 1 do
                local previousCell = continueInDirection(roadEnd.coordinates, invertDirection(roadEnd.direction), i)
                if (city.grid[previousCell.y] or {})[previousCell.x] == nil then
                    -- We reached the end of the grid. The road doesn't go beyond here.
                    break
                end
                if city.grid[previousCell.y][previousCell.x].type ~= "road"
                then
                    straightStreetLength = i
                    break
                end
            end
            local shouldBuildStraight = math.random() > (straightStreetLength / 10)
            DEBUG.log("Should build straight: " .. tostring(shouldBuildStraight) .. " (straight length: " .. straightStreetLength .. ")")
            if shouldBuildStraight then
                picked = {roadEnd.direction}
            else
                local sides = {left, right}
                picked = {sides[math.random(#sides)]}
            end
        elseif option == "0" then
            picked = {}
        else
            assert(false, "pickRoadExpansion doesn't yet handle the new roadConnection: " .. option)
        end

        if testDirections(city, roadEnd, picked) then
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
    for _, value in ipairs(map) do
        for i = 1, #value do
            local char = string.sub(value, i, i)
            if char == "1" then
                game.surfaces[1].set_tiles({{name = tileName, position = {x, y}}})
            end
            x = x + 1
        end
        x = start.x
        y = y + 1
    end
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

--- @param houseType HouseType
local function getRandomHouseName(houseType)
    local count
    if houseType == "residential" then
        count = 14
    elseif houseType == "highrise" then
        count = 8
    end
    return "tycoon-house-" .. houseType .. "-" .. math.random(1, count)
end

local function getRandomExcavationPitName()
    return "tycoon-excavation-pit-" .. math.random(1, 20)
end

--- @param city City
--- @param recentCoordinates Coordinates | nil
local function updateHouseOptions(city, recentCoordinates)
    if city.houseOptions == nil then
        city.houseOptions = {}
    end

    if #city.houseOptions < 50 and city.housesTryLater ~= nil and #city.housesTryLater > 0 then
        for i = 1, math.min(#city.housesTryLater, 10), 1 do
            table.insert(city.houseOptions, table.remove(city.housesTryLater, math.random(#city.housesTryLater)))
        end
    end

    local sizeBefore = #city.houseOptions

    if recentCoordinates ~= nil then
        local roadEndCoordinates = {}
        for _, value in ipairs(city.roadEnds) do
            table.insert(roadEndCoordinates, value.coordinates)
        end

        local surrounds = getSurroundingCoordinates(recentCoordinates.y, recentCoordinates.x, 1, false)
        for _, value in ipairs(surrounds) do
            if value.x <= 1 or value.y <= 1 or value.x >= #city.grid or value.y >= #city.grid then
                -- Skip locations that are at the edge of the grid or beyond
            elseif indexOf(city.houseOptions, value) == nil then
                    -- Only check cells that are unused and may have a house built there
                local isUnused = city.grid[value.y] ~= nil and city.grid[value.y][value.x] ~= nil and city.grid[value.y][value.x].type == "unused"
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
                        local hasSurroundingRoad = false
                        for _, s in ipairs(surroundsOfUnused) do
                            if city.grid[s.y][s.x].type == "road" then
                                DEBUG.log("y=" .. value.y .. " x=" .. value.x .. " has road neighbour: y=" .. s.y .. " x=" .. s.x)
                                hasSurroundingRoad = true
                                break
                            end
                        end
                        if hasSurroundingRoad then
                            table.insert(city.houseOptions, value)
                        end
                    end
                end
            end
        end
    end

    if sizeBefore < #city.houseOptions and math.random() < 0.1 then

        local offsetY = getOffsetY(city)
        local offsetX = getOffsetX(city)
        table.sort(city.houseOptions, function (a, b)
            -- This might still be shifted slighty wrong, but it's goo enough for now
            local cityCenter = {
                x = city.center.x + CELL_SIZE,
                y = city.center.y + CELL_SIZE,
            }
            local distanceA = getCachedDistance(a, offsetY, offsetX, cityCenter)
            local distanceB = getCachedDistance(b, offsetY, offsetX, cityCenter)

            return distanceA * (unusedFieldWeights[buildCoordinatesKey(a)] or 1) < distanceB * (unusedFieldWeights[buildCoordinatesKey(b)] or 1)
        end)
    end
end

--- @param city City
--- @return boolean hasBuiltExcavationPit
local function addExcavationPit(city)
    DEBUG.log("\n\nENTER addExcavationPit")
    DEBUG.logGrid(city.grid)

    if city.houseOptions == nil or #city.houseOptions == 0 then
        return false
    end

    local coordinates = table.remove(city.houseOptions, 1)

    local hasBuiltExcavationPit = false

    if (city.grid[coordinates.y] or {})[coordinates.x] == nil then
        -- noop, if the grid has not been expanded this far, then don't try to build a house here (yet)
        local c = coordinates.y .. "/" .. coordinates.x
        unusedFieldWeights[c] = (unusedFieldWeights[c] or 1) * 1.2
        table.insert(city.houseOptions, coordinates)
    elseif city.grid[coordinates.y][coordinates.x].type == "road" then
        -- noop, there's already a road so we can ignore this cell
    elseif city.grid[coordinates.y][coordinates.x].type == "house" then
        -- noop, for some reason the code is trying to build a house where there already is one, not sure why
    elseif doesCellHaveCollidables(city, coordinates) then
        -- Try again later
        local c = buildCoordinatesKey(coordinates)
        unusedFieldWeights[c] = (unusedFieldWeights[c] or 1) * 1.2
        -- table.insert(city.houseOptions, coordinates)
        if city.housesTryLater == nil then
            city.housesTryLater = {}
        end
        table.insert(city.housesTryLater, coordinates)
    else
        local startCoordinates = {
            y = (coordinates.y + getOffsetY(city)) * CELL_SIZE,
            x = (coordinates.x + getOffsetX(city)) * CELL_SIZE,
        }
        local area = {
            {startCoordinates.x, startCoordinates.y},
            {startCoordinates.x + CELL_SIZE, startCoordinates.y + CELL_SIZE}
        }

        removeColldingEntities(area)

        local excavationPit = game.surfaces[1].create_entity{
            name = getRandomExcavationPitName(),
            position = {x = startCoordinates.x - 0.5 + CELL_SIZE / 2, y = startCoordinates.y - 0.5  + CELL_SIZE / 2},
            force = "player"
        }

        city.grid[coordinates.y][coordinates.x] = {
            type = "house",
            houseType = "residential",
            constructionStage = "in_progress",
            entity = excavationPit,
            createdAtTick = game.tick
        }
        if city.excavationPits == nil then
            city.excavationPits = {}
        end
        table.insert(city.excavationPits, {
            coordinates = coordinates,
            createdAtTick = game.tick,
            buildingType = "residential"
        })
        hasBuiltExcavationPit = true
    end

    DEBUG.logGrid(city.grid)
    DEBUG.log("\n\nEXIT addExcavationPit")

    return hasBuiltExcavationPit
end

--- @param city City
--- @return Coordinates | nil coordinates
local function growAtRandomRoadEnd(city)

    DEBUG.log("\n\nENTER growAtRandomRoadEnd")
    DEBUG.logGrid(city.grid)

    local roadEnd = getInnerCircleRoadEnd(city)

    if roadEnd == nil then
        return
    end

    DEBUG.log('Coordinates: y=' .. roadEnd.coordinates.y .. " x=" .. roadEnd.coordinates.x)

    if roadEnd.coordinates.x == 1
     or roadEnd.coordinates.x == getGridSize(city.grid)
     or roadEnd.coordinates.y == 1
     or roadEnd.coordinates.y == getGridSize(city.grid)
     then
        DEBUG.log('Expanding city')
        expand_grid(city)
        -- Since we extended the grid (and inserted a top/left row/colum) all roadEnd coordinates need to shift one
        for _, r in ipairs(city.roadEnds) do
            r.coordinates.x = r.coordinates.x + 1
            r.coordinates.y = r.coordinates.y + 1
        end
        if city.houseOptions ~= nil then
            for _, r in ipairs(city.houseOptions) do
                r.x = r.x + 1
                r.y = r.y + 1
            end
        end
        if city.excavationPits ~= nil then
            for _, r in ipairs(city.excavationPits) do
                r.coordinates.x = r.coordinates.x + 1
                r.coordinates.y = r.coordinates.y + 1
            end
        end
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
            removeColldingEntities(currentArea)

            printTiles(currentCellStartCoordinates, getMap(direction), "concrete")
            local currentCell = city.grid[roadEnd.coordinates.y][roadEnd.coordinates.x]
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
            removeColldingEntities(neighourArea)
            
            local neighourSocket = invertDirection(direction)
            printTiles(neighbourCellStartCoordinates, getMap(neighourSocket), "concrete")
            local neighbourCell = city.grid[neighbourPosition.y][neighbourPosition.x]
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
                table.insert(city.roadEnds, {
                    coordinates = neighbourPosition,
                    -- We need to use the original direction, so that the next expansion continues in the same direction
                    direction = direction,
                })
                if math.random() > 0.5 then
                    sortRoadEnds(city)
                end
            else
                assert(false, "Road should not be expanding into a cell that's not a road or unused.")
            end
        end


        -- If we completed the expansion, then remove the current cell from the roadEnds
        local rix = indexOf(city.roadEnds, roadEnd)
        table.remove(city.roadEnds, rix)
    else
        -- todo: in what cases can't we build here? entity collision? player collision?
        -- houses should come later to fill empty gaps that have no collisions
        
        -- Add some weight onto this roadEnd, so that it gets processed later (compared to others who are at a similar distance or don't have their weight changed as much)
        roadEnd.additionalWeight = (roadEnd.additionalWeight or 1) * 1.2
        if math.random() > 0.75 then
            sortRoadEnds(city)
        end
    end
    DEBUG.logGrid(city.grid)
    return roadEnd.coordinates
end

--- @param city City
--- @param excavationPit ExcavationPit
local function buildHouse(city, excavationPit)
    local coordinates = excavationPit.coordinates
    city.grid[coordinates.y][coordinates.x].entity.destroy()

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
    local house = game.surfaces[1].create_entity{
        name = getRandomHouseName(excavationPit.buildingType),
        position = {x = startCoordinates.x - 0.5 + CELL_SIZE / 2, y = startCoordinates.y - 0.5  + CELL_SIZE / 2},
        force = "player"
    }
    script.register_on_entity_destroyed(house)
    global.tycoon_city_buildings[house.unit_number] = {
        cityId = city.id,
        entity_name = house.name
    }

    city.grid[coordinates.y][coordinates.x] = {
        type = "house",
        houseType = excavationPit.buildingType,
        createdAtTick = game.tick,
        entity = house,
    }
    if city.houseCounts == nil then
        city.houseCounts = {}
    end
    if city.houseCounts[excavationPit.buildingType] == nil then
        city.houseCounts[excavationPit.buildingType] = 1
    else
        city.houseCounts[excavationPit.buildingType] = city.houseCounts[excavationPit.buildingType] + 1
    end
end

local upgradePaths = {
    residential = {
        waitTime = 300,
        nextStage = "highrise"
    }
}

--- @param city City
local function upgradeHouse(city)
    -- todo: re-register on destroy hooks
    local upgradeCells = {}
    for y = 1, #city.grid, 1 do
        for x = 1, #city.grid, 1 do
            local cell = city.grid[y][x]
            if cell.type == "house" and cell.houseType ~= nil then
                local upgradePath = upgradePaths[cell.houseType]
                if upgradePath ~= nil then
                    if cell.createdAtTick + upgradePath.waitTime < game.tick then

                        -- Check that all surrounding cells are in use. It would be odd to build a skyscraper in open space.
                        local hasEmptySurroundingSpace = false
                        local surroundingCoordinates = getSurroundingCoordinates(y, x, 2, true)
                        for _, coords in ipairs(surroundingCoordinates) do
                            if city.grid[coords.y] == nil or city.grid[coords.y][coords.x] == nil or city.grid[coords.y][coords.x].type == "unused" then
                                hasEmptySurroundingSpace = true
                                break
                            end
                        end

                        if not hasEmptySurroundingSpace then
                            table.insert(upgradeCells, {
                                cell = cell,
                                coordinates = {
                                    x = x,
                                    y = y,
                                }
                            })
                        end
                    end
                end
            end
        end
    end

    if #upgradeCells == 0 then
        return
    end

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

    local upgradeCell = upgradeCells[1]

    upgradeCell.cell.entity.destroy()
    local coordinates = upgradeCell.coordinates
    local startCoordinates = {
        y = (coordinates.y + offsetY) * CELL_SIZE,
        x = (coordinates.x + offsetX) * CELL_SIZE,
    }
    local excavationPit = game.surfaces[1].create_entity{
        name = getRandomExcavationPitName(),
        position = {x = startCoordinates.x - 0.5 + CELL_SIZE / 2, y = startCoordinates.y - 0.5  + CELL_SIZE / 2},
        force = "player"
    }

    city.grid[coordinates.y][coordinates.x] = {
        type = "house",
        houseType = "highrise",
        constructionStage = "in_progress",
        entity = excavationPit,
        createdAtTick = game.tick
    }
    if city.excavationPits == nil then
        city.excavationPits = {}
    end
    table.insert(city.excavationPits, {
        coordinates = coordinates,
        createdAtTick = game.tick,
        buildingType = "highrise"
    })
end

local CITY = {
    growAtRandomRoadEnd = growAtRandomRoadEnd,
    addExcavationPit = addExcavationPit,
    updateHouseOptions = updateHouseOptions,
    buildHouse = buildHouse,
    upgradeHouse = upgradeHouse,
}

return CITY