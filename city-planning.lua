--- @param p1 Coordinates
--- @param p2 Coordinates
--- @return number The distance between the two points.
local function calculateDistance(p1, p2)
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    return math.sqrt(dx * dx + dy * dy)
end

-- every 1 minute
script.on_nth_tick(3600, function ()
    if not game.forces.player.technologies["tycoon-multiple-cities"].researched then
        return
    end

    local cityPlanningCenters = game.surfaces[1].find_entities_filtered{
        type = "tycoon-city-planning-center"
    }

    local totalAvailableFunds = 0
    for _, c in ipairs(cityPlanningCenters) do
        local availableFunds = c.get_item_count("tycoon-currency")
        totalAvailableFunds = totalAvailableFunds + availableFunds
    end

    -- improve this function to scale up
    local requiredFunds = #(global.tycoon_cities or {}) * 1000
    if requiredFunds > totalAvailableFunds then
        return
    end

    -- sort the centers with most currency first, so that we need to remove from fewer centers
    table.sort(cityPlanningCenters, function (a, b)
        return a.get_item_count("tycoon-currency") > b.get_item_count("tycoon-currency")
    end)

    for _, c in ipairs(cityPlanningCenters) do
        local availableCount = c.get_item_count("tycoon-currency")
        local removed = c.remove_item({name = "tycoon-currency", count = math.min(requiredFunds, availableCount)})
        requiredFunds = requiredFunds - removed
        if requiredFunds <= 0 then
            break
        end
    end

    -- make up to 10 attempts
    for i = 1, 10, 1 do
        local chunk = game.surfaces[1].get_random_chunk()
        if chunk ~= nil then
            if game.forces.player.is_chunk_charted(game.surfaces[1], chunk.position) then
                local position = { x = chunk.position.x * 32, y = chunk.position.y * 32 }
                for _, city in ipairs(global.tycoon_cities) do
                    local cityCenter = city.center
                    local distance = calculateDistance(city.center, position)
                    -- Require at least 32 chunks (or 3200 tiles), so that we can find a suitable position and leave space for the city's supply building radius
                    if distance > 100 * 32 then
                        local newCityPosition = game.surfaces[1].find_non_colliding_position("tycoon-town-center-virtual", position, 400, 5, true)
                        if newCityPosition ~= nil then
                            local isChunkCharted = game.forces.player.is_chunk_charted(game.surfaces[1], {
                                x = math.floor(newCityPosition.x / 32),
                                y = math.floor(newCityPosition.y / 32),
                            })
                            if isChunkCharted then
                                -- todo: spawn a new city
                            end
                        end
                        -- local newCity
                        -- city.grid = {
                        --     {{"corner.rightToBottom"},    {"linear.horizontal"}, {"corner.bottomToLeft"}},
                        --     {{"linear.vertical"}, {"town-hall"},         {"linear.vertical"}},
                        --     {{"corner.topToRight"},    {"linear.horizontal"}, {"corner.leftToTop"}},
                        -- }
                    
                        -- city.center.x = newCityCenter.x
                        -- city.center.y = newCityCenter.y
                    end
                end
            end
        end
    end

end)