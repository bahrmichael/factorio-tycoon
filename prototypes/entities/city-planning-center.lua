data:extend{
    {
        type = "container",
        name = "tycoon-city-planning-center",
        icon = "__tycoon__/graphics/icons/city-planning-center.png",
        icon_size = 64,
        max_health = 2000,
        inventory_size = 200,
        rotatable = false,
        flags = { "not-rotatable", "placeable-player"},
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
                    filename = "__tycoon__/graphics/entity/city-planning-center/city-planning-center.png",
                    priority = "high",
                    width = 190,
                    height = 190,
                    scale = 1,
                    shift = {0, 0}
                },
            }
        },
        circuit_wire_max_distance = 9,
    }
}