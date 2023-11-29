local Consumption = require("consumption")
local Constants = require("constants")
local CityPlanner = require("city-planner")
local Consumption = require("consumption")

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

local function getBuildables(city, hardwareStores)

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

--- @param rootGui any
--- @param constructionNeeds string[]
--- @param city City
--- @param hardwareStores any[]
local function addConstructionMaterialsGui(rootGui, constructionNeeds, city, hardwareStores, housingType)
   
    local constructionGui = rootGui.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-construction"}}}

    local tbl = constructionGui.add{type = "table", column_count = 2, draw_horizontal_lines = true}
    
    if #hardwareStores == 0 then
        tbl.add{type = "label", caption = {"", "[color=red]", {"tycoon-gui-missing", {"entity-name.tycoon-hardware-store"}}, "[/color]"}}
        tbl.add{type = "label", caption = ""}
    else
        for _, resource in ipairs(constructionNeeds) do

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

            tbl.add{type = "label", caption = {"", {"?", {itemName}, {fallbackName}}, ": "}}
            tbl.add{type = "label", caption = {"", "[color=" .. color .. "]", amounts.provided, "[/color]"}}
        end
    end

    constructionGui.add{type = "line"}

    constructionGui.add{type = "label", caption = {"", {"tycoon-gui-construction-requirement-1"}}}
    constructionGui.add{type = "label", caption = {"", {"tycoon-gui-construction-requirement-2"}}}

    if housingType ~= "simple" then
        constructionGui.add{type = "label", caption = {"", {"tycoon-gui-urbanization-requirement-1"}}}
        constructionGui.add{type = "label", caption = {"", {"tycoon-gui-urbanization-requirement-2"}}}
    end
end

--- @param rootGui any
--- @param basicNeeds string[]
--- @param city City
--- @param waterTowers any[]
--- @param markets any[]
local function addBasicNeedsView(rootGui, basicNeeds, city, waterTowers, markets)
    local basicNeedsGui = rootGui.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-basic-needs"}}, name = "basic_needs"}
    basicNeedsGui.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle-1"}}}
    basicNeedsGui.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle-2"}}}
    basicNeedsGui.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle-3"}}}

    basicNeedsGui.add{type = "line"}

    local displayedMissingSuppliers = {}

    local tbl = basicNeedsGui.add{type = "table", column_count = 2, draw_horizontal_lines = true}
    for _, resource in ipairs(basicNeeds) do

        local missingSupplier = nil
        if resource == "water" then
            if #waterTowers == 0 then
                missingSupplier = "tycoon-water-tower"
            end
        else
            if #markets == 0 then
                missingSupplier = "tycoon-market"
            end
        end

        if missingSupplier ~= nil then
            if displayedMissingSuppliers[missingSupplier] ~= true then
                tbl.add{type = "label", caption = {"", "[color=red]", {"tycoon-gui-missing", {"entity-name." .. missingSupplier}}, "[/color]"}}
                tbl.add{type = "label", caption = ""}
                displayedMissingSuppliers[missingSupplier] = true
            end
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

            tbl.add{type = "label", caption = {"", {itemName}, ": "}}

            local captionElements = {"", "[color=" .. color .. "]", amounts.provided, "/", amounts.required, "[/color]"}
            if resource == "water" and (amounts.provided == 0 or (amounts.required / amounts.provided) > 0.75) then
                table.insert(captionElements, " ")
                table.insert(captionElements, {"tycoon-gui-add-more-water-towers"})
            end
            tbl.add{type = "label", caption = captionElements}
        end
    end
end

--- @param city City
--- @param filter string | nil
local function countCitizens(city, filter)
    local total = 0
    for tier, count in pairs(city.citizens) do
        if filter == nil then
            total = total + count
        elseif filter == tier then
            total = total + count
        end
    end
    return total
end

