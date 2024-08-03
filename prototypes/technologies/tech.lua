data:extend{
    {
        type = "technology",
        name = "tycoon-university-science-red",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/university-science-red.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-building-recipe-university",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-university-science-red",
            },
        },
        prerequisites = { "automation" },
        unit = {
          count = 50,
          ingredients = {
            { "automation-science-pack", 1 },
          },
          time = 15,
        },
    },
    {
        type = "technology",
        name = "tycoon-farming",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/farming.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-wheat-to-grain",
            }
        },
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
        icon = "__tycoon__/graphics/technology/husbandry.png",
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
        name = "tycoon-university-science-green",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/university-science-green.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-university-science-green",
            },
        },
        prerequisites = { "logistic-science-pack", "tycoon-university-science-red" },
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
        name = "tycoon-milking",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/milking.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-milk-cow",
            },
        },
        prerequisites = { "tycoon-husbandry" },
        unit = {
          count = 200,
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
        icon = "__tycoon__/graphics/technology/baking.png",
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
        unit = {
          count = 200,
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
        icon = "__tycoon__/graphics/technology/bottling.png",
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
        unit = {
          count = 300,
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
        icon = "__tycoon__/graphics/technology/meat-grinder.png",
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
        unit = {
          count = 300,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
          },
          time = 60,
        },
    },
    {
        type = "technology",
        name = "tycoon-residential-housing",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/residential-housing.png",
        icon_size = 256,
        prerequisites = { "steel-processing", "optics", "tycoon-meat-processing", "tycoon-baking", "tycoon-milking", "tycoon-bottling" },
        unit = {
          count = 500,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
          },
          time = 30,
        },
    },
    {
        type = "technology",
        name = "tycoon-university-science-blue",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/university-science-blue.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-university-science-blue",
            },
        },
        prerequisites = { "tycoon-residential-housing", "chemical-science-pack", "tycoon-university-science-green" },
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
        name = "tycoon-university-science-black",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/university-science-black.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-university-science-black",
            },
        },
        prerequisites = { "tycoon-residential-housing", "military-science-pack", "tycoon-university-science-green" },
        unit = {
          count = 200,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
            { "military-science-pack", 1 },
          },
          time = 30,
        },
    },
    {
        type = "technology",
        name = "tycoon-egg-production",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/egg-production.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-egg",
            },
        },
        prerequisites = { "tycoon-husbandry" },
        unit = {
          count = 400,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
          },
          time = 60,
        },
    },
    {
        type = "technology",
        name = "tycoon-drinks",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/drinks.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-smoothie",
            },
        },
        prerequisites = { "tycoon-bottling" },
        unit = {
          count = 500,
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
        icon = "__tycoon__/graphics/technology/cookies.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-apple-cake",
            },
        },
        prerequisites = { "tycoon-egg-production", "tycoon-dairy-products", "tycoon-baking" },
        unit = {
            count = 600,
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
        name = "tycoon-dairy-products",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/dairy.png",
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
        unit = {
          count = 400,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
          },
          time = 60,
        },
    },
    {
        type = "technology",
        name = "tycoon-main-dish",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/restaurant-menu.png",
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
        unit = {
            count = 700,
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
        name = "tycoon-highrise-housing",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/highrise-housing.png",
        icon_size = 256,
        prerequisites = { "fluid-handling", "concrete", "tycoon-residential-housing", "tycoon-desserts", "tycoon-main-dish", "tycoon-dairy-products", "tycoon-drinks" },
        unit = {
          count = 1000,
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
        name = "tycoon-university-science-purple",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/university-science-purple.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-university-science-purple",
            },
        },
        prerequisites = { "tycoon-highrise-housing", "tycoon-university-science-blue", "production-science-pack", "tycoon-money-laundering" },
        unit = {
          count = 500,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
            { "chemical-science-pack", 1 },
            { "production-science-pack", 1 },
          },
          time = 30,
        },
    },
    {
        type = "technology",
        name = "tycoon-university-science-yellow",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/university-science-yellow.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-university-science-yellow",
            },
        },
        prerequisites = { "tycoon-highrise-housing", "tycoon-university-science-purple", "utility-science-pack" },
        unit = {
          count = 500,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
            { "chemical-science-pack", 1 },
            { "utility-science-pack", 1 },
          },
          time = 30,
        },
    },
    {
        type = "technology",
        name = "tycoon-public-transportation",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/public-transportation.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-passenger-train-station",
            },
        },
        prerequisites = { "tycoon-residential-housing", "automated-rail-transportation" },
        unit = {
          count = 800,
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
        unit = {
          count = 300,
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
        unit = {
          count = 300,
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
        unit = {
          count = 400,
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
        prerequisites = { "tycoon-electronic-devices", "tycoon-residential-housing", "advanced-electronics-2" },
        unit = {
          count = 600,
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
        unit = {
          count = 300,
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
        icon = "__tycoon__/graphics/technology/money-tech.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-money-stack",
            },
        },
        prerequisites = { "tycoon-residential-housing" },
        unit = {
            count = 400,
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
        name = "tycoon-advanced-treasury-payouts",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/technology/advanced-treasury-payouts.png",
        icon_size = 190,
        effects = {
            {
                -- this still triggers the on_research_finished event
                type = "nothing",
            },
        },
        prerequisites = { "tycoon-money-laundering" },
        unit = {
            count = 800,
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
            count = 800,
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
        icon = "__tycoon__/graphics/technology/multiple-cities.png",
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
