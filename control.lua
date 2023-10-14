local Queue = require "queue"
SEGMENTS = require("segments")
CITY = require("city")
CONSUMPTION = require("consumption")
-- TYCOON_STORY = require("tycoon-story")

local primary_industry_names = {"tycoon-apple-farm", "tycoon-wheat-farm", "tycoon-fishery"}

--- @param coordinates Coordinates
--- @param sendWarningForMethod string | nil
--- @return any | nil cell
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
            local cell = safeGridAccess(city, {x=x, y=y}, "initializeCity")
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
            local c = safeGridAccess(city, {y=i, x=j})
            -- todo: rather replace this with a proper initial grid (no need for translation then)
            assert(c ~= nil or #c == 0, "Failed to translate starter cells of city.")
            city.grid[i][j] = translateStarterCell(c[1])
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
    local roadEndCount = city.generator(4, 8)
    for i = 1, roadEndCount, 1 do
        Queue.pushright(city.roadEnds, table.remove(possibleRoadEnds, city.generator(#possibleRoadEnds)))
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

local function setConstructionMaterialsProvided(city, resource, amount)
    -- dev support, delete me
    if city.stats.construction_materials == nil then
        city.stats.construction_materials = {}
    end

    if city.stats.construction_materials[resource] == nil then
        city.stats.construction_materials[resource] = {
            provided = 0,
        }
    end
    city.stats.construction_materials[resource].provided = math.floor(amount)
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

local constructionIncrements = {
    default = {"stone-brick", "iron-plate"},
    residential = {"steel-plate", "small-lamp"},
    highrise = {"pump", "concrete", "pipe"}
}

local function addBasicNeedsGui(city, cityGui)

    local unlockedBasicNeeds = {}
    for key, values in pairs(CONSUMPTION.basicNeedIncrements) do
        if key == "default" or (game.players[1].force.technologies[ "tycoon-" .. key .. "-housing"] or {}).researched == true then
            for _, v in ipairs(values) do
                table.insert(unlockedBasicNeeds, v)
            end
        end
    end

    local basicNeedsGui = cityGui.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-basic-needs"}}, name = "basic_needs"}
    basicNeedsGui.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle-1"}}}
    basicNeedsGui.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle-2"}}}
    basicNeedsGui.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle-3"}}}
    for _, resource in ipairs(unlockedBasicNeeds) do

        local missingSupplier = nil
        if resource == "water" then
            local waterTowers = listSpecialCityBuildings(city, "tycoon-water-tower")
            if #waterTowers == 0 then
                missingSupplier = "tycoon-water-tower"
            end
        else
            local markets = listSpecialCityBuildings(city, "tycoon-market")
            if #markets == 0 then
                missingSupplier = "tycoon-market"
            end
        end

        if missingSupplier ~= nil then
            basicNeedsGui.add{type = "label", caption = {"", "[color=red]", {"tycoon-gui-missing", {"entity-name." .. missingSupplier}}, "[/color]"}}
        else
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

            local captionElements = {"", {itemName}, ": ", "[color=" .. color .. "]", amounts.provided, "/", amounts.required, "[/color]"}
            if resource == "water" and (amounts.provided == 0 or (amounts.required / amounts.provided) > 0.75) then
                table.insert(captionElements, " ")
                table.insert(captionElements, {"tycoon-gui-add-more-water-towers"})
            end
            basicNeedsGui.add{type = "label", caption = captionElements}
        end
    end
end

local function addConstructionGui(city, cityGui)
    local unlockedConstructionNeeds = {}
    for key, values in pairs(constructionIncrements) do
        if key == "default" or (game.players[1].force.technologies[ "tycoon-" .. key .. "-housing"] or {}).researched == true then
            for _, v in ipairs(values) do
                table.insert(unlockedConstructionNeeds, v)
            end
        end
    end

    local constructionGui = cityGui.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-construction"}}}
    local constructionGuiTable = constructionGui.add{type = "table", column_count = 3}
    local constructionSiteColoring = "green"
    if #(city.excavationPits or {}) >= #city.grid then
        constructionSiteColoring = "red"
    end
    constructionGuiTable.add{type = "label", caption = {"", {"tycoon-gui-construction-sites"}, ":"}}
    constructionGuiTable.add{type = "label", caption = {"", "[color=" .. constructionSiteColoring .. "]",  #(city.excavationPits or {}), "/", #city.grid, "[/color]"}}
    constructionGuiTable.add{type = "label", caption = ""}

    local housingTiers = {"simple", "residential", "highrise"}
    local buildables = getBuildables(city)
    for _, tier in ipairs(housingTiers) do
        if tier == "simple" or (game.players[1].force.technologies["tycoon-" .. tier .. "-housing"] or {}).researched == true then
            local text, coloring
            local tooManyConstructionSites = #(city.excavationPits or {}) >= #city.grid
            if not CONSUMPTION.areBasicNeedsMet(city, getNeeds(city, tier)) then
                text = {"tycoon-gui-growth-no-basic-needs"}
                coloring = "red"
            elseif buildables[tier] == nil then
                text = {"tycoon-gui-growth-no-construction-material"}
                coloring = "red"
            elseif tooManyConstructionSites then
                text = {"tycoon-gui-growth-pending-construction-sites"}
                coloring = "orange"
            else
                coloring = "green"
                text = {"tycoon-gui-growing"}
            end

            constructionGuiTable.add{type = "label", caption = {"", {"technology-name.tycoon-" .. tier .. "-housing"}, ": "}}
            constructionGuiTable.add{type = "label", caption = {"", "[color=" .. coloring .. "]", text, "[/color]"}}
            constructionGuiTable.add{type = "label", caption = ""}
        else
            constructionGuiTable.add{type = "label", caption = {"", {"technology-name.tycoon-" .. tier .. "-housing"}, ": "}}
            constructionGuiTable.add{type = "label", caption = {"", "[color=red]", {"tycoon-gui-not-researched"}, "[/color]"}}
            constructionGuiTable.add{type = "button", caption = "Open Technology", name = "tycoon_open_tech:" .. tier .. "-housing"}
        end
    end

    constructionGui.add{type = "line"}
    
    local constructionNeedsGui = constructionGui.add{type = "flow", direction = "vertical"}
    local hardwareStores = listSpecialCityBuildings(city, "tycoon-hardware-store")
    if #hardwareStores == 0 then
        constructionNeedsGui.add{type = "label", caption = {"", "[color=red]", {"tycoon-gui-missing", {"entity-name.tycoon-hardware-store"}}, "[/color]"}}
    else
        for _, resource in ipairs(unlockedConstructionNeeds) do

            local totalResourceCount = 0
            for _, hardwareStore in ipairs(hardwareStores or {}) do
                local availableCount = hardwareStore.get_item_count(resource)
                totalResourceCount = totalResourceCount + availableCount
            end
            setConstructionMaterialsProvided(city, resource, totalResourceCount)

            local amounts = city.stats.construction_materials[resource] or {provided =  0}

            local itemName = "item-name." .. resource
            local fallbackName = "entity-name." .. resource

            local color = "green"
            if amounts.provided == 0 then
                color = "red"
            end

            local captionElements = {"", {"?", {itemName}, {fallbackName}}, ": ", "[color=" .. color .. "]", amounts.provided, "[/color]"}
            constructionNeedsGui.add{type = "label", caption = captionElements}
        end
    end

end

 -- todo: show construction material supply
script.on_event(defines.events.on_gui_opened, function (gui)
    if gui.entity ~= nil and gui.entity.name == "tycoon-town-hall" then
        local player = game.players[gui.player_index]
        local unit_number = gui.entity.unit_number
        local city = findCityByTownHallUnitNumber(unit_number)
        assert(city ~= nil, "Could not find the city for town hall unit number ".. unit_number)

        CONSUMPTION.updateNeeds(city)

        local guiKey = "city_overview_" .. city.id
        local cityGui = player.gui.relative[guiKey]
        if cityGui ~= nil then
            -- clear any previous gui so that we can fully reconstruct it
            cityGui.destroy()
        end

        local anchor = {gui = defines.relative_gui_type.container_gui, name = "tycoon-town-hall", position = defines.relative_gui_position.right}
        cityGui = player.gui.relative.add{type = "frame", anchor = anchor, caption = {"", {"tycoon-gui-city-overview"}}, direction = "vertical", name = guiKey}
        cityGui.add{type = "label", caption = {"", {"tycoon-gui-update-info"}}}

        local stats = cityGui.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-stats"}}, name = "city_stats"}
        stats.add{type = "label", caption = {"", {"tycoon-gui-citizens"}, ": ",  countCitizens(city)}}

        addBasicNeedsGui(city, cityGui)
        addConstructionGui(city, cityGui)
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

--- @param suppliedTiers string[] | nil
local function newCityGrowth(city, suppliedTiers)
    assert(city.grid ~= nil and #city.grid > 1, "Expected grid to be initialized and larger than 1x1.")

    -- Attempt to complete constructions first
    local completedConstructionBuildingType = CITY.completeConstruction(city, suppliedTiers)
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
            }, city.buildingLocationQueue)
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
                constructionTimeInTicks = city.generator(600, 1200)
            }, city.buildingLocationQueue)
        end
        -- Keep the road construction outside the above if block,
        -- so that the roads can expand if no building has been constructed
        -- We can't add this to the buildables check, or the iteration will never get there
        if not isBuilt then
            if city.gardenLocationQueue ~= nil and city.generator() < 0.25 and Queue.count(city.gardenLocationQueue, true) > 0 then
                CITY.startConstruction(city, {
                    buildingType = "garden",
                    constructionTimeInTicks = 60 -- city.generator(300, 600)
                }, city.gardenLocationQueue)
            else
                -- The city should not grow its road network too much if there are (valid) possibleBuildingLocations
                -- todo: how do we separate out invalid ones?
                local excavationPitCount = #(city.excavationPits or {})
                local possibleBuildingLocationsCount = Queue.count(city.buildingLocationQueue)
                if city.generator() < (#city.grid / possibleBuildingLocationsCount) and excavationPitCount < #city.grid then
                    -- todo: add check that road resources are available
                    local coordinates = CITY.growAtRandomRoadEnd(city)
                    if coordinates ~= nil then
                        CITY.updatepossibleBuildingLocations(city, coordinates)
                        isBuilt = true
                    end
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
    return placePrimaryIndustryAtPosition(position, "tycoon-apple-farm")
end

local function spawnPrimaryIndustries()

    if not global.tycoon_has_initial_apple_farm then
        local p = placeInitialAppleFarm(global.tycoon_cities[1])
        if p ~= nil or (global.tycoon_initial_apple_farm_radius or 100) > 1000 then
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
            local entity = placePrimaryIndustryAtPosition(position, primaryIndustry.name)
            if entity ~= nil then
                table.remove(global.tycoon_new_primary_industries, i)
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
    local gridSize = getGridSize(city.grid)
    if gridSize < 10 then
        return
    end
    local counter = 0
    -- Dividing by 4 gives us a radius of 2 on each side
    local innerRadius = math.ceil(gridSize / 2 / 2)
    local outerRadius = gridSize - innerRadius
    for y = innerRadius, innerRadius * 2, 1 do
        for x = innerRadius, innerRadius * 2, 1 do
            local cell = safeGridAccess(city, {x=x, y=y})
            if cell ~= nil and cell.type == "unused" and CITY.isCellFree(city, {x=x, y=y}) then
                local surroundsOfUnused = getSurroundingCoordinates(y, x, 1, false)
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
                    Queue.pushright(city.gardenLocationQueue, {x=x, y=y})
                else
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
    for _, city in ipairs(global.tycoon_cities) do
        rediscoverUnusedFields(city)
    end
end)

script.on_nth_tick(10, function()
    spawnPrimaryIndustries()
end)

script.on_nth_tick(CITY_GROWTH_TICKS, function(event)
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
            if CONSUMPTION.areBasicNeedsMet(city, getNeeds(city, "simple")) then
                table.insert(suppliedTiers, "simple")
            end
            if CONSUMPTION.areBasicNeedsMet(city, getNeeds(city, "residential")) then
                table.insert(suppliedTiers, "residential")
            end
            if CONSUMPTION.areBasicNeedsMet(city, getNeeds(city, "highrise")) then
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
                        text = city.name .. " Town Center"
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

    local cityId = 1
    local generatorSalt = cityId * 1337
    global.tycoon_cities = {{
        id = cityId,
        generator = game.create_random_generator(game.surfaces[1].map_gen_settings.seed + generatorSalt),
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
            basic_needs = {},
            construction_materials = {}
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