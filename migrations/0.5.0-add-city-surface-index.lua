local Constants = require("constants")

-- WARN: migrations are run BEFORE any init(), always need this here
if global.tycoon_cities == nil then
    global.tycoon_cities = {}
end

for _, city in pairs(global.tycoon_cities) do
    city.surface_index = Constants.STARTING_SURFACE_ID
end
