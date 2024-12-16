data:extend{
    {
        type = "assembling-machine",
        name = "tycoon-university-v2",
        localised_name = {"entity-name.tycoon-university"},
        localised_description = {"entity-description.tycoon-university"},
        icon = "__tycoon__/graphics/icons/university.png",
        icon_size = 64,
        max_health = 200,
        rotatable = false,
        collision_box = { { -3.9, -3.4}, {3.9, 3.4} },
        selection_box = { { -3.9, -3.4}, {3.9, 3.4} },
        flags = {"placeable-player", "player-creation", "not-rotatable"},
        minable = {mining_time = 1, result = "tycoon-university"},
        animation = {
            layers = {
                {
                    filename = "__tycoon__/graphics/entity/university/university.png",
                    priority = "high",
                    width = 400,
                    height = 400,
                    shift = {0, -0.4},
                    scale = 0.7
                }
            },
        },
        crafting_categories = { "tycoon-university-science" },
        crafting_speed = 1,
        return_ingredients_on_change = false,
        energy_usage = "500kW",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
            emissions_per_minute = { pollution = 20 },
        },
        allowed_effects = {"speed", "productivity", "consumption", "pollution"},
        module_specification = {
            module_slots = 3,
        }
    }
}
