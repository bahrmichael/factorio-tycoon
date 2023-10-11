data:extend{
    {
        type = "recipe",
        name = "tycoon-wheat-to-grain",
        category = "crafting",
        energy_required = 15,
        enabled = true,
        ingredients = {
            { type = "item", name = "tycoon-wheat", amount = 25 },
        },
        result = "tycoon-grain",
        result_count = 25,
    },
    {
        type = "recipe",
        name = "tycoon-flour-to-dough",
        category = "crafting-with-fluid",
        energy_required = 15,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-flour", amount = 30 },
            { type = "fluid", name = "tycoon-milk", amount = 20 },
        },
        result = "tycoon-dough",
        result_count = 20,
    },
    {
        type = "recipe",
        name = "tycoon-dough-to-bread",
        category = "smelting",
        energy_required = 10,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-dough", amount = 10 },
        },
        result = "tycoon-bread",
        result_count = 10,
    },
    {
        type = "recipe",
        name = "tycoon-grain-to-flour",
        category = "crafting",
        energy_required = 30,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-grain", amount = 5 },
        },
        result = "tycoon-flour",
        result_count = 50,
    },
    {
        type = "recipe",
        name = "tycoon-iron-plate-to-bottle",
        category = "crafting",
        energy_required = 30,
        enabled = false,
        ingredients = {
            { type = "item", name = "iron-plate", amount = 5 },
        },
        result = "tycoon-bottle",
        result_count = 50,
    },
    {
        type = "recipe",
        name = "tycoon-bottle-to-milk-bottle",
        category = "crafting-with-fluid",
        energy_required = 15,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-bottle", amount = 25 },
            { type = "fluid", name = "tycoon-milk", amount = 25 },
        },
        result = "tycoon-milk-bottle",
        result_count = 25,
    },
    {
        type = "recipe",
        name = "tycoon-refurbish-bottle",
        category = "crafting-with-fluid",
        energy_required = 15,
        enabled = false,
        icon = "__tycoon__/graphics/icons/used-bottle.png",
        icon_size = 64,
        ingredients = {
            { type = "item", name = "tycoon-used-bottle", amount = 25 },
            { type = "fluid", name = "water", amount = 100 },
        },
        subgroup = "raw-resource",
        results = {
            {name = "tycoon-bottle", amount = 20},
            {name = "tycoon-bottle", amount = 5, probability = 0.2}
        },
    },
}