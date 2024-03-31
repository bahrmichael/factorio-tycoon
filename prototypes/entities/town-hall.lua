data:extend{
    {
        type = "container",
        name = "tycoon-town-hall",
        icon = "__tycoon__/graphics/icons/town-hall.png",
        icon_size = 64,
        map_color = {r=0.5, g=1, b=0.5},
        max_health = 10000,
        -- This has to be set in the runtime code
        -- destructible = false,
        inventory_size = 0,
        rotatable = false,
        flags = { "not-rotatable", "not-deconstructable"},
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