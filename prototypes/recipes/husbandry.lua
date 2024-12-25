data:extend{
    {
        type = "recipe-category",
        name = "tycoon-husbandry"
    },
    {
        type = "recipe",
        name = "tycoon-grow-cows-with-grain",
        category = "tycoon-husbandry",
        subgroup = "tycoon-basic-intermediates",
        order = "a[tycoon]-d[cow]",
        energy_required = 60,
        enabled = false,
        ingredients = {
            { type = "fluid", name = "water", amount = 200 },
            { type = "item", name = "tycoon-grain", amount = 50 },
        },
        results = { { type = "item", name = "tycoon-cow", amount = 1 } },
        localised_name = { "item-name.tycoon-cow" },
    },
    {
        type = "recipe",
        name = "tycoon-grow-chicken-with-grain",
        category = "tycoon-husbandry",
        subgroup = "tycoon-basic-intermediates",
        order = "a[tycoon]-d[chicken]",
        energy_required = 30,
        enabled = false,
        ingredients = {
            { type = "fluid", name = "water", amount = 200 },
            { type = "item", name = "tycoon-grain", amount = 50 },
        },
        results = { { type = "item", name = "tycoon-chicken", amount = 10 } },
        localised_name = { "item-name.tycoon-chicken" },
    },
    {
        type = "recipe",
        name = "tycoon-milk-cow",
        category = "tycoon-husbandry",
        icon = "__tycoon__/graphics/icons/milk.png",
        icon_size = 64,
        energy_required = 15,
        subgroup = "tycoon-basic-intermediates",
        order = "a[tycoon]-e[milk]",
        enabled = false,
        ingredients = {
            { type = "fluid", name = "water", amount = 200 },
            { type = "item", name = "tycoon-cow", amount = 1 },
            { type = "item", name = "tycoon-grain", amount = 20 },
        },
        results = {
            { type = "item", name = "tycoon-cow", amount = 1, probability = 0.98 },
            { type = "fluid", name = "tycoon-milk", amount = 50 },
        },

    },
    {
        type = "recipe",
        name = "tycoon-egg",
        category = "tycoon-husbandry",
        icon = "__tycoon__/graphics/icons/egg.png",
        icon_size = 64,
        energy_required = 30,
        subgroup = "tycoon-basic-intermediates",
        order = "a[tycoon]-e[egg]",
        enabled = false,
        ingredients = {
            { type = "fluid", name = "water", amount = 100 },
            { type = "item", name = "tycoon-chicken", amount = 10 },
            { type = "item", name = "tycoon-grain", amount = 50 },
        },
        results = {
            { type = "item", name = "tycoon-chicken", amount = 10, probability = 0.95 },
            { type = "item", name = "tycoon-egg", amount = 30 },
        },
    },
}
