local Queue = require "queue"
SEGMENTS = require("segments")
CITY = require("city")
-- TYCOON_STORY = require("tycoon-story")

local function getGridSize(grid)
    return #grid
end

local function getOffsetX(city)
    return -1 * (getGridSize(city.grid) - 1) / 2 + (city.center.x or 0)
end

local function getOffsetY(city)
    return -1 * (getGridSize(city.grid) - 1) / 2 + (city.center.y or 0)
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

local function translateStarterCell(cell)
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
            type = "building"
        }
    else
        cell = {
            type = "road",
            roadSockets = {"south", "north", "east", "west"}
        }
        -- assert(false, "Should not reach this branch in translateStarterCell.")
    end
    return cell
end

local function initializeCity(city)
    city.grid = {
        {{"corner.rightToBottom"},    {"linear.horizontal"}, {"corner.bottomToLeft"}},
        {{"linear.vertical"}, {"town-hall"},         {"linear.vertical"}},
        {{"corner.topToRight"},    {"linear.horizontal"}, {"corner.leftToTop"}},
    }

    local position = game.surfaces[1].find_non_colliding_position("tycoon-town-center-virtual", {0, 0}, 200, 5, true)
    city.center.x = position.x
    city.center.y = position.y

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


    for i = 1, #city.grid, 1 do
        for j = 1, #city.grid, 1 do
            city.grid[i][j] = translateStarterCell(city.grid[i][j][1])
        end
    end

    local possibleRoadEnds = {
        {
            coordinates = {
                x = 1,
                y = 1,
            },
            direction = "west"
        },
        {
            coordinates = {
                x = 1,
                y = 1,
            },
            direction = "north"
        },

        {
            coordinates = {
                x = 3,
                y = 1,
            },
            direction = "east"
        },
        {
            coordinates = {
                x = 3,
                y = 1,
            },
            direction = "north"
        },

        {
            coordinates = {
                x = 3,
                y = 3,
            },
            direction = "east"
        },
        {
            coordinates = {
                x = 3,
                y = 3,
            },
            direction = "south"
        },

        {
            coordinates = {
                x = 1,
                y = 3,
            },
            direction = "west"
        },
        {
            coordinates = {
                x = 1,
                y = 3,
            },
            direction = "south"
        },
    }

    city.roadEnds = Queue.new()

    -- We're adding some randomness here
    -- Instead of adding 8 road connections to the town center, we pick between 4 and 8.
    -- This makes individual towns feel a bit more diverse.
    local roadEndCount = math.random(4, 8)
    for i = 1, roadEndCount, 1 do
        Queue.pushright(city.roadEnds, table.remove(possibleRoadEnds, math.random(#possibleRoadEnds)))
    end
end

local DAY_TO_MINUTE_FACTOR = 600 / 25000

local function getRequiredAmount(amountPerDay, citizenCount)
    return math.ceil(amountPerDay * DAY_TO_MINUTE_FACTOR * citizenCount)
end

local function setBasicNeedsProvided(city, resource, amount)
    if city.stats.basic_needs[resource] == nil then
        city.stats.basic_needs[resource] = {
            provided = 0,
            required = 0,
        }
    end
    city.stats.basic_needs[resource].provided = math.floor(amount)
end

local function setBasicNeedsRequired(city, resource, amount)
    if city.stats.basic_needs[resource] == nil then
        city.stats.basic_needs[resource] = {
            provided = 0,
            required = 0,
        }
    end
    city.stats.basic_needs[resource].required = math.floor(amount)
end

local function updateNeeds(city)
    local citizenCount = city.stats.citizen_count
    for _, need in ipairs(city.basicNeeds.market) do
        setBasicNeedsRequired(city, need.resource, getRequiredAmount(need.amount, citizenCount))
    end
    for _, need in ipairs({city.basicNeeds.waterTower}) do
        setBasicNeedsRequired(city, need.resource, getRequiredAmount(need.amount, citizenCount))
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
            table.remove(city.unlockables, i)
            return
        end
    end
end

local function growCitizenCount(city, count)
    city.stats.citizen_count = city.stats.citizen_count + count
    updateUnlocks(city)
    -- update needs must run because updateUnlocksmay unlock new demands
    updateNeeds(city)
end

local function invalidateSpecialBuildingsList(city, name)
    assert(city.special_buildings ~= nil, "The special buildings should never be nil. There has been one error though, so I added this assetion.")
    -- Support for savegames <= 0.0.14
    if city.special_buildings.other == nil then
        city.special_buildings.other = {}
    end

    if city.special_buildings.other[name] ~= nil then
        city.special_buildings.other[name] = nil
    end 
end

local function listSpecialCityBuildings(city, name)
    -- Support for savegames <= 0.0.14
    if city.special_buildings.other == nil then
        city.special_buildings.other = {}
    end

    -- dev hack for profiling
    if name == "tycoon-treasury" then
        return {}
    end

    local entities = {}
    if city.special_buildings.other[name] ~= nil and #city.special_buildings.other[name] > 0 then
        entities = city.special_buildings.other[name]
    else
        entities = game.surfaces[1].find_entities_filtered{
            name=name,
            position=city.special_buildings.town_hall.position,
            radius=1000
        }
        city.special_buildings.other[name] = entities
    end

    local result = {}
    for _, entity in ipairs(entities) do
        if entity ~= nil and entity.valid then
            table.insert(result, entity)
        end
    end
    return result
end

local function consumeItems(items, entities, city, isConstruction)

    for _, item in ipairs(items) do
        local entitiesWithSupply = {}
        for _, entity in ipairs(entities) do
            local availableCount = entity.get_item_count(item.name)
            if availableCount > 0 then
                table.insert(entitiesWithSupply, entity)
            end
        end
        
        local requiredAmount
        if isConstruction then
            requiredAmount = item.required
        else
            requiredAmount = getRequiredAmount(item.required, city.stats.citizen_count)
        end
        local consumedAmount = 0
        for _, entity in ipairs(entitiesWithSupply) do
            local availableCount = entity.get_item_count(item.name)
            local removed = entity.remove_item({name = item.name, count = math.min(requiredAmount, availableCount)})
            consumedAmount = consumedAmount + removed
            requiredAmount = requiredAmount - consumedAmount
            if requiredAmount <= 0 then
                break
            end
        end

        local treasuries = listSpecialCityBuildings(city, "tycoon-treasury")
        if #treasuries > 0 then
            local randomTreasury = treasuries[math.random(#treasuries)]
            local currencyPerUnit = 1
            local reward = math.ceil(currencyPerUnit * consumedAmount)
            if reward > 0 then
                randomTreasury.insert{name = "tycoon-currency", count = reward}
            end
        end
    end
end

local function updateProvidedAmounts(city)
    local markets = listSpecialCityBuildings(city, "tycoon-market")
    local waterTowers = listSpecialCityBuildings(city, "tycoon-water-tower")

    if #markets >= 1 then
        for _, consumption in ipairs(city.basicNeeds.market) do
            local totalAvailable = 0
            for _, market in ipairs(markets) do
                local availableCount = market.get_item_count(consumption.resource)
                totalAvailable = totalAvailable + availableCount
            end
            setBasicNeedsProvided(city, consumption.resource, totalAvailable)
        end
    else
        for _, consumption in ipairs(city.basicNeeds.market) do
            setBasicNeedsProvided(city, consumption.resource, 0)
        end
    end

    if #waterTowers >= 1 then
        for _, consumption in ipairs({city.basicNeeds.waterTower}) do
            local totalAvailable = 0
            local waterTowersWithSupply = {}
            for _, waterTower in ipairs(waterTowers) do
                local availableCount = waterTower.get_fluid_count(consumption.resource)
                totalAvailable = totalAvailable + availableCount
            end
            setBasicNeedsProvided(city, consumption.resource, totalAvailable)
        end
    else
        for _, consumption in ipairs({city.basicNeeds.waterTower}) do
            setBasicNeedsProvided(city, consumption.resource, 0)
        end
    end
end

local function cityBasicConsumption(city)

    local markets = listSpecialCityBuildings(city, "tycoon-market")
    local waterTowers = listSpecialCityBuildings(city, "tycoon-water-tower")
    local treasuries = listSpecialCityBuildings(city, "tycoon-treasury")

    local countNeedsMet = 0

    if #markets >= 1 then
        for _, consumption in ipairs(city.basicNeeds.market) do
            local requiredAmount = getRequiredAmount(consumption.amount, city.stats.citizen_count)
            local marketsWithSupply = {}
            for _, market in ipairs(markets) do
                local availableCount = market.get_item_count(consumption.resource)
                if availableCount > 0 then
                    table.insert(marketsWithSupply, market)
                end
            end
            local consumedAmount = 0
            for _, market in ipairs(marketsWithSupply) do
                local availableCount = market.get_item_count(consumption.resource)
                local removed = market.remove_item({name = consumption.resource, count = math.min(requiredAmount, availableCount)})
                consumedAmount = consumedAmount + removed
                requiredAmount = requiredAmount - consumedAmount
                if requiredAmount <= 0 then
                    break
                end
            end
            if consumedAmount >= requiredAmount then
                countNeedsMet = countNeedsMet + 1
            end

            if #treasuries > 0 then
                local randomTreasury = treasuries[math.random(#treasuries)]
                local currencyPerUnit = 1
                local reward = math.ceil(currencyPerUnit * consumedAmount)
                if reward > 0 then
                    randomTreasury.insert{name = "tycoon-currency", count = reward}
                end
            end
        end
    end
    if #waterTowers >= 1 then
        for _, consumption in ipairs({city.basicNeeds.waterTower}) do
            local requiredAmount = getRequiredAmount(consumption.amount, city.stats.citizen_count)
            local waterTowersWithSupply = {}
            for _, waterTower in ipairs(waterTowers) do
                local availableCount = waterTower.get_fluid_count(consumption.resource)
                if availableCount > 0 then
                    table.insert(waterTowersWithSupply, waterTower)
                end
            end
            local consumedAmount = 0
            for _, waterTower in ipairs(waterTowersWithSupply) do
                local availableCount = waterTower.get_fluid_count(consumption.resource)
                local removed = waterTower.remove_fluid({name = consumption.resource, amount = math.min(requiredAmount, availableCount)})
                consumedAmount = consumedAmount + removed
                requiredAmount = requiredAmount - consumedAmount
                if requiredAmount <= 0 then
                    break
                end
            end
            if consumedAmount >= requiredAmount then
                countNeedsMet = countNeedsMet + 1
            end

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

local CITY_SUPPLY_BUILDINGS = {"tycoon-market", "tycoon-hardware-store"}

script.on_event(defines.events.on_built_entity, function(event)
    local entity = event.created_entity

    local isCitySupplyBuilding = false
    for _, supplyBuildingName in ipairs(CITY_SUPPLY_BUILDINGS) do
        if entity.name == supplyBuildingName then
            isCitySupplyBuilding = true
            break
        end
    end
    if not isCitySupplyBuilding then
        return
    end
    
    local nearbyTownHall = game.surfaces[1].find_entities_filtered{position=entity.position, radius=1000, name="tycoon-town-hall", limit=1}
    if #nearbyTownHall == 0 then
        game.players[1].print("You just built a city supply building outside of any town hall's range. Please build it within 1000 tiles of a city.")
        return
    end

    local cityMapping = global.tycoon_city_buildings[nearbyTownHall[1].unit_number]
    assert(cityMapping ~= nil, "When building an entity we found a town hall, but it has no city mapping.")
    local cityId = cityMapping.cityId
    local city = findCityById(cityId)
    assert(city ~= nil, "When building an entity we found a cityId, but there is no city for it.")

    invalidateSpecialBuildingsList(city, entity.name)
end)

-- todo: also add robots and other workers
script.on_event(defines.events.on_player_mined_entity, function(event)
    local entity = event.entity

    local isCitySupplyBuilding = false
    for _, supplyBuildingName in ipairs(CITY_SUPPLY_BUILDINGS) do
        if entity.name == supplyBuildingName then
            isCitySupplyBuilding = true
            break
        end
    end
    if not isCitySupplyBuilding then
        return
    end
    
    local nearbyTownHall = game.surfaces[1].find_entities_filtered{position=entity.position, radius=1000, name="tycoon-town-hall", limit=1}
    if #nearbyTownHall == 0 then
        -- If there's no town hall in range then it probably was destroyed
        -- todo: how should we handle that situation? Is the whole city gone?
        -- probably in the "destroyed" event, because the player can't mine the town hall
        return
    end

    local cityMapping = global.tycoon_city_buildings[nearbyTownHall[1].unit_number]
    assert(cityMapping ~= nil, "When mining an entity an entity we found a town hall, but it has no city mapping.")
    local cityId = cityMapping.cityId
    local city = findCityById(cityId)
    assert(city ~= nil, "When mining an entity we found a cityId, but there is no city for it.")

    invalidateSpecialBuildingsList(city, entity.name)
end)

-- This event does not trigger when the player (or another entity mines a building)
-- todo: does it trigger when the game destroys an entity via scripts?
script.on_event(defines.events.on_entity_destroyed, function(event)
    local unit_number = event.unit_number
    if unit_number ~= nil then
        -- todo: make sure that new buildings are listed here
        local building = global.tycoon_city_buildings[unit_number]
        if building ~= nil then
            if string.find(building.entity_name, "tycoon-house-residential-", 1, true) then
                local cityId = building.cityId
                local city = findCityById(cityId)
                if city ~= nil then
                    city.stats.citizen_count = city.stats.citizen_count - 4
                end
            elseif string.find(building.entity_name, "tycoon-house-highrise-", 1, true) then
                local cityId = building.cityId
                local city = findCityById(cityId)
                if city ~= nil then
                    city.stats.citizen_count = city.stats.citizen_count - 40
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

local function areBasicNeedsMet(city)
    updateNeeds(city)
    updateProvidedAmounts(city)

    for _, consumption in ipairs(city.basicNeeds.market) do
        if city.stats.basic_needs[consumption.resource] == nil then
            return false
        end
        if city.stats.basic_needs[consumption.resource].provided == nil or city.stats.basic_needs[consumption.resource].required == nil then
            return false
        end
        if city.stats.basic_needs[consumption.resource].provided < city.stats.basic_needs[consumption.resource].required then
            return false
        end
    end

    for _, consumption in ipairs({city.basicNeeds.waterTower}) do
        if city.stats.basic_needs[consumption.resource] == nil then
            return false
        end
        if city.stats.basic_needs[consumption.resource].provided == nil or city.stats.basic_needs[consumption.resource].required == nil then
            return false
        end
        if city.stats.basic_needs[consumption.resource].provided < city.stats.basic_needs[consumption.resource].required then
            return false
        end
    end

    return true
end

 -- todo: show excavation site count / show construction material supply
script.on_event(defines.events.on_gui_opened, function (gui)
    if gui.entity ~= nil and gui.entity.name == "tycoon-town-hall" then
        local player = game.players[gui.player_index]
        local unit_number = gui.entity.unit_number
        local city = findCityByTownHallUnitNumber(unit_number)
        assert(city ~= nil, "Could not find the city for town hall unit number ".. unit_number)

        updateNeeds(city)

        local cityGui = player.gui.relative["city_overview_" .. unit_number]
        if cityGui == nil then
            local anchor = {gui = defines.relative_gui_type.container_gui, name = "tycoon-town-hall", position = defines.relative_gui_position.right}
            cityGui = player.gui.relative.add{type = "frame", anchor = anchor, caption = {"", {"tycoon-gui-city-overview"}}, direction = "vertical", name = "city_overview_" .. unit_number}
            cityGui.add{type = "label", caption = {"", {"tycoon-gui-update-info"}}}

            local stats = cityGui.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-stats"}}, name = "city_stats"}
            stats.add{type = "label", caption = {"", {"tycoon-gui-citizens"}, ": ",  city.stats.citizen_count}, name = "citizen_count"}
            stats.add{type = "label", caption = {"", {"tycoon-gui-construction-sites"}, ": ",  #(city.excavationPits or {}), "/", #city.grid}, name = "construction_sites_count"}

            local basicNeeds = cityGui.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-basic-needs"}}, name = "basic_needs"}
            basicNeeds.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle-1"}}}
            basicNeeds.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle-2"}}}
            basicNeeds.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle-3"}}}
        end

        cityGui.city_stats.citizen_count.caption = {"", {"tycoon-gui-citizens"}, ": ",  city.stats.citizen_count}
        cityGui.city_stats.construction_sites_count.caption = {"", {"tycoon-gui-construction-sites"}, ": ",  #(city.excavationPits or {}), "/", #city.grid}

        if cityGui.city_stats.basic_needs_met ~= nil then
            -- Remove surplus UI from 0.0.14 and before
            cityGui.city_stats.basic_needs_met.destroy()
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
        if city.special_buildings.town_hall ~= nil and city.special_buildings.town_hall.valid then
            cityBasicConsumption(city)
        end
    end
end)

local CITY_GROWTH_TICKS = 60

local function canBuildSimpleHouse(city)
    local simpleCount = ((city.buildingCounts or {})["simple"] or 0)
    -- Todo: come up with a good function that slows down growth if there are too many
        -- low tier houses.
    local excavationPitCount = #(city.excavationPits or {})
    return simpleCount < (#city.grid * 10)
        and excavationPitCount <= #city.grid
end

local function canUpgradeToResidential(city)
    local simpleCount = ((city.buildingCounts or {})["simple"] or 0)
    if simpleCount < 20 then
        return false
    end

    local residentialCount = ((city.buildingCounts or {})["residential"] or 0)
    local gridSize = #city.grid
    local inner10Percent = math.ceil(gridSize * 0.1)
    local inner10PercentCells = inner10Percent * inner10Percent
    return residentialCount < inner10PercentCells
end

local function canUpgradeToHighrise(city)
    local residentialCount = ((city.buildingCounts or {})["residential"] or 0)
    if residentialCount < 20 then
        return false
    end

    -- highrise should not cover more than 50% of the houses
    -- ideally only an inner circle
    local highriseCount = ((city.buildingCounts or {})["highrise"] or 0)
    local gridSize = #city.grid
    local inner10Percent = math.ceil(gridSize * 0.1)
    local inner10PercentCells = inner10Percent * inner10Percent
    return highriseCount < inner10PercentCells
end

local citizenCounts = {
    simple = 4,
    residential = 20,
    highrise = 100,
}

local function newCityGrowth(city)
    assert(city.grid ~= nil and #city.grid > 1, "Expected grid to be initialized and larger than 1x1.")

    -- Attempt to complete constructions first
    local completedConsructionBuildingType = CITY.completeConstruction(city)
    if completedConsructionBuildingType ~= nil then
        if completedConsructionBuildingType == "simple" then
            growCitizenCount(city, citizenCounts["simple"])
        elseif completedConsructionBuildingType == "residential" then
            growCitizenCount(city, citizenCounts["residential"])
        elseif completedConsructionBuildingType == "highrise" then
            growCitizenCount(city, citizenCounts["highrise"])
        end

        return
    end

    -- Check if resources are available. Without resources no growth is possible.
    local hardwareStores = listSpecialCityBuildings(city, "tycoon-hardware-store")
    if #hardwareStores == 0 then
        -- If there are no hardware stores, then no construction resources are available.
        return
    end

    -- This array is ordered from most expensive to cheapest, so that
    -- we do expensive upgrades first (instead of just letting the road always expand).
    -- Sepcial buildings (like the treasury) are an exception that should ideally come first.
    local constructionResources = {
        specialBuildings = {{
            name = "stone",
            required = 1,
        }, {
            name = "iron-plate",
            required = 1,
        }},
        highrise = {{
            name = "stone",
            required = 100,
        }, {
            name = "iron-plate",
            required = 50,
        }, {
            name = "steel-plate",
            required = 25,
        }},
        residential = {{
            name = "stone",
            required = 10,
        }, {
            name = "iron-plate",
            required = 10,
        }},
        simple = {{
            name = "stone",
            required = 1,
        }, {
            name = "iron-plate",
            required = 1,
        }},
        -- road = {{
        --     name = "stone",
        --     required = 1,
        -- }},
    }

    local buildables = {}
    for key, resources in pairs(constructionResources) do
        local anyResourceMissing = false
        for _, resource in ipairs(resources) do
            for _, hardwareStore in ipairs(hardwareStores) do
                local availableCount = hardwareStore.get_item_count(resource.name)
                resource.available = (resource.available or 0) + availableCount
            end

            if resource.available < resource.required then
                anyResourceMissing = true
            end
        end

        if not anyResourceMissing then
            table.insert(buildables, {
                key = key,
                resources = resources,
            })
        end
    end

    -- DONE: check if the buildable array matches expectations
    -- game.print("debug")

    for _, buildable in ipairs(buildables) do
        local isBuilt
        if buildable.key == "specialBuildings" and #(city.priority_buildings or {}) > 0 then
            local prioBuilding = table.remove(city.priority_buildings, 1)
            isBuilt = CITY.startConstruction(city, {
                buildingType = prioBuilding.name,
                -- Special buildings should be completed very quickly.
                -- Here we just wait 2 seconds by default.
                constructionTimeInTicks = 120,
            })
            if not isBuilt then
                table.insert(city.priority_buildings, 1, prioBuilding)
            end
        elseif buildable.key == "highrise" and canUpgradeToHighrise(city) then
            isBuilt = CITY.upgradeHouse(city, "highrise")
            if isBuilt then
                growCitizenCount(city, -1 * citizenCounts["residential"])
            end
        elseif buildable.key == "residential" and canUpgradeToResidential(city) then
            isBuilt = CITY.upgradeHouse(city, "residential")
            if isBuilt then
                growCitizenCount(city, -1 * citizenCounts["simple"])
            end
        elseif buildable.key == "simple" and canBuildSimpleHouse(city) then
            isBuilt = CITY.startConstruction(city, {
                buildingType = "simple",
                constructionTimeInTicks = math.random(600, 1200)
            })
        end
        -- Keep the road construction outside the above if block,
        -- so that the roads can expand if no building has been constructed
        -- todo: count excavation pits so that we don't have too many before further expanding roads
        -- We can't add this to the buildables check, or the iteration will never get there
        if not isBuilt then
            -- The city should not grow its road network too much if there are (valid) possibleBuildingLocations
            -- todo: how do we separate out invalid ones?
            local excavationPitCount = #(city.excavationPits or {})
            local possibleBuildingLocationsCount = Queue.count(city.buildingLocationQueue)
            if math.random() < (#city.grid / possibleBuildingLocationsCount) and excavationPitCount < #city.grid then
                -- todo: add check that road resources are available
                local coordinates = CITY.growAtRandomRoadEnd(city)
                if coordinates ~= nil then
                    CITY.updatepossibleBuildingLocations(city, coordinates)
                    isBuilt = true
                end
            end
        else
            consumeItems(buildable.resources, hardwareStores, city, true)
            break
        end
    end
end

local function spawnPrimaryIndustries()
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
end

script.on_nth_tick(CITY_GROWTH_TICKS, function(event)
    
    -- global.tycoon_enable_debug_logging = true
    if event.tick < 200 then
        return
    end
    for _, city in ipairs(global.tycoon_cities) do
        if city.special_buildings.town_hall ~= nil and city.special_buildings.town_hall.valid then
            if false or areBasicNeedsMet(city) then
                newCityGrowth(city)
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
    end

    spawnPrimaryIndustries()
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
            other = {}
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
        center = {
            x = 8,
            y = -3,
        },
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

    global.tycoon_dev_no_city_special_buildings = true

    -- global.tycoon_cities = {}
    -- for i = 1, 8, 1 do
    --     game.surfaces[1].create_entity{
    --         name = "tycoon-house-highrise-" .. i,
    --         position = {x = -30 + i * 8, y = 20},
    --         force = "player"
    --     }
    -- end

--    TYCOON_STORY[1]()

    
        -- /c game. player. insert{ name="stone", count=1000 }
        -- /c game. player. insert{ name="tycoon-water-tower", count=1 }
        -- /c game. player. insert{ name="tycoon-cow", count=100 }
end)