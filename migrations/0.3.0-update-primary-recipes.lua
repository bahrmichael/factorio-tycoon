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

for key, entity_group in pairs(storage.tycoon_primary_industries or {}) do
    for _, entity in pairs(entity_group or {}) do
        if entity ~= nil and entity.valid then
            local new_recipe
            if key == "tycoon-apple-farm" then
                local level = findHighestProductivityLevel("tycoon-apple-farm-productivity")
                new_recipe = "tycoon-grow-apples-with-water-" .. level
            elseif key == "tycoon-wheat-farm" then
                local level = findHighestProductivityLevel("tycoon-wheat-farm-productivity")
                new_recipe = "tycoon-grow-wheat-with-water-" .. level
            elseif key == "tycoon-fishery" then
                local level = findHighestProductivityLevel("tycoon-fishing")
                new_recipe = "tycoon-fishing-" .. level
            end
            if new_recipe ~= nil then
                entity.set_recipe(new_recipe)
                entity.recipe_locked = true
            end
        end
    end
end
