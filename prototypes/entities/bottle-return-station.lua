data:extend{
    {
        type = "container",
        name = "tycoon-bottle-return-station",
        icon = "__tycoon__/graphics/icons/bottle-return-station.png",
        icon_size = 64,
        max_health = 200,
        inventory_size = 50,
        rotatable = false,
        flags = { "not-rotatable", "not-deconstructable"},
        corpse = "small-remnants",
        vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
        repair_sound = {filename = "__base__/sound/manual-repair-simple.ogg"},
        open_sound = {filename = "__base__/sound/machine-open.ogg", volume = 0.85},
        close_sound = {filename = "__base__/sound/machine-close.ogg", volume = 0.75},
        collision_box = { { -1.9, -1.9}, {1.9, 1.9} },
        selection_box = { { -1.9, -1.9}, {1.9, 1.9} },
        picture = {
            layers = {
                {
                    filename = "__tycoon__/graphics/entity/bottle-return-station/bottle-return-station.png",
                    priority = "high",
                    width = 256,
                    height = 256,
                    scale = 1,
                    shift = {0, -1}
                },
            }
        },
        circuit_wire_max_distance = 9,
    }
}