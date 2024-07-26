local citizen_science_lab = table.deepcopy(data.raw["lab"]["lab"])

citizen_science_lab.name = "tycoon-citizen-science-lab"
-- citizen_science_lab.icon = "__tycoon__/graphics/icons/citizen-science-lab.png"
-- citizen_science_lab.icon_size = 64
citizen_science_lab.minable.result = "tycoon-citizen-science-lab"
citizen_science_lab.inputs = {"tycoon-citizen-science-pack"}
citizen_science_lab.energy_usage = "75kW"
citizen_science_lab.researching_speed = 1
citizen_science_lab.module_specification = nil

-- citizen_science_lab.on_animation = {
--     layers = {
--         {
--             filename = "__tycoon__/graphics/entity/citizen-science-lab/citizen-science-lab.png",
--             width = 98,
--             height = 87,
--             frame_count = 33,
--             line_length = 11,
--             animation_speed = 1 / 3,
--             shift = util.by_pixel(0, 1.5),
--             hr_version = {
--                 filename = "__tycoon__/graphics/entity/citizen-science-lab/hr-citizen-science-lab.png",
--                 width = 194,
--                 height = 174,
--                 frame_count = 33,
--                 line_length = 11,
--                 animation_speed = 1 / 3,
--                 shift = util.by_pixel(0, 1.5),
--                 scale = 0.5
--             }
--         },
--         {
--             filename = "__tycoon__/graphics/entity/citizen-science-lab/citizen-science-lab-shadow.png",
--             width = 122,
--             height = 68,
--             frame_count = 1,
--             line_length = 1,
--             repeat_count = 33,
--             animation_speed = 1 / 3,
--             shift = util.by_pixel(13, 11),
--             draw_as_shadow = true,
--             hr_version = {
--                 filename = "__tycoon__/graphics/entity/citizen-science-lab/hr-citizen-science-lab-shadow.png",
--                 width = 242,
--                 height = 136,
--                 frame_count = 1,
--                 line_length = 1,
--                 repeat_count = 33,
--                 animation_speed = 1 / 3,
--                 shift = util.by_pixel(13, 11),
--                 scale = 0.5,
--                 draw_as_shadow = true
--             }
--         }
--     }
-- }

-- citizen_science_lab.off_animation = citizen_science_lab.on_animation

data:extend({citizen_science_lab})
