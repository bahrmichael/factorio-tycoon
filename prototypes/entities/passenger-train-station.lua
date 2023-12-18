data:extend{
    {
        type = "container",
        name = "tycoon-passenger-train-station",
        icon = "__tycoon__/graphics/icons/passenger-train-station.png",
        icon_size = 64,
        max_health = 2000,
        inventory_size = 100,
        minable = {
            mining_time = 1,
            result = "tycoon-passenger-train-station"
        },
        rotatable = false,
        flags = { "not-rotatable", "placeable-player", "player-creation"},
        corpse = "small-remnants",
        vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
        repair_sound = {filename = "__base__/sound/manual-repair-simple.ogg"},
        open_sound = {filename = "__base__/sound/machine-open.ogg", volume = 0.85},
        close_sound = {filename = "__base__/sound/machine-close.ogg", volume = 0.75},
        collision_box = { { -9.9, -1.9}, {9.9, 1.9} },
        selection_box = { { -9.9, -1.9}, {9.9, 1.9} },
        picture = {
            layers = {
                {
                    filename = "__tycoon__/graphics/entity/passenger-train-station/passenger-train-station.png",
                    priority = "high",
                    width = 732,
                    height = 239,
                    scale = 1,
                    shift = {0, -0.8}
                },
            }
        },
        circuit_wire_max_distance = 9,
        working_sound = {
            sound = {
                filename = "__tycoon__/sound/430983__be_a_hero_not_a_patriot__metro-warszawa-2017-centrum-station-ambience-ticket-inspectors-check-peoples-travelcards-with-beeping-poland.wav",
            },
            probability = 1,
            fade_in_ticks = 10,
            fade_out_ticks = 10,
        }
    }
}