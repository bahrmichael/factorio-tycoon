data:extend{
    {
      type = "storage-tank",
      name = "tycoon-water-tower",
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