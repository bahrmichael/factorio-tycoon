SEGMENTS = require("segments")
TYCOON_STORY = require("tycoon-story")

local function getGridSize(grid)
    return #grid
end

local function getOffsetX(city)
    return -1 * (getGridSize(city.grid) - 1) / 2 + (city.centerX or 0)
end

local function getOffsetY(city)
    return -1 * (getGridSize(city.grid) - 1) / 2 + (city.centerY or 0)
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
local function fill_circle(city, radius)
    local size = getGridSize(city.grid)
    local half = size / 2
    
    for y = 1, size do
        for x = 1, size do
            if city.grid[y] == nil or city.grid[y][x] == nil then
                local dx, dy = x - half, y - half
                local d = math.sqrt(dx * dx + dy * dy)
                if d <= radius then
                    city.grid[y][x] = table.shallow_copy_tycoon(SEGMENTS.allPossibilities)
                    table.insert(city.pending_cells, {y = y, x = x})
                end
            end
        end
    end
end

 -- In-place expansion of the grid and the circle by 1 unit on all sides
local function expand_grid_and_circle(city)
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

    local old_radius = old_size / 2
    local new_radius = old_radius + 1

    -- Update the new circle in the existing grid
    fill_circle(city, new_radius)
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
        type="tree",
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

local function initializeCity(city)
    city.grid = {
        {{"intersection"},    {"linear.horizontal"}, {"intersection"}},
        {{"linear.vertical"}, {"town-hall"},         {"linear.vertical"}},
        {{"intersection"},    {"linear.horizontal"}, {"intersection"}},
    }

    local position = game.surfaces[1].find_non_colliding_position("tycoon-town-center-virtual", {0, 0}, 200, 5, true)
    city.centerX = position.x
    city.centerY = position.y

    local function clearCell(y, x)
        local area = {
            -- Add 1 tile of border around it, so that it looks a bit nicer
            {x - 1, y - 1},
            {x + SEGMENTS.segmentSize + 1, y + SEGMENTS.segmentSize + 1}
        }
        local removables = game.surfaces[1].find_entities_filtered({
            area=area,
            name={"character", "tycoon-town-hall"},
            invert=true
        })
        for _, entity in ipairs(removables) do
            if entity.valid then
                entity.destroy()
            end
        end
    end

    for y = 1, getGridSize(city.grid) do
        for x = 1, getGridSize(city.grid) do
            local cell = city.grid[y][x]
            if cell ~= nil then
                local map = SEGMENTS.getMapForKey(cell[1])
                local startCoordinates = {
                    y = (y + getOffsetY(city)) * SEGMENTS.segmentSize,
                    x = (x + getOffsetX(city)) * SEGMENTS.segmentSize,
                }
                clearCell(startCoordinates.y, startCoordinates.x)
                if map ~= nil then
                    printTiles(startCoordinates.y, startCoordinates.x, map, "concrete")
                end
                if cell[1] == "town-hall" then
                    local townHall = game.surfaces[1].create_entity{
                        name = "tycoon-town-hall",
                        position = {x = startCoordinates.x - 1 + SEGMENTS.segmentSize / 2, y = startCoordinates.y - 1 + SEGMENTS.segmentSize / 2},
                        force = "player"
                    }
                    city.special_buildings.town_hall = townHall
                    global.tycoon_city_buildings[townHall.unit_number] = {
                        cityId = city.id,
                        entity_name = townHall.name
                    }
                end
            end
        end
    end

    -- Add an other ring and start collapsing cells
    expand_grid_and_circle(city)

    for y = 1, getGridSize(city.grid) do
        for x = 1, getGridSize(city.grid) do
            reduceCell(city.grid, y, x)
        end
    end
end

local function popRandomLowEntropyElementFromTable(t, city_grid)
    assert(city_grid ~= nil, "Grid must not be nil. Has it been initialized?")
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
            local neighbourRow = city_grid[neighbour.y]
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
        return cell[1] == "house"
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
            if value == "house" then
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

