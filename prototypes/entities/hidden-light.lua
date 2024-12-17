local function GenerateHiddenLight(size)
    local lightRange = size
    local hiddenLight = table.deepcopy(data.raw["lamp"]["small-lamp"])
    hiddenLight.name = "hiddenlight-" .. size
    hiddenLight.collision_mask = { layers = {} } -- So nothing can collide with it and do damage.
    hiddenLight.flags = { "not-blueprintable", "not-deconstructable", "placeable-off-grid", "not-on-map", "not-upgradable", "not-in-kill-statistics" } -- So if it should die somehow (script?) it still won't appear in any kills/losses list.
    hiddenLight.selection_box = nil --makes a nice cross on the powered area rather than a default sized box
    hiddenLight.selectable_in_game = false
    hiddenLight.picture_off = {
        filename = "__tycoon__/graphics/entity/hidden-light/transparent.png",
        priority = "very-low",
        width = 1,
        height = 1
    }
    hiddenLight.picture_on = {
        filename = "__tycoon__/graphics/entity/hidden-light/transparent.png",
        priority = "very-low",
        width = 1,
        height = 1
    }
    hiddenLight.light = { intensity = 0.6, size = lightRange, color = { r = 1.0, g = 0.7, b = 0.3 } }
    hiddenLight.energy_usage_per_tick = "1W"
    hiddenLight.energy_source.type = "void"
    hiddenLight.energy_source.render_no_network_icon = false
    hiddenLight.energy_source.render_no_power_icon = false
    return hiddenLight
end

data:extend { GenerateHiddenLight(40) }
data:extend { GenerateHiddenLight(60) }
