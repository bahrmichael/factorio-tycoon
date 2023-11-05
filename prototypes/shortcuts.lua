data:extend({
	{
    type = "shortcut",
    name = "tycoon-cities-overview", 
    toggleable = false,
    localised_name = { "shortcut.tycoon-cities-overview"},
    icon = {
      filename = "__tycoon__/graphics/shortcut_open_x32.png",
      priority = "extra-high-no-scale",
      size = 32,
      scale = 1,
      flags = {"icon"}
    },
    order = "a[tycoon]-a[town-overview]",
    action = "lua",
    associated_control_input = "tycoon-cities-overview",
	}
})