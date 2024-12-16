local Util = require("util")

local GLOBAL_FIELD_NAME = "tycoon-used-bottles"
local EMPTY_VALUE = 0

local function assert_init(city_id)
    if storage[GLOBAL_FIELD_NAME] == nil then
        storage[GLOBAL_FIELD_NAME] = {
            [city_id] = EMPTY_VALUE
        }
    elseif storage[GLOBAL_FIELD_NAME][city_id] == nil then
        storage[GLOBAL_FIELD_NAME][city_id] = EMPTY_VALUE
    end
end

local function change_used_bottles(city_id, bottle_count)
    assert_init(city_id)

    storage[GLOBAL_FIELD_NAME][city_id] = storage[GLOBAL_FIELD_NAME][city_id] + bottle_count
end

local function count_used_bottles(city_id)
    assert_init(city_id)

    return storage[GLOBAL_FIELD_NAME][city_id]
end

local function return_used_bottles(city)
    local current_count = count_used_bottles(city.id)
    if current_count == 0 then
        return
    end

    local stations = Util.list_special_city_buildings(city, "tycoon-bottle-return-station")
    if #stations == 0 then
        return
    end

    local stations_with_space = {}
    for _, s in pairs(stations) do
        if s ~= nil and s.valid then
            local inventory = s.get_inventory(defines.inventory.chest)
            table.insert(stations_with_space, {
                station = s,
                available_slots = inventory.count_empty_stacks(),
            })
        end
    end

    local count_returned_bottles = 0
    for _, entry in pairs(stations_with_space) do
        if entry.available_slots > 1 then
            local share_per_station = math.ceil(current_count / #stations)
            if share_per_station == 0 then
                break
            end
            local target_quantity = city.generator(share_per_station)
            local quantity = math.min(share_per_station, target_quantity)
            local used_bottles_stack_size = 50 -- todo: can we load this from the prototype?
            entry.station.insert{name = "tycoon-used-bottle", count = math.min(quantity, entry.available_slots * used_bottles_stack_size)}
            count_returned_bottles = count_returned_bottles + quantity
        end
    end

    change_used_bottles(city.id, -1 * count_returned_bottles)
end

return {
    change_used_bottles = change_used_bottles,
    return_used_bottles = return_used_bottles,
}
