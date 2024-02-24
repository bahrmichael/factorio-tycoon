local function increase_productivity(new_recipe, entity_name)
    for i, primary_industry in pairs(global.tycoon_primary_industries[entity_name] or {}) do
        if primary_industry.valid then
            primary_industry.set_recipe(new_recipe)
            primary_industry.recipe_locked = true
        else
            table.remove(global.tycoon_primary_industries[entity_name], i)
        end
    end
end

local function on_research_finished(event)
    if global.tycoon_primary_industries == nil then
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
    end
end

return {
    on_research_finished = on_research_finished,
}