
local CityPlanning = require("city-planner")
local RecipeCalculator = require("recipe-calculator")
local GuiEventHandler = require("gui-event-handler")
local ShortcutHandler = require("shortcut-handler")
local ResearchHandler = require("research-event-handler")
local OnPlayerEventHandler = require("player-event-handler")
local OnChunkChartedHandler = require("chunk-charted-handler")
local OnConstructionHandler = require("construction-event-handler")
local Passengers = require("passengers")
local ChatMessages = require("chat-messages")
local Consumption = require("consumption")
local City = require("city")
local Queue = require("queue")
local PrimaryIndustries = require("primary-industries")

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
    for _, city in ipairs(global.tycoon_cities or {}) do
        Passengers.clearPassengers(city)
        Passengers.spawnPassengers(city)
    end
end

local function expand_roads()
    for _, city in ipairs(global.tycoon_cities or {}) do
        if Queue.count(city.buildingLocationQueue) < #city.grid then
            local coordinates = City.growAtRandomRoadEnd(city)
            if coordinates ~= nil then
                City.updatepossibleBuildingLocations(city, coordinates)
            end
        end
    end
end

script.on_nth_tick(FIVE_SECONDS, function()
    expand_roads()
    City.complete_house_construction()
    handle_passengers()
end)

local function add_more_cities()
    if #(global.tycoon_cities or {}) > 0 then
        -- todo: only run this when total population reaches a certain threshold
        CityPlanning.addMoreCities(false)
    end
end

script.on_nth_tick(THIRTY_SECONDS, function()
    City.construct_priority_buildings()
    -- todo: implement me later
    -- rediscover_unused_fields()
    add_more_cities()
    CityPlanning.tag_cities()
end)

local function display_intro_messages()
    ChatMessages.show_info_messages()
end

local housing_tiers = {"simple", "residential", "highrise"}

local function consume_resources()
    for _, city in ipairs(global.tycoon_cities or {}) do
        Consumption.consumeBasicNeeds(city)
        Consumption.consumeAdditionalNeeds(city)

        for _, tier in ipairs(housing_tiers) do
            Consumption.update_construction_timers(city, tier)
        end

    end
end

local function return_urban_planning_center_currency()
    if global.tycoon_urban_planning_center_currency_pending ~= nil then

        local city = (global.tycoon_cities or {})[1]
        if city == nil then
            -- Not planning to localise this as it should rarely happen and is just a temporary migration
            game.print({"", "[color=orange]Factorio Tycoon:[/color] ", "With the new version we removed the urban planning centers, but were not able to return the currency. We're sorry about that!"})
            global.tycoon_urban_planning_center_currency_pending = nil
            return
        end
        local treasuries = City.list_special_city_buildings(city, "tycoon-treasury")
        if #treasuries == 0 then
            -- Not planning to localise this as it should rarely happen and is just a temporary migration
            game.print({"", "[color=orange]Factorio Tycoon:[/color] ", "With the new version we removed the urban planning centers, but were not able to return the currency. We're sorry about that!"})
            global.tycoon_urban_planning_center_currency_pending = nil
            return
        else
            if global.tycoon_urban_planning_center_currency_info == nil then
                game.print({"", "[color=orange]Factorio Tycoon:[/color] ", "We're returning all currency from urban planning centers to your first treasury. Please make sure you have enough free space in your first treasury."})
                global.tycoon_urban_planning_center_currency_info = True
            end
            local treasury = treasuries[1]
            local inserted_count = treasury.insert{name = "tycoon-currency", count = global.tycoon_urban_planning_center_currency_pending}
            global.tycoon_urban_planning_center_currency_pending = global.tycoon_urban_planning_center_currency_pending - inserted_count
            if global.tycoon_urban_planning_center_currency_pending <= 0 then
                game.print({"", "[color=orange]Factorio Tycoon:[/color] ", "Completed returning all currency from urban planning centers to your first treasury."})
                global.tycoon_urban_planning_center_currency_pending = nil
                global.tycoon_urban_planning_center_currency_info = nil
                return
            end
        end


    end
    -- todo: display message about returning currency
end

script.on_nth_tick(ONE_MINUTE, function()
    consume_resources()
    City.construct_gardens()
    display_intro_messages()

    -- Drop this migration mechanism with version 0.6 or 0.7
    return_urban_planning_center_currency()
end)

--- EVENT HANDLERS
script.on_event({
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity
}, function(event)
    OnConstructionHandler.on_built(event)
end)

script.on_event({
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    -- Register entities with script.register_on_entity_destroyed(entity) so that this event fires.
    defines.events.on_entity_destroyed,
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
    global.tycoon_global_generator = game.create_random_generator()
    global.tycoon_city_buildings = {}
end)

script.on_event(defines.events.on_gui_opened, function (event)
    GuiEventHandler.on_gui_opened(event)
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
    GuiEventHandler.on_gui_text_changed(event)
end)

script.on_event(defines.events.on_gui_click, function(event)
    GuiEventHandler.on_gui_click(event)
end)

script.on_event(defines.events.on_gui_checked_state_changed, function(event)
    GuiEventHandler.on_gui_checked_state_changed(event)
end)

--- REMOTE INTERFACES
remote.add_interface("tycoon", {
    spawn_city = CityPlanning.addCity,
    calculate_recipes = RecipeCalculator.calculateAllRecipes
})