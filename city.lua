--- @class Coordinates
--- @field x number
--- @field y number

--- @alias Direction
---| "south"
---| "east"
---| "north"
---| "west"

--- @class RoadEnd
--- @field direction Direction
--- @field coordinates Coordinates
--- @field additionalWeight number | nil


--- @alias CellType
---| "road"
---| "house"

--- @class Cell
--- @field type CellType
--- @field roadSockets Direction[] | nil

--- @alias RoadConnectionCount
---| "0"
---| "1"
---| "2"
---| "3"

--- @class City
--- @field roadEnds RoadEnd[]
--- @field grid (Cell | nil)[][]
--- @field center Coordinates

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

--- @param city City
--- @return RoadEnd | nil roadEnd
local function getInnerCircleRoadEnd(city)
    if #city.roadEnds == 0 then
        return nil
    end
    table.sort(city.roadEnds, function (a, b)
        -- This might still be shifted slighty wrong, but it's goo enough for now
        local cityCenter = {
            x = city.center.x + CELL_SIZE,
            y = city.center.y + CELL_SIZE,
        }
        local distanceA = calculateDistance({
            y = (a.coordinates.y + getOffsetY(city)) * CELL_SIZE,
            x = (a.coordinates.x + getOffsetX(city)) * CELL_SIZE,
        }, cityCenter)
        local distanceB = calculateDistance({
            y = (b.coordinates.y + getOffsetY(city)) * CELL_SIZE,
            x = (b.coordinates.x + getOffsetX(city)) * CELL_SIZE,
        }, cityCenter)
        return distanceA * (a.additionalWeight or 1) < distanceB * (b.additionalWeight or 1)
    end)
    return city.roadEnds[1]
end

local function hasCliffsOrWater(area)
    local tiles = game.surfaces[1].find_tiles_filtered{
        area = area,
        name = {"water", "deepwater", "cliff"},
        limit = 1
    }
    return #tiles > 0
end

local function isAreaFree(area, maxTreeCount)
    -- Water / Cliffs
    if hasCliffsOrWater(area) then
        return false
    end

    -- Too many trees / Other entities
    local entities = game.surfaces[1].find_entities_filtered({
        area=area,
        type={"tree", "character"},
        invert=true,
        limit = 1,
    })
    if #entities > 0 then
        return false
    end
    local trees = game.surfaces[1].find_entities_filtered({
        area=area,
        type="tree",
        limit = maxTreeCount,
    })
    return #trees < maxTreeCount
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
    return not isAreaFree(area, 10)
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

 -- In-place expansion of the grid and the circle by 1 unit on all sides
 --- @param city City
 local function expand_grid(city)
    local old_size = getGridSize(city.grid)
    local new_size = old_size + 2  -- Expand by 1 on each side

    -- Shift rows downward to keep center
    for y = new_size, 1, -1 do
        city.grid[y] = city.grid[y-1] or {}
    end

    -- Add new columns at the left and right
    for y = 1, new_size do
        table.insert(city.grid[y], 1, nil)
        city.grid[y][new_size] = nil
    end

    -- local old_radius = old_size / 2
    -- local new_radius = old_radius + 1

    -- Update the new circle in the existing grid
    -- fill_circle(city, new_radius)
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

    -- Test the compatibility of the directions
    for _, direction in ipairs(lookoutDirections) do
        local neighbourPosition = continueInDirection(roadEnd.coordinates, direction, 1)
        -- if city.grid[neighbourPosition.y] == nil then
        --     expand_grid(city)
        -- end

        -- This should never be fail, because the upstream function is supposed to expand the grid if the position is on the outsides
        local neighbourCell = city.grid[neighbourPosition.y][neighbourPosition.x]
        -- Streets must not expand into houses or collidables, but may expand into empty fields or streets
        if neighbourCell == "house" then
            return false
        elseif doesCellHaveCollidables(city, neighbourPosition) then
            return false
        end

        -- Streets must not continue directly next to and parallel to each other
        -- local neighboursSideDirections = {}
        -- if roadEnd.direction == "north" or roadEnd.direction == "south" then
        --     neighboursSideDirections = {"east", "west"}
        -- elseif roadEnd.direction == "west" or roadEnd.direction == "east" then
        --     neighboursSideDirections = {"south", "north"}
        -- end
        -- local neighboursSideNeighbours = {
        --     continueInDirection(neighbourPosition, neighboursSideDirections[1], 1),
        --     continueInDirection(neighbourPosition, neighboursSideDirections[2], 1),
        -- }
        -- for _, position in ipairs(neighboursSideNeighbours) do
        --     if city.grid[position.y] ~= nil and city.grid[position.y][position.x] ~= nil then
        --         local cell = city.grid[position.y][position.x]
        --         if cell ~= nil and cell.type == "road" then
        --             local sockets = cell.roadSockets or {}
        --             for _, socket in ipairs(sockets) do
        --                 if socket == roadEnd.direction or socket == invertDirection(roadEnd.direction) then
        --                     return false
        --                 end
        --             end
        --         end
        --     end
        -- end

        -- give a small chance to dodge the lookahead so that areas will eventually close again
        -- if math.random() > 0.7 then
        --     -- Look at the cells 2 and 3 cells ahaed. If any of them are roads, we don't expand so that we can leave some space for houses.
        --     for i = 2, 3, 1 do
        --         local lookAheadPosition = continueInDirection(roadEnd.coordinates, direction, i)
        --         -- If the cell is outside of the grid, then there should be nothing yet and it's fine for us to expand in that direction
        --         if city.grid[lookAheadPosition.y] ~= nil and city.grid[lookAheadPosition.y][lookAheadPosition.x] ~= nil then
        --             if city.grid[lookAheadPosition.y][lookAheadPosition.x] == "road" then
        --                 -- todo: should we also about at houses? i think it's fine to have a road go towards a house and then stop there
        --                 return false
        --             end
        --         end
        --     end
        -- end
    end

    return true
