require "util"
require "story"

local function think(color, title, thought)
    game.players[1].print({"","[img=entity/character][color=" .. color .. "]",{title .. "-title"},": [/color]",{"think-"..thought}})
end

local function findSpecialBuilding(name)
    for _, building in ipairs(global.tycoon_cities[1].special_buildings.others) do
        if building.name == name then
            return building.entity
        end
    end
    return nil
end

local story_table =
{
  {
	{  
      action = function()
        global.tycoon_city_building = false
        global.tycoon_cities[1].basicNeeds = {
            market = {},
            waterTower = {}
        }

        local character = game.players[1]
        character.insert{name = "inserter", count = 5}
        character.insert{name = "iron-gear-wheel", count = 47}
        character.insert{name = "pistol", count = 1}
        character.insert{name = "firearm-magazine", count = 1}
        character.insert{name = "electronic-circuit", count = 90}
        character.insert{name = "copper-cable", count = 38}
        character.insert{name = "solar-panel", count = 10}
        character.insert{name = "small-electric-pole", count = 50}

        character.insert{name = "stone", count = 500}
        character.insert{name = "iron-plate", count = 1000}
        character.insert{name = "pipe", count = 1000}

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
           think("green", "crew-member", "story-4")
        end
    },
    {
        condition = story_elapsed_check(4),
        action =
        function()
           think("blue", "captain", "story-5")
        end
    },
    {
        condition = story_elapsed_check(1),
        action =
        function()
            global.tycoon_city_consumption = {
                {
                    resource = "stone",
                    amount = 1
                }
            }
          set_goal({"deliver-initial-stone", 10})
        end
    }, 
    {
        condition = function() 
            return global.tycoon_cities[1].special_buildings.town_hall ~= nil and global.tycoon_cities[1].special_buildings.town_hall.get_item_count("stone") >= 10
        end,
        action = function()
            set_goal("")
            table.insert(global.tycoon_cities[1].priority_buildings, {name = "tycoon-water-tower", priority = 10})
            global.tycoon_city_building = true
            think("green", "crew-member", "story-6")
        end
    },
    {
        condition = function() 
            return global.tycoon_cities[1].special_buildings.town_hall.get_item_count("stone") == 0
        end,
        action =
        function()
            global.tycoon_city_building = false
           think("green", "crew-member", "story-7")
        end
    },
    {
        condition = story_elapsed_check(3),
        action =
        function()
           think("blue", "captain", "story-8")
           global.tycoon_city_consumption = {
                {
                    resource = "stone",
                    amount = 1
                },
                {
                    resource = "iron-plate",
                    amount = 1
                }
            }
           set_goal({"deliver-initial-iron-and-stone", 20, 20})
        end
    },
    {
        condition = function() 
            return global.tycoon_cities[1].special_buildings.town_hall.get_item_count("stone") >= 20 and global.tycoon_cities[1].special_buildings.town_hall.get_item_count("iron-plate") >= 20
        end,
        action = function()
            set_goal("")
            think("green", "crew-member", "story-9")
            global.tycoon_city_building = true
            table.insert(global.tycoon_cities[1].priority_buildings, {name = "tycoon-market", priority = 10})
            table.insert(global.tycoon_cities[1].priority_buildings, {name = "tycoon-treasury", priority = 5})
        end
    },
    {
        condition = story_elapsed_check(4),
        action =
        function()
           think("blue", "captain", "story-10")
           set_goal({"supply-water"})
        end
    },
    {
        condition = function() 
            local waterTower = findSpecialBuilding("tycoon-water-tower")
            return waterTower ~= nil and (waterTower.get_fluid_contents().water or 0) > 50
        end,
        action = function()
            set_goal("")
            global.tycoon_water_consumption = 1
            global.tycoon_enable_water_consumption = 1
            think("green", "crew-member", "story-11")
        end
    },
    {
        condition = story_elapsed_check(5),
        action =
        function()
           think("green", "crew-member", "story-12")
        end
    },
    {
        condition = story_elapsed_check(2),
        action =
        function()
           think("blue", "captain", "story-13")
           -- todo: instead of clearing the area, try to find a spot where we can place it freely
           local function clearArea(area)
                local removables = game.surfaces[1].find_entities_filtered({area=area})
                for _, entity in pairs(removables) do
                    if entity.valid and entity.name ~= "character" and entity.name ~= "town-hall" and entity.name ~= "tycoon-water-tower" then
                        entity.destroy()
                    end
                end
            end
            clearArea({
                {0 - 5, global.tycoon_city_size_tiles + 15},
                {0 + 5, global.tycoon_city_size_tiles + 25},
            })
           local appleFarm = game.surfaces[1].create_entity{
                name = "tycoon-apple-farm",
                position = {x = 0, y = global.tycoon_city_size_tiles + 20},
                force = "player"
            }
            global.tycoon_apple_farm = appleFarm
        end
    },
    {
        condition = story_elapsed_check(4),
        action =
        function()
           think("blue", "captain", "story-14")
           set_goal({"supply-apple-farm"})
        end
    },
    {
        condition = function() 
            return not global.tycoon_apple_farm.get_output_inventory().is_empty()
        end,
        action = function()
            think("blue", "captain", "story-15")
            set_goal({"supply-city-with-apples"})
        end
    },
    {
        condition = function() 
            local market = findSpecialBuilding("tycoon-market")
            return market ~= nil and market.get_item_count("tycoon-apple") > 0
        end,
        action = function()
            global.tycoon_cities[1].basicNeeds = {
                market = {
                    {
                        amount = 1,
                        resource = "tycoon-apple",
                    },
                },
                waterTower = {
                    amount = 10,
                    resource = "water",
                }
            }

            set_goal("")
            think("green", "crew-member", "story-16")
        end
    },
    {
        condition = story_elapsed_check(4),
        action =
        function()
           think("blue", "captain", "story-17")
        end
    },
    {
        condition = story_elapsed_check(3),
        action =
        function()
           think("green", "crew-member", "story-18")
        end
    },
    {
        condition = story_elapsed_check(4),
        action =
        function()
           think("blue", "captain", "story-19")
           set_goal({"build-university"})
        end
    },
    {
        condition = function ()
            return game.surfaces[1].count_entities_filtered{name="tycoon-university"} > 0
        end,
        action =
        function()
           think("blue", "captain", "story-20")
           set_goal({"fund-research"})
        end
    },
    {
        condition = function ()
            local university = game.surfaces[1].find_entities_filtered{name="tycoon-university"}[1]
            return not university.get_output_inventory().is_empty()
        end,
        action =
        function()
           think("blue", "captain", "story-21")
           set_goal("")
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

--   game.map_settings.enemy_expansion.enabled = false
--   game.forces.enemy.evolution_factor = 0
--   game.map_settings.enemy_evolution.enabled = false
  --game.disable_tips_and_tricks()
  -- game.players[1].force.disable_all_prototypes()
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