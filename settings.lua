data:extend({
    {
        type = "bool-setting",
        name = "tycoon-spawn-initial-city",
        setting_type = "startup",
        default_value = true,
    },
    {
        type = "int-setting",
        name = "tycoon-tags-text-length",
        setting_type = "runtime-global",
        default_value = 16,
        minimum_value = 0,
        maximum_value = 32,
    },
})