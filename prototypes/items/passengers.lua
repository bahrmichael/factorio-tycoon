local DataConstants = require("data-constants")

for i, v in ipairs(DataConstants.CityNames) do
  data:extend{
    {
      type = "item-with-tags",
      name = "tycoon-passenger-" .. string.lower(v),
      icon = "__tycoon__/graphics/icons/passengers/" .. i .. ".png",
      icon_size = 64,
      subgroup = "tycoon-passengers",
      order = "a[tycoon]-a[passenger]-a[" .. i .. "]",
      stack_size = 1
    }
  }
end
