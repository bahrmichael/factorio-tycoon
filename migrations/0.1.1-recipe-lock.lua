local Constants = require("constants")

for _, entity in ipairs(game.surfaces[Constants.STARTING_SURFACE_ID].find_entities_filtered{
    name = {"tycoon-apple-farm", "tycoon-wheat-farm", "tycoon-fishery"}
}) do
    entity.recipe_locked = true
end
