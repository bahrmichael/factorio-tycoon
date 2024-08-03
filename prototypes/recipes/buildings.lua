data:extend{
    {
        type = "recipe",
        name = "tycoon-building-recipe-university",
        category = "crafting",
        enabled = false,
        ingredients = {
            { type = "item", name = "stone-brick", amount = 50 },
            { type = "item", name = "copper-cable", amount = 10 },
            { type = "item", name = "transport-belt", amount = 5 },
            { type = "item", name = "inserter", amount = 5 },
        },
        result = "tycoon-university",
        result_count = 1,
    },
    {
        type = "recipe",
        name = "tycoon-building-recipe-water-tower",
        category = "crafting",
        enabled = true,
        ingredients = {
            { type = "item", name = "stone-brick", amount = 5 },
            { type = "item", name = "iron-plate", amount = 10 },
            { type = "item", name = "pipe", amount = 5 },
        },
        result = "tycoon-water-tower",
        result_count = 1,
    },
    {
        type = "recipe",
        name = "tycoon-building-recipe-market",
        category = "crafting",
        enabled = true,
        ingredients = {
            { type = "item", name = "stone-brick", amount = 10 },
            { type = "item", name = "wood", amount = 10 },
        },
        result = "tycoon-market",
        result_count = 1,
    },
    {
        type = "recipe",
        name = "tycoon-building-recipe-hardware-store",
        category = "crafting",
        enabled = true,
        ingredients = {
            { type = "item", name = "stone-brick", amount = 10 },
            { type = "item", name = "iron-plate", amount = 10 },
        },
        result = "tycoon-hardware-store",
        result_count = 1,
    },
    {
        type = "recipe",
        name = "tycoon-building-stable",
        category = "crafting",
        enabled = false,
        ingredients = {
            { type = "item", name = "stone-brick", amount = 20 },
            { type = "item", name = "pipe", amount = 5 },
            { type = "item", name = "inserter", amount = 2 },
        },
        result = "tycoon-stable",
        result_count = 1,
    },
    {
        type = "recipe",
        name = "tycoon-butchery",
        category = "crafting",
        enabled = false,
        ingredients = {
            { type = "item", name = "stone-brick", amount = 10 },
            { type = "item", name = "steel-plate", amount = 5 },
            { type = "item", name = "inserter", amount = 5 },
        },
        result = "tycoon-butchery",
        result_count = 1,
    },
    {
        type = "recipe",
        name = "tycoon-passenger-train-station",
        category = "crafting",
        enabled = false,
        ingredients = {
            { type = "item", name = "concrete", amount = 200 },
            { type = "item", name = "steel-plate", amount = 50 },
            { type = "item", name = "small-lamp", amount = 10 },
            { type = "item", name = "rail", amount = 20 },
            { type = "item", name = "advanced-circuit", amount = 10 },
        },
        result = "tycoon-passenger-train-station",
        result_count = 1,
    },
    {
        type = "recipe",
        name = "tycoon-citizen-science-lab",
        category = "crafting",
        enabled = false,
        ingredients = {
          {"tycoon-laptop", 5},
          {"tycoon-money-stack", 10},
          {"tycoon-soap", 10},
          {"tycoon-gloves", 50}
        },
        result = "tycoon-citizen-science-lab"
      }
}
