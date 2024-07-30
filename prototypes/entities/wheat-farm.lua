data:extend{
    {
        type = "assembling-machine",
        name = "tycoon-wheat-farm",
        icon = "__tycoon__/graphics/icons/wheat-farm.png",
        icon_size = 256,
        max_health = 200,
        rotatable = false,
        flags = { "not-rotatable" },
        minable = {
            mining_time = 3,
            results = {}
        },
        fluid_boxes = {
            {
                production_type = "input",
                base_area = 10,
                height = 2,
                base_level = -1,
                pipe_connections = {
                    { type = "input", position = { 7.2, 0.5 } },
                },
            },
            off_when_no_fluid_recipe = false,
        },
        collision_box = { { -6.9, -6.9}, {6.9, 6.9} },
        selection_box = { { -6.9, -6.9}, {6.9, 6.9} },
        collision_mask = { "player-layer", "water-tile", "resource-layer", "item-layer", "ghost-layer", "object-layer", "train-layer", "rail-layer", "transport-belt-layer" },
        window_bounding_box = { { -0.125, 0.6875 }, { 0.1875, 1.1875 } },
        animation = {
            layers = {
                {
                    filename = "__tycoon__/graphics/entity/wheat-farm/wheat-farm.png",
                    priority = "high",
                    width = 500,
                    height = 500,
                    shift = {0, 0},
                    scale = 0.95
                }
            },
        },
        crafting_categories = { "tycoon-growing-wheat" },
        crafting_speed = 1,
        return_ingredients_on_change = true,
        -- 60KW is one solar panel, makes sense to go with "solar energy" as the crops grow
        energy_usage = "60KW",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
            emissions_per_minute = -5,
        },
    }
}
