local Consumption = require("consumption")
local Constants = require("constants")
local CityPlanner = require("city-planner")
local Util = require("util")

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

local function getBasicNeeds(city, tier)
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
        assert(false, "Unknown tier for getBasicNeeds: " .. tier)
    end
end

local function getAdditionalNeeds(city, tier)
    if city.stats.additional_needs == nil then
        -- edge case for when this has not been initialized (e.g. when upgrading the savegame to the latest version of this mod)
        return {}
    end
    if tier == "simple" then
        return {
            ["tycoon-cooking-pot"] = city.stats.additional_needs["tycoon-cooking-pot"],
            ["tycoon-cooking-pan"] = city.stats.additional_needs["tycoon-cooking-pan"],
            ["tycoon-cutlery"] = city.stats.additional_needs["tycoon-cutlery"],
        }
    elseif tier == "residential" then
        return {
            ["tycoon-bicycle"] = city.stats.additional_needs["tycoon-bicycle"],
            ["tycoon-candle"] = city.stats.additional_needs["tycoon-candle"],
            ["tycoon-soap"] = city.stats.additional_needs["tycoon-soap"],
            ["tycoon-gloves"] = city.stats.additional_needs["tycoon-gloves"],
            ["tycoon-television"] = city.stats.additional_needs["tycoon-television"],
        }
    elseif tier == "highrise" then
        return {
            ["tycoon-smartphone"] = city.stats.additional_needs["tycoon-smartphone"],
            ["tycoon-laptop"] = city.stats.additional_needs["tycoon-laptop"],
        }
    else
        assert(false, "Unknown tier for getAdditionalNeeds: " .. tier)
    end
end

local function getItemPrice(itemName)
    local value = Consumption.resourcePrices[itemName]
    if value == nil then
        return "?"
    else
        return string.format("%.1f", value)
    end
end

local house_ratios = {
    residential = Constants.RESIDENTIAL_HOUSE_RATIO,
    highrise = Constants.HIGHRISE_HOUSE_RATIO,
}

--- @param rootGui any
--- @param constructionNeeds string[]
--- @param city City
--- @param hardwareStores any[]
local function addConstructionMaterialsGui(rootGui, constructionNeeds, city, hardwareStores, housingType)
   
    local constructionGui = rootGui.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-construction"}}}

    local tbl = constructionGui.add{type = "table", column_count = 4, draw_horizontal_lines = true}
    
    if #hardwareStores == 0 then
        tbl.add{type = "label", caption = {"", "[color=red]", {"tycoon-gui-missing", {"entity-name.tycoon-hardware-store"}}, "[/color]"}}
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
            
            local c1 = tbl.add{type = "label", caption = "[item=" .. resource .. "]"}
            c1.style.padding = 5
            c1.style.minimal_width = 100
            local c2 = tbl.add{type = "label", caption = {"", {"?", {itemName}, {fallbackName}}}}
            c2.style.padding = 5
            c2.style.minimal_width = 100
            local c3 = tbl.add{type = "label", caption = {"", "[color=" .. color .. "]", amounts.provided, "[/color]"}}
            c3.style.padding = 5
            c3.style.minimal_width = 100
            local c4 = tbl.add{type = "label", caption = "[item=tycoon-currency] " .. getItemPrice(resource)}
            c4.style.padding = 5
            c4.style.minimal_width = 100
        end
    end

    constructionGui.add{type = "line"}

    constructionGui.add{type = "label", caption = {"", {"tycoon-gui-construction-requirement-1"}}}
    constructionGui.add{type = "label", caption = {"", {"tycoon-gui-construction-requirement-2"}}}

    constructionGui.add{type = "line"}

    local lowerTierMap = {
        residential = "simple",
        highrise = "residential",
    }

    if housingType ~= "simple" then
        local lowerTierCount = ((city.buildingCounts or {})[lowerTierMap[housingType]] or 0)
        local higherTierCount = ((city.buildingCounts or {})[housingType] or 0)
        local numberOfLowerTierHousesNeeded = Util.countPendingLowerTierHouses(lowerTierCount, higherTierCount, house_ratios[housingType])

        if numberOfLowerTierHousesNeeded > 0 then
            constructionGui.add{type = "label", caption = {"", "[color=red]", {"tycoon-gui-grow-other-housing-tier", {"", {"technology-name.tycoon-" .. housingType .. "-housing"}}, numberOfLowerTierHousesNeeded, {"", {"technology-name.tycoon-" .. lowerTierMap[housingType] .. "-housing"}}}, "[/color]"}}
        end
    end
