SEGMENTS = require("segments")
TYCOON_STORY = require("tycoon-story")

local tycoon_state = {
    grid = nil,
    pendingCells = {},
}

local function getGridSize()
    return #tycoon_state.grid
end

local function getOffset()
    return -1 * (getGridSize() - 1) / 2 + 1
end

local function printTiles(startY, startX, map, tileName)
    local x, y = startX, startY
    for _, value in ipairs(map) do
        for i = 1, #value do
            local char = string.sub(value, i, i)
            if char == "1" then
                game.surfaces[1].set_tiles({{name = tileName, position = {x, y}}})
            end
            x = x + 1
        end
        x = startX
        y = y + 1
    end
end

local function getCell(grid, y, x)
    local row = grid[y]
    if row == nil then
        return nil
    end
    return row[x]
end

local function getInverseDirection(direction)
    if direction == "top" then
        return "bottom"
    elseif direction == "bottom" then
        return "top"
    elseif direction == "right" then
        return "left"
    elseif direction == "left" then
        return "right"
    end
end

local function getSocket(sockets, direction)
    if direction == "top" then
        return sockets.top
    elseif direction == "bottom" then
        return sockets.bottom
    elseif direction == "right" then
        return sockets.right
    elseif direction == "left" then
        return sockets.left
    end
end

local function isOptionValid(grid, y, x, localOption)

    local sides = {
        {
            direction = "left",
            cell = getCell(grid, y, x - 1)
        },
        {
            direction = "top",
            cell = getCell(grid, y - 1, x)
        },
        {
            direction = "right",
            cell = getCell(grid, y, x + 1)
        },
        {
            direction = "bottom",
            cell = getCell(grid, y + 1, x)
        }
    }

    local skipNeighbours = {"intersection"}

    for _, side in ipairs(sides) do
        -- If a side's cell is nil, then it means that this cell is
        -- not part of the grid yet and doesn't affect the collapse.
        if side.cell ~= nil then

            local localSocket = getSocket(SEGMENTS.getObjectForKey(localOption).sockets, side.direction)
            local directionFromSide = getInverseDirection(side.direction)

            -- For certain cells it makes little sense to have them next to each other.
            -- E.g. an intersection next to an intersection looks a bit odd.
            if #side.cell == 1 then
                for _, skippable in ipairs(skipNeighbours) do
                    if localOption == skippable and side.cell[1] == skippable then
                        return false
                    end
                end 
            end

            local hasValidOption = false
            for _, option in ipairs(side.cell) do
                local socketOfSide = getSocket(SEGMENTS.getObjectForKey(option).sockets, directionFromSide)
                if localSocket == socketOfSide then
                    hasValidOption = true
                    break
                end
            end
            if not hasValidOption then
                return false
            end
        end
    end

    return true
end

local function reduceCell(grid, y, x) 
    if grid[y] == nil or grid[y][x] == nil then
        return
    end
    -- If there is only 1 option, then we don't need to collapse further
    if #grid[y][x] > 1 then
        local currentOptions = grid[y][x]
        local newOptions = {}
        
        for _, option in ipairs(currentOptions) do
            if isOptionValid(grid, y, x, option) then
                table.insert(newOptions, option)
            end
        end

        grid[y][x] = newOptions
    end
end

function table.shallow_copy_tycoon(t)
    local t2 = {}
    for k,v in pairs(t) do
      t2[k] = v
    end
    return t2
end

-- Fill a circle in the grid with center (h, k) and radius r
local function fill_circle(grid, radius)
    local size = getGridSize()
    local half = size / 2
    
    for y = 1, size do
        for x = 1, size do
            if grid[y] == nil or grid[y][x] == nil then
                local dx, dy = x - half, y - half
                local d = math.sqrt(dx * dx + dy * dy)
                if d <= radius then
                    grid[y][x] = table.shallow_copy_tycoon(SEGMENTS.allPossibilities)
                    table.insert(tycoon_state.pendingCells, {y = y, x = x})
                end
            end
        end
    end
end

 -- In-place expansion of the grid and the circle by 1 unit on all sides
local function expand_grid_and_circle(grid)
    local old_size = getGridSize()
    local new_size = old_size + 2  -- Expand by 1 on each side

    -- Shift rows downward to keep center
    for y = new_size, 1, -1 do
        grid[y] = grid[y-1] or {}
    end

    -- Add new columns at the left and right
    for y = 1, new_size do
        table.insert(grid[y], 1, nil)
        grid[y][new_size] = nil
    end

    local old_radius = old_size / 2
    local new_radius = old_radius + 1

    global.tycoon_city_size_tiles = new_radius * SEGMENTS.segmentSize

    -- Update the new circle in the existing grid
    fill_circle(grid, new_radius)
end

