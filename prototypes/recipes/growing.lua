data:extend{
    {
        type = "recipe-category",
        name = "tycoon-growing-apples"
    },
    {
        type = "recipe",
        name = "tycoon-grow-apples-with-water",
        category = "tycoon-growing-apples",
        order = "a[tycoon]-a[apples]",
        energy_required = 30,
        enabled = true,
        ingredients = {
            { type = "fluid", name = "water", amount = 300 },
        },
        result = "tycoon-apple",
        result_count = 150,
    },
    {
        type = "recipe-category",
        name = "tycoon-growing-wheat"
    },
    {
        type = "recipe",
        name = "tycoon-grow-wheat-with-water",
        category = "tycoon-growing-wheat",
        order = "a[tycoon]-b[wheat]",
        energy_required = 30,
        enabled = true,
        ingredients = {
            { type = "fluid", name = "water", amount = 400 },
        },
        result = "tycoon-wheat",
        result_count = 50,
    }
}