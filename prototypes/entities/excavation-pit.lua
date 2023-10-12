local function createExcavationPit(name, spriteSize)
  return {
    type = "container",
    name = "tycoon-" .. name,
    icon = "__tycoon__/graphics/entity/" .. name .. "/" .. name .. ".png",
    icon_size = 64,
    max_health = 200,
    rotatable = false,
    inventory_size = 0,
    corpse = "small-remnants",
    vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
    repair_sound = {filename = "__base__/sound/manual-repair-simple.ogg"},
    open_sound = {filename = "__base__/sound/machine-open.ogg", volume = 0.85},
    close_sound = {filename = "__base__/sound/machine-close.ogg", volume = 0.75},
    collision_box = { { -2.4, -2.4}, {2.4, 2.4} },
    selection_box = { { -2.4, -2.4}, {2.4, 2.4} },
    picture = {
        layers = {
            {
                filename = "__tycoon__/graphics/entity/" .. name .. "/" .. name .. ".png",
                priority = "high",
                width = spriteSize.width,
                height = spriteSize.height,
                scale = 1,
                shift = {0, 0}
            },
        }
    },
  }
end

local function getSpriteSize(i)
  if i == 5 then
    return {
      width = 170,
      height = 173,
    }
  elseif i == 10 or i == 11 then
    return {
      width = 170,
      height = 170,
    }
  elseif i == 17 then
    return {
      width = 190,
      height = 185,
    }
  elseif i == 18 then
    return {
      width = 161,
      height = 177,
    }
  elseif i == 19 then
    return {
      width = 160,
      height = 164,
    }
  else
    return {
      width = 200,
      height = 200,
    }
  end
end

for i = 1, 20, 1 do
  data:extend{createExcavationPit("excavation-pit-" .. i, getSpriteSize(i))}
end