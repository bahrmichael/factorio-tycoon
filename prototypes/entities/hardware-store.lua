data:extend{
    {
        type = "container",
        name = "tycoon-hardware-store",
        icon = "__tycoon__/graphics/icons/hardware-store.png",
        icon_size = 64,
        max_health = 200,
        inventory_size = 50,
        minable = {
            mining_time = 1,
            result = "tycoon-hardware-store"
        },
        rotatable = false,
        flags = { "not-rotatable", "placeable-player", "player-creation"},
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
                    filename = "__tycoon__/graphics/entity/hardware-store/hardware-store.png",
                    priority = "high",
                    width = 200,
                    height = 200,
                    scale = 0.8,
                    shift = {0, 0}
                },
            }
        },
        circuit_wire_max_distance = 9,
    }
}