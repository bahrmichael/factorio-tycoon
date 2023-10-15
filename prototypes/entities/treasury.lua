data:extend{
    {
        type = "container",
        name = "tycoon-treasury",
        icon = "__tycoon__/graphics/icons/treasury.png",
        icon_size = 64,
        max_health = 200,
        inventory_size = 200,
        rotatable = false,
        corpse = "small-remnants",
        vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
        repair_sound = {filename = "__base__/sound/manual-repair-simple.ogg"},
        open_sound = {filename = "__base__/sound/machine-open.ogg", volume = 0.85},
        close_sound = {filename = "__base__/sound/machine-close.ogg", volume = 0.75},
        collision_box = { { -2.9, -1.9}, {2.9, 1.9} },
        selection_box = { { -2.9, -1.9}, {2.9, 1.9} },
        picture = {
            layers = {
                {
                    filename = "__tycoon__/graphics/entity/treasury/treasury.png",
                    priority = "high",
                    width = 190,
                    height = 190,
                    scale = 1.18,
                    shift = {0, -1}
                },
            }
        },
    }
}