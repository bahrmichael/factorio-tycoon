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
        result = "automation-science-pack",
        result_count = 1,
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
        result = "logistic-science-pack",
        result_count = 1,
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
        result = "military-science-pack",
        result_count = 1,
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
        result = "chemical-science-pack",
        result_count = 1,
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
        result = "production-science-pack",
        result_count = 1,
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
        result = "utility-science-pack",
        result_count = 1,
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
