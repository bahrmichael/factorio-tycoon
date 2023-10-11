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
        enabled = true,
        ingredients = {
            { type = "item", name = "tycoon-currency", amount = math.floor(70 / kwPerCurrency) },
        },
        result = "automation-science-pack",
        result_count = 1,
    },
    {
        type = "recipe",
        name = "tycoon-university-science-green",
        category = "tycoon-university-science",
        energy_required = 5,
        enabled = true,
        ingredients = {
            { type = "item", name = "tycoon-currency", amount = math.floor(130 / kwPerCurrency) },
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
            { type = "item", name = "tycoon-currency", amount = math.floor(275 / kwPerCurrency) },
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
            { type = "item", name = "tycoon-currency", amount = math.floor(450 / kwPerCurrency) },
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
            { type = "item", name = "tycoon-currency", amount = math.floor(1200 / kwPerCurrency) },
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
            { type = "item", name = "tycoon-currency", amount = math.floor(1500 / kwPerCurrency) },
        },
        result = "utility-science-pack",
        result_count = 1,
    },
}