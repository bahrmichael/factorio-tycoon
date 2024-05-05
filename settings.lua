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
    {
        type = "bool-setting",
        name = "tycoon-tags-show-population",
        order = "4-t-s",
        setting_type = "runtime-global",
        default_value = true,
    },
    {
        type = "bool-setting",
        name = "tycoon-skip-check-resources",
        order = "5-s-c",
        setting_type = "runtime-global",
        default_value = false,
    },
    {
        type = "bool-setting",
        name = "tycoon-reveal-spawned",
        order = "6-r-s",
        setting_type = "runtime-global",
        default_value = false,
    },
})