local kwPerCurrency = 20

data:extend{
    {
        type = "recipe-category",
        name = "tycoon-university-science"
    },
    {
        type = "recipe",
        name = "tycoon-university-science-red",
        category = "tycoon-university-science",
        energy_required = 5,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-currency", amount = 5 * math.floor(70 / kwPerCurrency) },
        },
        results = { { type = "item", name = "automation-science-pack", amount = 1 } },
        localised_name = { "item-name.automation-science-pack" },
    },
    {
        type = "recipe",
        name = "tycoon-university-science-green",
        category = "tycoon-university-science",
        energy_required = 5,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-currency", amount = 10 * math.floor(130 / kwPerCurrency) },
        },
        results = { { type = "item", name = "logistic-science-pack", amount = 1 } },
        localised_name = { "item-name.logistic-science-pack" },
    },
    {
        type = "recipe",
        name = "tycoon-university-science-black",
        category = "tycoon-university-science",
        energy_required = 5,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-currency", amount = 8 * math.floor(275 / kwPerCurrency) },
        },
        results = { { type = "item", name = "military-science-pack", amount = 1 } },
        localised_name = { "item-name.military-science-pack" },
    },
    {
        type = "recipe",
        name = "tycoon-university-science-blue",
        category = "tycoon-university-science",
        energy_required = 5,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-currency", amount = 10 * math.floor(450 / kwPerCurrency) },
        },
        results = { { type = "item", name = "chemical-science-pack", amount = 1 } },
        localised_name = { "item-name.chemical-science-pack" },
    },
    {
        type = "recipe",
        name = "tycoon-university-science-purple",
        category = "tycoon-university-science",
        energy_required = 5,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-money-stack", amount = 5 },
        },
        results = { { type = "item", name = "production-science-pack", amount = 1 } },
        localised_name = { "item-name.production-science-pack" },
    },
    {
        type = "recipe",
        name = "tycoon-university-science-yellow",
        category = "tycoon-university-science",
        energy_required = 5,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-money-stack", amount = 20 },
        },
        results = { { type = "item", name = "utility-science-pack", amount = 1 } },
        localised_name = { "item-name.utility-science-pack" },
    },
    {
        type = "recipe",
        name = "tycoon-citizen-science-pack",
        category = "tycoon-university-science",
        energy_required = 10,
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-money-stack", amount = 100 },
            { type = "item", name = "tycoon-laptop", amount = 1 },
        },
        results = {
            { type = "item", name = "tycoon-citizen-science-pack", amount = 1, probability = 0.75 },
        },
    },
}
