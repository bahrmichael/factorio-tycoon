data:extend{
    {
        type = "recipe-category",
        name = "tycoon-growing-apples"
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

data:extend{
    {
        type = "recipe",
        name = "tycoon-grow-apples-with-water-1",
        category = "tycoon-growing-apples",
        order = "a[tycoon]-a[apples]",
        energy_required = 30,
        enabled = true,
        ingredients = {
            { type = "fluid", name = "water", amount = 300 },
        },
        result = "tycoon-apple",
        -- 50 per minute is a good starting amount
        result_count = 25
    },
}
for i = 2, 11, 1 do
    data:extend{
        {
            type = "recipe",
            name = "tycoon-grow-apples-with-water-" .. i,
            category = "tycoon-growing-apples",
            order = "a[tycoon]-a[apples]",
            energy_required = 30,
            enabled = false,
            ingredients = {
                { type = "fluid", name = "water", amount = 300 },
            },
            result = "tycoon-apple",
            result_count = 16+math.pow(i*3, 2),
        },
    }
end