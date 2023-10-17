for _, entity in ipairs(game.surfaces[1].find_entities_filtered{
    name = {"tycoon-apple-farm", "tycoon-wheat-farm", "tycoon-fishery"}
}) do
    entity.recipe_locked = true
end
