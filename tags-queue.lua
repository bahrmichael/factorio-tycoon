local Util = require("util")

local function get_queue()
    if global.tycoon_tags_queue == nil then
        global.tycoon_tags_queue = {}
    end
    return global.tycoon_tags_queue
end

local function key(chunk_position, surface_index)
    return surface_index .. "-" .. Util.chunkToHash(chunk_position)
end

local function get(chunk_position, surface_index)
    local k = key(chunk_position, surface_index)
    return get_queue()[k]
end

local function set(chunk_position, surface_index, entity_name, entity_position)
    local k = key(chunk_position, surface_index)
    -- storing pos and name is a bit too much, but avoids searching for entity, which might be more expensive
    get_queue()[k] = { pos = entity_position, entity_name, surface_index }
end

local function delete(chunk_position, surface_index)
    local k = key(chunk_position, surface_index)
    get_queue()[k] = nil
end

return {
    get = get,
    set = set,
    delete = delete,
}