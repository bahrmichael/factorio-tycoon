data:extend {
    {
        type = "recipe",
        name = "tycoon-wheat-to-grain",
        category = "crafting",
        energy_required = 15,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-wheat", amount = 25 },
        },
        results = { { type = "item", name = "tycoon-grain", amount = 50 } },
        localised_name = { "item-name.tycoon-grain" },
    },
    {
        type = "recipe",
        name = "tycoon-flour-to-dough",
        category = "crafting-with-fluid",
        energy_required = 5,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-flour", amount = 30 },
            { type = "fluid", name = "tycoon-milk", amount = 20 },
        },
        results = { { type = "item", name = "tycoon-dough", amount = 20 } },
        localised_name = { "item-name.tycoon-dough" },
    },
    {
        type = "recipe",
        name = "tycoon-dough-to-bread",
        category = "smelting",
        energy_required = 1,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-dough", amount = 1 },
        },
        results = { { type = "item", name = "tycoon-bread", amount = 1 } },
        localised_name = { "item-name.tycoon-bread" },
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
        results = { { type = "item", name = "tycoon-flour", amount = 50 } },
        localised_name = { "item-name.tycoon-flour" },
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
        results = { { type = "item", name = "tycoon-bottle", amount = 50 } },
        localised_name = { "item-name.tycoon-bottle" },
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
        results = { { type = "item", name = "tycoon-milk-bottle", amount = 25 } },
        localised_name = { "item-name.tycoon-milk-bottle" },
    },
    {
        type = "recipe",
        name = "tycoon-refurbish-bottle",
        category = "crafting-with-fluid",
        subgroup = "tycoon-basic-intermediates",
        order = "a[tycoon]-g[used-bottle]-a",
        energy_required = 15,
        enabled = false,
        icon = "__tycoon__/graphics/icons/used-bottle.png",
        icon_size = 64,
        ingredients = {
            { type = "item", name = "tycoon-used-bottle", amount = 25 },
            { type = "fluid", name = "water", amount = 100 },
        },
        results = {
            { type = "item", name = "tycoon-bottle", amount = 20 },
            { type = "item", name = "tycoon-bottle", amount = 5, probability = 0.2 }
        },
    },
    {
        type = "recipe",
        name = "tycoon-refurbish-bottle-with-soap",
        category = "crafting-with-fluid",
        subgroup = "tycoon-basic-intermediates",
        order = "a[tycoon]-g[used-bottle]-b",
        energy_required = 5,
        enabled = false,
        icon = "__tycoon__/graphics/icons/used-bottle.png",
        icon_size = 64,
        ingredients = {
            { type = "item", name = "tycoon-used-bottle", amount = 25 },
            { type = "item", name = "tycoon-soap", amount = 1 },
            { type = "fluid", name = "water", amount = 50 },
        },
        results = {
            { type = "item", name = "tycoon-bottle", amount = 20 },
            { type = "item", name = "tycoon-bottle", amount = 5, probability = 0.75 }
        },
    },
    {
        type = "recipe",
        name = "tycoon-smoothie",
        category = "crafting-with-fluid",
        energy_required = 30,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-bottle", amount = 25 },
            { type = "item", name = "tycoon-apple", amount = 50 },
            { type = "fluid", name = "tycoon-milk", amount = 25 },
        },
        results = { { type = "item", name = "tycoon-smoothie", amount = 25 } },
        localised_name = { "item-name.tycoon-smoothie" },
    },
    {
        type = "recipe",
        name = "tycoon-apple-cake",
        category = "crafting",
        energy_required = 10,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-butter", amount = 1 },
            { type = "item", name = "tycoon-apple", amount = 5 },
            { type = "item", name = "tycoon-egg", amount = 2 },
            { type = "item", name = "tycoon-dough", amount = 1 },
        },
        results = { { type = "item", name = "tycoon-apple-cake", amount = 1 } },
        localised_name = { "item-name.tycoon-apple-cake" },
    },
    {
        type = "recipe",
        name = "tycoon-butter",
        category = "crafting-with-fluid",
        energy_required = 60,
        enabled = false,
        ingredients = {
            { type = "fluid", name = "tycoon-milk", amount = 50 },
        },
        results = { { type = "item", name = "tycoon-butter", amount = 25 } },
        localised_name = { "item-name.tycoon-butter" },
    },
    {
        type = "recipe",
        name = "tycoon-cheese",
        category = "crafting-with-fluid",
        energy_required = 60,
        enabled = false,
        ingredients = {
            { type = "fluid", name = "tycoon-milk", amount = 200 },
        },
        results = { { type = "item", name = "tycoon-cheese", amount = 50 } },
        localised_name = { "item-name.tycoon-cheese" },
    },
    {
        type = "recipe",
        name = "tycoon-burger",
        category = "crafting",
        energy_required = 15,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-cheese", amount = 1 },
            { type = "item", name = "tycoon-patty", amount = 1 },
            { type = "item", name = "tycoon-bread", amount = 1 },
        },
        results = { { type = "item", name = "tycoon-burger", amount = 1 } },
        localised_name = { "item-name.tycoon-burger" },
    },
    {
        type = "recipe",
        name = "tycoon-patty",
        category = "crafting",
        energy_required = 2,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-meat", amount = 1 },
        },
        results = { { type = "item", name = "tycoon-patty", amount = 1 } },
        localised_name = { "item-name.tycoon-patty" },
    },
    {
        type = "recipe",
        name = "tycoon-dumpling",
        category = "crafting",
        energy_required = 5,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-dough", amount = 1 },
            { type = "item", name = "tycoon-fish-filet", amount = 1 },
        },
        results = { { type = "item", name = "tycoon-dumpling", amount = 1 } },
        localised_name = { "item-name.tycoon-dumpling" },
    },
}
