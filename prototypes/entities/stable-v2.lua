data:extend {
    {
        type = "assembling-machine",
        name = "tycoon-stable-v2",
        localised_name = { "entity-name.tycoon-stable" },
        localised_description = { "entity-description.tycoon-stable" },
        icon = "__tycoon__/graphics/icons/stable.png",
        icon_size = 64,
        max_health = 200,
        flags = { "placeable-player", "player-creation" },
        minable = { mining_time = 1, result = "tycoon-stable" },
        fluid_boxes = {
            { -- 输入流体箱
                production_type = "input",
                volume = 2000, -- 10 * 2 * 100
                pipe_connections = {
                    { direction = defines.direction.east, flow_direction = "input", position = { 4.8, 0.5 } },
                },
                --pipe_picture = pipe_pic,
                --pipe_covers = pipecoverpic,
            },
            { -- 输出流体箱
                production_type = "output",
                volume = 2000,
                pipe_connections = {
                    { direction = defines.direction.east, flow_direction = "output", position = { 4.8, -3.5 } },
                },
                --pipe_picture = pipe_pic,
                --pipe_covers = pipecoverpic,
            },
        },
        collision_box = { { -4.9, -4.9 }, { 4.9, 4.9 } },
        --collision_mask = { "player-layer", "water-tile", "item-layer", "object-layer", "train-layer", "rail-layer", "transport-belt-layer" },
        selection_box = { { -4.9, -4.9 }, { 4.9, 4.9 } },
        window_bounding_box = { { -0.125, 0.6875 }, { 0.1875, 1.1875 } },
        graphics_set = {
            animation = {
                layers = {
                    {
                        filename = "__tycoon__/graphics/entity/stable/stable.png",
                        priority = "high",
                        width = 500,
                        height = 500,
                        shift = { 0, -0.2 },
                        scale = 0.7
                    }
                },
            },
        },
        crafting_categories = { "tycoon-husbandry" },
        crafting_speed = 1,
        return_ingredients_on_change = true,
        energy_usage = "300kW",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
            emissions_per_minute = { pollution = 10 },
        },
        allowed_effects = { "speed", "productivity", "consumption", "pollution" },
        module_slots = 3,
    }
}
