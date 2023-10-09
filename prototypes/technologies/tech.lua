data:extend{
    {
        type = "technology",
        name = "tycoon-baking",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/baking.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-grain-to-flour",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-flour-to-dough",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-dough-to-bread",
            },
        },
        -- prerequisites = { "kr-matter-processing" },
        order = "g-e-e",
        unit = {
          count = 10,
          ingredients = {
            { "automation-science-pack", 1 },
          },
          time = 30,
        },
    },
    {
        type = "technology",
        name = "tycoon-bottling",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/bottling.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-bottle-to-milk-bottle",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-iron-plate-to-bottle",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-refurbish-bottle",
            },
        },
        -- prerequisites = { "kr-matter-processing" },
        order = "g-e-e",
        unit = {
          count = 10,
          ingredients = {
            { "automation-science-pack", 1 },
          },
          time = 30,
        },
    },
    {
        type = "technology",
        name = "tycoon-meat-processing",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/meat-grinder.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-fish-to-fish-filet",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-cows-to-meat",
            },
        },
        -- prerequisites = { "kr-matter-processing" },
        order = "g-e-e",
        unit = {
          count = 10,
          ingredients = {
            { "automation-science-pack", 1 },
          },
          time = 30,
        },
    },
}