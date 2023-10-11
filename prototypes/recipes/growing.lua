data:extend{
    {
        type = "recipe-category",
        name = "tycoon-growing"
    },
    {
        type = "recipe",
        name = "tycoon-grow-apples-with-water",
        category = "tycoon-growing",
        energy_required = 30,
        enabled = true,
        ingredients = {
            { type = "fluid", name = "water", amount = 300 },
        },
        result = "tycoon-apple",
        result_count = 150,
    },
    {
        type = "recipe",
        name = "tycoon-grow-wheat-with-water",
        category = "tycoon-growing",
        energy_required = 30,
        enabled = true,
        ingredients = {
            { type = "fluid", name = "water", amount = 400 },
        },
        result = "tycoon-wheat",
        result_count = 50,
    }
}