local function createHouse(name)
  return {
    type = "container",
    name = "tycoon-" .. name,
    icon = "__tycoon__/graphics/icons/house-simple.png",
    icon_size = 64,
    max_health = 500,
    rotatable = false,
    minable = {
      mining_time = 1,  -- Adjust the mining time as you see fit
      results = {}  -- Empty table means no items will be returned
    },
    inventory_size = 0,
    corpse = "small-remnants",
    vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
    repair_sound = {filename = "__base__/sound/manual-repair-simple.ogg"},
    open_sound = {filename = "__base__/sound/machine-open.ogg", volume = 0.85},
    close_sound = {filename = "__base__/sound/machine-close.ogg", volume = 0.75},
    collision_box = { { -1.9, -1.9}, {1.9, 1.9} },
    selection_box = { { -1.9, -1.9}, {1.9, 1.9} },
    picture = {
        layers = {
            {
                filename = "__tycoon__/graphics/entity/" .. name .. "/" .. name .. ".png",
                priority = "high",
                width = 200,
                height = 200,
                scale = 0.8,
                shift = {0, 0}
            },
        }
    },
    working_sound = {
      sound = {
          variations = {
              {
                  filename = "__tycoon__/sound/274349__iamazerrad__crowd-noise-1.wav",
              },
              {
                  filename = "__tycoon__/sound/440949__l_q__amsterdam-background.wav",
              },
              {
                  filename = "__tycoon__/sound/524629__nimlos__barcelona-street-ambience-small-cafeteria-outdoors.wav",
              },
          }
      },
      fade_in_ticks = 10,
      fade_out_ticks = 10,
      max_sounds_per_type = 1
  },
  }
end

for i = 1, 14, 1 do
  data:extend{createHouse("house-simple-" .. i)}
end