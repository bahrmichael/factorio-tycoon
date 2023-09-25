data:extend{
    {
        type = "assembling-machine",
        name = "tycoon-university",
        icon = "__tycoon__/graphics/icons/university.png",
        icon_size = 64,
        max_health = 200,
        collision_box = { { -12, -9}, {12, 11} },
        selection_box = { { -12, -9}, {12, 11} },
        flags = {"placeable-player", "player-creation"},
        minable = {mining_time = 1, result = "tycoon-university"},
        animation = {
            layers = {
                {
                    filename = "__tycoon__/graphics/entity/university/university.png",
                    priority = "high",
                    width = 800,
                    height = 800,
                    shift = {0, -1},
                    scale = 1
                }
            },
        },
        crafting_categories = { "tycoon-university-science" },
        crafting_speed = 60,
        return_ingredients_on_change = false,
        energy_usage = "500KW",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
            emissions_per_minute = 20,
        },
    }
}
