--- @param prefix string
--- @return number level
local function findHighestProductivityLevel(prefix)
    for i = 1, 20, 1 do
        if (game.forces.player.technologies[prefix .. "-" .. i] or {}).researched == true then
            -- noop, attempt the next level
        else
            return i
        end
    end
    return 1
end

local function getFixedRecipeForIndustry(industryName)
    if industryName == "tycoon-apple-farm" then
        local level = findHighestProductivityLevel("tycoon-apple-farm-productivity")
        local recipe = "tycoon-grow-apples-with-water-" .. level
        return recipe
    elseif industryName == "tycoon-wheat-farm" then
        local level = findHighestProductivityLevel("tycoon-wheat-farm-productivity")
        local recipe = "tycoon-grow-wheat-with-water-" .. level
        return recipe
    elseif industryName == "tycoon-fishery" then
        local level = findHighestProductivityLevel("tycoon-fishery-productivity")
        local recipe = "tycoon-fishing-" .. level
        return recipe
    end
end

if storage.tycoon_primary_industries ~= nil then
    for _, entity in ipairs(storage.tycoon_primary_industries["tycoon-wheat-farm"] or {}) do
        if entity.valid then
            local currentRecipe = entity.get_recipe()
            if currentRecipe == nil then
                entity.set_recipe(getFixedRecipeForIndustry(entity.name))
                entity.recipe_locked = true
            end
        end
    end

    for _, entity in ipairs(storage.tycoon_primary_industries["tycoon-fishery"] or {}) do
        if entity.valid then
            local currentRecipe = entity.get_recipe()
            if currentRecipe == nil then
                entity.set_recipe(getFixedRecipeForIndustry(entity.name))
                entity.recipe_locked = true
            end
        end
    end
end
