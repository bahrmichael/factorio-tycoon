local function increase_productivity(new_recipe, entity_name)
    for i, primary_industry in pairs(storage.tycoon_primary_industries[entity_name] or {}) do
        if primary_industry.valid then
            primary_industry.set_recipe(new_recipe)
            primary_industry.recipe_locked = true
        else
            table.remove(storage.tycoon_primary_industries[entity_name], i)
        end
    end
end

local function on_research_finished(event)
    if storage.tycoon_primary_industries == nil then
        return
    end

    local research = event.research
    local name = research.name

    if name == "tycoon-apple-farm-productivity" then
        increase_productivity("tycoon-grow-apples-with-water-" .. research.level, "tycoon-apple-farm")
    elseif name == "tycoon-wheat-farm-productivity" then
        increase_productivity("tycoon-grow-wheat-with-water-" .. research.level, "tycoon-wheat-farm")
    elseif name == "tycoon-fishery-productivity" then
        increase_productivity("tycoon-fishing-" .. research.level, "tycoon-fishery")
    elseif name == "tycoon-bottling" then
        for _, city in pairs(storage.tycoon_cities or {}) do
            table.insert(city.priority_buildings, {name = "tycoon-bottle-return-station", priority = 5})
        end
    elseif name == "tycoon-new-cities" then
        for _, city in pairs(storage.tycoon_cities or {}) do
            if city.special_buildings.town_hall ~= nil and city.special_buildings.town_hall.valid then
                city.special_buildings.town_hall.insert({name = "tycoon-town-hall", count = 1})
                game.print({"", {"tycoon-town-hall-added", city.name}})
                break
            end
        end
    elseif name == "tycoon-advanced-treasury-payouts" then
        storage.tycoon_money_stacks_treasury_researched = true
    end
end

return {
    on_research_finished = on_research_finished,
}
