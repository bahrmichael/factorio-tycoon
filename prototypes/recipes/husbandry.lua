data:extend{
    {
        type = "recipe-category",
        name = "tycoon-husbandry"
    },
    {
        type = "recipe",
        name = "tycoon-grow-cows-with-grain",
        category = "tycoon-husbandry",
        subgroup = "tycoon-intermediate-products",
        order = "a[tycoon]-d[cow]",
        energy_required = 60,
        enabled = false,
        ingredients = {
            { type = "fluid", name = "water", amount = 200 },
            { type = "item", name = "tycoon-grain", amount = 50 },
        },
        result = "tycoon-cow",
        result_count = 1,
    },
    {
        type = "recipe",
        name = "tycoon-milk-cow",
        category = "tycoon-husbandry",
        icon = "__tycoon__/graphics/icons/milk.png",
        icon_size = 64,
        energy_required = 60,
        subgroup = "tycoon-intermediate-products",
        order = "a[tycoon]-e[milk]",
        enabled = false,
        ingredients = {
            { type = "fluid", name = "water", amount = 200 },
            { type = "item", name = "tycoon-cow", amount = 1 },
            { type = "item", name = "tycoon-grain", amount = 10 },
        },
        results = {
            { type = "item", name = "tycoon-cow", amount = 1, probability = 0.98 },
            { type = "fluid", name = "tycoon-milk", amount = 100 },
        },
    },
}