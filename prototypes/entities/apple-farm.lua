data:extend {
    {
        type = "assembling-machine",
        name = "tycoon-apple-farm",
        icon = "__tycoon__/graphics/icons/apple-farm.png",
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
                volume = 2000, --  ：base_area * height * 1000 (10 * 2 * 100)
                pipe_connections = {
                    { direction = defines.direction.east, flow_direction = "input", position = { 6.8, 0.0 } }, -- 根据位置调整方向
                },
                -- 添加 pipe_picture 和 pipe_covers，你需要定义这些变量
                --pipe_picture = pipe_pic,
                --pipe_covers = pipecoverpic,
            },
        },
        fluid_boxes_off_when_no_fluid_recipe = false,
        collision_box = { { -6.9, -5.4 }, { 6.9, 7.4 } },
        --collision_mask = { "player-layer", "water-tile", "resource-layer", "item-layer", "ghost-layer", "object-layer", "train-layer", "rail-layer", "transport-belt-layer" },
        selection_box = { { -6.9, -5.4 }, { 6.9, 7.4 } },
        window_bounding_box = { { -0.125, 0.6875 }, { 0.1875, 1.1875 } },
        graphics_set = {
            animation = {
                layers = {
                    {
                        filename = "__tycoon__/graphics/entity/apple-farm/apple-farm.png",
                        priority = "high",
                        width = 500,
                        height = 500,
                        shift = { 0, 0.5 },
                        scale = 1
                    }
                },
            },
        },
        crafting_categories = { "tycoon-growing-apples" },
        crafting_speed = 1,
        return_ingredients_on_change = true,
        -- 60kW is one solar panel, makes sense to go with "solar energy" as the crops grow
        energy_usage = "300kW",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
            emissions_per_minute = { pollution = -5 },
        },
    }
}
