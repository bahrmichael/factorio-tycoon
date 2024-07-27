local citizen_science_lab = table.deepcopy(data.raw["lab"]["lab"])

citizen_science_lab.name = "tycoon-citizen-science-lab"
citizen_science_lab.icon = "__tycoon__/graphics/icons/citizen-science-lab.png"
citizen_science_lab.icon_size = 64
citizen_science_lab.minable.result = "tycoon-citizen-science-lab"
citizen_science_lab.inputs = {"tycoon-citizen-science-pack"}
citizen_science_lab.energy_usage = "75kW"
citizen_science_lab.researching_speed = 1
citizen_science_lab.module_specification = nil
citizen_science_lab.collision_box = {{-2.4, -2.4}, {2.4, 2.4}}
citizen_science_lab.selection_box = {{-2.4, -2.4}, {2.4, 2.4}}

citizen_science_lab.off_animation = {
    layers = {
        {
            filename = "__tycoon__/graphics/entity/citizen-science-lab/citizen-science-lab.png",
            width = 256,
            height = 256,
            shift = {0.05, -1.5},
            scale = 0.95,
        },
    }
}

citizen_science_lab.on_animation = citizen_science_lab.off_animation

data:extend({citizen_science_lab})