end

--- @param rootGui any
--- @param basicNeeds string[]
--- @param city City
--- @param waterTowers any[]
--- @param markets any[]
--- @param housingTier string
local function addBasicNeedsView(rootGui, basicNeeds, city, waterTowers, markets, housingTier)
    local basicNeedsGui = rootGui.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-basic-needs"}}, name = "basic_needs"}
    basicNeedsGui.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle-1"}}}
    basicNeedsGui.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle-2"}}}
    basicNeedsGui.add{type = "label", caption = {"", {"tycoon-gui-consumption-cycle-3"}}}

    basicNeedsGui.add{type = "line"}

    local displayedMissingSuppliers = {}

    local tbl = basicNeedsGui.add{type = "table", column_count = 4, draw_horizontal_lines = true}
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
                tbl.add{type = "label", caption = ""}
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
            if amounts.provided > 0 and amounts.provided < amounts.required then
                color = "orange"
            elseif amounts.provided == 0 then
                color = "red"
            end

            local imgName
            if resource == "water" or resource == "tycoon-milk" then
                imgName = "fluid=" .. resource
            else
                -- Vanilla items like water are not in our localization config, and therefore have to be accessed differently
                imgName = "item=" .. resource
            end
            
            local c1 = tbl.add{type = "label", caption = "[" .. imgName .. "]"}
            c1.style.padding = 5
            c1.style.minimal_width = 100

            local c2 = tbl.add{type = "label", caption = {"", {itemName}}}
            c2.style.padding = 5
            c2.style.minimal_width = 100

            local captionElements = {"", "[color=" .. color .. "]", amounts.provided, "/", amounts.required, "[/color]"}
            if resource == "water" and (amounts.provided == 0 or (amounts.required / amounts.provided) > 0.75) then
                table.insert(captionElements, " ")
                table.insert(captionElements, {"tycoon-gui-add-more-water-towers"})
            end
            local c3 = tbl.add{type = "label", caption = captionElements}
            c3.style.padding = 5
            c3.style.minimal_width = 100
            if resource ~= "water" then
                local c4 = tbl.add{type = "label", caption = "[item=tycoon-currency] " .. getItemPrice(resource)}
                c4.style.padding = 5
                c4.style.minimal_width = 100
            else
                local c5 = tbl.add{type = "label", caption = ""}
                c5.style.padding = 5
                c5.style.minimal_width = 100
            end
        end
    end
end

