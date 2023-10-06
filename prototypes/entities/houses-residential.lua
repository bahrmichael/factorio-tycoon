local function createHouse(name)
  return {
    type = "container",
    name = "tycoon-" .. name,
    icon = "__tycoon__/graphics/entity/" .. name .. "/" .. name .. ".png",
    icon_size = 64,
    max_health = 1000,
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
    collision_box = { { -2, -2}, {2.5, 2.5} },
    selection_box = { { -2, -2}, {3, 3} },
    picture = {
        layers = {
            {
                filename = "__tycoon__/graphics/entity/" .. name .. "/" .. name .. ".png",
                priority = "high",
                width = 125,
                height = 160,
                scale = 1.9,
                shift = {0.5, -1.6}
            },
        }
    },
  }
end

for i = 1, 9, 1 do
  data:extend{createHouse("house-residential-" .. i)}
end