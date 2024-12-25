data:extend {
    {
        type = "recipe-category",
        name = "tycoon-fishing"
    }
}

local function add_incresing_tech(recipe_name_base, recipe_category, result_name, order_suffix)
    for i = 1, 11, 1 do
        data:extend {
            {
                type = "recipe",
                name = recipe_name_base .. "-" .. i,
                category = recipe_category,
                order = "a[tycoon]-" .. order_suffix,
                subgroup = "tycoon-primary-resources",
                energy_required = 30,
                enabled = i == 1,
                ingredients = {},
                results = { { type = "item", name = result_name, amount = i == 1 and 15 or (12 + math.pow(i * 3, 2)) } },
                localised_name = { "item-name." .. result_name },
                hidden = true,
                hidden_from_player_crafting = true,
            },
        }
    end
end

add_incresing_tech("tycoon-fishing", "tycoon-fishing", "raw-fish", "a[fish]")
