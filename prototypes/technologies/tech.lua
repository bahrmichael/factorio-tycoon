data:extend{
    {
        type = "technology",
        name = "tycoon-wind-power",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/wind-turbine.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-wind-turbine",
            }
        },
        order = "g-e-e",
        unit = {
          count = 10,
          ingredients = {
            { "automation-science-pack", 1 },
          },
          time = 10,
        },
    },
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
          count = 10,
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
                recipe = "tycoon-milk-cow",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-building-stable",
            },
            {
                type = "unlock-recipe",
                recipe = "tycoon-grow-cows-with-grain",
            },
        },
        prerequisites = { "tycoon-farming" },
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
        prerequisites = { "tycoon-farming", "tycoon-husbandry", "automation-2" },
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
        prerequisites = { "tycoon-husbandry", "automation-2" },
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
        prerequisites = { "steel-processing", "optics", "tycoon-meat-processing", "tycoon-baking" },
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
        prerequisites = { "fluid-handling", "concrete", "tycoon-residential-housing", "tycoon-bottling" },
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
        name = "tycoon-multiple-cities",
        mod = "Tycoon",
        icon = "__tycoon__/graphics/icons/multiple-cities.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-urban-planning-center",
            },
        },
        prerequisites = { "tycoon-highrise-housing", "automated-rail-transportation", "advanced-electronics" },
        order = "g-e-e",
        unit = {
          count = 100,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
            { "chemical-science-pack", 1 },
            { "production-science-pack", 1 },
          },
          time = 60,
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
        prerequisites = { "tycoon-multiple-cities" },
        order = "g-e-e",
        unit = {
          count = 200,
          ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
            { "chemical-science-pack", 1 },
            { "production-science-pack", 1 },
          },
          time = 60,
        },
    },
    {
        type = "technology",
        name = "tycoon-apple-farm-productivity-1",
        mod = "Tycoon",
        level = 1,
        icon = "__tycoon__/graphics/icons/apple-farm.png",
        icon_size = 256,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "tycoon-grow-apples-with-water-2",
            },
        },
        prerequisites = { "tycoon-farming" },
        unit = {
            count = 20,
            ingredients = {
                { "automation-science-pack", 1 },
            },
            time = 30,
        },
    },
}

for i = 2, 10, 1 do
    data:extend{
        {
            type = "technology",
            name = "tycoon-apple-farm-productivity-" .. i,
            mod = "Tycoon",
            level = i,
            icon = "__tycoon__/graphics/icons/apple-farm.png",
            icon_size = 256,
            effects = {
                {
                    type = "unlock-recipe",
                    recipe = "tycoon-grow-apples-with-water-" .. i + 1,
                },
            },
            prerequisites = { "tycoon-apple-farm-productivity-" .. (i - 1) },
            unit = {
                count = 20+math.pow(i*2, 2),
                ingredients = {
                    { "automation-science-pack", 1 },
                },
                time = 30,
            },
        },
    }
end