local function listSpecialCityBuildings(city, name)
    local entities = {}
    if city.special_buildings.other[name] ~= nil and #city.special_buildings.other[name] > 0 then
        entities = city.special_buildings.other[name]
    else
        entities = game.surfaces[1].find_entities_filtered{
            name=name,
            position=city.special_buildings.town_hall.position,
            radius=Constants.CITY_RADIUS
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

local basicNeeds = {
    simple = {"water", "tycoon-apple"},
    residential = {"water", "tycoon-apple", "tycoon-meat", "tycoon-bread"},
    highrise = {"water", "tycoon-apple", "tycoon-meat", "tycoon-bread", "tycoon-fish-filet", "tycoon-milk-bottle"}
}

local constructionNeeds = {
    simple = {"stone-brick", "iron-plate"},
    residential = {"stone-brick", "iron-plate", "steel-plate", "small-lamp"},
    highrise = {"steel-plate", "small-lamp", "pump", "concrete", "pipe"}
}

--- @param city City
--- @param housingType string
local function addHousingView(housingType, city, anchor)
    if housingType ~= "simple" and not game.forces.player.technologies["tycoon-" .. housingType .. "-housing"].researched then
        anchor.add{type = "label", caption = {"", "[color=red]", {"tycoon-gui-not-researched"}, "[/color]"}}
        anchor.add{type = "button", caption = "Open Technology", name = "tycoon_open_tech:" .. housingType .. "-housing"}
        return
    end

    local stats = anchor.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-stats"}}, name = "city_stats"}
    stats.add{type = "label", caption = {"", {"tycoon-gui-citizens"}, ": ",  countCitizens(city, housingType)}}

    local waterTowers = listSpecialCityBuildings(city, "tycoon-water-tower")
    local markets = listSpecialCityBuildings(city, "tycoon-market")
    local hardwareStores = listSpecialCityBuildings(city, "tycoon-hardware-store")

    addBasicNeedsView(anchor, basicNeeds[housingType], city, waterTowers, markets)
    addConstructionMaterialsGui(anchor, constructionNeeds[housingType], city, hardwareStores, housingType)
end

local function getOverallBasicNeedsCaption(city)
    local simpleMet = Consumption.areBasicNeedsMet(city, getNeeds(city, "simple"), true)
    local residentialMet = not game.forces.player.technologies["tycoon-residential-housing"].researched or Consumption.areBasicNeedsMet(city, getNeeds(city, "residential"), true)
    local highriseMet = not game.forces.player.technologies["tycoon-highrise-housing"].researched or Consumption.areBasicNeedsMet(city, getNeeds(city, "highrise"), true)

    if simpleMet and residentialMet and highriseMet then
        return {"", "[color=green]", {"tycoon-gui-status-supplied"}, "[/color]"}
    elseif simpleMet or residentialMet or highriseMet then
        return {"", "[color=orange]", {"tycoon-gui-status-lacking"}, "[/color]"}
    else
        return {"", "[color=red]", {"tycoon-gui-status-missing"}, "[/color]"}
    end
end

local function areConstructionNeedsMet(city, housingTier, stores) 
    local hardwareStores = stores or listSpecialCityBuildings(city, "tycoon-hardware-store")
    local needs = constructionResources[housingTier]

    for _, need in ipairs(needs) do
        -- name/required
        local totalAvailable = 0
        for _, store in ipairs(hardwareStores) do
            local availableCount = store.get_item_count(need.name)
            totalAvailable = totalAvailable + availableCount
        end

        if need.required > totalAvailable then
            return false
        end
    end

    return true
end

local function getOverallConstructionMaterialsCaption(city)
    local hardwareStores = listSpecialCityBuildings(city, "tycoon-hardware-store")
    local simpleMet = areConstructionNeedsMet(city, "simple", hardwareStores)
    local residentialMet = not game.forces.player.technologies["tycoon-residential-housing"].researched or areConstructionNeedsMet(city, "residential", hardwareStores)
    local highriseMet = not game.forces.player.technologies["tycoon-highrise-housing"].researched or areConstructionNeedsMet(city, "highrise", hardwareStores)

    if simpleMet and residentialMet and highriseMet then
        return {"", "[color=green]", {"tycoon-gui-status-supplied"}, "[/color]"}
    elseif simpleMet or residentialMet or highriseMet then
        return {"", "[color=orange]", {"tycoon-gui-status-lacking"}, "[/color]"}
    else
        return {"", "[color=red]", {"tycoon-gui-status-missing"}, "[/color]"}
    end
end

local function addCityOverview(city, anchor)
    local stats = anchor.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-stats"}}, name = "city_stats"}
    local tbl = stats.add{type = "table", column_count = 2, draw_horizontal_lines = true}
    -- citizen count
    tbl.add{type = "label", caption = {"", {"tycoon-gui-citizens"}, ": "}}
    tbl.add{type = "label", caption = {"", countCitizens(city)}}
    -- overall basic needs status
    tbl.add{type = "label", caption = {"", {"tycoon-gui-basic-needs"}, ": "}}
    tbl.add{type = "label", caption = getOverallBasicNeedsCaption(city)}
    -- overall construction materials status
    tbl.add{type = "label", caption = {"", {"tycoon-gui-construction-materials"}, ": "}}
    tbl.add{type = "label", caption = getOverallConstructionMaterialsCaption(city)}
end

local function canCreatePassengerForCity(train_station_numer, destination_city_id)
    
    -- If the player has not set any filters for this station (i.e. they are nil or none are false), then we can display new cities as accepted
    -- If any city has been disabled, then we won't allow new cities to automatically show up and produce passengers

    local areAllFiltersPositive = true
    if global.tycoon_train_station_passenger_filters ~= nil and global.tycoon_train_station_passenger_filters[train_station_numer] ~= nil then
        for _, c in ipairs(global.tycoon_cities) do
            if global.tycoon_train_station_passenger_filters[train_station_numer][c.id] == false then
                areAllFiltersPositive = false
                break
            end
        end
    end

    if areAllFiltersPositive then
        return true
    end

    -- If the station does not know how to filter a station yet and not all filters are positive, then set the new one to negative
    if global.tycoon_train_station_passenger_filters[train_station_numer][destination_city_id] == nil then
        global.tycoon_train_station_passenger_filters[train_station_numer][destination_city_id] = areAllFiltersPositive
    end

    return global.tycoon_train_station_passenger_filters[train_station_numer][destination_city_id]
end

local function addTrainStationView(trainStationUnitNumber, anchor, city)
    if not city then
        anchor.add{type = "label", caption = {"", {"tycoon-gui-train-station-is-missing-city" }}}
        return
    end

    if not global.tycoon_train_station_limits then
        global.tycoon_train_station_limits = {}
    end

    if not global.tycoon_train_station_limits[trainStationUnitNumber] then
        -- 100 is the inventory_size of the passenger-train-station entity, filling up 80% is a good default to not immediately get stuck
        global.tycoon_train_station_limits[trainStationUnitNumber] = 80
    end

    local flow = anchor.add{type = "flow", direction = "vertical"}
    if city ~= nil then
        flow.add{type = "label", caption = {"", {"tycoon-gui-train-station-for-city", city.name}}}
        flow.add{type = "line"}
    end
    flow.add{type = "label", caption = {"", {"tycoon-gui-train-station-limit", 0, 100}, ":"}}
    flow.add{
        type = "textfield", 
        numeric = true,
        allow_decimal = false,
        allow_negative = false,
        text = "" .. global.tycoon_train_station_limits[trainStationUnitNumber],
        name = "train_station_limit:" .. trainStationUnitNumber
    }

    flow.add{type = "line", direction = "horizontal"}
    flow.add{type = "label", caption = {"", {"tycoon-gui-select-departures"}}}

    for _, c in ipairs(global.tycoon_cities or {}) do
        if city.name == c.name then
            flow.add{type = "checkbox", caption = c.name, state = false, enabled = false}
        else
            flow.add{type = "checkbox", caption = c.name, 
                state = canCreatePassengerForCity(trainStationUnitNumber, c.id),
                name = "train_station_gui_checkbox:" .. string.lower(c.name),
                tags = {
                    destination_city_id = c.id,
                    train_station_unit_number = trainStationUnitNumber
                }
            }
        end
    end
end

local function addCityView(city, anchor)
    local tabbed_pane = anchor.add{type="tabbed-pane"}
    local tab_overview = tabbed_pane.add{type="tab", caption={"", {"tycoon-gui-city-overview"}}}
    local tab_simple = tabbed_pane.add{type="tab", caption={"", {"technology-name.tycoon-simple-housing"}}}
    local tab_residential = tabbed_pane.add{type="tab", caption={"", {"technology-name.tycoon-residential-housing"}}}
    local tab_highrise = tabbed_pane.add{type="tab", caption={"", {"technology-name.tycoon-highrise-housing"}}}

    local overviewContainer = tabbed_pane.add{type = "flow", direction = "vertical"}
    tabbed_pane.add_tab(tab_overview, overviewContainer)
    addCityOverview(city, overviewContainer)
    
    local simpleContainer = tabbed_pane.add{type = "flow", direction = "vertical"}
    tabbed_pane.add_tab(tab_simple, simpleContainer)
    addHousingView("simple", city, simpleContainer)
    
    local residentialContainer = tabbed_pane.add{type = "flow", direction = "vertical"}
    tabbed_pane.add_tab(tab_residential, residentialContainer)
    addHousingView("residential", city, residentialContainer)
    
    local highriseContainer = tabbed_pane.add{type = "flow", direction = "vertical"}
    tabbed_pane.add_tab(tab_highrise, highriseContainer)
    addHousingView("highrise", city, highriseContainer)

    tabbed_pane.selected_tab_index = 1
end

local function addUrbanPlanningCenterView(anchor)
    local totalAvailable = CityPlanner.getTotalAvailableFunds()
    local requiredFunds = CityPlanner.getRequiredFundsForNextCity()
    local tbl = anchor.add{type = "table", column_count = 2, draw_horizontal_lines = true}
    tbl.add{type = "label", caption = {"", {"tycoon-required-funds-for-next-city"}, ":"}}
    tbl.add{type = "label", caption = {"", requiredFunds}}
    tbl.add{type = "label", caption = {"", {"tycoon-total-available-funds"}, ":"}}
    tbl.add{type = "label", caption = {"", totalAvailable}}

    anchor.add{type = "label", caption = {"", {"tycoon-progress"}}}
    anchor.add{type = "progressbar", value = totalAvailable / requiredFunds}
    
    if requiredFunds < totalAvailable then
        anchor.add{type = "line", direction = "horizontal"}
        anchor.add{type = "label", caption = {"", {"tycoon-urban-planning-center-hint-1"}}}
        anchor.add{type = "label", caption = {"", {"tycoon-urban-planning-center-hint-2"}}}
        anchor.add{type = "label", caption = {"", {"tycoon-urban-planning-center-hint-3"}}}
    end
end

local function addCitiesOverview(anchor)
    local columnWidth = 100
    local tbl = anchor.add{type = "table", column_count = 4, draw_horizontal_lines = true}
    local c1 = tbl.add{type = "label", caption = "Name"}
    c1.style.width = columnWidth
    local c2 = tbl.add{type = "label", caption = "Citizens"}
    c2.style.width = columnWidth
    local c3 = tbl.add{type = "label", caption = "Basic Needs Supplied"}
    c3.style.width = columnWidth
    local c4 = tbl.add{type = "label", caption = ""}
    c4.style.width = columnWidth
    for i, city in ipairs(global.tycoon_cities or {}) do
        local needsMet = Consumption.areBasicNeedsMet(city, nil, true)
        local color = "red"
        local text = "tycoon-no"
        if needsMet then
            color = "green"
            text = "tycoon-yes"
        end
        tbl.add{type = "label", caption = {"", "[font=default-bold]", city.name, "[/font]"}}
        tbl.add{type = "label", caption = countCitizens(city)}
        tbl.add{type = "label", caption = {"", "[color=".. color .."]", {text}, "[/color]"}}
        tbl.add{type = "button", caption = "Show Details", name = "multiple_cities_select_tab:" .. i, tags = {selected_tab = i + 1}}
    end
end

local function addMultipleCitiesOverview(anchor)
    local flow_title_bar = anchor.add{type="flow", direction="horizontal"}
    flow_title_bar.add{type = "label", caption = {"", "[font=default-bold]", {"tycoon-gui-cities-overview"}, "[/font]"}}
    local close_button = flow_title_bar.add{
        type="sprite-button", 
        sprite="utility/close_white",
        hovered_sprite="utility/close_black", 
        clicked_sprite="utility/close_black", 
        style="frame_action_button", -- needed to keep the icon small
        name="close_multiple_cities_overview"
    }

    local tabbed_pane = anchor.add{type="tabbed-pane", name = "multiple_cities_overview_tabbed_pane"}
    local tab_all_cities = tabbed_pane.add{type="tab", caption={"", {"tycoon-gui-all-cities"}}}
    local overviewContainer = tabbed_pane.add{type = "flow", direction = "vertical"}
    overviewContainer.style.padding = {10, 10, 10, 10}
    tabbed_pane.add_tab(tab_all_cities, overviewContainer)
    addCitiesOverview(overviewContainer)

    for i, city in ipairs(global.tycoon_cities or {}) do
        local tab_city = tabbed_pane.add{type="tab", caption=city.name}

        local cityContainer = tabbed_pane.add{type = "flow", direction = "vertical"}
        tabbed_pane.add_tab(tab_city, cityContainer)
        addCityView(city, cityContainer)
    end

    tabbed_pane.selected_tab_index = 1
end

local function addSupplyBuildingOverview(anchor, cityName)
    if cityName == "Unknown" then
        anchor.add{type = "label", caption = {"", {"tycoon-supply-building-not-connected"}}}
    else
        anchor.add{type = "label", caption = {"", {"tycoon-supply-building-city", cityName}}}
    end
end

local GUI = {
    addHousingView = addHousingView,
    addBasicNeedsView = addBasicNeedsView,
    addConstructionMaterialsGui = addConstructionMaterialsGui,
    addCityView = addCityView,
    addTrainStationView = addTrainStationView,
    addUrbanPlanningCenterView = addUrbanPlanningCenterView,
    addMultipleCitiesOverview = addMultipleCitiesOverview,
    addSupplyBuildingOverview = addSupplyBuildingOverview,
}

return GUI