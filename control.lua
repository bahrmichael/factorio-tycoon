local Queue = require "queue"
local City = require("city")
local Consumption = require("consumption")
local Constants = require("constants")
local Gui = require("gui")
local GridUtil = require("grid-util")
local CityPlanning = require("city-planner")
local Passengers = require("passengers")
local Util = require("util")

local primary_industry_names = {"tycoon-apple-farm", "tycoon-wheat-farm", "tycoon-fishery"}

local function growCitizenCount(city, count, tier)
    if city.citizens[tier] == nil then
        city.citizens[tier] = 0
    end
    city.citizens[tier] = city.citizens[tier] + count
    Consumption.updateNeeds(city)
end

local function invalidateSpecialBuildingsList(city, name)
    assert(city.special_buildings ~= nil, "The special buildings should never be nil. There has been one error though, so I added this assertion.")

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

--- @param prefix string
--- @return number level
local function findHighestProductivityLevel(prefix)
    for i = 1, 20, 1 do
        if (game.forces.player.technologies[prefix .. "-" .. i] or {}).researched == true then
            -- noop, attempt the next level
        else
            return i - 1
        end
    end
    return 0
end

local function placePrimaryIndustryAtPosition(position, entityName)
    if position ~= nil then
        -- This is mainly here to avoid two industries being right next to each other, blocking each others pipes
        local nearbyPrimaryIndustries = game.surfaces[1].find_entities_filtered{
            position = position,
            radius = 20,
            name = primary_industry_names,
            limit = 1
        }
        if #nearbyPrimaryIndustries > 0 then
            return nil
        end
        -- fisheries don't have a pipe input and therfore don't need this condition
        -- they are also placed near water, so this would lead to no fisheries being placed anywhere
        if entityName ~= "tycoon-fishery" then
            local nearbyCliffOrWater = game.surfaces[1].find_tiles_filtered{
                position = position,
                radius = 10,
                name = {"cliff", "water", "deepwater"},
                limit = 1
            }
            if #nearbyCliffOrWater > 0 then
                return nil
            end
        end
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
            local entity = game.surfaces[1].create_entity{
                name = entityName,
                position = {x = position.x, y = position.y},
                force = "neutral",
                move_stuck_players = true
            }
            if entity ~= nil then
                -- or any other primary industry that has productivity research
                if entity.name == "tycoon-apple-farm" then
                    local level = findHighestProductivityLevel("tycoon-apple-farm-productivity")
                    local recipe = "tycoon-grow-apples-with-water-" .. level + 1
                    entity.set_recipe(recipe)
                end
                entity.recipe_locked = true
                return entity
            else
                game.print("Factorio Error: The mod has encountered an issue when placing primary industries. Please report this to the developer. You can continue playing.")
            end
        end
    end
    return nil
end

