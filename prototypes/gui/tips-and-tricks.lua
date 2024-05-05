data:extend({
    {
      type = "tips-and-tricks-item-category",
      name = "tycoon",
      order = "a[tycoon]",
    },
    {
      type = "tips-and-tricks-item",
      name = "tycoon-about-tycoon",
      category = "tycoon",
      order = "a[tycoon]",
      starting_status = "suggested",
      is_title = true,
    },
    {
      type = "tips-and-tricks-item",
      name = "tycoon-cities",
      category = "tycoon",
      order = "a[tycoon]-a",
      starting_status = "suggested",
      indent = 1,
    },
    {
        type = "tips-and-tricks-item",
        name = "tycoon-currency",
        category = "tycoon",
        order = "a[tycoon]-b",
        starting_status = "suggested",
        indent = 1,
    },
    {
        type = "tips-and-tricks-item",
        name = "tycoon-supply-buildings",
        category = "tycoon",
        order = "a[tycoon]-c",
        indent = 1,
        trigger = {
            type = "or",
            triggers = {
                {
                    type = "craft-item",
                    event_type = "crafting-finished",
                    item = "tycoon-water-tower"
                },
                {
                    type = "craft-item",
                    event_type = "crafting-finished",
                    item = "tycoon-market"
                },
                {
                    type = "craft-item",
                    event_type = "crafting-finished",
                    item = "tycoon-hardware-store"
                }
            }
        }
    },
    {
        type = "tips-and-tricks-item",
        name = "tycoon-primary-industries",
        category = "tycoon",
        order = "a[tycoon]-d",
        indent = 1,
        trigger = {
            type = "time-elapsed",
            ticks = 60 * 60 * 15, -- 30 minutes
        },
    },
    {
        type = "tips-and-tricks-item",
        name = "tycoon-residential-needs",
        category = "tycoon",
        order = "a[tycoon]-e-a",
        indent = 1,
        trigger = {
            type = "research",
            technology = "tycoon-residential-housing"
        },
    },

    {
        type = "tips-and-tricks-item",
        name = "tycoon-recycling",
        category = "tycoon",
        order = "a[tycoon]-e-b",
        indent = 1,
        trigger = {
            type = "research",
            technology = "tycoon-bottling"
        },
    },
    {
        type = "tips-and-tricks-item",
        name = "tycoon-highrise-needs",
        category = "tycoon",
        order = "a[tycoon]-e-c",
        indent = 1,
        trigger = {
            type = "research",
            technology = "tycoon-highrise-housing"
        },
    },
    {
        type = "tips-and-tricks-item",
        name = "tycoon-fund-new-cities",
        category = "tycoon",
        order = "a[tycoon]-f-a",
        indent = 1,
        trigger = {
            type = "research",
            technology = "tycoon-multiple-cities"
        },
    },
    {
        type = "tips-and-tricks-item",
        name = "tycoon-cities-overview",
        category = "tycoon",
        order = "a[tycoon]-f-b",
        indent = 1,
        trigger = {
            type = "research",
            technology = "tycoon-multiple-cities"
        },
    },
    {
        type = "tips-and-tricks-item",
        name = "tycoon-public-transportation",
        category = "tycoon",
        order = "a[tycoon]-g-a",
        indent = 1,
        trigger = {
            type = "research",
            technology = "tycoon-public-transportation"
        },
    },
    {
        type = "tips-and-tricks-item",
        name = "tycoon-passenger-train-stations",
        category = "tycoon",
        order = "a[tycoon]-g-b",
        indent = 1,
        trigger = {
            type = "research",
            technology = "tycoon-public-transportation"
        },
    },
  })