local Queue = require "queue"
SEGMENTS = require("segments")
CITY = require("city")
CONSUMPTION = require("consumption")
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
                        force = "neutral",
                        move_stuck_players = true
                    }
                    townHall.destructible = false
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

    table.insert(city.priority_buildings, {name = "tycoon-treasury", priority = 10})
end

local function growCitizenCount(city, count, tier)
    if city.citizens[tier] == nil then
        city.citizens[tier] = 0
    end
    city.citizens[tier] = city.citizens[tier] + count
    CONSUMPTION.updateNeeds(city)
end

local function invalidateSpecialBuildingsList(city, name)
    assert(city.special_buildings ~= nil, "The special buildings should never be nil. There has been one error though, so I added this assetion.")

    if city.special_buildings.other[name] ~= nil then
        city.special_buildings.other[name] = nil
    end 
end

local function listSpecialCityBuildings(city, name)
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

local function getItemForPrimaryProduction(name)
    if name == "tycoon-apple-farm" then
        return "tycoon-apple"
    elseif name == "tycoon-wheat-farm" then
        return "tycoon-wheat"
    elseif name == "tycoon-fishery" then
        return "raw-fish"
    else
        return "Unknown"
    end
end

local function localizePrimaryProductionName(name)
    if name == "tycoon-apple-farm" then
        return "Apple Farm"
    elseif name == "tycoon-wheat-farm" then
        return "Wheat Farm"
    elseif name == "tycoon-fishery" then
        return "Fishery"
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
                force = "neutral",
                move_stuck_players = true
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

