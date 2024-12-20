
local CityPlanning = require("city-planner")
local RecipeCalculator = require("recipe-calculator")
local GuiEventHandler = require("gui-event-handler")
local ShortcutHandler = require("shortcut-handler")
local ResearchHandler = require("research-event-handler")
local OnPlayerEventHandler = require("player-event-handler")
local OnChunkChartedHandler = require("chunk-charted-handler")
local OnConstructionHandler = require("construction-event-handler")
local SurfaceEventHandler = require("surface-event-handler")
local Passengers = require("passengers")
local ChatMessages = require("chat-messages")
local Consumption = require("consumption")
local City = require("city")
local Queue = require("queue")
local PrimaryIndustries = require("primary-industries")
local UsedBottlesStore = require("used-bottles-store")
local FloorUpgradesQueue = require("floor-upgrades-queue")
local Achievements = require("achievements")

--- TICK HANDLERS
local ONE_SECOND = 60;
local FIVE_SECONDS = 5 * ONE_SECOND;
local THIRTY_SECONDS = 30 * ONE_SECOND;
local ONE_MINUTE = 60 * ONE_SECOND;

script.on_nth_tick(ONE_SECOND, function()
    CityPlanning.build_initial_city()
    PrimaryIndustries.spawn_initial_industry()
    City.start_house_construction()
end)

local function handle_passengers()
    for _, city in ipairs(storage.tycoon_cities or {}) do
        Passengers.clearPassengers(city)
        Passengers.spawnPassengers(city)
    end
end

local function expand_roads()
    for _, city in ipairs(storage.tycoon_cities or {}) do
        if Queue.count(city.buildingLocationQueue) < #city.grid then
            local coordinates = City.growAtRandomRoadEnd(city)
            if coordinates ~= nil then
                City.updatePossibleBuildingLocations(city, coordinates)
            end
        end
    end
end

script.on_nth_tick(FIVE_SECONDS, function()
    expand_roads()
    City.complete_house_construction()
    handle_passengers()
    FloorUpgradesQueue.process()

    -- best before return ;)
    Consumption.pay_to_treasury_all()
end)

script.on_nth_tick(THIRTY_SECONDS, function()
    City.construct_priority_buildings()
    CityPlanning.tag_cities()

    storage.tycoon_passenger_transported_count = (storage.tycoon_passenger_transported_count or 10) * 10
    Achievements.check_population_achievements()
    Achievements.check_passenger_transport_achievements()
end)

local function display_intro_messages()
    ChatMessages.show_info_messages()
end

local function consume_resources()
    for _, city in ipairs(storage.tycoon_cities or {}) do
        Consumption.consumeBasicNeeds(city)
        Consumption.consumeAdditionalNeeds(city)
        Consumption.update_construction_timers_all(city)
    end
end

script.on_nth_tick(ONE_MINUTE, function()
    for _, city in pairs(storage.tycoon_cities or {}) do
        UsedBottlesStore.return_used_bottles(city)
    end
    consume_resources()
    City.construct_gardens()
    display_intro_messages()
end)

--- EVENT HANDLERS
script.on_event({
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built
}, function(event)
    OnConstructionHandler.on_built(event, event.name == defines.events.script_raised_built)
end)

script.on_event({
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    -- Register entities with script.register_on_object_destroyed(entity) so that this event fires.
    defines.events.on_entity_destroyed,
    defines.events.script_raised_destroy
}, function(event)
    OnConstructionHandler.on_removed(event)
end)

script.on_event(defines.events.on_chunk_generated, function (event)
    OnChunkChartedHandler.on_chunk_generated(event)
end)

script.on_event(defines.events.on_chunk_charted, function (event)
    OnChunkChartedHandler.on_chunk_charted(event)
end)

script.on_event(defines.events.on_chunk_deleted, function (event)
    OnChunkChartedHandler.on_chunk_deleted(event)
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    OnPlayerEventHandler.on_player_cursor_stack_changed(event)
end)

script.on_event(defines.events.on_research_finished, function(event)
    ResearchHandler.on_research_finished(event)
end)

script.on_event({defines.events.on_lua_shortcut, "tycoon-cities-overview"}, function(event)
    ShortcutHandler.on_shortcut(event)
end)

script.on_init(function()
    storage.tycoon_global_generator = game.create_random_generator()
    storage.tycoon_city_buildings = {}
end)

script.on_event(defines.events.on_gui_opened, GuiEventHandler.on_gui_opened)

script.on_event(defines.events.on_gui_text_changed, GuiEventHandler.on_gui_text_changed)

script.on_event(defines.events.on_gui_click, GuiEventHandler.on_gui_click)

script.on_event(defines.events.on_gui_checked_state_changed, GuiEventHandler.on_gui_checked_state_changed)

script.on_event(defines.events.on_gui_closed, GuiEventHandler.on_gui_closed)

-- surface events
script.on_event(defines.events.on_surface_cleared, SurfaceEventHandler.on_surface_cleared)

script.on_event(defines.events.on_surface_created, SurfaceEventHandler.on_surface_created)

script.on_event(defines.events.on_surface_deleted, SurfaceEventHandler.on_surface_deleted)

script.on_event(defines.events.on_surface_imported, SurfaceEventHandler.on_surface_imported)

script.on_event(defines.events.on_surface_renamed, SurfaceEventHandler.on_surface_renamed)

--- REMOTE INTERFACES
remote.add_interface("tycoon", {
    spawn_city = CityPlanning.addCity,
    calculate_recipes = RecipeCalculator.calculateAllRecipes
})
