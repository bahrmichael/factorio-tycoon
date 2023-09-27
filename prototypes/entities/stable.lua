data:extend{
    {
        type = "assembling-machine",
        name = "tycoon-stable",
        icon = "__tycoon__/graphics/entity/stable/stable.png",
        icon_size = 64,
        max_health = 200,
        minable = {mining_time = 1, result = "tycoon-stable"},
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
        collision_mask = { "player-layer", "water-tile", "resource-layer", "item-layer", "ghost-layer", "object-layer", "train-layer", "rail-layer", "transport-belt-layer" },
        selection_box = { { -6.9, -5.4}, {6.9, 6.9} },
        window_bounding_box = { { -0.125, 0.6875 }, { 0.1875, 1.1875 } },
        animation = {
            layers = {
                {
                filename = "__tycoon__/graphics/entity/stable/stable.png",
                priority = "high",
                width = 500,
                height = 500,
                shift = {0, 0},
                scale = 1
                }
            },
        },
        crafting_categories = { "tycoon-husbandry" },
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