local CITY_SUPPLY_BUILDINGS = {"tycoon-market", "tycoon-hardware-store", "tycoon-water-tower"}

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
script.on_event({defines.events.on_player_mined_entity}, function(event)
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

local citizenCounts = {
    simple = 4,
    residential = 20,
    highrise = 100,
}

-- This event does not trigger when the player (or another entity mines a building)
-- todo: does it trigger when the game destroys an entity via scripts?
script.on_event(defines.events.on_entity_destroyed, function(event)
    local unit_number = event.unit_number
    if unit_number ~= nil then
        -- todo: make sure that new buildings are listed here
        local building = global.tycoon_city_buildings[unit_number]
        if building ~= nil then
            if string.find(building.entity_name, "tycoon-house-simple-", 1, true) then
                local cityId = building.cityId
                local city = findCityById(cityId)
                if city ~= nil then
                    growCitizenCount(city, -1 * citizenCounts["simple"], "simple")
                end
            elseif string.find(building.entity_name, "tycoon-house-residential-", 1, true) then
                local cityId = building.cityId
                local city = findCityById(cityId)
                if city ~= nil then
                    growCitizenCount(city, -1 * citizenCounts["residential"], "residential")
                end
            elseif string.find(building.entity_name, "tycoon-house-highrise-", 1, true) then
                local cityId = building.cityId
                local city = findCityById(cityId)
                if city ~= nil then
                    growCitizenCount(city, -1 * citizenCounts["highrise"], "highrise")
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
        local position
        if industryName == "tycoon-fishery" then
            -- To make it look prettier, we place fisheries near water
            local waterTiles = game.surfaces[1].find_tiles_filtered{
                area = chunk.area,
                name = {"water", "deepwater"},
                limit = 20
            }
            local hasWater = #waterTiles >= 20
            if not hasWater then
                return
            end
            local nonWaterTiles = game.surfaces[1].find_tiles_filtered{
                area = chunk.area,
                name = {"water", "deepwater"},
                invert = true,
                limit = 1
            }
            local hasLand = #nonWaterTiles > 0
            if not hasLand then
                return
            end

            position = game.surfaces[1].find_non_colliding_position(industryName, {x = chunk.position.x * 32, y = chunk.position.y * 32}, 64, 1, true)
        else
            position = game.surfaces[1].find_non_colliding_position_in_box(industryName, chunk.area, 2, true)
        end
        if position ~= nil then
            local minDistance = 500
            if industryName == "tycoon-fishery" then
                -- map_gen_settings.water is a percentage value. As the amount of water on the map decreases, we want to spawn more fisheries per given area.
                -- Don't go below 50 though
                minDistance = math.max(200 * game.surfaces[1].map_gen_settings.water, 50)
            end
            local nearbySameProduction = game.surfaces[1].find_entities_filtered{position=position, radius=minDistance, name=industryName, limit=1}
            if #nearbySameProduction == 0 then
                placePrimaryIndustryAtPosition(position, industryName)
            end
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

--- @param city City
local function countCitizens(city)
    local total = 0
    for _, count in pairs(city.citizens) do
        total = total + count
    end
    return total
end


local function getNeeds(city, tier)
    if tier == "simple" then
        return {
            water = city.stats.basic_needs.water,
            ["tycoon-apple"] = city.stats.basic_needs["tycoon-apple"],
        }
    elseif tier == "residential" then
        return {
            water = city.stats.basic_needs.water,
            ["tycoon-apple"] = city.stats.basic_needs["tycoon-apple"],
            ["tycoon-meat"] = city.stats.basic_needs["tycoon-meat"],
            ["tycoon-bread"] = city.stats.basic_needs["tycoon-bread"],
        }
    elseif tier == "highrise" then
        return {
            water = city.stats.basic_needs.water,
            ["tycoon-apple"] = city.stats.basic_needs["tycoon-apple"],
            ["tycoon-meat"] = city.stats.basic_needs["tycoon-meat"],
            ["tycoon-bread"] = city.stats.basic_needs["tycoon-bread"],
            ["tycoon-fish-filet"] = city.stats.basic_needs["tycoon-fish-filet"],
            ["tycoon-milk-bottle"] = city.stats.basic_needs["tycoon-milk-bottle"],
        }
    else
        assert(false, "Unknown tier for getNeeds: " .. tier)
    end
end

local function getBuildables(city, stores)
    -- Check if resources are available. Without resources no growth is possible.
    local hardwareStores = stores or listSpecialCityBuildings(city, "tycoon-hardware-store")
    if #hardwareStores == 0 then
        -- If there are no hardware stores, then no construction resources are available.
        return {}
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
            required = 20,
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
            buildables[key] = resources
        end
    end

    return buildables
end

 -- todo: show construction material supply
script.on_event(defines.events.on_gui_opened, function (gui)
    if gui.entity ~= nil and gui.entity.name == "tycoon-town-hall" then
        local player = game.players[gui.player_index]
        local unit_number = gui.entity.unit_number
        local city = findCityByTownHallUnitNumber(unit_number)
        assert(city ~= nil, "Could not find the city for town hall unit number ".. unit_number)

        CONSUMPTION.updateNeeds(city)

        -- todo: we don't need to do this init when we move to the city manager, because the view is created/destroyed every time
        local cityGui = player.gui.relative["city_overview_" .. unit_number]
        if cityGui == nil then
            local anchor = {gui = defines.relative_gui_type.container_gui, name = "tycoon-town-hall", position = defines.relative_gui_position.right}
            cityGui = player.gui.relative.add{type = "frame", anchor = anchor, caption = {"", {"tycoon-gui-city-overview"}}, direction = "vertical", name = "city_overview_" .. unit_number}
            cityGui.add{type = "label", caption = {"", {"tycoon-gui-update-info"}}}

            local stats = cityGui.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-stats"}}, name = "city_stats"}
            stats.add{type = "label", caption = {"", {"tycoon-gui-citizens"}, ": ",  0}, name = "citizen_count"}

            local basicNeeds = cityGui.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-basic-needs"}}, name = "basic_needs"}
            basicNeeds.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle-1"}}}
            basicNeeds.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle-2"}}}
            basicNeeds.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle-3"}}}
        end

        cityGui.city_stats.citizen_count.caption = {"", {"tycoon-gui-citizens"}, ": ",  countCitizens(city)}

        local unlockedBasicNeeds = {}
        for key, values in pairs(CONSUMPTION.basicNeedIncrements) do
            if key == "default" or (game.players[1].force.technologies[ "tycoon-" .. key .. "-housing"] or {}).researched == true then
                for _, v in ipairs(values) do
                    table.insert(unlockedBasicNeeds, v)
                end
            end
        end

        local basicNeedsGui = cityGui.basic_needs
        for _, resource in ipairs(unlockedBasicNeeds) do
            local amounts = city.stats.basic_needs[resource]

            local itemName = resource
            if string.find(resource, "tycoon-", 1, true) then
                itemName = "item-name." .. itemName
            elseif resource == "water" then
                -- Vanilla items like water are not in our localization config, and therefore have to be accessed differently
                itemName = "fluid-name." .. resource
            end

            local color = "green"
            if amounts.provided < amounts.required or (amounts.provided == 0 and amounts.required == 0) then
                color = "red"
            end

            local gui = basicNeedsGui[resource]
            if gui == nil then
                gui = basicNeedsGui.add{type = "flow", direction = "vertical", caption = {"", {itemName}}, name = resource}
                gui.add{type = "label", name = "supply", caption = {"", {itemName}, ": ", "[color=" .. color .. "]", amounts.provided, "/", amounts.required, "[/color]"}}
            else
                gui.supply.caption = {"", {itemName}, ": ", "[color=" .. color .. "]", amounts.provided, "/", amounts.required, "[/color]"}
            end
        end

        if cityGui.upgrades ~= nil then
            cityGui.upgrades.destroy()
        end

        local upgradesGui = cityGui.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-upgrades"}}, name = "upgrades"}
        local upgradesGuiTable = upgradesGui.add{type = "table", column_count = 3}
        local constructionSiteColoring = "green"
        if #(city.excavationPits or {}) >= #city.grid then
            constructionSiteColoring = "red"
        end
        upgradesGuiTable.add{type = "label", caption = {"", {"tycoon-gui-construction-sites"}}}
        upgradesGuiTable.add{type = "label", caption = {"", "[color=" .. constructionSiteColoring .. "]",  #(city.excavationPits or {}), "/", #city.grid, "[/color]"}}
        upgradesGuiTable.add{type = "label", caption = ""}

        local housingTiers = {"residential", "highrise"}
        local buildables = getBuildables(city)
        for _, tier in ipairs(housingTiers) do
            if (game.players[1].force.technologies["tycoon-" .. tier .. "-housing"] or {}).researched == true then
                local text, coloring
                if not CONSUMPTION.areBasicNeedsMet(city, getNeeds(city, tier)) then
                    text = {"tycoon-gui-growth-no-basic-needs"}
                    coloring = "red"
                elseif buildables[tier] == nil then
                    text = {"tycoon-gui-growth-no-construction-material"}
                    coloring = "red"
                else
                    coloring = "green"
                    text = {"tycoon-gui-growing"}
                end

                upgradesGuiTable.add{type = "label", caption = {"", {"technology-name.tycoon-" .. tier .. "-housing"}, ": "}}
                upgradesGuiTable.add{type = "label", caption = {"", "[color=" .. coloring .. "]", text, "[/color]"}}
                upgradesGuiTable.add{type = "label", caption = ""}
            else
                upgradesGuiTable.add{type = "label", caption = {"", {"technology-name.tycoon-" .. tier .. "-housing"}, ": "}}
                upgradesGuiTable.add{type = "label", caption = {"", "[color=red]", {"tycoon-gui-not-researched"}, "[/color]"}}
                upgradesGuiTable.add{type = "button", caption = "Open Technology", name = "tycoon_open_tech:" .. tier .. "-housing"}
            end
        end
    end
end)


script.on_event(defines.events.on_gui_click, function(event)
    local player = game.players[event.player_index]
    local element = event.element

    if string.find(element.name, "tycoon_open_tech:", 1, true) then
        local delimiter = ":"
        local parts = {} -- To store the split parts
        for substring in element.name:gmatch("[^" .. delimiter .. "]+") do
            table.insert(parts, substring)
        end
        player.open_technology_gui("tycoon-" .. parts[2])
    end
end)

script.on_nth_tick(600, function()
    for _, city in ipairs(global.tycoon_cities) do
        if city.special_buildings.town_hall ~= nil and city.special_buildings.town_hall.valid then
            CONSUMPTION.consumeBasicNeeds(city)
        end
    end
end)

local CITY_GROWTH_TICKS = 300

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
    if simpleCount < residentialCount * 5 then
        -- There should be 5 simple buildings for every residential building
        return false
    end

    local needsMet = CONSUMPTION.areBasicNeedsMet(city, getNeeds(city, "residential"))
    if not needsMet then
        return false
    end

    local gridSize = #city.grid
    local residentialPercentage = math.ceil(gridSize * 0.1)
    local residentialPercentageCount = residentialPercentage * residentialPercentage
    return residentialCount < residentialPercentageCount
end

local function canUpgradeToHighrise(city)
    local residentialCount = ((city.buildingCounts or {})["residential"] or 0)
    if residentialCount < 20 then
        return false
    end

    -- highrise should not cover more than 50% of the houses
    -- ideally only an inner circle
    local highriseCount = ((city.buildingCounts or {})["highrise"] or 0)
    if residentialCount < highriseCount * 5 then
        -- There should be 5 residential buildings for every highrise building
        return false
    end

    local needsMet = CONSUMPTION.areBasicNeedsMet(city, getNeeds(city, "highrise"))
    if not needsMet then
        return false
    end

    local gridSize = #city.grid
    local highRisePercentage = math.ceil(gridSize * 0.01)
    local highRisePercentageCount = highRisePercentage * highRisePercentage
    return highriseCount < highRisePercentageCount
end

local function newCityGrowth(city)
    assert(city.grid ~= nil and #city.grid > 1, "Expected grid to be initialized and larger than 1x1.")

    -- Attempt to complete constructions first
    local completedConstructionBuildingType = CITY.completeConstruction(city)
    if completedConstructionBuildingType ~= nil then
        if completedConstructionBuildingType == "simple" then
            growCitizenCount(city, citizenCounts["simple"], "simple")
        elseif completedConstructionBuildingType == "residential" then
            growCitizenCount(city, citizenCounts["residential"], "residential")
        elseif completedConstructionBuildingType == "highrise" then
            growCitizenCount(city, citizenCounts["highrise"], "highrise")
        end

        return
    end

    -- Check if resources are available. Without resources no growth is possible.
    local hardwareStores = listSpecialCityBuildings(city, "tycoon-hardware-store")
    if #hardwareStores == 0 then
        -- If there are no hardware stores, then no construction resources are available.
        return {}
    end

    local buildables = getBuildables(city, hardwareStores)

    for key, resources in pairs(buildables) do
        local isBuilt
        if key == "specialBuildings" and #(city.priority_buildings or {}) > 0 then
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
        elseif key == "highrise" and canUpgradeToHighrise(city) then
            isBuilt = CITY.upgradeHouse(city, "highrise")
            if isBuilt then
                growCitizenCount(city, -1 * citizenCounts["residential"], "residential")
            end
        elseif key == "residential" and canUpgradeToResidential(city) then
            isBuilt = CITY.upgradeHouse(city, "residential")
            if isBuilt then
                growCitizenCount(city, -1 * citizenCounts["simple"], "simple")
            end
        elseif key == "simple" and canBuildSimpleHouse(city) then
            isBuilt = CITY.startConstruction(city, {
                buildingType = "simple",
                constructionTimeInTicks = math.random(600, 1200)
            })
        end
        -- Keep the road construction outside the above if block,
        -- so that the roads can expand if no building has been constructed
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
            for _, item in ipairs(resources) do
                CONSUMPTION.consumeItem(item, hardwareStores, city, true)
            end
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
            if false or CONSUMPTION.areBasicNeedsMet(city) then
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
        center = {
            x = 8,
            y = -3,
        },
        hasTag = false,
        name = "Your First City",
        stats = {
            basic_needs = {}
        },
        citizens = {
            simple = 0,
            residential = 0,
            highrise = 0,
        },
        constructionProbability = 1.0,
    }}
    initializeCity(global.tycoon_cities[1])
    CONSUMPTION.updateNeeds(global.tycoon_cities[1])

    global.tycoon_primary_industries = {"tycoon-apple-farm", "tycoon-wheat-farm", "tycoon-fishery"}

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