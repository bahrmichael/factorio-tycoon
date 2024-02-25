local PrimaryIndustries = require("primary-industries")

if global.tycoon_primary_industries ~= nil then
    for name, _ in pairs(global.tycoon_primary_industries or {}) do
        local recipe = PrimaryIndustries.getFixedRecipeForIndustry(name)
        for _, entity in pairs(global.tycoon_primary_industries[name] or {}) do
            if entity.valid then
                entity.set_recipe(recipe)
            end
        end
    end
end
