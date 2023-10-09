data:extend{
    {
        type = "recipe-category",
        name = "tycoon-butchery"
    },
    {
        type = "recipe",
        name = "tycoon-cows-to-meat",
        category = "tycoon-butchery",
        energy_required = 30,
        enabled = true,
        ingredients = {
            { type = "item", name = "tycoon-cow", amount = 1 },
        },
        result = "tycoon-meat",
        result_count = 100,
    },
}