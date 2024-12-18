data:extend {
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
                volume = 20000, -- 10 * 2 * 1000
                pipe_connections = {
                    { direction = defines.direction.east, flow_direction = "input", position = { 6.8, 0.5 } }, -- 注意 direction 仍然是 east
                },
                --pipe_picture = pipe_pic,
                --pipe_covers = pipecoverpic,
            },
        },
        fluid_boxes_off_when_no_fluid_recipe = false,
        collision_box = { { -6.9, -6.9 }, { 6.9, 6.9 } },
        selection_box = { { -6.9, -6.9 }, { 6.9, 6.9 } },
        --collision_mask = { "player-layer", "water-tile", "resource-layer", "item-layer", "ghost-layer", "object-layer", "train-layer", "rail-layer", "transport-belt-layer" },
        window_bounding_box = { { -0.125, 0.6875 }, { 0.1875, 1.1875 } },
        graphics_set = {
            animation = {
                layers = {
                    {
                        filename = "__tycoon__/graphics/entity/wheat-farm/wheat-farm.png",
                        priority = "high",
                        width = 500,
                        height = 500,
                        shift = { 0, 0 },
                        scale = 0.95
                    }
                },
            },
        },
        crafting_categories = { "tycoon-growing-wheat" },
        crafting_speed = 1,
        return_ingredients_on_change = true,
        disabled_when_recipe_not_researched = false,
        -- 60kW is one solar panel, makes sense to go with "solar energy" as the crops grow
        energy_usage = "60kW",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
            emissions_per_minute = { pollution = -5 },
        },
    }
}