local function initializeCity()
    tycoon_state.grid = {
        {{"corner.bottomToLeft"},{ "water-tower"},      {"corner.rightToBottom"}},
        {{"linear.vertical"},    {"town-hall"},          {"linear.vertical"}},
        {{"intersection"},       {"linear.horizontal"},  {"intersection"}},
    }

    local function clearCell(y, x)
        local xStart = (x * SEGMENTS.segmentSize) + getOffset()
        local yStart = (y * SEGMENTS.segmentSize) + getOffset()
        local area = {
            -- Add 1 tile of border around it, so that it looks a bit nicer
            {xStart - 1, yStart -1 },
            {xStart + SEGMENTS.segmentSize + 1, yStart + SEGMENTS.segmentSize + 1}
        }
        local removables = game.surfaces[1].find_entities_filtered({area=area})
        for _, entity in pairs(removables) do
            if entity.valid and entity.name ~= "character" and entity.name ~= "town-hall" and entity.name ~= "water-tower" then
                entity.destroy()
            end
        end
    end

    for y = 1, getGridSize() do
        for x = 1, getGridSize() do
            local cell = tycoon_state.grid[y][x]
            if cell ~= nil then
                local map = SEGMENTS.getMapForKey(cell[1])
                if map ~= nil then
                    clearCell(y, x)
                    printTiles((y + getOffset()) * SEGMENTS.segmentSize, (x + getOffset()) * SEGMENTS.segmentSize, map, "concrete")
                    local startCoordinates = {
                        y = (y + getOffset()) * SEGMENTS.segmentSize,
                        x = (x + getOffset()) * SEGMENTS.segmentSize,
                    }
                    if cell[1] == "town-hall" then
                        local townHall = game.surfaces[1].create_entity{
                            name = "town-hall",
                            position = {x = startCoordinates.x - 1 + SEGMENTS.segmentSize / 2, y = startCoordinates.y - 1  + SEGMENTS.segmentSize / 2},
                            force = "player"
                        }
                        global.tycoon_town_hall = townHall
                    elseif cell[1] == "water-tower" then
                        local waterTower = game.surfaces[1].create_entity{
                            name = "water-tower",
                            position = {x = startCoordinates.x + SEGMENTS.segmentSize / 2, y = startCoordinates.y - 1 * SEGMENTS.segmentSize + SEGMENTS.segmentSize / 2},
                            force = "player"
                        }
                        game.surfaces[1].create_entity{
                            name = "pipe",
                            position = {x = waterTower.position.x + 2, y = waterTower.position.y},
                            force = "player"
                        }
                        global.tycoon_water_tower = waterTower
                    end
                end
            end
        end
    end

    -- Add an other ring and start collapsing cells
    expand_grid_and_circle(tycoon_state.grid)
    for y = 1, getGridSize() do
        for x = 1, getGridSize() do
            reduceCell(tycoon_state.grid, y, x)
        end
    end
end

local function popRandomLowEntropyElementFromTable(t)
    assert(tycoon_state.grid ~= nil, "Grid must not be nil. Has it been initialized?")
    assert(t ~= nil, "Table must not be nil. Has it been initialized?")
    if #t == 0 then
        return nil
    end
    -- "The sort algorithm is not stable; that is, elements considered equal by the given order may have their relative positions changed by the sort."
    -- We make use of this to have the lowest entropy values first, but then have some randomization (I assume).
    table.sort(t, function (a, b)
        return #a < #b
    end)

    -- Try to find an element that is next to a street coming out of the existing grid
    for i, coordinates in ipairs(t) do
        local neighbours = {
            {
                y = coordinates.y,
                x = coordinates.x + 1,
                side = "right"
            },
            {
                y = coordinates.y + 1,
                x = coordinates.x,
                side = "top"
            },
            {
                y = coordinates.y,
                x = coordinates.x - 1,
                side = "left"
            },
            {
                y = coordinates.y - 1,
                x = coordinates.x,
                side = "bottom"
            }
        }
        for _, neighbour in ipairs(neighbours) do
            local neighbourRow = tycoon_state.grid[neighbour.y]
            if neighbourRow ~= nil then
                local neighbourCell = neighbourRow[neighbour.y]
                if neighbourCell ~= nil and #neighbourCell == 1 and neighbourCell[1] ~= "empty" then
                    local socket = getSocket(SEGMENTS.getObjectForKey(neighbourCell[1]).sockets, getInverseDirection(neighbour.side))
                    if socket == "street" then
                        return table.remove(t, i)
                    end
                end
            end
        end
    end

    return table.remove(t, 1)
end

-- https://stackoverflow.com/a/66699630
local function utils_Set(list)
    if list == nil then
        return {}
    end
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

local function countConnectedHouses(grid, y, x, count, visited)
    -- Verify that the current cell is a house
    if grid[y] == nil or grid[y][x] == nil then
        return 0
    end

    -- Check if we already visited this cell
    local _set = utils_Set(visited)
    if _set[y .. "x" .. x] then
        return 0
    end
    table.insert(visited, y .. "x" .. x)

    local leftCell = getCell(grid, y, x - 1)
    local rightCell = getCell(grid, y, x + 1)
    local topCell = getCell(grid, y - 1, x)
    local bottomCell = getCell(grid, y + 1, x)

    local function isHouseNeighbour(cell)
        if cell == nil or #cell ~= 1 then
            return false
        end
        return cell[1] == "empty"
    end

    if isHouseNeighbour(leftCell) then
        count = count + countConnectedHouses(grid, y, x - 1, count, visited)
    end
    if isHouseNeighbour(rightCell) then
        count = count + countConnectedHouses(grid, y, x + 1, count, visited)
    end
    if isHouseNeighbour(topCell) then
        count = count + countConnectedHouses(grid, y - 1, x, count, visited)
    end
    if isHouseNeighbour(bottomCell) then
        count = count + countConnectedHouses(grid, y + 1, x, count, visited)
    end
    return count + 1
