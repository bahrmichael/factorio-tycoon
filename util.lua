local Constants = require("constants")
local UtilBitwise = require("util-bitwise")

local function splitString(s, delimiter)
    local parts = {}
    for substring in s:gmatch("[^" .. delimiter .. "]+") do
        table.insert(parts, substring)
    end
    return parts
end

-- Return the first index with the given value (or nil if not found).
--- @param array any[]
--- @param value any
--- @return number | nil Index The index of the element in the array, or nil if there's no match.
local function indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end

--- @param p1 Coordinates
--- @param p2 Coordinates
--- @return number The distance between the two points.
local function calculateDistance(p1, p2)
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    return math.sqrt(dx * dx + dy * dy)
end

--- @param v number
--- @param min number
--- @param max number
--- @return number Clamped value to [min;max] range
local function clamp(v, min, max)
    if v < min then
        return min
    elseif v > max then
        return max
    end
    return v
end

--- @param v number
--- @param min number Lower bound of v
--- @param max number Upper bound of v
--- @return number Normalized value in [0;1] range
local function normalize(v, min, max)
    return (v - min) / (max - min)
end

--- @param v number Normalized value in [0;1] range
--- @param min number
--- @param max number
--- @return number Linear interpolation of [min;max] range by v
local function lerp(v, min, max)
    return min + (max - min)*v
end

--- Similar to lerp, but clamps v into [0;1] range
local function lerpClamped(v, min, max)
    return lerp(clamp(v, 0, 1), min, max)
end

