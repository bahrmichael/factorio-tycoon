local Util = require("util")
local Gui = require("gui")
local GuiState = require("gui-state")

local function on_gui_opened(event)
    if (event.entity or {}).name == "tycoon-town-hall" then
        local player = game.players[event.player_index]
        local unit_number = event.entity.unit_number
        local city = Util.findCityByTownHallUnitNumber(unit_number)
        assert(city ~= nil, "Could not find the city for town hall unit number ".. unit_number)

        local guiKey = "city_overview"
        local cityGui = player.gui.relative[guiKey]
        if cityGui ~= nil then
            -- Clear any previous gui so that we can fully reconstruct it
            cityGui.destroy()
        end

        local anchor = {
            gui = defines.relative_gui_type.container_gui,
            name = "tycoon-town-hall",
            position = defines.relative_gui_position.right
        }
        cityGui = player.gui.relative.add{
            type = "frame",
            anchor = anchor,
            caption = city.name,
            direction = "vertical",
            name = guiKey
        }

        Gui.addCityView(city, cityGui, event.player_index)
    elseif (event.entity or {}).name == "tycoon-passenger-train-station" then
        local player = game.players[event.player_index]
        local unit_number = event.entity.unit_number

        local guiKey = "train_station_view"
        local trainStationGui = player.gui.relative[guiKey]
        if trainStationGui ~= nil then
            -- clear any previous gui so that we can fully reconstruct it
            trainStationGui.destroy()
        end

        local anchor = {gui = defines.relative_gui_type.container_gui, name = "tycoon-passenger-train-station", position = defines.relative_gui_position.right}
        trainStationGui = player.gui.relative.add{type = "frame", anchor = anchor, caption = {"", {"tycoon-gui-train-station-view"}}, direction = "vertical", name = guiKey}

        local cityId = Util.getGlobalBuilding(unit_number).cityId
        Gui.addTrainStationView(
            unit_number,
            trainStationGui,
            Util.findCityById(cityId)
        )
    elseif (event.entity or {}).name == "tycoon-treasury" then
        local player = game.players[event.player_index]
        local unit_number = event.entity.unit_number

        local guiKey = "treasury_view"
        local treasuryGui = player.gui.relative[guiKey]
        if treasuryGui ~= nil then
            -- clear any previous gui so that we can fully reconstruct it
            treasuryGui.destroy()
        end

        local anchor = {gui = defines.relative_gui_type.container_gui, name = "tycoon-treasury", position = defines.relative_gui_position.right}
        treasuryGui = player.gui.relative.add{type = "frame", anchor = anchor, caption = {"", {"tycoon-gui-treasury-view"}}, direction = "vertical", name = guiKey}

        local cityId = Util.getGlobalBuilding(unit_number).cityId
        Gui.addTreasuryView(
            unit_number,
            treasuryGui,
            Util.findCityById(cityId)
        )
    elseif event.entity ~= nil and Util.isSupplyBuilding(event.entity.name) then
        local player = game.players[event.player_index]

        local unit_number = event.entity.unit_number
        local cityName = Util.findCityNameByEntityUnitNumber(unit_number)

        local guiKey = "supply_building_view"
        local supplyBuildingView = player.gui.relative[guiKey]
        if supplyBuildingView ~= nil then
            -- clear any previous gui so that we can fully reconstruct it
            supplyBuildingView.destroy()
        end

        local gui_type = defines.relative_gui_type.container_gui
        if event.entity.name == "tycoon-water-tower" then
            gui_type = defines.relative_gui_type.storage_tank_gui
        end
        local anchor = {
            gui = gui_type,
            name = event.entity.name,
            position = defines.relative_gui_position.right
        }
        supplyBuildingView = player.gui.relative.add{
            type = "frame",
            anchor = anchor,
            caption = {"", {"entity-name." .. event.entity.name}},
            direction = "vertical",
            name = guiKey
        }

        Gui.addSupplyBuildingOverview(supplyBuildingView, cityName)
    end
end

