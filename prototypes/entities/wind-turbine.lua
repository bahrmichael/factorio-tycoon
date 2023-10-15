local BOX = { { -0.9, -0.9 }, { 0.9, 0.9 } }

data:extend({
    {
        type = "electric-energy-interface",
        name = "tycoon-wind-turbine",
        icon = "__tycoon__/graphics/icons/wind-turbine.png",
        icon_size = 256,
        order = "a",
        flags = { "placeable-player", "player-creation" },
        minable = { mining_time = 0.5, result = "tycoon-wind-turbine" },
        max_health = 500,
        corpse = "medium-remnants",
        effectivity = 1,
        collision_box = BOX,
        selection_box = BOX,
        collision_mask = { "resource-layer", "object-layer", "player-layer", "water-tile" },
        energy_source = {
            type = "electric",
            usage_priority = "primary-output",
            buffer_capacity = "15kW",
            render_no_power_icon = false
        },
        energy_production = "30kW",
        energy_usage = "0kW",
        animations = { layers = {
            {
                filename = "__tycoon__/graphics/entity/wind-turbine/wind-turbine.png",
                width = 284,
                height = 284,
                frame_count = 1,
                shift = {-0.27, -3.1}
            },
        } },
        random_animation_offset = false,
        working_sound = {
            sound = {
                filename = "__base__/sound/train-wheels.ogg",
                volume = 0.6
            },
            match_speed_to_activity = true,
        },
    },
})