--- @param rootGui any
--- @param additionalNeeds string[]
--- @param city City
--- @param markets any[]
--- @param housingTier string
local function addAdditionalNeedsView(rootGui, additionalNeeds, city, markets, housingTier)
    if city.stats.additional_needs == nil then
        -- These stats have never been set yet, so there's no way we can display this info.
        -- Todo: move this down and explain why we're not showing it yet.
        return
    end

    local additionalNeedsGui = rootGui.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-additional-needs"}}, name = "additional_needs"}
    additionalNeedsGui.add{type = "label", caption = {"", {"tycoon-gui-additional-needs-consumption"}}}
    additionalNeedsGui.add{type = "line"}

    local displayedMissingSuppliers = {}

    local tbl = additionalNeedsGui.add{type = "table", column_count = 4, draw_horizontal_lines = true}
    for _, resource in ipairs(additionalNeeds) do

        local missingSupplier = nil
        if #markets == 0 then
            missingSupplier = "tycoon-market"
        end

        if missingSupplier ~= nil then
            if displayedMissingSuppliers[missingSupplier] ~= true then
                tbl.add{type = "label", caption = {"", "[color=red]", {"tycoon-gui-missing", {"entity-name." .. missingSupplier}}, "[/color]"}}
                tbl.add{type = "label", caption = ""}
                tbl.add{type = "label", caption = ""}
                tbl.add{type = "label", caption = ""}
                displayedMissingSuppliers[missingSupplier] = true
            end
        elseif city.stats.additional_needs[resource] ~= nil then
            local amounts = city.stats.additional_needs[resource]

            local itemName = resource
            if string.find(resource, "tycoon-", 1, true) then
                itemName = "item-name." .. itemName
            end

            local color = "green"
            if amounts.provided > 0 and amounts.provided < amounts.required then
                color = "orange"
            elseif amounts.provided == 0 then
                color = "red"
            end

            local imgName = "item=" .. resource
            
            local c1 = tbl.add{type = "label", caption = "[" .. imgName .. "]"}
            c1.style.padding = 5
            c1.style.minimal_width = 100

            local c2 = tbl.add{type = "label", caption = {"", {itemName}}}
            c2.style.padding = 5
            c2.style.minimal_width = 100

            local captionElements = {"", "[color=" .. color .. "]", amounts.provided, "/", amounts.required, "[/color]"}
            local c3 = tbl.add{type = "label", caption = captionElements}
            c3.style.padding = 5
            c3.style.minimal_width = 100
            if resource ~= "water" then
                local c4 = tbl.add{type = "label", caption = "[item=tycoon-currency] " .. getItemPrice(resource)}
                c4.style.padding = 5
                c4.style.minimal_width = 100
            else
                local c5 = tbl.add{type = "label", caption = ""}
                c5.style.padding = 5
                c5.style.minimal_width = 100
            end
        end
    end

    additionalNeedsGui.add{type = "line"}
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
        entities = game.surfaces[city.surface_index].find_entities_filtered{
            name=name,
            position=city.center,
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
    residential = {"water", "tycoon-milk-bottle", "tycoon-meat", "tycoon-bread", "tycoon-fish-filet"},
    highrise = {"water", "tycoon-smoothie", "tycoon-apple-cake", "tycoon-cheese", "tycoon-burger", "tycoon-dumpling" }
}

local additionalNeeds = {
    simple = {"tycoon-cooking-pan", "tycoon-cooking-pot", "tycoon-cutlery"},
    residential = {"tycoon-bicycle", "tycoon-candle", "tycoon-soap", "tycoon-gloves", "tycoon-television"},
    highrise = {"tycoon-smartphone", "tycoon-laptop"}
}

local constructionNeeds = {
    simple = {"stone-brick", "iron-plate"},
    residential = {"stone-brick", "iron-plate", "steel-plate", "small-lamp"},
    highrise = {"steel-plate", "small-lamp", "pump", "concrete", "pipe"}
}

local function getSupplyLevelsSummary(supplyLevels)
    local total = 0
    for _, value in pairs(supplyLevels) do
        total = total + value
    end
    local average = total / #supplyLevels
    if average == 1 then
        return "supplied"
    elseif average == 0 then
        return "missing"
    else
        return "lacking"
    end
end

local function mapSupplyLevelToLocalised(supplyLevel)
    if supplyLevel == "supplied" then
        return {"", "[color=green]", {"tycoon-gui-status-supplied"}, "[/color]"}
    elseif supplyLevel == "missing" then
        return {"", "[color=red]", {"tycoon-gui-status-missing"}, "[/color]"}
    else
        return {"", "[color=orange]", {"tycoon-gui-status-lacking"}, "[/color]"}
    end
end

local function areConstructionNeedsMet(city, housingTier, stores) 
    local hardwareStores = stores or listSpecialCityBuildings(city, "tycoon-hardware-store")
    local needs = Constants.CONSTRUCTION_MATERIALS[housingTier]

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

local function areThereEnoughConstructionMaterials(city, housingTier)
    local hardwareStores = listSpecialCityBuildings(city, "tycoon-hardware-store")
    local isMet = areConstructionNeedsMet(city, housingTier, hardwareStores)
    return isMet
