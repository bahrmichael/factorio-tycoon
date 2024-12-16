data:extend{
    {
        type = "assembling-machine",
        name = "tycoon-stable-v2",
        localised_name = {"entity-name.tycoon-stable"},
        localised_description = {"entity-description.tycoon-stable"},
        icon = "__tycoon__/graphics/icons/stable.png",
        icon_size = 64,
        max_health = 200,
        flags = { "placeable-player", "player-creation" },
        minable = {mining_time = 1, result = "tycoon-stable"},
        fluid_boxes = {
            {
                production_type = "input",
                base_area = 10,
                height = 2,
                base_level = -1,
                pipe_connections = {
                    { type = "input", position = { 5.4, 0.5 } },
                },
            },
            {
                production_type = "output",
                base_level = 1,
                pipe_connections =
                {
                  {
                    type = "output",
                    position = { 5.4, -3.5 }
                  }
                }
            },
        },
        collision_box = { { -4.9, -4.9}, {4.9, 4.9} },
        --collision_mask = { "player-layer", "water-tile", "item-layer", "object-layer", "train-layer", "rail-layer", "transport-belt-layer" },
        selection_box = { { -4.9, -4.9}, {4.9, 4.9} },
        window_bounding_box = { { -0.125, 0.6875 }, { 0.1875, 1.1875 } },
        animation = {
            layers = {
                {
                filename = "__tycoon__/graphics/entity/stable/stable.png",
                priority = "high",
                width = 500,
                height = 500,
                shift = {0, -0.2},
                scale = 0.7
                }
            },
        },
        crafting_categories = { "tycoon-husbandry" },
        crafting_speed = 1,
        return_ingredients_on_change = true,
        energy_usage = "300kW",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
            emissions_per_minute = 10,
        },
        allowed_effects = {"speed", "productivity", "consumption", "pollution"},
        module_specification = {
            module_slots = 3,
        }
    }
}
