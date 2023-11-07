data:extend{
    {
        type = "container",
        name = "tycoon-urban-planning-center",
        icon = "__tycoon__/graphics/icons/urban-planning-center.png",
        icon_size = 64,
        max_health = 2000,
        inventory_size = 50,
        minable = {
            mining_time = 1,
            result = "tycoon-urban-planning-center"
        },
        rotatable = false,
        flags = { "not-rotatable", "placeable-player", "player-creation"},
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
                    filename = "__tycoon__/graphics/entity/urban-planning-center/urban-planning-center.png",
                    priority = "high",
                    width = 245,
                    height = 245,
                    scale = 1.05,
                    shift = {-0.1, -1}
                },
            }
        },
        circuit_wire_max_distance = 9,
    }
}