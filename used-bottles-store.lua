local Util = require("util")

local GLOBAL_FIELD_NAME = "tycoon-used-bottles"
local EMPTY_VALUE = 0

local function assert_init(city_id) 
    if global[GLOBAL_FIELD_NAME] == nil then
        global[GLOBAL_FIELD_NAME] = {
            [city_id] = EMPTY_VALUE
        }
    elseif global[GLOBAL_FIELD_NAME][city_id] == nil then
        global[GLOBAL_FIELD_NAME][city_id] = EMPTY_VALUE
    end
end

local function change_used_bottles(city_id, bottle_count)
    assert_init(city_id)

    global[GLOBAL_FIELD_NAME][city_id] = global[GLOBAL_FIELD_NAME][city_id] + bottle_count
end

local function count_used_bottles(city_id)
    assert_init(city_id)

    return global[GLOBAL_FIELD_NAME][city_id]
end

local function return_used_bottles_to_market(city)
    local current_count = count_used_bottles(city.id)
    if current_count == 0 then
        return
    end

    local markets = Util.list_special_city_buildings(city, "tycoon-market")
    if #markets == 0 then
        return
    end

    local markets_with_space = {}
    for _, market in pairs(markets) do
        if market ~= nil and market.valid then
            local inventory = market.get_inventory(defines.inventory.chest)
            table.insert(markets_with_space, {
                market = market,
                available_slots = inventory.count_empty_stacks(),
            })
        end
    end

    local count_returned_bottles = 0
    for _, entry in pairs(markets_with_space) do
        if entry.available_slots > 1 then
            local share_per_market = math.ceil(current_count / #markets)
            local target_quantity = math.random(share_per_market)
            local quantity = math.min(share_per_market, target_quantity)
            local used_bottles_stack_size = 50 -- todo: can we load this from the prototype?
            entry.market.insert{name = "tycoon-used-bottle", count = math.min(quantity, entry.available_slots * used_bottles_stack_size)}
            count_returned_bottles = count_returned_bottles + quantity
        end
    end

    change_used_bottles(city.id, -1 * count_returned_bottles)
end

return {
    change_used_bottles = change_used_bottles,
    return_used_bottles_to_market = return_used_bottles_to_market,
}