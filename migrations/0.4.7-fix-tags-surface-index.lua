local Constants = require("constants")

-- WARN: migrations are run BEFORE any init(), always need this here
if global.tycoon_tags_queue == nil then
    global.tycoon_tags_queue = {}
end

-- we can't remove while iterating, need to rebuild
local new_queue = {}
for _, tag in pairs(global.tycoon_tags_queue) do
    local k = _
    local t = tag

    if #tag == 2 then
        log(string.format("fixing old tag: [%d] = %s", _, serpent.line(tag)))
        t = {tag[1], tag[2], Constants.STARTING_SURFACE_ID}
        k = Constants.STARTING_SURFACE_ID .."-".. _
    elseif #tag < 2 then
        t = nil
    end

    new_queue[k] = t
end
-- replace old array with new one
global.tycoon_tags_queue = new_queue
