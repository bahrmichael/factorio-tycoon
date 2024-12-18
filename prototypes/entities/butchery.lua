data:extend {
    {
        type = "assembling-machine",
        name = "tycoon-butchery",
        icon = "__tycoon__/graphics/icons/butchery.png",
        icon_size = 64,
        max_health = 200,
        collision_box = { { -8.4, -2.4 }, { 8.4, 2.4 } },
        selection_box = { { -8.5, -2.5 }, { 8.5, 2.5 } },
        flags = { "not-rotatable", "placeable-player", "player-creation" },
        minable = { mining_time = 1, result = "tycoon-butchery" },
        rotatable = false,
        graphics_set = {
            animation = {
                layers = {
                    {
                        filename = "__tycoon__/graphics/entity/butchery/butchery.png",
                        priority = "high",
                        width = 707,
                        height = 353,
                        scale = 0.8,
                        shift = { 0, -0.8 }
                    },
                },
            },
        },
        crafting_categories = { "tycoon-butchery" },
        crafting_speed = 1,
        disabled_when_recipe_not_researched = false,
        return_ingredients_on_change = false,
        energy_usage = "300kW",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
            emissions_per_minute = { pollution = 50 },
        },
        allowed_effects = { "speed", "productivity", "consumption", "pollution" },
        module_slots = 3,

    }
}
