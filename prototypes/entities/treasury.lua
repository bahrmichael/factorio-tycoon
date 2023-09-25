data:extend{
    {
        type = "container",
        name = "tycoon-treasury",
        icon = "__tycoon__/graphics/entity/treasury/treasury.png",
        icon_size = 64,
        max_health = 200,
        inventory_size = 200,
        corpse = "small-remnants",
        vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
        repair_sound = {filename = "__base__/sound/manual-repair-simple.ogg"},
        open_sound = {filename = "__base__/sound/machine-open.ogg", volume = 0.85},
        close_sound = {filename = "__base__/sound/machine-close.ogg", volume = 0.75},
        collision_box = { { -2.4, -1.6}, {2.6, 2.6} },
        selection_box = { { -2.4, -1.6}, {2.6, 2.6} },
        picture = {
            layers = {
                {
                    filename = "__tycoon__/graphics/entity/treasury/treasury.png",
                    priority = "high",
                    width = 190,
                    height = 190,
                    scale = 1.05,
                    shift = {0.5, 0}
                },
            }
        },
    }
}