data:extend{
    {
        type = "technology",
        name = "tycoon-husbandry",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/husbandry.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-building-stable",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-grow-cows-with-grain",
            },
        },
        order = "g-e-e",
        unit = {
          count = 15,
          ingredients = {
            { "automation-science-pack", 1 },
          },
          time = 30,
        },
    },
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
          count = 60,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
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
                recipe = "tycoon-milk-cow",
            },
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
        prerequisites = { "tycoon-husbandry" },
        order = "g-e-e",
        unit = {
          count = 30,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
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
                recipe = "tycoon-butchery",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-fish-to-fish-filet",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-cows-to-meat",
            },
        },
        prerequisites = { "tycoon-husbandry" },
        order = "g-e-e",
        unit = {
          count = 30,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
          },
          time = 30,
        },
    },
    {
        type = "technology",
        name = "tycoon-residential-housing",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/residential-housing.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-university-science-black",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-university-science-blue",
            },
        },
        prerequisites = { "tycoon-meat-processing", "tycoon-baking" },
        order = "g-e-e",
        unit = {
          count = 60,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
          },
          time = 30,
        },
    },
    {
        type = "technology",
        name = "tycoon-highrise-housing",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/highrise-housing.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-university-science-purple",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-university-science-yellow",
            },
        },
        prerequisites = { "steel-processing", "tycoon-residential-housing", "tycoon-bottling" },
        order = "g-e-e",
        unit = {
          count = 120,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
            { "chemical-science-pack", 1 },
          },
          time = 30,
        },
    },
}