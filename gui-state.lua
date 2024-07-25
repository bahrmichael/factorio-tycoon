local function assert_state_exists(player_index)
    if global.tycoon_gui_state == nil then
        global.tycoon_gui_state = {}
    end
    if global.tycoon_gui_state[player_index] == nil then
        global.tycoon_gui_state[player_index] = {}
    end
end

local function set_state(player_index, key, path)
    assert(player_index, "Player index must not be nil.")
    assert(key, "Key must not be nil.")
    assert_state_exists(player_index)
    global.tycoon_gui_state[player_index][key] = path
end

local function get_state(player_index, key)
    assert(player_index, "Player index must not be nil.")
    assert(key, "Key must not be nil.")
    assert_state_exists(player_index)
    return global.tycoon_gui_state[player_index][key]
end

return {
    set_state = set_state,
    get_state = get_state,
    housing_type_to_tab = {
        ["overview"] = 1,
        ["simple"] = 2,
        ["residential"] =  3,
        ["highrise"] =  4,
    },
}