end

local function collapseCell(grid, y, x)
    local cell = grid[y][x]
    local pick
    if #cell == 0 then
        pick = "empty"
    elseif #cell == 1 then
        pick = cell[1]
    else
        local weightedValues = {}
        for _, value in ipairs(cell) do
            local weight = SEGMENTS.getWeightForKey(value)
            if value == "empty" then
                local connectedFields = countConnectedHouses(grid, y, x, 0, {})
                weight = weight / connectedFields
                if weight < 1 then
                    weight = 1
                end
            end
            for i = 1, weight, 1 do
                table.insert(weightedValues, value)
            end
        end
        pick = weightedValues[math.random(1, #weightedValues)]
    end
    grid[y][x] = {pick}
end

local removableEntities = {
    "rock-",
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

local function printCell(grid, y, x)

    local startCoordinates = {
        y = (y + getOffset()) * SEGMENTS.segmentSize,
        x = (x + getOffset()) * SEGMENTS.segmentSize,
    }
    local area = {
        {startCoordinates.x, startCoordinates.y},
        {startCoordinates.x + SEGMENTS.segmentSize, startCoordinates.y + SEGMENTS.segmentSize}
    }

    local hasWaterOrCliffs = false
    local tiles = game.surfaces[1].find_tiles_filtered{
        area = area
    }
    for _, tile in pairs(tiles) do
        if tile.name == "water" or tile.name == "cliff" then
            hasWaterOrCliffs = true
            break
        end
    end
     
    if hasWaterOrCliffs then
        return false
    end
    
    local entitiesForTrees = game.surfaces[1].find_entities_filtered({area=area})
    local treeCount = 0
    for _, entity in pairs(entitiesForTrees) do
        if entity.valid and string.find(entity.name, "tree-", 1, true) then
            treeCount = treeCount + 1
        end
    end
    if treeCount > 5 then
        return false
    end
    
    removeColldingEntities(area)
    
    local entities = game.surfaces[1].find_entities_filtered({area=area})
    -- Don't attempt to build over entities (which includes the character and anything they built)
    if #entities > 0 then
        return
    end

    local key = grid[y][x][1]
    if key ~= "empty" then
        local map = SEGMENTS.getMapForKey(key)
        if map ~= nil then
            printTiles(startCoordinates.y, startCoordinates.x, map, "concrete")
        end
    elseif key == "empty" then
        local map = {
            "111111",
            "111111",
            "111111",
            "111111",
            "111111",
            "111111"
        }
        printTiles(startCoordinates.y, startCoordinates.x, map, "refined-concrete")
        local houseNames = {}
        for i = 1, 14, 1 do
            table.insert(houseNames, "house-residential-" .. i)
          end
        game.surfaces[1].create_entity{
            name = houseNames[math.random(1, #houseNames)],
            position = {x = startCoordinates.x - 0.5 + SEGMENTS.segmentSize / 2, y = startCoordinates.y - 0.5  + SEGMENTS.segmentSize / 2},
            force = "player"
        }
    end
    return true
end

script.on_nth_tick(60, function(event)

    if global.tycoon_city_building == true and getGridSize() > 1 then
        local townHall = global.tycoon_town_hall

        if townHall ~= nil and townHall.valid then
            local requiredResources = global.tycoon_city_consumption
            for _, resource in ipairs(requiredResources) do
                local requiredResource = resource.resource
                local requiredAmount = resource.amount
                local resourceCount = townHall.get_item_count(requiredResource)
                if resourceCount < requiredAmount then
                    return
                end
            end

            for _, resource in ipairs(requiredResources) do
                townHall.remove_item{name = resource.resource, count = resource.amount}
            end


            local nextCell = popRandomLowEntropyElementFromTable(tycoon_state.pendingCells)
            if nextCell == nil then
                expand_grid_and_circle(tycoon_state.grid)
            else
                reduceCell(tycoon_state.grid, nextCell.y, nextCell.x)
                collapseCell(tycoon_state.grid, nextCell.y, nextCell.x)
                printCell(tycoon_state.grid, nextCell.y, nextCell.x)
            end
            global.tycoon_state = tycoon_state
        end
    end
  
end)

script.on_load(function()
    -- We're assuming that the city was initialized during the on_init hook, and that the player didn't break this
    tycoon_state = global.tycoon_state -- This is what's loading the previous saved city / grid
end)

script.on_init(function() 
    global.tycoon_state = initializeCity()
    TYCOON_STORY[1]()
    -- global.tycoon_city_building = true
    -- global.tycoon_city_consumption = {
    --     {
    --         resource = "stone",
    --         amount = 1
    --     }
    -- }
        
        -- /c game. player. insert{ name="stone", count=1000 }
end)