local function on_gui_text_changed(event)
    if string.find(event.element.name, "train_station_limit", 1, true) then
        local trainStationUnitNumber = tonumber(Util.splitString(event.element.name, ":")[2])
        assert(trainStationUnitNumber, "Failed to resolve train station unit number in on_gui_text_changed.")
        storage.tycoon_train_station_limits[trainStationUnitNumber] = math.min(tonumber(event.text) or 0, 100)
    end
end

local function on_gui_click(event)
    local player = game.players[event.player_index]
    local element = event.element

    if element.name == "" then
        return
    end

    local elementNameParts = Util.splitString(element.name, ":")

    if elementNameParts[1] == "tycoon_open_tech" then
        player.open_technology_gui("tycoon-" .. elementNameParts[2])
    elseif elementNameParts[1] == "close_multiple_cities_overview" then
        element.parent.parent.destroy()
    elseif elementNameParts[1] == "multiple_cities_select_tab" then
        if element.type == "button" then
            local selectedTab = tonumber(elementNameParts[2]) + 1
            local guiKey = "multiple_cities_overview"
            local gui = player.gui.center[guiKey]
            gui.children[2].selected_tab_index = selectedTab
            GuiState.set_state(event.player_index, "city_tab", selectedTab)
        else
            GuiState.set_state(event.player_index, "city_tab", element.parent.selected_tab_index)
        end
    elseif elementNameParts[1] == "city_tab" then
        local city_tab = tonumber(elementNameParts[2])
        GuiState.set_state(event.player_index, "city_tab", city_tab)
        if elementNameParts[3] == "housing_tab" then
            GuiState.set_state(event.player_index, "city_tab:" .. city_tab .. ":housing_tab", tonumber(elementNameParts[4]))
            if elementNameParts[5] == "needs_tab" then
                GuiState.set_state(event.player_index, "city_tab:" .. city_tab .. ":housing_tab:" .. elementNameParts[4] .. ":needs_tab", tonumber(elementNameParts[6]))
            end
        end

    end
end

local function on_gui_checked_state_changed_train_station(event)
    local element = event.element
    local tags = element.tags
    local destination_city_id = tags.destination_city_id
    local train_station_unit_number = tags.train_station_unit_number
    if destination_city_id and train_station_unit_number then
        if storage.tycoon_train_station_passenger_filters == nil then
            storage.tycoon_train_station_passenger_filters = {}
        end
        if storage.tycoon_train_station_passenger_filters[train_station_unit_number] == nil then
            storage.tycoon_train_station_passenger_filters[train_station_unit_number] = {}
        end
        storage.tycoon_train_station_passenger_filters[train_station_unit_number][destination_city_id] = element.state
    end
end

local function on_gui_checked_state_changed_treasury(event)
    local element = event.element

    local elementNameParts = Util.splitString(element.name, ":")
    local treasuryUnitNumber = tonumber(elementNameParts[2])

    assert(treasuryUnitNumber, "Failed to resolve treasury unit number in on_gui_checked_state_changed_treasury.")

    local isChecked = element.state

    storage.tycoon_money_stacks_treasury_enabled[treasuryUnitNumber] = isChecked
end

local function on_gui_checked_state_changed(event)
    local element = event.element
    if string.find(element.name, "train_station_gui_checkbox", 1, true) then
        on_gui_checked_state_changed_train_station(event)
    elseif string.find(element.name, "treasury_money_stack_enabled", 1, true) then
        on_gui_checked_state_changed_treasury(event)
    end
end

local function on_gui_closed(event)
    local player = game.players[event.player_index]

    -- Close city overview
    if player.gui.relative["city_overview"] then
        player.gui.relative["city_overview"].destroy()
    end

    -- -- Close multiple cities overview
    if player.gui.center["multiple_cities_overview"] then
        player.gui.center["multiple_cities_overview"].destroy()
    end
end


return {
    on_gui_opened = on_gui_opened,
    on_gui_text_changed = on_gui_text_changed,
    on_gui_click = on_gui_click,
    on_gui_checked_state_changed = on_gui_checked_state_changed,
    on_gui_closed = on_gui_closed,
}