end

--- @param array any[]
--- @param exclude any[]
local function rebuildTableWithout(array, exclude)
    local result = {}
    for _, value in ipairs(array) do
        if indexOf(exclude, value) == nil then
            table.insert(result, value)
        end
    end
    return result
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
    weightedValues["2"] = 1
    -- One connection will later be randomized again if it should be a corner or a straight.
    weightedValues["1"] = 1

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
    local left = getLeftDirection(roadEnd.direction)
    local right = getRightDirection(roadEnd.direction)

    local options = getRoadConnectionCountOptions()
    shuffle(options)

    for _, option in ipairs(options) do
        if option == "3" then
            if testDirections(city, roadEnd, {roadEnd.direction, left, right}) then
                return {roadEnd.direction, left, right}
            end
            -- If the test doesn't succeed, then continue trying the other options
        elseif option == "2" then
            local sides = {roadEnd.direction, left, right}
            local picked = {
                table.remove(sides, math.random(#sides)),
                table.remove(sides, math.random(#sides)),
            }
            if testDirections(city, roadEnd, picked) then
                return picked
            end
            -- If the test doesn't succeed, then continue trying the other options
        elseif option == "1" then
            local straightStreetLength = 0
            for i = 1, 10, 1 do
                local previousCell = continueInDirection(roadEnd.coordinates, invertDirection(roadEnd.direction), i)
                if city.grid[previousCell.y] == nil 
                or city.grid[previousCell.y][previousCell.x] == nil 
                or city.grid[previousCell.y][previousCell.x].type ~= "road"
                then
                    straightStreetLength = i
                    break
                end
            end
            local shouldBuildStraight = math.random() > (straightStreetLength / 10)
            if shouldBuildStraight then
                if testDirections(city, roadEnd, {roadEnd.direction}) then
                    return {roadEnd.direction}
                end
            else
                local sides = {roadEnd.direction, left, right}
                for _i = 1, 3, 1 do
                    local picked = {
                        table.remove(sides, math.random(#sides)),
                    }
                    if testDirections(city, roadEnd, picked) then
                        return picked
                    end
                end
            end
        elseif option == "0" then
            return {}
        else
            assert(false, "pickRoadExpansion doesn't yet handle the new roadConnection: " .. option)
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

--- @param city City
local function growAtRandomRoadEnd(city)

    local roadEnd = getInnerCircleRoadEnd(city)

    if roadEnd == nil then
        return
    end

    if roadEnd.coordinates.x == 1
     or roadEnd.coordinates.x == getGridSize(city.grid)
     or roadEnd.coordinates.y == 1
     or roadEnd.coordinates.y == getGridSize(city.grid)
     then
        expand_grid(city)
        -- Since we extended the grid (and inserted a top/left row/colum) all roadEnd coordinates need to shift one
        for _, r in ipairs(city.roadEnds) do
            r.coordinates.x = r.coordinates.x + 1
            r.coordinates.y = r.coordinates.y + 1
        end
        return
    end
    -- We received the position for a road that extended into a cell. We now need to figure out if we can grow the road in any direction, and if we should add houses.
    -- local neighbours = {
    --     {0, 1},
    --     {0, -1},
    --     {1, 0},
    --     {-1, 0},
    -- }
    -- -- Randomly sort the neighbours, so that we always start looking in different directions
    -- table.sort(neighbours, function (_a, _b)
    --     return math.random() > 0.5
    -- end)


    -- local continuationOptions = {
    --     "intersection",
    --     "t-section:front-left",
    --     "t-section:front-right",
    --     "t-section:sides",
    --     "corner:left",
    --     "corner:right",
    -- }
    --     -- Randomly sort the continuationOptions, so that we always attempt to build something different
    -- table.sort(continuationOptions, function (_a, _b)
    --     return math.random() > 0.5
    -- end)

    local cellsExpandedInto = {}

    local pickedExpansionDirections = pickRoadExpansion(city, roadEnd)
    if pickedExpansionDirections ~= nil then
        -- For each direction, fill the current cell with the direction and the neighbour with the inverse direction
        for _, direction in ipairs(pickedExpansionDirections) do
            local currentCellStartCoordinates = {
                y = (roadEnd.coordinates.y + getOffsetY(city)) * CELL_SIZE,
                x = (roadEnd.coordinates.x + getOffsetX(city)) * CELL_SIZE,
            }
            printTiles(currentCellStartCoordinates, getMap(direction), "concrete")
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
            printTiles(neighbourCellStartCoordinates, getMap(invertDirection(direction)), "concrete")

            table.insert(cellsExpandedInto, {
                coordinates = neighbourPosition,
                direction = invertDirection(direction),
            })
        end

        if #pickedExpansionDirections == 1 then
            local possibleHouseOptions = {}
            if roadEnd.direction == pickedExpansionDirections[1] then
                if roadEnd.direction == "south" then
                    table.insert(possibleHouseOptions, {x = roadEnd.coordinates.x - 1, y = roadEnd.coordinates.y})
                    table.insert(possibleHouseOptions, {x = roadEnd.coordinates.x + 1, y = roadEnd.coordinates.y})
                elseif roadEnd.direction == "east" then
                    table.insert(possibleHouseOptions, {x = roadEnd.coordinates.x, y = roadEnd.coordinates.y - 1})
                    table.insert(possibleHouseOptions, {x = roadEnd.coordinates.x, y = roadEnd.coordinates.y + 1})
                elseif roadEnd.direction == "north" then
                    table.insert(possibleHouseOptions, {x = roadEnd.coordinates.x - 1, y = roadEnd.coordinates.y})
                    table.insert(possibleHouseOptions, {x = roadEnd.coordinates.x + 1, y = roadEnd.coordinates.y})
                elseif roadEnd.direction == "west" then
                    table.insert(possibleHouseOptions, {x = roadEnd.coordinates.x, y = roadEnd.coordinates.y - 1})
                    table.insert(possibleHouseOptions, {x = roadEnd.coordinates.x, y = roadEnd.coordinates.y + 1})
                end
            end

            for _, value in ipairs(possibleHouseOptions) do
                local row = city.grid[value.y]
                assert(row ~= nil, "Cell should not be nil, because the grid should previously have been expanded")
                local cell = city.grid[value.y][value.x]
                if cell == nil then
                    city.grid[value.y][value.x] = {
                        type = "house"
                    }
                else
                    -- This cell is already taken, so we're not doing anything
                end
            end
        end

        if city.grid[roadEnd.coordinates.y][roadEnd.coordinates.x] == nil then
            city.grid[roadEnd.coordinates.y][roadEnd.coordinates.x] = {
                type = "road",
                roadSockets = pickedExpansionDirections
            }
        else
            -- patch values from city initialization (should be moved there)
            local cell = city.grid[roadEnd.coordinates.y][roadEnd.coordinates.x]
            if cell == "intersection" then
                cell = {
                    type = "road",
                    roadSockets = {"south", "north", "east", "west"}
                }
            elseif cell == "linear.horizontal" then
                cell = {
                    type = "road",
                    roadSockets = {"east", "west"}
                }
            elseif cell == "linear.vertical" then
                cell = {
                    type = "road",
                    roadSockets = {"south", "north"}
                }
            elseif cell == "town-hall" then
                cell = {
                    type = "house"
                }
            end
            if cell ~= nil and cell.type == "road" and #cell.roadSockets < 4 then
                for _, direction in ipairs(pickedExpansionDirections) do
                    table.insert(cell.roadSockets, direction)
                end
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
    end

    
    -- Update the grid so it knows where the new roads are
    -- Add cells that we expanded (and that weren't a road before) into the array of roadEnds
    for _, cell in ipairs(cellsExpandedInto) do
        -- if city.grid[cell.coordinates.y] == nil then
        --     city.grid[cell.coordinates.y] = {}
        -- end

        -- test
        cell.direction = invertDirection(cell.direction)

        if city.grid[cell.coordinates.y][cell.coordinates.x] == nil then
            city.grid[cell.coordinates.y][cell.coordinates.x] = {
                type = "road",
                roadSockets = {cell.direction}
            }
            table.insert(city.roadEnds, cell)
        elseif city.grid[cell.coordinates.y][cell.coordinates.x].type == "road" then
            table.insert(city.grid[cell.coordinates.y][cell.coordinates.x].roadSockets, cell.direction)
            table.insert(city.roadEnds, cell)
        end
    end
end

local CITY = {
    growAtRandomRoadEnd = growAtRandomRoadEnd
}

return CITY