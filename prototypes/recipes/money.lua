data:extend{
    {
        type = "recipe",
        name = "tycoon-money-stack",
        category = "crafting",
        icon = "__tycoon__/graphics/icons/money-stack.png",
        icon_size = 64,
        energy_required = 5,
        subgroup = "tycoon-additional-intermediates",
        order = "a[tycoon]-e[money-stack]",
        enabled = false,
        ingredients = {
            { type = "item", name = "tycoon-currency", amount = 100 },
        },
        results = {
            { type = "item", name = "tycoon-money-stack", amount = 1, probability = 0.9 },
        },
        localised_name = { "item-name.tycoon-money-stack" },

    },
}