end

local function getConstructionMaterialsLevelLocalised(city, housingTier)
    if areThereEnoughConstructionMaterials(city, housingTier) then
        return {"", "[color=green]", {"tycoon-gui-status-supplied"}, "[/color]"}
    else
        return {"", "[color=red]", {"tycoon-gui-status-missing"}, "[/color]"}
    end
end

local lowerTierMap = {
    residential = "simple",
    highrise = "residential"
}

local function get_colouring(isTrue) 
    return isTrue and "[color=green]" or "[color=red]"
end

--- @param city City
--- @param housingType string
local function addHousingView(housingType, city, anchor)
    
    anchor.style.natural_height = 600
    if housingType ~= "simple" and not game.forces.player.technologies["tycoon-" .. housingType .. "-housing"].researched then
        anchor.add{type = "label", caption = {"", "[color=red]", {"tycoon-gui-not-researched"}, "[/color]"}}
        anchor.add{type = "button", caption = "Open Technology", name = "tycoon_open_tech:" .. housingType .. "-housing"}
        return
    end

    local waterTowers = listSpecialCityBuildings(city, "tycoon-water-tower")
    local markets = listSpecialCityBuildings(city, "tycoon-market")
    local hardwareStores = listSpecialCityBuildings(city, "tycoon-hardware-store")

    local tabbed_pane = anchor.add{type="tabbed-pane"}
    local tab_overview = tabbed_pane.add{type="tab", caption={"", {"tycoon-gui-overview"}}}
    local tab_basic_needs = tabbed_pane.add{type="tab", caption={"", {"tycoon-gui-basic-needs"}}}
    local tab_additional_needs = tabbed_pane.add{type="tab", caption={"", {"tycoon-gui-additional-needs"}}}
    local tab_construction_material = tabbed_pane.add{type="tab", caption={"", {"tycoon-gui-construction-materials"}}}

    local overview_container = tabbed_pane.add{type = "flow", direction = "vertical"}
    tabbed_pane.add_tab(tab_overview, overview_container)
    local stats = overview_container.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-stats"}}, name = "city_stats"}
    stats.add{type = "label", caption = {"", {"tycoon-gui-citizens"}, ": ",  countCitizens(city, housingType)}}

    local basicNeedsSupplyLevelsSummary = getSupplyLevelsSummary(Consumption.getSupplyLevels(city, getBasicNeeds(city, housingType)));
    local additionalNeedsSupplyLevelsSummary = getSupplyLevelsSummary(Consumption.getSupplyLevels(city, getAdditionalNeeds(city, housingType)));
    
    local tbl = stats.add{type = "table", column_count = 2, draw_horizontal_lines = true}
    -- overall basic needs status
    tbl.add{type = "label", caption = {"", {"tycoon-gui-basic-needs"}, ": "}}
    tbl.add{type = "label", caption = mapSupplyLevelToLocalised(basicNeedsSupplyLevelsSummary)}
    -- overall additional needs status
    tbl.add{type = "label", caption = {"", {"tycoon-gui-additional-needs"}, ": "}}
    tbl.add{type = "label", caption = mapSupplyLevelToLocalised(additionalNeedsSupplyLevelsSummary)}
    -- overall construction materials status
    tbl.add{type = "label", caption = {"", {"tycoon-gui-construction-materials"}, ": "}}
    tbl.add{type = "label", caption = getConstructionMaterialsLevelLocalised(city, housingType)}

    local construction_info = overview_container.add{type = "frame", direction = "vertical", caption = {"", {"tycoon-gui-construction-info"}}}

    local lowerTierCount = ((city.buildingCounts or {})[lowerTierMap[housingType]] or 0)
    local higherTierCount = ((city.buildingCounts or {})[housingType] or 0)
    local numberOfLowerTierHousesNeeded
    if lowerTierCount == 0 then
        numberOfLowerTierHousesNeeded = house_ratios[housingType] or 0
    else
        numberOfLowerTierHousesNeeded = Util.countPendingLowerTierHouses(lowerTierCount, higherTierCount, house_ratios[housingType])
    end

    local met_hardware_store = #hardwareStores > 0
    local met_construction_material = areThereEnoughConstructionMaterials(city, housingType)
    local met_lower_tier_houses = housingType == "simple" or numberOfLowerTierHousesNeeded == 0

    local construction_info_table = construction_info.add{type = "table", column_count = 3, draw_horizontal_lines = true}

    construction_info_table.add{type = "label", caption = {"", {"item-name.tycoon-hardware-store"}}}
    local hardware_store_status = not met_hardware_store and "tycoon-gui-status-missing" or "tycoon-gui-status-built"
    construction_info_table.add{type = "label", caption = " "}
    construction_info_table.add{type = "label", caption = {"", get_colouring(met_hardware_store), {hardware_store_status},"[/color]"}}

    construction_info_table.add{type = "label", caption = {"", {"tycoon-gui-construction-materials"}}}
    local construction_material_status = met_construction_material and "tycoon-gui-status-supplied" or "tycoon-gui-status-missing"
    construction_info_table.add{type = "label", caption = " "}
    construction_info_table.add{type = "label", caption = {"", get_colouring(met_construction_material), {construction_material_status},"[/color]"}}

    if housingType ~= "simple" then
        construction_info_table.add{type = "label", caption = {"", {"tycoon-gui-lower-tier-houses-requirement"}}}
        construction_info_table.add{type = "label", caption = " "}
        construction_info_table.add{type = "label", caption = {"", get_colouring(met_lower_tier_houses), numberOfLowerTierHousesNeeded,"[/color]"}}
    end

    construction_info_table.add{type = "label", caption = {"", {"tycoon-gui-next-construction"}}}
    construction_info_table.add{type = "label", caption = " "}
    local timer = (city.construction_timers or {})[housingType] or {
        last_construction = 0,
        construction_interval = math.huge
    }
    local remainig_seconds = math.max(math.ceil(((timer.last_construction + timer.construction_interval) - game.tick) / 60), 0)
    local minutes = math.floor(remainig_seconds / 60)
    local seconds = remainig_seconds % 60
    if not (met_hardware_store and met_construction_material and met_lower_tier_houses) or minutes > 30 then
        construction_info_table.add{type = "label", caption = {"", "[color=red]", {"tycoon-housing-missing-prerequisites"}, "[/color]"}}
    elseif minutes > 10 then
        construction_info_table.add{type = "label", caption = {"", "[color=orange]", {"tycoon-housing-construction-time-remaining", string.format("%02d", minutes), string.format("%02d", seconds)},"[/color]"}}
    else
        construction_info_table.add{type = "label", caption = {"", "[color=green]", {"tycoon-housing-construction-time-remaining", string.format("%02d", minutes), string.format("%02d", seconds)},"[/color]"}}
    end

    construction_info.add{type = "label", caption = {"", {"tycoon-gui-boost-construction-speed"}}}
    
    local basic_needs_container = tabbed_pane.add{type = "scroll-pane", direction = "vertical"}
    tabbed_pane.add_tab(tab_basic_needs, basic_needs_container)
    addBasicNeedsView(basic_needs_container, basicNeeds[housingType], city, waterTowers, markets, housingType)

    local advanced_needs_container = tabbed_pane.add{type = "scroll-pane", direction = "vertical"}
    tabbed_pane.add_tab(tab_additional_needs, advanced_needs_container)
    addAdditionalNeedsView(advanced_needs_container, additionalNeeds[housingType], city, markets, housingType)

    local construction_needs_container = tabbed_pane.add{type = "scroll-pane", direction = "vertical"}
    tabbed_pane.add_tab(tab_construction_material, construction_needs_container)
    addConstructionMaterialsGui(construction_needs_container, constructionNeeds[housingType], city, hardwareStores, housingType)
    
    tabbed_pane.selected_tab_index = 1
