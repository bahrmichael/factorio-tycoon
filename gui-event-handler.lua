local Util = require("util")
local Gui = require("gui")

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

        Gui.addCityView(city, cityGui)
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

        local cityId = ((global.tycoon_entity_meta_info or {})[unit_number] or {}).cityId
        Gui.addTrainStationView(
            unit_number,
            trainStationGui,
            Util.findCityById(cityId)
        )
    elseif event.entity ~= nil and Util.isSupplyBuilding(event.entity.name) then
        local player = game.players[event.player_index]
        
        local unit_number = event.entity.unit_number
        local cityName = Util.findCityByEntityUnitNumber(unit_number)

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
        global.tycoon_train_station_limits[trainStationUnitNumber] = math.min(tonumber(event.text) or 0, 100)
    end
end

local function on_gui_click(event)
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
end

local function on_gui_checked_state_changed(event)
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
end

return {
    on_gui_opened = on_gui_opened,
    on_gui_text_changed = on_gui_text_changed,
    on_gui_click = on_gui_click,
    on_gui_checked_state_changed = on_gui_checked_state_changed,
}