data:extend{
    {
      type = "tool",
      name = "tycoon-citizen-science-pack",
      icon = "__tycoon__/graphics/icons/citizen-science-pack.png",
      icon_size = 64,
      durability = 100,
      subgroup = "science-pack",
      group = "intermediate-products",
      -- utility science pack is f, so we place citizen science after that
      order = "g[citizen-science-pack]",
      stack_size = 200
    }
  }
