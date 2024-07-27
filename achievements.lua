local function assert_global_achievements()
    if global.tycoon_achievements == nil then
        global.tycoon_achievements = {}
    end
end

local function unlock_achievement_for_all(achievement_name)
    for _, player in pairs(game.players) do
        player.unlock_achievement(achievement_name)
    end
end

--- @param city City
local function countCitizens(city)
    local total = 0
    for _, count in pairs(city.citizens) do
        total = total + count
    end
    return total
end

local function check_population_achievements()
    assert_global_achievements()
    if global.tycoon_achievements.population_complete then
        return
    end
    local total = 0;
    local next_step = global.tycoon_achievements.population_next_step or 100
    for _, city in ipairs(global.tycoon_cities or {}) do
        local citizen_count = countCitizens(city)
        total = total + citizen_count
        if total >= next_step then
            unlock_achievement_for_all("tycoon-population-" .. next_step)
            if next_step >= 100000 then
                global.tycoon_achievements.population_complete = true
            else
                global.tycoon_achievements.population_next_step = next_step * 10
            end
            return
        end
    end
end

local function check_passenger_transport_achievements()
    assert_global_achievements()
    if global.tycoon_achievements.passenger_transport_complete then
        return
    end
    local next_step = global.passenger_transport_next_step or 100
    local passengers_transported = global.tycoon_passenger_transported_count or 0
    
    if passengers_transported >= next_step then
        unlock_achievement_for_all("tycoon-passenger-transport-" .. next_step)
        if next_step >= 100000 then
            global.tycoon_achievements.passenger_transport_complete = true
        else
            global.tycoon_achievements.passenger_transport_next_step = next_step * 10
        end
        return
    end
end

return {
    unlock_achievement_for_all = unlock_achievement_for_all,
    check_population_achievements = check_population_achievements,
    check_passenger_transport_achievements = check_passenger_transport_achievements,
}
