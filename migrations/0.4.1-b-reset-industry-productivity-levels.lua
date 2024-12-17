local PrimaryIndustries = require("primary-industries")

if storage.tycoon_primary_industries ~= nil then
    for name, _ in pairs(storage.tycoon_primary_industries or {}) do
        local recipe = PrimaryIndustries.getFixedRecipeForIndustry(name)
        for _, entity in pairs(storage.tycoon_primary_industries[name] or {}) do
            if entity.valid then
                entity.set_recipe(recipe)
            end
        end
    end
end
