data:extend{
    {
        type = "recipe-category",
        name = "tycoon-growing"
    },
    {
        type = "recipe",
        name = "tycoon-grow-apples-with-water",
        category = "tycoon-growing",
        energy_required = 60,
        enabled = true,
        ingredients = {
            { type = "fluid", name = "water", amount = 200 },
        },
        result = "tycoon-apple",
        result_count = 40,
    },
    {
        type = "recipe",
        name = "tycoon-grow-wheat-with-water",
        category = "tycoon-growing",
        energy_required = 60,
        enabled = false,
        ingredients = {
            { type = "fluid", name = "water", amount = 200 },
        },
        result = "tycoon-wheat",
        result_count = 40,
    }
}