--- @param p Position
--- @return ChunkPosition
local function positionToChunk(p)
    -- Factorio-Lua, // // // !
    --return { x = p.x // Constants.CHUNK_SIZE, y = p.y // Constants.CHUNK_SIZE }
    return { x = math.floor(p.x / Constants.CHUNK_SIZE), y = math.floor(p.y / Constants.CHUNK_SIZE) }
end

--- @param p Position
--- @param size number Region size
--- @return RegionPosition
local function positionToRegion(p, size)
    return { x = math.floor(p.x / (Constants.CHUNK_SIZE * size)), y = math.floor(p.y / (Constants.CHUNK_SIZE * size)) }
end

--- @param ch ChunkPosition
--- @return Position
local function chunkToPosition(ch)
    return { x = ch.x * Constants.CHUNK_SIZE, y = ch.y * Constants.CHUNK_SIZE }
end

--- @param ch ChunkPosition
--- @param size number Region size
--- @return Position
local function chunkToRegion(ch, size)
    return { x = math.floor(ch.x / size), y = math.floor(ch.y / size) }
end

--- @param ch ChunkPosition
--- @param size number Size of array in one dimension
--- @return number Index in array
local function chunkToIndex2D(ch, size)
    return math.floor(ch.y % size)*size + math.floor(ch.x % size)
end

--- we could use string.format("%d;%d", p.x, p.y), but it looks slower
--- @param p ChunkPosition, only integers please! For floats use math.floor()
--- @return number Hash to be used for dictionary keys
local function chunkToHash(p)
    -- WARN: only 16-bit signed values [-32768; 32767] are usable, uncomment assert to crash with message
    --assert( (p.x >= -32768 and p.x <= 32767) and (p.y >= -32768 and p.y <= 32767) )
    return UtilBitwise.pack2xInt16(p.x, p.y)
end

--- @param k Hash used for dictionary keys, as returned by chunkToHash()
--- @return ChunkPosition
local function chunkFromHash(k)
    local p = UtilBitwise.unpack2xInt16(k)
    return { x = p[1], y = p[2] }
end

--- @param v number Factorio slider value [0.16; 6.0] aka [17%; 600%] as in gui
--- @return number value in the [-1; 1] range
local function factorioSliderInverse(v)
    -- formula is like e^((x-1)/3) for x==[-5;6], but can't find it. starting value 0 or 1?
    --  x:   -5   -4   -3   -2   -1    0    1    2    3    4    5    6
    --  v: 0.16 0.25 0.33 0.50 0.75 1.00 1.33 1.50 2.00 3.00 4.00 6.00
    if v < 1.0 then
        return (1 - 1/v)/(6-1)
    end

    return normalize(v, 1, 6)
end

assert(factorioSliderInverse(1/6) == -1)
assert(factorioSliderInverse(1.0) ==  0)
assert(factorioSliderInverse(6.0) ==  1)


--- @param lowerTierBuildingCounts number
--- @param higherTierBuildingCounts number
--- @param houseRatio number
--- @return number Number of lower tier houses needed.
local function countPendingLowerTierHouses(lowerTierBuildingCounts, higherTierBuildingCounts, houseRatio)
    -- or 0 is for simple houses that might not send anything
    local higherTierExpectation = higherTierBuildingCounts * (houseRatio or 0)
    if lowerTierBuildingCounts < higherTierExpectation then
        return higherTierExpectation - lowerTierBuildingCounts
    end

    return 0
end

local lowerTierThreshold = {
    highrise = 20,
    residential = 20,
}

local function hasReachedLowerTierThreshold(city, currentHousingTier)
    if currentHousingTier == "highrise" then
        local residentialCount = ((city.buildingCounts or {})["residential"] or 0)
        return residentialCount >= lowerTierThreshold[currentHousingTier]
    elseif currentHousingTier == "residential" then
        local simpleCount = ((city.buildingCounts or {})["simple"] or 0)
        return simpleCount >= lowerTierThreshold[currentHousingTier]
    else
        return true
    end
end

local function findCityById(cityId)
    for _, city in ipairs(global.tycoon_cities) do
        if city.id == cityId then
            return city
        end
    end
    return nil
end

local function findCityByTownHallUnitNumber(townHallUnitNumber)
    for _, city in ipairs(global.tycoon_cities) do
        if (city.special_buildings.town_hall or {}).valid
            and (city.special_buildings.town_hall or {}).unit_number == townHallUnitNumber then
            return city
        end
    end
    return nil
end

local function isSupplyBuilding(entityName)
    for _, supplyBuildingName in ipairs(Constants.CITY_SUPPLY_BUILDINGS) do
        if entityName == supplyBuildingName then
            return true
        end
    end
    return false
end

--- @param entityName string
--- @return boolean
local function isHouse(entityName)
    return string.find(entityName, "tycoon-house-", 1, true) ~= nil
end

local function findCityByEntityUnitNumber(unitNumber)
    local metaInfo = (global.tycoon_entity_meta_info or {})[unitNumber]
    if metaInfo == nil then
        return "Unknown"
    end
    local cityId = metaInfo.cityId
    local cityName = ((global.tycoon_cities or {})[cityId] or {}).name
    return cityName or "Unknown"
end

local function list_special_city_buildings(city, name)
    local entities = {}
    if city.special_buildings.other[name] ~= nil and #city.special_buildings.other[name] > 0 then
        entities = city.special_buildings.other[name]
    else
        entities = game.surfaces[city.surface_index].find_entities_filtered{
            name=name,
            position=city.center,
            radius=Constants.CITY_RADIUS,
        }
        city.special_buildings.other[name] = entities
    end

    local result = {}
    for _, entity in ipairs(entities) do
        if entity ~= nil and entity.valid then
            table.insert(result, entity)
        end
    end
    return result
end

local function aggregateSupplyBuildingResources(supplyBuildings)
    local resources = {}

    for _, entity in ipairs(supplyBuildings) do
        local contents = entity.get_inventory(defines.inventory.chest).get_contents()
        for item, count in pairs(contents) do
            resources[item] = (resources[item] or 0) + count
        end
    end

    return resources
end

return {
    countPendingLowerTierHouses = countPendingLowerTierHouses,
    hasReachedLowerTierThreshold = hasReachedLowerTierThreshold,
    lowerTierThreshold = lowerTierThreshold,
    splitString = splitString,
    indexOf = indexOf,
    calculateDistance = calculateDistance,

    clamp = clamp,
    normalize = normalize,
    lerp = lerp,
    lerpClamped = lerpClamped,

    positionToChunk = positionToChunk,
    positionToRegion = positionToRegion,
    chunkToPosition = chunkToPosition,
    chunkToRegion = chunkToRegion,
    chunkToIndex2D = chunkToIndex2D,
    chunkToHash = chunkToHash,
    chunkFromHash = chunkFromHash,

    factorioSliderInverse = factorioSliderInverse,

    findCityByTownHallUnitNumber = findCityByTownHallUnitNumber,
    findCityById = findCityById,
    isSupplyBuilding = isSupplyBuilding,
    isHouse = isHouse,
    findCityByEntityUnitNumber = findCityByEntityUnitNumber,

    aggregateSupplyBuildingResources = aggregateSupplyBuildingResources,
    list_special_city_buildings = list_special_city_buildings,
}