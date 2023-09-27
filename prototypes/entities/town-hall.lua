data:extend{
    {
        type = "container",
        name = "tycoon-town-hall",
        icon = "__tycoon__/graphics/entity/town-hall/town-hall.png",
        icon_size = 64,
        max_health = 200,
        inventory_size = 100,
        corpse = "small-remnants",
        vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
        repair_sound = {filename = "__base__/sound/manual-repair-simple.ogg"},
        open_sound = {filename = "__base__/sound/machine-open.ogg", volume = 0.85},
        close_sound = {filename = "__base__/sound/machine-close.ogg", volume = 0.75},
        collision_box = { {-2, -2}, {2.9, 2.9} },
        selection_box = { {-2.4, -2.4}, {3.4, 3.4} },
        picture = {
            layers = {
                {
                    filename = "__tycoon__/graphics/entity/town-hall/town-hall.png",
                    priority = "high",
                    width = 250,
                    height = 250,
                    scale = 0.8,
                    shift = {0.55, 0.2}
                },
            }
        },
    }
}