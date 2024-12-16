-- WARN: migrations are run BEFORE any init(), always need this here
if storage.tycoon_cities == nil then
    storage.tycoon_cities = {}
end

for _, city in pairs(storage.tycoon_cities) do
    local _, x = math.modf(city.center.x)
    local _, y = math.modf(city.center.y)
    if math.abs(x) > 0.001 or math.abs(y) > 0.001 then
        log(string.format("non-integer center: %.3f, %.3f id: %d name: %s",
            city.center.x, city.center.y, city.id, city.name
        ))
        city.center = { x = math.floor(city.center.x), y = math.floor(city.center.y) }
    end
end
