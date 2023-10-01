require "util"
require "story"

local function think(color, title, thought)
    game.players[1].print({"","[img=entity/character][color=" .. color .. "]",{title .. "-title"},": [/color]",{"think-"..thought}})
end

local function listSpecialCityBuildings(city, name)
    -- Support for savegames <= 0.0.14
    if city.special_buildings.other == nil then
        city.special_buildings.other = {}
    end

    if city.special_buildings.other[name] ~= nil then
        return city.special_buildings.other[name]
    end
    local entities = game.surfaces[1].find_entities_filtered{
        name=name,
        position=city.special_buildings.town_hall.position,
        radius=1000
    }
    city.special_buildings.other[name] = entities
    return entities
end

local story_table =
{
  {
	{
      action = function()
        set_info()
      end
    },
    {
      condition = story_elapsed_check(1),
      action =
      function()
         think("blue", "captain", "story-1")
      end
    },
    {
        condition = story_elapsed_check(4),
        action =
        function()
           think("green", "crew-member", "story-2")
        end
    },
    {
        condition = story_elapsed_check(5),
        action =
        function()
           think("blue", "captain", "story-3")
        end
    },
    {
        condition = story_elapsed_check(6),
        action =
        function()
            local townHall = global.tycoon_cities[1].special_buildings.town_hall
            assert(townHall ~= nil, "Town hall should have been created.")
            townHall.insert{name="pipe", count=50}
            townHall.insert{name="pipe-to-ground", count=30}
            townHall.insert{name="iron-plate", count=200}
            townHall.insert{name="stone", count=200}
            townHall.insert{name="inserter", count=10}
            townHall.insert{name="offshore-pump", count=2}
            townHall.insert{name="solar-panel", count=10}
            townHall.insert{name="medium-electric-pole", count=50}
            townHall.insert{name="electric-furnace", count=2}
            townHall.insert{name="electric-mining-drill", count=2}
            townHall.insert{name="transport-belt", count=100}
            townHall.insert{name="car", count=1}
            townHall.insert{name="wood", count=30}
            think("green", "crew-member", "story-4")
        end
    },
    {
        condition = story_elapsed_check(2),
        action =
        function()
            game.show_message_dialog{text = {"tycoon-story-starter-items-in-town-hall"}}
        end
    },
    {
        condition = story_elapsed_check(4),
        action =
        function()
           think("blue", "captain", "story-5")
           set_goal({"goal-craft-item", {"item-name.tycoon-water-tower"}})
        end
    },
    {
        condition =
        function()
            return game.players[1].get_item_count("tycoon-water-tower") > 0
        end,
        action =
        function()
            think("blue", "captain", "story-6")
            set_goal({"goal-place-water-tower"})
        end
    },
    {
        condition = function() 
            local waterTowers = listSpecialCityBuildings(global.tycoon_cities[1], "tycoon-water-tower")
            for _, waterTower in ipairs(waterTowers) do
                if (waterTower.get_fluid_contents().water or 0) > 0 then
                    return true
                end
            end
            return false
        end,
        action = function()
            set_goal("")
            think("green", "crew-member", "story-7")
            global.tycoon_new_primary_industries = {{name = "tycoon-apple-farm", startCoordinates = { x = 0, y = 60}}}
        end
    },
    {
        condition = story_elapsed_check(4),
        action =
        function()
           think("blue", "captain", "story-8")
           set_goal({"goal-supply-apple-farm"})
           game.show_message_dialog{text = {"tycoon-story-finding-primary-industries"}}
        end
    },
    {
        condition = function() 
            local appleFarms = game.surfaces[1].find_entities_filtered{name="tycoon-apple-farm"}
            for _, appleFarm in ipairs(appleFarms) do
                local hasOutput = not appleFarm.get_output_inventory().is_empty()
                if hasOutput then
                    return true
                end
            end
            return false
        end,
        action = function()
            think("blue", "captain", "story-9")
            set_goal("")
        end
    },
    {
        condition = story_elapsed_check(4),
        action =
        function()
           think("blue", "captain", "story-10")
           set_goal({"goal-supply-apples", 10})
        end
    },
    {
        condition = function() 
            local markets = listSpecialCityBuildings(global.tycoon_cities[1], "tycoon-market")
            for _, market in ipairs(markets) do
                if market.get_item_count("tycoon-apple") >= 10 then
                    return true
                end
            end
            return false
        end,
        action = function()
            set_goal("")
            think("green", "crew-member", "story-11")
        end
    },
    {
        condition = story_elapsed_check(8),
        action =
        function()
           think("blue", "captain", "story-12")
           set_goal({"goal-craft-item", {"item-name.tycoon-hardware-store"}})
        end
    },
    {
        condition =
        function()
            return game.players[1].get_item_count("tycoon-hardware-store") > 0
        end,
        action =
        function()
            set_goal({"goal-place-hardware-store"})
        end
    },
    {
        condition =
        function()
            local hardwareStores = listSpecialCityBuildings(global.tycoon_cities[1], "tycoon-hardware-store")
            return #hardwareStores > 0
        end,
        action =
        function()
            think("blue", "captain", "story-13")
            set_goal({"goal-supply-city-with-hardware", 20, 20})
            table.insert(global.tycoon_cities[1].priority_buildings, {name = "tycoon-treasury", priority = 10})
        end
    },
    {
        condition =
        function()
            local hardwareStores = listSpecialCityBuildings(global.tycoon_cities[1], "tycoon-hardware-store")
            for _, hardwareStore in ipairs(hardwareStores) do
                if hardwareStore.get_item_count("iron-plate") >= 20 and hardwareStore.get_item_count("stone") >= 20 then
                    return true
                end
            end
            return false
        end,
        action =
        function()
            think("green", "crew-member", "story-14")
            set_goal("")
        end
    },
    {
        condition =
        function()
            local treasuries = listSpecialCityBuildings(global.tycoon_cities[1], "tycoon-treasury")
            return #treasuries > 0
        end,
        action =
        function()
           think("green", "crew-member", "story-15")
        end
    },
    {
        condition = story_elapsed_check(4),
        action =
        function()
           think("blue", "captain", "story-16")
           set_goal({"goal-build-university"})
        end
    },
    {
        condition = function ()
            return game.surfaces[1].count_entities_filtered{name="tycoon-university"} > 0
        end,
        action =
        function()
           think("blue", "captain", "story-17")
           set_goal({"goal-fund-research"})
        end
    },
    {
        condition = function ()
            local universities = game.surfaces[1].find_entities_filtered{name="tycoon-university"}

            for _, university in ipairs(universities) do
                if not university.get_output_inventory().is_empty() then
                    return true
                end
            end
            return false
        end,
        action =
        function()
           think("blue", "captain", "story-18")
           set_goal("")
        end
    },
    {
        condition = story_elapsed_check(10),
        action =
        function()
           think("blue", "captain", "story-19")
           set_goal({"", {"goal-grow-city", 100}})
        end
    },
    {
        condition = story_elapsed_check(4),
        action =
        function()
            -- todo: introduce gui element on town hall to show if it has enough construction material
            game.show_message_dialog{text = {"tycoon-story-keep-supplying-construction-material"}}
        end
    },
    {
        condition = function ()
            return global.tycoon_cities[1].stats.citizen_count >= 100
        end,
        action =
        function()
           think("blue", "captain", "story-20")
           set_goal({"goal-supply-milk"})
        end
    },
    {
        condition = story_elapsed_check(4),
        action =
        function()
            game.show_message_dialog{text = {"tycoon-story-new-demand-check-town-hall"}}
        end
    },
    {
        condition = function()
            local markets = listSpecialCityBuildings(global.tycoon_cities[1], "tycoon-market")
            for _, market in ipairs(markets) do
                if market.get_item_count("tycoon-milk-bottle") > 0 then
                    return true
                end
            end
            return false
        end,
        action = function()
            think("green", "crew-member", "story-21")
            set_goal({"", {"goal-grow-city", 200}})
        end
    },
    {
        condition = function ()
            return global.tycoon_cities[1].stats.citizen_count >= 200
        end,
        action =
        function()
           think("blue", "captain", "story-22")
           set_goal({"goal-supply-meat"})
        end
    },
    {
        condition = story_elapsed_check(4),
        action =
        function()
            game.show_message_dialog{text = {"tycoon-story-new-demand-check-town-hall"}}
        end
    },
    {
        condition = function()
            local markets = listSpecialCityBuildings(global.tycoon_cities[1], "tycoon-market")
            for _, market in ipairs(markets) do
                if market.get_item_count("tycoon-meat") > 0 then
                    return true
                end
            end
            return false
        end,
        action = function()
            set_goal("")
            think("green", "crew-member", "story-23")
        end
    },
    {
        condition = story_elapsed_check(10),
        action =
        function()
           think("red", "narrator", "story-ending")
        end
    },
    {
        condition = function() 
            return global.tycoon_cities[1].special_buildings.town_hall.get_item_count("stone") == -1
        end,
        action =
        function()
            game.print("Shutdown")
        end
    }
  }
}



story_init_helpers(story_table)

local init = function()
  global.story = story_init()
end

local story_events =
{
  defines.events.on_tick,
  defines.events.on_entity_died,
  defines.events.on_built_entity,
  defines.events.on_player_mined_item,
  defines.events.on_player_mined_entity,
  defines.events.on_sector_scanned,
  defines.events.on_entity_died,
  defines.events.on_entity_damaged,
  defines.events.on_player_died
} 

script.on_event(story_events, function(event)
   if game.players[1].character then
     story_update(global.story, event)
   end
end)

return {
    init
}