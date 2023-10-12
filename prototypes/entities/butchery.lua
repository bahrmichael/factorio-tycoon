data:extend{
    {
        type = "assembling-machine",
        name = "tycoon-butchery",
        icon = "__tycoon__/graphics/icons/butchery.png",
        icon_size = 64,
        max_health = 200,
        collision_box = { { -8.4, -2.4}, {8.4, 2.4} },
        selection_box = { { -8.5, -2.5}, {8.5, 2.5} },
        flags = {"placeable-player", "player-creation"},
        minable = {mining_time = 1, result = "tycoon-butchery"},
        rotatable = false,
        animation = {
            layers = {
                {
                    filename = "__tycoon__/graphics/entity/butchery/butchery.png",
                    priority = "high",
                    width = 707,
                    height = 353,
                    scale = 0.8,
                    shift = {0, -0.6}
                },
            },
        },
        crafting_categories = { "tycoon-butchery" },
        crafting_speed = 1,
        return_ingredients_on_change = false,
        energy_usage = "300KW",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
            emissions_per_minute = 50,
        },
    }
}
