-- convert v0.4.0 back to a simple array
if storage.tycoon_primary_industries ~= nil then
    local new_array = {}

    for name, _ in pairs(storage.tycoon_primary_industries or {}) do
        new_array[name] = {}

        for k, entity in pairs(storage.tycoon_primary_industries[name] or {}) do
            if entity.valid then
                table.insert(new_array[name], entity)
            else
                log("invalid entity '".. tostring(name) .."', index: ".. tostring(k))
            end
        end
        local count = #new_array[name]
        if count ~= 0 then
            log("tycoon_primary_industries['".. tostring(name) .."']: ".. tostring(count))
        end
    end
    -- rewrite whole arrays at once
    storage.tycoon_primary_industries = new_array
end