end

local function getOverallSupplyLevelsSummary(city, needsFn)
    local simpleLevels = Consumption.getSupplyLevels(city, needsFn(city, "simple"))
    local residentialLevels = Consumption.getSupplyLevels(city, needsFn(city, "residential"))
    local highriseLevels = Consumption.getSupplyLevels(city, needsFn(city, "highrise"))

    local simpleLevelSummary = getSupplyLevelsSummary(simpleLevels)
    local residentialLevelSummary = game.forces.player.technologies["tycoon-residential-housing"].researched and getSupplyLevelsSummary(residentialLevels) or "supplied"
    local highriseLevelSymmary = game.forces.player.technologies["tycoon-highrise-housing"].researched and getSupplyLevelsSummary(highriseLevels) or "supplied"

    if simpleLevelSummary == "supplied" and residentialLevelSummary == "supplied" and highriseLevelSymmary == "supplied" then
        return "supplied"
    elseif simpleLevelSummary == "missing" and residentialLevelSummary == "missing" and highriseLevelSymmary == "missing" then
        return "missing"
    else
        return "lacking"
    end
end

local function getOverallAdditionalNeedsCaption(city)
    local supplyLevel = getOverallSupplyLevelsSummary(city, getAdditionalNeeds)
    return mapSupplyLevelToLocalised(supplyLevel)
