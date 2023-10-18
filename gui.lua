local CONSUMPTION = require("consumption")

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
    local constructionGuiTable = constructionGui.add{type = "table", column_count = 3}
    local constructionSiteColoring = "green"
    if #(city.excavationPits or {}) >= #city.grid then
        constructionSiteColoring = "red"
    end
    constructionGuiTable.add{type = "label", caption = {"", {"tycoon-gui-construction-sites"}, ":"}}
    constructionGuiTable.add{type = "label", caption = {"", "[color=" .. constructionSiteColoring .. "]",  #(city.excavationPits or {}), "/", #city.grid, "[/color]"}}
    constructionGuiTable.add{type = "label", caption = ""}

    constructionGui.add{type = "line"}

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

    -- constructionGui.add{type = "line"}
    -- constructionGui.add{type = "label", caption = {"", {"tycoon-gui-urbanization-requirement-1"}}}
    -- constructionGui.add{type = "label", caption = {"", {"tycoon-gui-urbanization-requirement-2"}}}
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
    local simpleMet = CONSUMPTION.areBasicNeedsMet(city, getNeeds(city, "simple"))
    local residentialMet = not game.forces.player.technologies["tycoon-residential-housing"].researched or CONSUMPTION.areBasicNeedsMet(city, getNeeds(city, "residential"))
    local highriseMet = not game.forces.player.technologies["tycoon-highrise-housing"].researched or CONSUMPTION.areBasicNeedsMet(city, getNeeds(city, "highrise"))

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
    -- construction sites
    local constructionSiteColoring = "green"
    if #(city.excavationPits or {}) >= #city.grid then
        constructionSiteColoring = "red"
    end
    tbl.add{type = "label", caption = {"", {"tycoon-gui-construction-sites"}, ":"}}
    tbl.add{type = "label", caption = {"", "[color=" .. constructionSiteColoring .. "]",  #(city.excavationPits or {}), "/", #city.grid, "[/color]"}}
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

local GUI = {
    addHousingView = addHousingView,
    addBasicNeedsView = addBasicNeedsView,
    addConstructionMaterialsGui = addConstructionMaterialsGui,
    addCityView = addCityView,
}

return GUI