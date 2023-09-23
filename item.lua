local function createHouse(name, width, height, scale, shift, inventory_size, selection_box)
  return {
    type = "container",
    name = name,
    icon = "__tycoon__/graphics/entity/" .. name .. "/" .. name .. ".png",
    icon_size = 64,
    max_health = 200,
    inventory_size = inventory_size,
    corpse = "small-remnants",
    vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
    repair_sound = {filename = "__base__/sound/manual-repair-simple.ogg"},
    open_sound = {filename = "__base__/sound/machine-open.ogg", volume = 0.85},
    close_sound = {filename = "__base__/sound/machine-close.ogg", volume = 0.75},
    collision_box = { { -2, -2}, {2.5, 2.5} },
    selection_box = selection_box,
    picture = {
        layers = {
            {
                filename = "__tycoon__/graphics/entity/" .. name .. "/" .. name .. ".png",
                priority = "high",
                width = width,
                height = height,
                scale = scale,
                shift = shift
            },
        }
    },
  }
end

local scaling = 1

for i = 1, 14, 1 do
  data:extend{createHouse("house-residential-" .. i, 200, 200, scaling, {0.5, 0.5}, 0, { { -2, -2}, {3, 3} })}
end

data:extend{createHouse("town-hall", 250, 250, scaling, {0.6, 0}, 100, { { -3, -3}, {4, 4} })}

-- data.raw["assembling-machine"]["assembling-machine-3"].fluid_boxes[1]


data:extend{
  {
    type = "storage-tank",
    name = "water-tower-2",
    icon = "__tycoon__/graphics/entity/water-tower/water-tower.png",
    icon_size = 64,
    max_health = 200,
    fluid_box = table.deepcopy(data.raw["storage-tank"]["storage-tank"].fluid_box),
    collision_box = { { -1.9, -1.9}, {1.9, 1.9} },
    selection_box = { { -1.9, -1.9}, {1.9, 1.9} },
    window_bounding_box = { { -0.125, 0.6875 }, { 0.1875, 1.1875 } },
    pictures = table.deepcopy(data.raw["storage-tank"]["storage-tank"].pictures),
    flow_length_in_ticks = 360,
  }
}


data:extend{
  {
    type = "storage-tank",
    name = "water-tower",
    icon = "__tycoon__/graphics/entity/water-tower/water-tower.png",
    icon_size = 64,
    max_health = 200,
    fluid_box = {
      production_type = "input",
      base_area = 10,
      height = 2,
      base_level = -1,
      pipe_connections = {
        { position = { 2, 0 }, type = "input" },
      },
    },
    collision_box = { { -1.9, -1.9}, {1.9, 1.9} },
    selection_box = { { -1.9, -1.9}, {1.9, 1.9} },
    window_bounding_box = { { -0.125, 0.6875 }, { 0.1875, 1.1875 } },
    pictures = {
      picture = {
        layers = {
          {
            filename = "__tycoon__/graphics/entity/water-tower/water-tower.png",
            priority = "high",
            width = 500,
            height = 500,
            shift = {0, -1},
            scale = 0.5
          }
        }
      },
      fluid_background = {
        filename = "__base__/graphics/entity/storage-tank/fluid-background.png",
        priority = "extra-high",
        width = 32,
        height = 15,
      },
      window_background = {
        filename = "__base__/graphics/entity/storage-tank/window-background.png",
        priority = "extra-high",
        width = 17,
        height = 24,
      },
      flow_sprite = {
        filename = "__base__/graphics/entity/pipe/fluid-flow-low-temperature.png",
        priority = "extra-high",
        width = 160,
        height = 20,
      },
      gas_flow = {
        filename = "__base__/graphics/entity/pipe/steam.png",
        priority = "extra-high",
        line_length = 10,
        width = 24,
        height = 15,
        frame_count = 60,
        axially_symmetrical = false,
        direction_count = 1,
        animation_speed = 0.25,
        hr_version = {
          filename = "__base__/graphics/entity/pipe/hr-steam.png",
          priority = "extra-high",
          line_length = 10,
          width = 48,
          height = 30,
          frame_count = 60,
          axially_symmetrical = false,
          animation_speed = 0.25,
          direction_count = 1,
        },
      },
    },
    flow_length_in_ticks = 360,
  }
}

data:extend{
  {
    type = "assembling-machine",
    name = "tycoon-apple-farm",
    icon = "__tycoon__/graphics/entity/apple-farm/apple-farm.png",
    icon_size = 64,
    max_health = 200,
    fluid_boxes = {
      {
        production_type = "input",
        base_area = 10,
        height = 2,
        base_level = -1,
        pipe_connections = {
          { type = "input", position = { 7, 0 } },
        },
      },
      off_when_no_fluid_recipe = false,
    },
    collision_box = { { -6.9, -5.4}, {6.9, 6.9} },
    selection_box = { { -6.9, -5.4}, {6.9, 6.9} },
    window_bounding_box = { { -0.125, 0.6875 }, { 0.1875, 1.1875 } },
    animation = {
      layers = {
        {
          filename = "__tycoon__/graphics/entity/apple-farm/apple-farm.png",
          priority = "high",
          width = 500,
          height = 500,
          shift = {0, 0},
          scale = 1
        }
      },
    },
    crafting_categories = { "growing" },
    crafting_speed = 10,
    return_ingredients_on_change = true,
    energy_usage = "144.8KW",
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
      emissions_per_minute = -5,
    },
  }
}

data:extend{
  {
    type = "item",
    name = "apple",
    icon = "__tycoon__/graphics/icons/apple.png",
    icon_size = 64,
    subgroup = "raw-resource",
    order = "a[apple]",
    stack_size = 200
  }
}