end

local function getOverallBasicNeedsCaption(city)
    local supplyLevel = getOverallSupplyLevelsSummary(city, getBasicNeeds)
    return mapSupplyLevelToLocalised(supplyLevel)
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
    -- overall additional needs status
    tbl.add{type = "label", caption = {"", {"tycoon-gui-additional-needs"}, ": "}}
    tbl.add{type = "label", caption = getOverallAdditionalNeedsCaption(city)}
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
    
    Consumption.updateNeeds(city)

    local tabbed_pane = anchor.add{type="tabbed-pane"}
    local tab_overview = tabbed_pane.add{type="tab", caption={"", {"tycoon-gui-city-overview"}}}
    local tab_simple = tabbed_pane.add{type="tab", caption={"", {"technology-name.tycoon-simple-housing"}}}
    local tab_residential = tabbed_pane.add{type="tab", caption={"", {"technology-name.tycoon-residential-housing"}}}
    local tab_highrise = tabbed_pane.add{type="tab", caption={"", {"technology-name.tycoon-highrise-housing"}}}

    local overviewContainer = tabbed_pane.add{type = "flow", direction = "vertical"}
    tabbed_pane.add_tab(tab_overview, overviewContainer)
    addCityOverview(city, overviewContainer)
    
    local simpleContainer = tabbed_pane.add{type = "scroll-pane", direction = "vertical"}
    tabbed_pane.add_tab(tab_simple, simpleContainer)
    addHousingView("simple", city, simpleContainer)
    
    local residentialContainer = tabbed_pane.add{type = "scroll-pane", direction = "vertical"}
    tabbed_pane.add_tab(tab_residential, residentialContainer)
    addHousingView("residential", city, residentialContainer)
    
    local highriseContainer = tabbed_pane.add{type = "scroll-pane", direction = "vertical"}
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
    local c1 = tbl.add{type = "label", caption = {"", {"tycoon-gui-name"}}}
    c1.style.width = columnWidth
    local c2 = tbl.add{type = "label", caption =  {"", {"tycoon-gui-citizens"}}}
    c2.style.width = columnWidth
    local c3 = tbl.add{type = "label", caption =  {"", {"tycoon-gui-basic-needs-met"}}}
    c3.style.width = columnWidth + 50
    local c4 = tbl.add{type = "label", caption = ""}
    c4.style.width = columnWidth
    for i, city in ipairs(global.tycoon_cities or {}) do
        tbl.add{type = "label", caption = {"", "[font=default-bold]", city.name, "[/font]"}}
        tbl.add{type = "label", caption = countCitizens(city)}
        tbl.add{type = "label", caption = getOverallBasicNeedsCaption(city)}
        tbl.add{type = "button", caption = {"", {"tycoon-gui-show-details"}}, name = "multiple_cities_select_tab:" .. i, tags = {selected_tab = i + 1}}
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