local function getRandomHouseName()
    local houseNames = {}
    for i = 1, 14, 1 do
        table.insert(houseNames, "tycoon-house-residential-" .. i)
    end
    return houseNames[math.random(1, #houseNames)]
end

local function getPriorityBuilding(city)
    local priorityBuildings = city.priority_buildings
    if priorityBuildings == nil or #priorityBuildings == 0 then
        return nil
    end
    table.sort(city.priority_buildings, function (a, b)
        return (b.priority or 0) > (a.priority or 0)
    end)
    return table.remove(city.priority_buildings, 1)
end

local TICKS_PER_DAY = 25000

local function setBasicNeedsProvided(city, resource, amount)
    if city.stats.basic_needs[resource] == nil then
        city.stats.basic_needs[resource] = {
            provided = 0,
            required = 0,
        }
    end
    city.stats.basic_needs[resource].provided = amount
end

local function setBasicNeedsRequired(city, resource, amount)
    if city.stats.basic_needs[resource] == nil then
        city.stats.basic_needs[resource] = {
            provided = 0,
            required = 0,
        }
    end
    city.stats.basic_needs[resource].required = amount
end

local function updateNeeds(city)
    local citizenCount = city.stats.citizen_count
    for _, need in ipairs(city.basicNeeds.market) do
        setBasicNeedsRequired(city, need.resource, need.amount * citizenCount)
    end
    for _, need in ipairs({city.basicNeeds.waterTower}) do
        setBasicNeedsRequired(city, need.resource, need.amount * citizenCount)
    end
end

local function updateUnlocks(city)
    local citizenCount = city.stats.citizen_count
    for i, v in ipairs(city.unlockables) do
        if citizenCount >= v.threshold then
            if v.type == "basicNeed" and v.basicNeedCategory == "market" then
                game.print({"", {"tycoon-city-has-reached-population", v.threshold}})
                for _, item in ipairs(v.items) do
                    table.insert(city.basicNeeds.market, item)
                    game.print({"", {"tycoon-city-additional-basic-need", item.amount, {"item-name." .. item.resource}}})
                end
                if v.supplyChain == "wheat-cow-milk" then
                    game.forces[1].recipes['tycoon-building-stable'].enabled = true
                    game.forces[1].recipes['tycoon-wheat-to-grain'].enabled = true
                    game.forces[1].recipes['tycoon-grow-cows-with-grain'].enabled = true
                    game.forces[1].recipes['tycoon-milk-cows'].enabled = true
                    game.print({"", {"tycoon-new-building", {"entity-name.tycoon-stable"}}})

                    table.insert(global.tycoon_primary_industries, "tycoon-wheat-farm")
                    game.print({"", {"tycoon-exploration-discovers-primary-industries"}})
                    
                elseif v.supplyChain == "meat" then
                    game.forces[1].recipes['tycoon-butchery'].enabled = true
                    game.forces[1].recipes['tycoon-cows-to-meat'].enabled = true
                    game.print({"", {"tycoon-new-building", {"entity-name.tycoon-butchery"}}})
                end
            else
                game.print("Unhandled unlock: " .. v.type .. "#" .. v.basicNeedCategory)
            end
            updateNeeds(city)
            table.remove(city.unlockables, i)
            return
        end
    end
end

local function printCell(y, x, city)

    local grid = city.grid

    local startCoordinates = {
        y = (y + getOffsetY(city)) * SEGMENTS.segmentSize,
        x = (x + getOffsetX(city)) * SEGMENTS.segmentSize,
    }
    local area = {
        {startCoordinates.x, startCoordinates.y},
        {startCoordinates.x + SEGMENTS.segmentSize, startCoordinates.y + SEGMENTS.segmentSize}
    }

    if not isAreaFree(area, 10) then
        return
    end
    
    removeColldingEntities(area)

    local key = grid[y][x][1]
    if key ~= "empty" then
        local map = SEGMENTS.getMapForKey(key)
        if map ~= nil then
            printTiles(startCoordinates.y, startCoordinates.x, map, "concrete")
        end
        if key == "house" then
            local priorityBuilding = getPriorityBuilding(city)
            if priorityBuilding ~= nil then
                local building = game.surfaces[1].create_entity{
                    name = priorityBuilding.name,
                    position = {x = startCoordinates.x - 0.5 + SEGMENTS.segmentSize / 2, y = startCoordinates.y - 0.5  + SEGMENTS.segmentSize / 2},
                    force = "player"
                }
                global.tycoon_city_buildings[building.unit_number] = {
                    cityId = city.id,
                    entity_name = building.name
                }
                -- todo: how should we handle the town hall being destroyed?
            else
                local house = game.surfaces[1].create_entity{
                    name = getRandomHouseName(),
                    position = {x = startCoordinates.x - 0.5 + SEGMENTS.segmentSize / 2, y = startCoordinates.y - 0.5  + SEGMENTS.segmentSize / 2},
                    force = "player"
                }
                city.stats.citizen_count = city.stats.citizen_count + 4
                updateNeeds(city)
                updateUnlocks(city)
                script.register_on_entity_destroyed(house)
                global.tycoon_city_buildings[house.unit_number] = {
                    cityId = city.id,
                    entity_name = house.name
                }
            end
        end
    end
end

local function cityGrowth(city)
    if getGridSize(city.grid) > 1 then

        local hardwareStores = game.surfaces[1].find_entities_filtered{
            name="tycoon-hardware-store",
            position=city.special_buildings.town_hall.position,
            radius=1000
        }

        local hardwareConsumption = {
            {
                resource = "iron-plate",
                amount = 1,
            },
            {
                resource = "stone",
                amount = 1,
            }
        }
        local storeWithSupply = nil

        if #hardwareStores >= 1 then
            for _, store in ipairs(hardwareStores) do
                local countNeedsMetInStore = 0
                for _, consumption in ipairs(hardwareConsumption) do
                    if store.get_item_count(consumption.resource) >= consumption.amount then
                        countNeedsMetInStore = countNeedsMetInStore + 1
                    end
                end
                if countNeedsMetInStore == #hardwareConsumption then
                    storeWithSupply = store
                    break
                end
            end
        end

        if storeWithSupply ~= nil and storeWithSupply.valid then

            local nextCell = popRandomLowEntropyElementFromTable(city.pending_cells, city.grid)
            if nextCell == nil then
                expand_grid_and_circle(city)
            else
                reduceCell(city.grid, nextCell.y, nextCell.x)
                collapseCell(city.grid, nextCell.y, nextCell.x)

                -- todo: this may consume resources even if the house/street is not printed.
                -- move the consumption further in, or return a print result from printCell
                for _, consumption in ipairs(hardwareConsumption) do
                    storeWithSupply.remove_item{name = consumption.resource, count = consumption.amount}
                end
                printCell(nextCell.y, nextCell.x, city)
            end
        end
    end
end

local function cityBasicConsumption(city, amountModifier)

    local markets = game.surfaces[1].find_entities_filtered{
        name="tycoon-market",
        position=city.special_buildings.town_hall.position,
        radius=1000
    }
    local waterTowers = game.surfaces[1].find_entities_filtered{
        name="tycoon-water-tower",
        position=city.special_buildings.town_hall.position,
        radius=1000
    }
    local treasuries = game.surfaces[1].find_entities_filtered{
        name="tycoon-treasury",
        position=city.special_buildings.town_hall.position,
        radius=1000
    }

    local countNeedsMet = 0

    if #markets >= 1 then
        for _, consumption in ipairs(city.basicNeeds.market) do
            local requiredAmount = math.ceil(consumption.amount * city.stats.citizen_count * amountModifier)
            local marketsWithSupply = {}
            for _, market in ipairs(markets) do
                local marketItemCount = market.get_item_count(consumption.resource)
                if marketItemCount >= requiredAmount then
                    table.insert(marketsWithSupply, market)
                end
            end
            if #marketsWithSupply > 0 then
                local randomMarket = marketsWithSupply[math.random(#marketsWithSupply)]
                local itemsRemoved = randomMarket.remove_item({name = consumption.resource, count = requiredAmount})
                setBasicNeedsProvided(city, consumption.resource, math.ceil(itemsRemoved / amountModifier))
                countNeedsMet = countNeedsMet + 1

                -- Let citizens pay for each item that they buy
                if #treasuries > 0 then
                    local randomTreasury = treasuries[math.random(#treasuries)]
                    local currencyPerUnit = 1
                    local reward = math.ceil(currencyPerUnit * requiredAmount)
                    if reward > 0 then
                        randomTreasury.insert{name = "tycoon-currency", count = reward}
                    end
                end
            end
        end
    else
        setBasicNeedsProvided(city, "tycoon-apple", 0)
    end
    if #waterTowers >= 1 then
        for _, consumption in ipairs({city.basicNeeds.waterTower}) do
            local waterTowersWithSupply = {}
            local requiredAmount = math.ceil(consumption.amount * city.stats.citizen_count * amountModifier)
            for _, waterTower in ipairs(waterTowers) do
                local towerFluidCount = waterTower.get_fluid_count(consumption.resource)
                if towerFluidCount >= requiredAmount then
                    table.insert(waterTowersWithSupply, waterTower)
                end
            end
            if #waterTowersWithSupply > 0 then
                local randomWaterTower = waterTowersWithSupply[math.random(#waterTowersWithSupply)]
                local fluidRemoved = randomWaterTower.remove_fluid({name = consumption.resource, amount = requiredAmount})
                setBasicNeedsProvided(city, consumption.resource, math.ceil(fluidRemoved / amountModifier))
                countNeedsMet = countNeedsMet + 1

                -- Let citizens pay for each piece of water
                if #treasuries > 0 then
                    local randomTreasury = treasuries[math.random(#treasuries)]
                    local currencyPerUnit = 0.1
                    local reward = math.ceil(currencyPerUnit * requiredAmount)
                    if reward > 0 then
                        randomTreasury.insert{name = "tycoon-currency", count = reward}
                    end
                end
            end
        end
    else
        setBasicNeedsProvided(city, "water", 0)
    end
    local needsCount = (#city.basicNeeds.market + #{city.basicNeeds.waterTower})
    return needsCount == countNeedsMet
end

local function getItemForPrimaryProduction(name)
    if name == "tycoon-apple-farm" then
        return "tycoon-apple"
    elseif name == "tycoon-wheat-farm" then
        return "tycoon-wheat"
    else
        return "Unknown"
    end
end

local function localizePrimaryProductionName(name)
    if name == "tycoon-apple-farm" then
        return "Apple Farm"
    elseif name == "tycoon-wheat-farm" then
        return "Wheat Farm"
    else
        return "Primary Production"
    end
end

local function placePrimaryIndustryAtPosition(position, entityName)
    if position ~= nil then
        local tag = game.forces.player.add_chart_tag(game.surfaces[1],
            {
                position = {x = position.x, y = position.y},
                icon = {
                    type = "item",
                    name = getItemForPrimaryProduction(entityName),
                },
                text = localizePrimaryProductionName(entityName),
            }
        )
        if tag ~= nil then
            return game.surfaces[1].create_entity{
                name = entityName,
                position = {x = position.x, y = position.y},
                force = "player"
            }
        end
    end
    return nil
end

local function randomPrimaryIndustry()
    local industries = global.tycoon_primary_industries
    return industries[math.random(#industries)]
end

local function findCityById(cityId)
    for _, city in ipairs(global.tycoon_cities) do
        if city.id == cityId then
            return city
        end
    end
    return nil
end

script.on_event(defines.events.on_entity_destroyed, function(event)
    local unit_number = event.unit_number
    if unit_number ~= nil then
        local building = global.tycoon_city_buildings[unit_number]
        if building ~= nil then
            if string.find(building.entity_name, "tycoon-house-residential-", 1, true) then
                local cityId = building.cityId
                local city = findCityById(cityId)
                if city ~= nil then
                    city.stats.citizen_count = city.stats.citizen_count - 4
                end
            end
        end
    end
end)

script.on_event(defines.events.on_chunk_charted, function (chunk)
    if math.abs(chunk.position.x) < 5 and math.abs(chunk.position.y) < 5 then
        return
    end
    if math.random() < 0.25 then
        local industryName = randomPrimaryIndustry()
        local position = game.surfaces[1].find_non_colliding_position_in_box(industryName, chunk.area, 2, true)
        local nearbySameProduction = game.surfaces[1].find_entities_filtered{position=position, radius=1000, name=industryName, limit=1}
        if #nearbySameProduction == 0 then
            placePrimaryIndustryAtPosition(position, industryName)
        end
    end
end)

local function findCityByTownHallUnitNumber(townHallUnitNumber)
    for _, city in ipairs(global.tycoon_cities) do
        if city.special_buildings.town_hall ~= nil and city.special_buildings.town_hall.unit_number == townHallUnitNumber then
            return city
        end
    end
    return nil
end

script.on_event(defines.events.on_gui_opened, function (gui)
    if gui.entity ~= nil and gui.entity.name == "tycoon-town-hall" then
        local player = game.players[gui.player_index]
        local unit_number = gui.entity.unit_number
        local city = findCityByTownHallUnitNumber(unit_number)
        assert(city ~= nil, "Could not find the city for town hall unit number ".. unit_number)

        local cityGui = player.gui.relative["city_overview_" .. unit_number]
        if cityGui == nil then
            local anchor = {gui = defines.relative_gui_type.container_gui, name = "tycoon-town-hall", position = defines.relative_gui_position.right}
            cityGui = player.gui.relative.add{type = "frame", anchor = anchor, caption = {"", {"tycoon-gui-city-overview"}}, direction = "vertical", name = "city_overview_" .. unit_number}
            cityGui.add{type = "label", caption = {"", {"tycoon-gui-update-info"}}}

            local stats = cityGui.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-stats"}}, name = "city_stats"}
            stats.add{type = "label", caption = "Citizens: " .. city.stats.citizen_count, name = "citizen_count"}

            local basicNeeds = cityGui.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-basic-needs"}}, name = "basic_needs"}
            basicNeeds.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle"}}}
        end

        if cityGui.city_stats.basic_needs_met == nil then
            cityGui.city_stats.add{type = "label", caption = {"", {"tycoon-gui-basic-needs-met"}, ": ", "[color=red]", {"tycoon-no"}, "[/color]"}, name = "basic_needs_met"}
        end

        cityGui.city_stats.citizen_count.caption = {"", {"tycoon-gui-citizens"}, ": ",  city.stats.citizen_count}
        if city.basicNeedsMet then
            cityGui.city_stats.basic_needs_met.caption = {"", {"tycoon-gui-basic-needs-met"}, ": ", "[color=green]", {"tycoon-yes"}, "[/color]"}
        else
            cityGui.city_stats.basic_needs_met.caption = {"", {"tycoon-gui-basic-needs-met"}, ": ", "[color=red]", {"tycoon-no"}, "[/color]"}
        end

        local basicNeedsGui = cityGui.basic_needs
        for key, value in pairs(city.stats.basic_needs) do

            local itemName = key
            if string.find(key, "tycoon-", 1, true) then
                itemName = "item-name." .. itemName
            elseif key == "water" then
                -- Vanilla items like water are not in our localization config, and therefore have to be access differently
                itemName = "fluid-name." .. key
            end

            local color = "green"
            if value.provided < value.required then
                color = "red"
            end

            local gui = basicNeedsGui[key]
            if gui == nil then
                gui = basicNeedsGui.add{type = "flow", direction = "vertical", caption = {"", {itemName}}, name = key}
                gui.add{type = "label", name = "supply", caption = {"", {itemName}, ": ", "[color=" .. color .. "]", value.provided, "/", value.required, "[/color]"}}
            end
            gui.supply.caption = {"", {itemName}, ": ", "[color=" .. color .. "]", value.provided, "/", value.required, "[/color]"}
        end
    end
end)

script.on_nth_tick(600, function()
    for _, city in ipairs(global.tycoon_cities) do
        local basicNeedsMet = cityBasicConsumption(city, 600 / TICKS_PER_DAY)
        city.basicNeedsMet = basicNeedsMet
    end
end)

script.on_nth_tick(60, function(event)

    for _, city in ipairs(global.tycoon_cities) do
        if city.basicNeedsMet and city.constructionProbability > math.random() then
            cityGrowth(city)
        end

        -- We need to initialize the tag here, because tags can only be placed on charted chunks.
        -- And the game needs a moment to start and chart the initial chunks, even if it can already place entities.
        if city.tag == nil and city.special_buildings.town_hall ~= nil then
            local tag = game.forces.player.add_chart_tag(game.surfaces[1],
                {
                    position = {x = city.special_buildings.town_hall.position.x, y = city.special_buildings.town_hall.position.y}, 
                    text = city.name .. " Town Center"
                }
            )
            city.tag = tag
        end
    end

    if global.tycoon_new_primary_industries ~= nil and #global.tycoon_new_primary_industries > 0 then
        for i, primaryIndustry in ipairs(global.tycoon_new_primary_industries) do
            local x, y
            if primaryIndustry.startCoordinates == nil then
                local chunk = game.surfaces[1].get_random_chunk()
                x = chunk.x * 32
                y = chunk.y * 32
            else
                x = primaryIndustry.startCoordinates.x
                y = primaryIndustry.startCoordinates.y
            end
            local position = game.surfaces[1].find_non_colliding_position(primaryIndustry.name, {x, y}, 200, 5, true)
            local entity = placePrimaryIndustryAtPosition(position, primaryIndustry.name)
            if entity ~= nil then
                table.remove(global.tycoon_new_primary_industries, i)
            end
        end
    end
end)

script.on_init(function()

    global.tycoon_city_buildings = {}

    global.tycoon_cities = {{
        id = 1,
        grid = {},
        pending_cells = {},
        priority_buildings = {},
        special_buildings = {
            town_hall = nil,
        },
        basicNeeds = {
            market = {
                {
                    amount = 3,
                    resource = "tycoon-apple",
                },
            },
            waterTower = {
                amount = 10,
                resource = "water",
            }
        },
        basicNeedsMet = false,
        luxyryNeeds = {

        },
        constructionNeeds = {
            strone = 1
        },
        centerX = 8,
        centerY = -3,
        hasTag = false,
        name = "Your First City",
        stats = {
            citizen_count = 5,
            basic_needs = {}
        },
        constructionProbability = 1.0,
        unlockables = {
            {
                threshold = 100,
                type = "basicNeed",
                basicNeedCategory = "market",
                items = {
                    {
                        amount = 1,
                        resource = "tycoon-milk-bottle",
                    },
                },
                supplyChain = "wheat-cow-milk"
            },
            {
                threshold = 200,
                type = "basicNeed",
                basicNeedCategory = "market",
                items = {
                    {
                        amount = 1,
                        resource = "tycoon-meat",
                    },
                },
                supplyChain = "meat"
            }
        }
    }}
    initializeCity(global.tycoon_cities[1])
    updateNeeds(global.tycoon_cities[1])

    global.tycoon_primary_industries = {"tycoon-apple-farm", "tycoon-wheat-farm"}

    TYCOON_STORY[1]()

    -- local x, y = 1,1
    -- local startCoordinates = {
    --     y = (y + getOffsetY(global.tycoon_city[1])) * SEGMENTS.segmentSize,
    --     x = (x + getOffsetX(global.tycoon_city[1])) * SEGMENTS.segmentSize,
    -- }
    -- printTiles(startCoordinates.x, startCoordinates.y, SEGMENTS.house.map, "concrete")
    -- game.surfaces[1].create_entity{
    --     name = "tycoon-stable",
    --     position = {x = 0, y = 20},
    --     force = "player"
    -- }

        -- /c game. player. insert{ name="stone", count=1000 }
        -- /c game. player. insert{ name="tycoon-water-tower", count=1 }
        -- /c game. player. insert{ name="tycoon-cow", count=100 }
end)