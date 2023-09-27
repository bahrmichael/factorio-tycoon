data:extend{
    {
        type = "recipe-category",
        name = "tycoon-husbandry"
    },
    {
        type = "recipe",
        name = "tycoon-grow-cows-with-grain",
        category = "tycoon-husbandry",
        energy_required = 60,
        enabled = false,
        ingredients = {
            { type = "fluid", name = "water", amount = 200 },
            { type = "item", name = "tycoon-grain", amount = 10 },
        },
        result = "tycoon-cow",
        result_count = 1,
    },
    {
        type = "recipe",
        name = "tycoon-milk-cows",
        category = "tycoon-husbandry",
        icon = "__tycoon__/graphics/icons/milk-bottle.png",
        icon_size = 64,
        energy_required = 60,
        subgroup = "raw-resource",
        enabled = false,
        ingredients = {
            { type = "fluid", name = "water", amount = 10 },
            { type = "item", name = "tycoon-cow", amount = 1 },
            { type = "item", name = "tycoon-grain", amount = 2 },
        },
        results = {
            { type = "item", name = "tycoon-cow", amount = 1 },
            { type = "item", name = "tycoon-milk-bottle", amount = 2 },
        },
    },
}