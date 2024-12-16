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
        results = {{type="item", name="tycoon-university", amount=1}},
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
        results = {{type="item", name="tycoon-water-tower", amount=1}},
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
        results = {{type="item", name="tycoon-market", amount=1}},
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
        results = {{type="item", name="tycoon-hardware-store", amount=1}},
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
        results = {{type="item", name="tycoon-stable", amount=1}},
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
        results = {{type="item", name="tycoon-butchery", amount=1}},
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
        results = {{type="item", name="tycoon-passenger-train-station", amount=1}},
    },
    {
        type = "recipe",
        name = "tycoon-citizen-science-lab",
        category = "crafting",
        enabled = false,
        ingredients = {
          {type="item", name="tycoon-laptop", amount=5},
          {type="item", name="tycoon-money-stack", amount=10},
          {type="item", name="tycoon-soap", amount=10},
          {type="item", name="tycoon-gloves", amount=50}
        },
        result = "tycoon-citizen-science-lab"
      }
}
