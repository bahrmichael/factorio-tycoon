-- util = require "data/tf_util/tf_util"

-- local collision_util = require("collision-mask-util")

-- local drone_layer = collision_util.get_first_unused_layer()

function gaussian (mean, variance)
    return  math.sqrt(-2 * variance * math.log(math.random())) *
            math.cos(2 * math.pi * math.random()) + mean
  end
local random_height = gaussian(90, 10) / 100

local base = util.copy(data.raw.character.character)

data:extend
{
    {
        type = "unit",
        name = "tycoon-mining-drone",
        -- localised_name = {"", {"mining-drone"}, " (", item or "eh", ")"},
        icon = "__Mining_Drones_Remastered__/data/icons/mining_drone.png",
        icon_size = 64,
        icons = {
          {
            icon = "__Mining_Drones_Remastered__/data/icons/mining_drone.png",
            icon_size = 64,
          }
        },
        flags = {"placeable-off-grid", "hidden", "not-in-kill-statistics"},
        -- map_color = {r ^ 0.5, g ^ 0.5, b ^ 0.5, 0.5},
        -- enemy_map_color = {r = 1},
        max_health = 150,
        radar_range = 1,
        -- order="zzz-"..bot_name,
        --subgroup = "iron-units",
        -- healing_per_tick = 0.1,
        --minable = {result = name, mining_time = 2},
        collision_box = {{-0.18, -0.18}, {0.18, 0.18}},
        collision_mask = {"consider-tile-transitions", "doodad-layer", "object-layer"},
        --render_layer = "object",
        render_layer = "lower-object-above-shadow",
        -- max_pursue_distance = 64,
        resistances = nil,
        -- min_persue_time = 60 * 15,
        selection_box = {{-0.3, -0.3}, {0.3, 0.3}},
        sticker_box = {{-0.3, -1}, {0.2, 0.3}},
        distraction_cooldown = (15),
        move_while_shooting = false,
        can_open_gates = true,
        not_controllable = true,
        ai_settings =
        {
          do_separation = false
        },
        attack_parameters =
        {
          type = "projectile",
          ammo_category = "bullet",
          warmup = 0,
          cooldown = 0,
          range = 0.5,
          ammo_type =
          {
            category = "bullet",
            target_type = "entity",
            action =
            {
              type = "direct",
              action_delivery =
              {
                {
                  type = "instant",
                  target_effects =
                  {
                    {
                      type = "damage",
                      damage = {amount = 0 , type = "physical"}
                    }
                  }
                }
              }
            }
          },
          animation = base.animations[1].mining_with_tool
        },
        vision_distance = 100,
        has_belt_immunity = true,
        affected_by_tiles = true,
        movement_speed = 0.05 * random_height,
        distance_per_frame = 0.05 / random_height,
        pollution_to_join_attack = 1000000,
        -- corpse = bot_name.."-corpse",
        run_animation = base.animations[1].running,
        rotation_speed = 0.05 / random_height,
        -- light =
        -- {
        --   {
        --     minimum_darkness = 0.3,
        --     intensity = 0.4,
        --     size = 15 * random_height,
        --     color = {r=1.0, g=1.0, b=1.0}
        --   },
        --   {
        --     type = "oriented",
        --     minimum_darkness = 0.3,
        --     picture =
        --     {
        --       filename = "__core__/graphics/light-cone.png",
        --       priority = "extra-high",
        --       flags = { "light" },
        --       scale = 2,
        --       width = 200,
        --       height = 200
        --     },
        --     shift = {0, -7 * random_height},
        --     size = 1 * random_height,
        --     intensity = 0.6,
        --     color = {r=1.0, g=1.0, b=1.0}
        --   }
        -- },
        -- running_sound_animation_positions = {5, 16},
        -- walking_sound = sound_enabled and
        -- {
        --   aggregation =
        --   {
        --     max_count = 2,
        --     remove = true
        --   },
        --   variations = sound
        -- } or nil
      }
}