local function randomPrimaryIndustry()
    return primary_industry_names[global.tycoon_global_generator(#primary_industry_names)]
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

local function isSupplyBuilding(entityName)
    for _, supplyBuildingName in ipairs(CITY_SUPPLY_BUILDINGS) do
        if entityName == supplyBuildingName then
            return true
        end
    end
    return false
end

script.on_event(defines.events.on_built_entity, function(event)
    local entity = event.created_entity

    if isSupplyBuilding(entity.name) or entity.name == "tycoon-passenger-train-station" then
        local nearbyTownHall = game.surfaces[1].find_entities_filtered{position=entity.position, radius=Constants.CITY_RADIUS, name="tycoon-town-hall", limit=1}
        if #nearbyTownHall == 0 then
            game.players[event.player_index].print({"", {"tycoon-supply-building-not-connected"}})
            return
        end

        local cityMapping = global.tycoon_city_buildings[nearbyTownHall[1].unit_number]
        assert(cityMapping ~= nil, "When building an entity we found a town hall, but it has no city mapping.")
        local cityId = cityMapping.cityId
        local city = findCityById(cityId)
        assert(city ~= nil, "When building an entity we found a cityId, but there is no city for it.")

        invalidateSpecialBuildingsList(city, entity.name)

        if global.tycoon_entity_meta_info == nil then
            global.tycoon_entity_meta_info = {}
        end
        global.tycoon_entity_meta_info[entity.unit_number] = {
            cityId = cityId
        }
    end
    
end)

--- @param entityName string
--- @return boolean
local function isHouse(entityName)
    return string.find(entityName, "tycoon-house-", 1, true) ~= nil
end

local citizenCounts = {
    simple = 4,
    residential = 20,
    highrise = 100,
}

script.on_event({
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    -- Register entities with script.register_on_entity_destroyed(entity) so that this event fires.
    defines.events.on_entity_destroyed,
}, function(event)
    if global.tycoon_city_buildings == nil then
        return
    end
    
    local unit_number = event.unit_number
    local building = global.tycoon_city_buildings[unit_number]

    if building == nil or building.entity == nil then
        return
    end

    if isSupplyBuilding(building.entity_name) or building.entity_name == "tycoon-passenger-train-station" then
        
        local nearbyTownHall = game.surfaces[1].find_entities_filtered{position=building.entity.position, radius=Constants.CITY_RADIUS, name="tycoon-town-hall", limit=1}
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

        invalidateSpecialBuildingsList(city, building.entity_name)
    elseif isHouse(building.entity_name) and unit_number ~= nil then
        -- todo: make sure that new buildings are listed here
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

        if global.tycoon_house_lights ~= nil then
            local light = global.tycoon_house_lights[unit_number]
            if light ~= nil and light.valid then
                light.destroy()
            end
        end
    end

    -- todo: mark cell as unused again, clear paving if necessary
end)

local function addToGlobalPrimaryIndustries(entity)
    if entity == nil then
        return
    end
    if global.tycoon_primary_industries == nil then
        global.tycoon_primary_industries = {}
    end
    if global.tycoon_primary_industries[entity.name] == nil then
        global.tycoon_primary_industries[entity.name] = {}
    end
    table.insert(global.tycoon_primary_industries[entity.name], entity)
end

script.on_event(defines.events.on_chunk_charted, function (chunk)
    if math.abs(chunk.position.x) < 5 and math.abs(chunk.position.y) < 5 then
        return
    end
    if global.tycoon_global_generator() < 0.25 then
        local industryName = randomPrimaryIndustry()
        local position
        if industryName == "tycoon-fishery" then
            -- To make it look prettier, we place fisheries near water
            local tiles = game.surfaces[1].find_tiles_filtered{
                area = chunk.area,
            }
            local countWater = 0
            local aWaterTile
            for _, t in ipairs(tiles) do
                if t.name == "water" or t.name == "deepwater" then
                    countWater = countWater + 1
                    if aWaterTile == nil then
                        aWaterTile = t
                    end
                end
            end
            local hasEnoughWater = (countWater / #tiles) > 0.25
            if not hasEnoughWater then
                return
            end

            position = game.surfaces[1].find_non_colliding_position(industryName, aWaterTile.position, 100, 1, true)
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
            local nearbyBlockingEntities = game.surfaces[1].find_entities_filtered{position=position, radius=minDistance, name=industryName, limit=1}
            if #nearbyBlockingEntities == 0 then
                local p = placePrimaryIndustryAtPosition(position, industryName)
                addToGlobalPrimaryIndustries(p)
            end
        end
    end
end)

local function findCityByEntityUnitNumber(unitNumber)
    local metaInfo = (global.tycoon_entity_meta_info or {})[unitNumber]
    if metaInfo == nil then
        return "Unknown"
    end
    local cityId = metaInfo.cityId
    local cityName = ((global.tycoon_cities or {})[cityId] or {}).name
    return cityName or "Unknown"
end

local function findCityByTownHallUnitNumber(townHallUnitNumber)
    for _, city in ipairs(global.tycoon_cities) do
        if city.special_buildings.town_hall ~= nil and city.special_buildings.town_hall.unit_number == townHallUnitNumber then
            return city
        end
    end
    return nil
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
            ["tycoon-milk-bottle"] = city.stats.basic_needs["tycoon-milk-bottle"],
            ["tycoon-meat"] = city.stats.basic_needs["tycoon-meat"],
            ["tycoon-bread"] = city.stats.basic_needs["tycoon-bread"],
            ["tycoon-fish-filet"] = city.stats.basic_needs["tycoon-fish-filet"],
        }
    elseif tier == "highrise" then
        return {
            water = city.stats.basic_needs.water,
            ["tycoon-smoothie"] = city.stats.basic_needs["tycoon-smoothie"],
            ["tycoon-apple-cake"] = city.stats.basic_needs["tycoon-apple-cake"],
            ["tycoon-cheese"] = city.stats.basic_needs["tycoon-cheese"],
            ["tycoon-burger"] = city.stats.basic_needs["tycoon-burger"],
            ["tycoon-dumpling"] = city.stats.basic_needs["tycoon-dumpling"],
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
            name = "stone-brick",
            required = 1,
        }, {
            name = "iron-plate",
            required = 1,
        }},
        highrise = {{
            name = "concrete",
            required = 50,
        }, {
            name = "steel-plate",
            required = 25,
        }, {
            name = "small-lamp",
            required = 5,
        }, {
            name = "pump",
            required = 2,
        }, {
            name = "pipe",
            required = 10,
        }},
        residential = {{
            name = "stone-brick",
            required = 30,
        }, {
            name = "iron-plate",
            required = 20,
        }, {
            name = "steel-plate",
            required = 10,
        }, {
            name = "small-lamp",
            required = 2,
        }},
        simple = {{
            name = "stone-brick",
            required = 10,
        }, {
            name = "iron-plate",
            required = 5,
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

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    local player = game.players[event.player_index]
    if (player or {}).cursor_stack ~= nil then
        if player.cursor_stack.valid_for_read and (player.cursor_stack.name == "tycoon-passenger-train-station" or player.cursor_stack.name == "tycoon-market" or player.cursor_stack.name == "tycoon-hardware-store" or player.cursor_stack.name == "tycoon-water-tower") then

            -- Clear renderings if there are any. Otherwise we may increase the alpha value making it brighter.
            rendering.clear("tycoon")

            for _, city in ipairs(global.tycoon_cities or {}) do

                local r = rendering.draw_circle{
                    color = {0.1, 0.2, 0.1, 0.01},
                    -- todo: add tech that increases this range, but only up to 250 which is the max for building cities all over the map
                    radius = Constants.CITY_RADIUS,
                    filled = true,
                    target = city.special_buildings.town_hall,
                    surface = game.surfaces[1],
                    draw_on_ground = true,
                }

                if global.tycoon_player_renderings == nil then
                    global.tycoon_player_renderings = {}
                end
                if global.tycoon_player_renderings[event.player_index] == nil then
                    global.tycoon_player_renderings[event.player_index] = {}
                end
                table.insert(global.tycoon_player_renderings, r)
            end
        else
            rendering.clear("tycoon")
        end
    end
end)

script.on_event(defines.events.on_research_finished, function(event)
    if global.tycoon_primary_industries == nil then
        return
    end

    local research = event.research
    local name = research.name

    if string.find(name, "tycoon-apple-farm-productivity", 1, true) then
        local new_recipe = research.effects[1].recipe
        for i, farm in ipairs(global.tycoon_primary_industries["tycoon-apple-farm"] or {}) do
            if farm.valid then
                farm.set_recipe(new_recipe)
                farm.recipe_locked = true
            else
                table.remove(global.tycoon_primary_industries["tycoon-apple-farm"], i)
            end
        end
        game.forces.player.recipes["tycoon-grow-apples-with-water-" .. research.level].enabled = false
    end
end)

script.on_event({defines.events.on_lua_shortcut, "tycoon-cities-overview"}, function(event)
    -- First is the clickable shortcut, second is the hotkey
    if event.prototype_name == "tycoon-cities-overview" or event.input_name == "tycoon-cities-overview" then
        local player = game.players[event.player_index]

        local guiKey = "multiple_cities_overview"
        local gui = player.gui.center[guiKey]
        if gui ~= nil then
            -- If there already was a gui, then we need to close it
            gui.destroy()
        else
            local frame = player.gui.center.add{
                type = "frame",
                name = guiKey,
                direction = "vertical"
            }

            Gui.addMultipleCitiesOverview(frame)
        end
    end
end)

 -- todo: show construction material supply
script.on_event(defines.events.on_gui_opened, function (gui)
    if gui.entity ~= nil and gui.entity.name == "tycoon-town-hall" then
        local player = game.players[gui.player_index]
        local unit_number = gui.entity.unit_number
        local city = findCityByTownHallUnitNumber(unit_number)
        assert(city ~= nil, "Could not find the city for town hall unit number ".. unit_number)

        Consumption.updateNeeds(city)

        -- For backwards compatibility
        if player.gui.relative["city_overview_1"] then
            player.gui.relative["city_overview_1"].destroy()
        end

        local guiKey = "city_overview"
        local cityGui = player.gui.relative[guiKey]
        if cityGui ~= nil then
            -- clear any previous gui so that we can fully reconstruct it
            cityGui.destroy()
        end

        local anchor = {gui = defines.relative_gui_type.container_gui, name = "tycoon-town-hall", position = defines.relative_gui_position.right}
        cityGui = player.gui.relative.add{type = "frame", anchor = anchor, caption = city.name, direction = "vertical", name = guiKey}

        Gui.addCityView(city, cityGui)
    elseif gui.entity ~= nil and gui.entity.name == "tycoon-passenger-train-station" then
        local player = game.players[gui.player_index]
        local unit_number = gui.entity.unit_number

        local guiKey = "train_station_view"
        local trainStationGui = player.gui.relative[guiKey]
        if trainStationGui ~= nil then
            -- clear any previous gui so that we can fully reconstruct it
            trainStationGui.destroy()
        end

        local anchor = {gui = defines.relative_gui_type.container_gui, name = "tycoon-passenger-train-station", position = defines.relative_gui_position.right}
        trainStationGui = player.gui.relative.add{type = "frame", anchor = anchor, caption = {"", {"tycoon-gui-train-station-view"}}, direction = "vertical", name = guiKey}

        local cityId = ((global.tycoon_entity_meta_info or {})[unit_number] or {}).cityId
        Gui.addTrainStationView(unit_number, trainStationGui, findCityById(cityId))
    elseif gui.entity ~= nil and gui.entity.name == "tycoon-urban-planning-center" then
        local player = game.players[gui.player_index]

        local guiKey = "urban_planning_center_view"
        local urbanPlanningCenterGui = player.gui.relative[guiKey]
        if urbanPlanningCenterGui ~= nil then
            -- clear any previous gui so that we can fully reconstruct it
            urbanPlanningCenterGui.destroy()
        end

        local anchor = {gui = defines.relative_gui_type.container_gui, name = "tycoon-urban-planning-center", position = defines.relative_gui_position.right}
        urbanPlanningCenterGui = player.gui.relative.add{type = "frame", anchor = anchor, caption = {"", {"entity-name.tycoon-urban-planning-center"}}, direction = "vertical", name = guiKey}

        Gui.addUrbanPlanningCenterView(urbanPlanningCenterGui)
        
    elseif gui.entity ~= nil and isSupplyBuilding(gui.entity.name) then
        local player = game.players[gui.player_index]
        
        local unit_number = gui.entity.unit_number
        local cityName = findCityByEntityUnitNumber(unit_number)

        local guiKey = "supply_building_view"
        local supplyBuildingView = player.gui.relative[guiKey]
        if supplyBuildingView ~= nil then
            -- clear any previous gui so that we can fully reconstruct it
            supplyBuildingView.destroy()
        end

        local anchor = {gui = defines.relative_gui_type.container_gui, name = gui.entity.name, position = defines.relative_gui_position.right}
        supplyBuildingView = player.gui.relative.add{type = "frame", anchor = anchor, caption = {"", {"entity-name." .. gui.entity.name}}, direction = "vertical", name = guiKey}

        Gui.addSupplyBuildingOverview(supplyBuildingView, cityName)
    end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
    if string.find(event.element.name, "train_station_limit", 1, true) then
        local trainStationUnitNumber = tonumber(Util.splitString(event.element.name, delimiter)[2])
        global.tycoon_train_station_limits[trainStationUnitNumber] = math.min(tonumber(event.text) or 0, 100)
    end
end)

script.on_event(defines.events.on_gui_click, function(event)
    local player = game.players[event.player_index]
    local element = event.element

    if string.find(element.name, "tycoon_open_tech:", 1, true) then
        player.open_technology_gui("tycoon-" .. Util.splitString(element.name, ":")[2])
    elseif element.name == "close_multiple_cities_overview" then
        element.parent.parent.destroy()
    elseif string.find(element.name, "multiple_cities_select_tab:", 1, true) then
        local selectedTab = element.tags.selected_tab
        local guiKey = "multiple_cities_overview"
        local gui = player.gui.center[guiKey]
        gui.children[2].selected_tab_index = selectedTab
    end
end)

script.on_nth_tick(Constants.CITY_CONSUMPTION_TICKS, function()
    for _, city in ipairs(global.tycoon_cities or {}) do
        if city.special_buildings.town_hall ~= nil and city.special_buildings.town_hall.valid then
            Consumption.consumeBasicNeeds(city)
        end
    end
end)

local function canBuildSimpleHouse(city)
    local simpleCount = ((city.buildingCounts or {})["simple"] or 0)
    -- Todo: come up with a good function that slows down growth if there are too many
        -- low tier houses.
    local excavationPitCount = #(city.excavationPits or {})
    return simpleCount < (#city.grid * 10)
        and excavationPitCount <= #city.grid
end

--- @param supplyLevels number[]
--- @param city City
--- @return boolean shouldTierGrow
local function shouldTierGrow(supplyLevels, city)
    -- https://mods.factorio.com/mod/tycoon/discussion/6565de7d3e4062cbd3213508
    -- ((S1/D1 + S2/D2 + ... + Sn/Dn) / n)²
    local innerSum = 0;
    for _, value in pairs(supplyLevels) do
        innerSum = innerSum + math.min(1, value)
    end

    local growthChance = math.pow((innerSum / #supplyLevels), 2)

    return city.generator() < growthChance
end

local function canUpgradeToResidential(city)
    if not game.forces.player.technologies["tycoon-residential-housing"].researched then
        return false
    end

    local simpleCount = ((city.buildingCounts or {})["simple"] or 0)
    if simpleCount < 20 then
        return false
    end

    local residentialCount = ((city.buildingCounts or {})["residential"] or 0)
    if simpleCount < residentialCount * 5 then
        -- There should be 5 simple buildings for every residential building
        return false
    end

    local gridSize = #city.grid
    local residentialPercentage = math.ceil(gridSize * 0.1)
    local residentialPercentageCount = residentialPercentage * residentialPercentage
    return residentialCount < residentialPercentageCount
end

local function canUpgradeToHighrise(city)
    if not game.forces.player.technologies["tycoon-highrise-housing"].researched then
        return false
    end

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

    local gridSize = #city.grid
    local highRisePercentage = math.ceil(gridSize * 0.01)
    local highRisePercentageCount = highRisePercentage * highRisePercentage
    return highriseCount < highRisePercentageCount
end

--- @param suppliedTiers string[] | nil
local function newCityGrowth(city, suppliedTiers)
    assert(city.grid ~= nil and #city.grid > 1, "Expected grid to be initialized and larger than 1x1.")

    -- Attempt to complete constructions first
    local completedConstructionBuildingType = City.completeConstruction(city, suppliedTiers)
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
            isBuilt = City.startConstruction(city, {
                buildingType = prioBuilding.name,
                -- Special buildings should be completed very quickly.
                -- Here we just wait 2 seconds by default.
                constructionTimeInTicks = 120,
            }, "buildingLocationQueue")
            if not isBuilt then
                table.insert(city.priority_buildings, 1, prioBuilding)
            end
        elseif key == "highrise" and Util.indexOf(suppliedTiers, "highrise") ~= nil and canUpgradeToHighrise(city) then
            isBuilt = City.upgradeHouse(city, "highrise")
            if isBuilt then
                growCitizenCount(city, -1 * citizenCounts["residential"], "residential")
            end
        elseif key == "residential" and Util.indexOf(suppliedTiers, "residential") ~= nil and canUpgradeToResidential(city) then
            isBuilt = City.upgradeHouse(city, "residential")
            if isBuilt then
                growCitizenCount(city, -1 * citizenCounts["simple"], "simple")
            end
        elseif key == "simple" and canBuildSimpleHouse(city) then
            isBuilt = City.startConstruction(city, {
                buildingType = "simple",
                constructionTimeInTicks = city.generator(600, 1200)
            }, "buildingLocationQueue")
        end
        -- Keep the road construction outside the above if block,
        -- so that the roads can expand if no building has been constructed
        -- We can't add this to the buildables check, or the iteration will never get there
        if not isBuilt then
            if city.gardenLocationQueue ~= nil and city.generator() < 0.25 and Queue.count(city.gardenLocationQueue, true) > 0 then
                City.startConstruction(city, {
                    buildingType = "garden",
                    constructionTimeInTicks = 60 -- city.generator(300, 600)
                }, "gardenLocationQueue")
            else
                -- The city should not grow its road network too much if there are (valid) possibleBuildingLocations
                -- todo: how do we separate out invalid ones?
                local excavationPitCount = #(city.excavationPits or {})
                local possibleBuildingLocationsCount = Queue.count(city.buildingLocationQueue)
                if city.generator() < (#city.grid / possibleBuildingLocationsCount) and excavationPitCount < #city.grid then
                    -- todo: add check that road resources are available
                    local coordinates = City.growAtRandomRoadEnd(city)
                    if coordinates ~= nil then
                        City.updatepossibleBuildingLocations(city, coordinates)
                        isBuilt = true
                    end
                end
            end
        else
            for _, item in ipairs(resources) do
                Consumption.consumeItem(item, hardwareStores, city, true)
            end
            break
        end
    end
end

 -- Function to calculate a point at a certain percentage distance along a line
 local function interpolateCoordinates(coord1, coord2, percentage)
    local x1, y1 = coord1.x, coord1.y
    local x2, y2 = coord2.x, coord2.y

    if percentage < 0 then
        percentage = 0
    elseif percentage > 1 then
        percentage = 1
    end

    local newX = x1 + (x2 - x1) * percentage
    local newY = y1 + (y2 - y1) * percentage

    return { x = newX, y = newY }
end

local function placeInitialAppleFarm(city)
    local waterTiles = game.surfaces[1].find_tiles_filtered{
        position = city.center,
        -- 1000 is the max range that the search algorithm may extend to, it's not related to the city radius
        radius = math.min(global.tycoon_initial_apple_farm_radius or 100, 1000),
        name={"water", "deepwater"},
        limit = 1,
    }
    if #waterTiles == 0 then
        return
    end

    local waterPosition = waterTiles[1].position
    local coordinates = interpolateCoordinates(city.center, waterPosition, 0.5)
    local position = game.surfaces[1].find_non_colliding_position("tycoon-apple-farm", coordinates, 200, 5, true)
    -- make sure this doesn't spawn too close to town halls
    local townHalls = game.surfaces[1].find_entities_filtered{
        position = position,
        radius = 50,
        name = "tycoon-town-hall",
        limit = 1
    }
    if #townHalls > 0 then
        return nil
    end
    return placePrimaryIndustryAtPosition(position, "tycoon-apple-farm")
end

local function spawnPrimaryIndustries()

    if not global.tycoon_has_initial_apple_farm and #(global.tycoon_cities or {}) > 0 then
        local p = placeInitialAppleFarm(global.tycoon_cities[1])
        if p ~= nil or (global.tycoon_initial_apple_farm_radius or 100) > 1000 then
            addToGlobalPrimaryIndustries(p)
            global.tycoon_has_initial_apple_farm = true
        else
            global.tycoon_initial_apple_farm_radius = (global.tycoon_initial_apple_farm_radius or 100) + 100
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

            -- make sure this doesn't spawn too close to existing player entities
            local playerEntities = game.surfaces[1].find_entities_filtered{
                position = position,
                radius = 50,
                force = game.forces.player,
                limit = 1
            }
            if #playerEntities > 0 then
                return
            end

            local entity = placePrimaryIndustryAtPosition(position, primaryIndustry.name)
            if entity ~= nil then
                table.remove(global.tycoon_new_primary_industries, i)
                addToGlobalPrimaryIndustries(primaryIndustry)
            end
        end
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

--- @param city City
local function rediscoverUnusedFields(city)
    local gridSize = GridUtil.getGridSize(city.grid)
    if gridSize < 10 then
        return
    end
    local counter = 0
    -- Dividing by 4 gives us a radius of 2 on each side
    local innerRadius = math.ceil(gridSize / 2 / 2)
    local outerRadius = gridSize - innerRadius
    for y = innerRadius, innerRadius * 2, 1 do
        for x = innerRadius, innerRadius * 2, 1 do
            local cell = GridUtil.safeGridAccess(city, {x=x, y=y})
            if cell ~= nil and cell.type == "unused" and City.isCellFree(city, {x=x, y=y}) then
                local surroundsOfUnused = getSurroundingCoordinates(y, x, 1, false)
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
                    if city.gardenLocationQueue == nil then
                        city.gardenLocationQueue = Queue.new()
                    end
                    Queue.pushright(city.gardenLocationQueue, {x=x, y=y})
                else
                    if city.buildingLocationQueue == nil then
                        city.buildingLocationQueue = Queue.new()
                    end
                    Queue.pushright(city.buildingLocationQueue, {x=x, y=y})
                end

                counter = counter +1
                if counter > 5 then
                    -- Just add one entry per 10 minutes
                    -- Abort if we added enough records
                    -- This hopefully keeps other functions performant enough
                    return
                end
            end
        end
    end
end

script.on_nth_tick(1200, function()
    for _, city in ipairs(global.tycoon_cities or {}) do
        rediscoverUnusedFields(city)
    end
end)

script.on_nth_tick(10, function()
    spawnPrimaryIndustries()
end)

script.on_nth_tick(Constants.CITY_GROWTH_TICKS, function(event)
    -- global.tycoon_enable_debug_logging = true

    -- No need to do anything in the first 2 seconds
    if event.tick < 120 then
        return
    end

    if not global.tycoon_intro_message_displayed then
        game.print({"", "[color=orange]Factorio Tycoon:[/color] ", {"tycooon-intro-message-welcome"}})
        if game.surfaces[1].map_gen_settings.autoplace_controls["enemy-base"].size > 0 then
            game.print({"", "[color=orange]Factorio Tycoon:[/color] ", {"tycooon-intro-message-peaceful-warning"}})
        end
        global.tycoon_intro_message_displayed = true
    end
    -- show the primary industries message after 10 minutes
    if not global.tycoon_info_message_primary_industries_displayed and game.tick > 60 * 60 * 10 then
        game.print({"", "[color=orange]Factorio Tycoon:[/color] ", {"tycooon-info-message-primary-industries"}})
        global.tycoon_info_message_primary_industries_displayed = true
    end

    for _, city in ipairs(global.tycoon_cities) do
        if city.special_buildings.town_hall ~= nil and city.special_buildings.town_hall.valid then

            local suppliedTiers = {}
            if shouldTierGrow(Consumption.getBasicNeedsSupplyLevels(city, getNeeds(city, "simple")), city) then
                table.insert(suppliedTiers, "simple")
            end
            if shouldTierGrow(Consumption.getBasicNeedsSupplyLevels(city, getNeeds(city, "residential")), city) then
                table.insert(suppliedTiers, "residential")
            end
            if shouldTierGrow(Consumption.getBasicNeedsSupplyLevels(city, getNeeds(city, "highrise")), city) then
                table.insert(suppliedTiers, "highrise")
            end
            if #suppliedTiers > 0 then
                newCityGrowth(city, suppliedTiers)
            end

            -- We need to initialize the tag here, because tags can only be placed on charted chunks.
            -- And the game needs a moment to start and chart the initial chunks, even if it can already place entities.
            if city.tag == nil and city.special_buildings.town_hall ~= nil then
                local tag = game.forces.player.add_chart_tag(game.surfaces[1],
                    {
                        position = {x = city.special_buildings.town_hall.position.x, y = city.special_buildings.town_hall.position.y},
                        text = city.name
                    }
                )
                city.tag = tag
            end
        end
    end
end)

script.on_init(function()

    global.tycoon_global_generator = game.create_random_generator()

    global.tycoon_city_buildings = {}

    -- for i = 1, 8, 1 do
    --     game.surfaces[1].create_entity{
    --         name = "tycoon-house-highrise-" .. i,
    --         position = {x = -30 + i * 8, y = 20},
    --         force = "player"
    --     }
    -- end
    
        -- /c game. player. insert{ name="stone", count=1000 }
        -- /c game. player. insert{ name="tycoon-water-tower", count=1 }
        -- /c game. player. insert{ name="tycoon-cow", count=100 }
end)

script.on_nth_tick(Constants.PASSENGER_SPAWNING_TICKS, function()
    if #(global.tycoon_cities or {}) > 0 then
        for _, city in ipairs(global.tycoon_cities) do
            Passengers.clearPassengers(city)
            Passengers.spawnPassengers(city)
        end
        return
    end
end)

script.on_nth_tick(Constants.INITIAL_CITY_TICK, function ()
    if global.tycoon_cities == nil then
        global.tycoon_cities = {}
    end

    if #global.tycoon_cities == 0 then
        CityPlanning.addMoreCities(true, true)
    end
end)

script.on_nth_tick(Constants.MORE_CITIES_TICKS, function ()
    if global.tycoon_cities == nil then
        global.tycoon_cities = {}
    end

    if #global.tycoon_cities > 0 then
        CityPlanning.addMoreCities(false, false)
    end
end)

script.on_event(defines.events.on_gui_checked_state_changed, function(event)

    local element = event.element
    if not string.find(element.name, "train_station_gui_checkbox", 1, true) then
        return
    end
    local tags = element.tags
    local destination_city_id = tags.destination_city_id
    local train_station_unit_number = tags.train_station_unit_number
    if destination_city_id and train_station_unit_number then
        if global.tycoon_train_station_passenger_filters == nil then
            global.tycoon_train_station_passenger_filters = {}
        end
        if global.tycoon_train_station_passenger_filters[train_station_unit_number] == nil then
            global.tycoon_train_station_passenger_filters[train_station_unit_number] = {}
        end
        global.tycoon_train_station_passenger_filters[train_station_unit_number][destination_city_id] = element.state
    end
end)

local function spawnSuppliedBuilding(city, entityName, supplyName, supplyAmount)

    local position = game.surfaces[1].find_non_colliding_position(entityName, city.center, 200, 5, true)
    position.x = math.floor(position.x)
    position.y = math.floor(position.y) + 20

    local e = game.surfaces[1].create_entity{
        name = entityName,
        position = position,
        force = "neutral",
        move_stuck_players = true
    }

    if supplyName == "water" then
        e.insert_fluid{name = "water", amount = supplyAmount}
    else
        e.insert{name = supplyName, count = supplyAmount}
    end
end

commands.add_command("tycoon", nil, function(command)
    if command.player_index ~= nil and command.parameter == "spawn_city" then
        CityPlanning.addMoreCities(false, true)
        
        local cityIndex = #global.tycoon_cities
        local city = global.tycoon_cities[cityIndex]
        spawnSuppliedBuilding(city, "tycoon-market", "tycoon-apple", 1000)
        spawnSuppliedBuilding(city, "tycoon-hardware-store", "stone-brick", 1000)
        spawnSuppliedBuilding(city, "tycoon-hardware-store", "iron-plate", 1000)
        spawnSuppliedBuilding(city, "tycoon-water-tower", "water", 10000)
    elseif command.player_index ~= nil and command.parameter == "position" then
        local player = game.players[command.player_index]
        player.print('x='..player.character.position.x..' y='..player.character.position.y)
    elseif command.parameter == "grow-1" then
        local c = City.growAtRandomRoadEnd(global.tycoon_cities[1])
        if c == nil then
            game.print("City 1 expanded grid to size " .. #global.tycoon_cities[1].grid)
        else
            game.print("new road in cit 1: x=" .. c.x .. " y=" .. c.y)
        end
    elseif command.parameter == "grow-2" then
        local c = City.growAtRandomRoadEnd(global.tycoon_cities[2])
        if c == nil then
            game.print("City 2 expanded grid to size " .. #global.tycoon_cities[1].grid)
        else
            game.print("new road in city 2: x=" .. c.x .. " y=" .. c.y)
        end
    elseif command.parameter == "grid" then
        DEBUG.logGrid(global.tycoon_cities[1].grid, game.print)
    else
        game.print("Unknown command: tycoon " .. (command.parameter or ""))
    end
end)