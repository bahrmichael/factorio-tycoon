data:extend{
    {
        type = "technology",
        name = "tycoon-farming",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/farming.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-wheat-to-grain",
            }
        },
        order = "g-e-e",
        unit = {
          count = 30,
          ingredients = {
            { "automation-science-pack", 1 },
          },
          time = 10,
        },
    },
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
            {
                type = "unlock-recipe",
                recipe = "tycoon-grow-chicken-with-grain",
            },
        },
        prerequisites = { "tycoon-farming" },
        order = "g-e-e",
        unit = {
          count = 60,
          ingredients = {
            { "automation-science-pack", 1 },
          },
          time = 30,
        },
    },
    {
        type = "technology",
        name = "tycoon-milking",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/milking.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-milk-cow",
            },
        },
        prerequisites = { "tycoon-husbandry" },
        order = "g-e-e",
        unit = {
          count = 60,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
          },
          time = 60,
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
        prerequisites = { "tycoon-farming", "tycoon-husbandry", "automation-2", "tycoon-milking" },
        order = "g-e-e",
        unit = {
          count = 100,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
          },
          time = 60,
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
        prerequisites = { "tycoon-milking", "automation-2" },
        order = "g-e-e",
        unit = {
          count = 150,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
          },
          time = 60,
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
            {
                type = "unlock-recipe",
                recipe = "tycoon-chicken-to-meat",
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
          time = 100,
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
        prerequisites = { "steel-processing", "optics", "tycoon-meat-processing", "tycoon-baking", "tycoon-milking", "tycoon-bottling" },
        order = "g-e-e",
        unit = {
          count = 100,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
          },
          time = 30,
        },
    },
    {
        type = "technology",
        name = "tycoon-egg-production",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/egg-production.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-egg",
            },
        },
        prerequisites = { "tycoon-husbandry" },
        order = "g-e-e",
        unit = {
          count = 60,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
          },
          time = 100,
        },
    },
    {
        type = "technology",
        name = "tycoon-drinks",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/drinks.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-smoothie",
            },
        },
        prerequisites = { "tycoon-bottling" },
        order = "g-e-e",
        unit = {
          count = 100,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
            { "chemical-science-pack", 1 },
          },
          time = 60,
        },
    },
    {
        type = "technology",
        name = "tycoon-desserts",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/cookies.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-apple-cake",
            },
        },
        prerequisites = { "tycoon-egg-production", "tycoon-dairy-products", "tycoon-baking" },
        order = "g-e-e",
        unit = {
            count = 150,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack", 1 },
                { "chemical-science-pack", 1 },
            },
            time = 100,
        },
    },
    {
        type = "technology",
        name = "tycoon-dairy-products",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/dairy.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-butter",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-cheese",
            },
        },
        prerequisites = { "tycoon-milking" },
        order = "g-e-e",
        unit = {
          count = 60,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
          },
          time = 100,
        },
    },
    {
        type = "technology",
        name = "tycoon-main-dish",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/restaurant-menu.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-burger",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-dumpling",
            },
        },
        prerequisites = { "tycoon-meat-processing", "tycoon-dairy-products", "tycoon-baking" },
        order = "g-e-e",
        unit = {
            count = 200,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack", 1 },
                { "chemical-science-pack", 1 },
            },
            time = 100,
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
        prerequisites = { "fluid-handling", "concrete", "tycoon-residential-housing", "tycoon-desserts", "tycoon-main-dish", "tycoon-dairy-products", "tycoon-drinks" },
        order = "g-e-e",
        unit = {
          count = 400,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
            { "chemical-science-pack", 1 },
          },
          time = 30,
        },
    },
    {
        type = "technology",
        name = "tycoon-public-transportation",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/public-transportation.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-passenger-train-station",
            },
        },
        prerequisites = { "tycoon-residential-housing", "automated-rail-transportation" },
        order = "g-e-e",
        unit = {
          count = 50,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
            { "chemical-science-pack", 1 },
          },
          time = 60,
        },
    },
    {
        type = "technology",
        name = "tycoon-apple-farm-productivity",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/apple-farm.png",
        icon_size = 256,
        effects = {
            {
                -- this still triggers the on_research_finished event
                type = "nothing",
            },
        },
        prerequisites = { "tycoon-farming" },
        unit = {
            count_formula = "(L^2)*100",
            ingredients = {
                { "automation-science-pack", 1 },
            },
            time = 60,
        },
        max_level = 10,
        upgrade = true,
    },
    {
        type = "technology",
        name = "tycoon-wheat-farm-productivity",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/wheat-farm.png",
        icon_size = 256,
        effects = {
            {
                -- this still triggers the on_research_finished event
                type = "nothing",
            },
        },
        prerequisites = { "tycoon-husbandry" },
        unit = {
            count_formula = "(L^2)*100",
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack", 1 },
            },
            time = 60,
        },
        max_level = 10,
        upgrade = true,
    },
    {
        type = "technology",
        name = "tycoon-fishery-productivity",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/fishery.png",
        icon_size = 256,
        effects = {
            {
                -- this still triggers the on_research_finished event
                type = "nothing",
            },
        },
        prerequisites = { "tycoon-husbandry" },
        unit = {
            count_formula = "(L^2)*100",
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack", 1 },
                { "chemical-science-pack", 1 },
            },
            time = 60,
        },
        max_level = 10,
        upgrade = true,
    },
    {
        type = "technology",
        name = "tycoon-personal-transportation",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/bicycle.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-iron-chain",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-tire",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-bicycle",
            },
        },
        prerequisites = { "tycoon-residential-housing", "plastics" },
        order = "g-e-e",
        unit = {
          count = 200,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
            { "chemical-science-pack", 1 },
          },
          time = 60,
        },
    },
    {
        type = "technology",
        name = "tycoon-candles",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/candle.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-candle",
            },
        },
        prerequisites = { "tycoon-residential-housing", "oil-processing" },
        order = "g-e-e",
        unit = {
          count = 50,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
            { "chemical-science-pack", 1 },
          },
          time = 60,
        },
    },
    {
        type = "technology",
        name = "tycoon-kitchen-utilities",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/cutlery.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-cutlery",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-cooking-pot",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-cooking-pan",
            },
        },
        prerequisites = { "steel-processing" },
        order = "g-e-e",
        unit = {
          count = 100,
          ingredients = {
            { "automation-science-pack", 1 },
          },
          time = 30,
        },
    },
    {
        type = "technology",
        name = "tycoon-electronic-devices",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/television.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-television",
            },
        },
        prerequisites = { "advanced-electronics" },
        order = "g-e-e",
        unit = {
          count = 100,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
          },
          time = 60,
        },
    },
    {
        type = "technology",
        name = "tycoon-computers",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/laptop.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-smartphone",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-laptop",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-keyboard",
            },
        },
        prerequisites = { "tycoon-electronic-devices", "tycoon-residential-housing" },
        order = "g-e-e",
        unit = {
          count = 200,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
            { "chemical-science-pack", 1 },
          },
          time = 30,
        },
    },
    {
        type = "technology",
        name = "tycoon-hygiene",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/soap.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-soap",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-gloves",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-refurbish-bottle-with-soap",
            },
        },
        prerequisites = { "oil-processing", "tycoon-residential-housing" },
        order = "g-e-e",
        unit = {
          count = 100,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
            { "chemical-science-pack", 1 },
          },
          time = 30,
        },
    },
    {
        type = "technology",
        name = "tycoon-money-laundering",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/money-stack.png",
        icon_size = 64,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-money-stack",
            },
        },
        prerequisites = { "tycoon-residential-housing" },
        unit = {
            count = 75,
            ingredients = {
              { "automation-science-pack", 1 },
              { "logistic-science-pack", 1 },
              { "chemical-science-pack", 1 },
            },
            time = 60,
        },
    },
    {
        type = "technology",
        name = "tycoon-citizen-science",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/entity/citizen-science-lab/citizen-science-lab.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-citizen-science-lab",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-citizen-science-pack",
            },
        },
        prerequisites = { "tycoon-money-laundering", "tycoon-computers", "tycoon-hygiene" },
        unit = {
            count = 100,
            ingredients = {
              { "automation-science-pack", 1 },
              { "logistic-science-pack", 1 },
              { "chemical-science-pack", 1 },
            },
            time = 60,
        },
    },
    {
        type = "technology",
        name = "tycoon-new-cities",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/multiple-cities.png",
        icon_size = 256,
        effects = {
            {
                -- this still triggers the on_research_finished event
                type = "nothing",
            },
        },
        prerequisites = { "tycoon-public-transportation", "tycoon-citizen-science" },
        unit = {
            count_formula = "(L^3)*100",
            ingredients = {
                { "tycoon-citizen-science-pack", 1 },
            },
            time = 60,
        },
        max_level = 5,
        upgrade = true,
    },
}
