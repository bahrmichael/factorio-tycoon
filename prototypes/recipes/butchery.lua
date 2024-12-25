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
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-cow", amount = 1 },
        },
        results = { { type = "item", name = "tycoon-meat", amount = 50 } },
        localised_name = { "item-name.tycoon-meat" },
    },
    {
        type = "recipe",
        name = "tycoon-chicken-to-meat",
        category = "tycoon-butchery",
        energy_required = 10,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-chicken", amount = 1 },
        },
        results = { { type = "item", name = "tycoon-meat", amount = 10 } },
        localised_name = { "item-name.tycoon-meat" },
    },
    {
        type = "recipe",
        name = "tycoon-fish-to-fish-filet",
        category = "tycoon-butchery",
        energy_required = 15,
        enabled = false,
        ingredients = {
            { type = "item", name = "raw-fish", amount = 1 },
        },
        results = { { type = "item", name = "tycoon-fish-filet", amount = 10 } },
        localised_name = { "item-name.tycoon-fish-filet" },
    },
}
