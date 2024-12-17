local Constants = require("constants")

-- WARN: migrations are run BEFORE any init(), always need this here
if storage.tycoon_cities == nil then
    storage.tycoon_cities = {}
end

for _, city in pairs(storage.tycoon_cities) do
    city.surface_index = Constants.STARTING_SURFACE_ID
end
