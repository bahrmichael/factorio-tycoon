-- WARN: migrations are run BEFORE any init(), always need this here
if storage.tycoon_cities == nil then
    storage.tycoon_cities = {}
end

for _, city in pairs(storage.tycoon_cities) do
    log(string.format("debt: %.3f id: %d name: %s", city.stats.debt or 0, city.id, city.name))
    if city.stats.debt == nil then
        city.stats.debt = 0.0
    end
end
