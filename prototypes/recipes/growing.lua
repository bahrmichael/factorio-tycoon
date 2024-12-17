data:extend{
    {
        type = "recipe-category",
        name = "tycoon-growing-apples"
    },
    {
        type = "recipe-category",
        name = "tycoon-growing-wheat"
    }
}

local function add_incresing_tech(recipe_name_base, recipe_category, result_name, order_suffix)
    for i = 1, 11, 1 do
        data:extend{
            {
                type = "recipe",
                name = recipe_name_base .. "-" .. i,
                category = recipe_category,
                order = "a[tycoon]-" .. order_suffix,
                energy_required = 30,
                enabled = i == 1,
                ingredients = {
                    { type = "fluid", name = "water", amount = 300 },
                },
                -- power fit from ~100/min to ~1800/min, (energy_required=30 needs half of that)
                -- lvl  1: ( 1+f) / (11+f) = sqrt( 100/min) => f = ~2.084
                -- lvl 11: (11+f) / (11+f) = sqrt(1800/min)
                results = {{type="item", name=result_name, amount=(30/60) * 1800 * math.pow((i+2.084) / (11+2.084), 2)}},
                hidden = true,
                hidden_from_player_crafting = true,
            },
        }
    end
end

add_incresing_tech("tycoon-grow-wheat-with-water", "tycoon-growing-wheat", "tycoon-wheat", "b[wheat]")
add_incresing_tech("tycoon-grow-apples-with-water", "tycoon-growing-apples", "tycoon-apple", "a[apples]")
