local Constants = require("constants")

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

return {
    countPendingLowerTierHouses = countPendingLowerTierHouses,
    hasReachedLowerTierThreshold = hasReachedLowerTierThreshold,
    lowerTierThreshold = lowerTierThreshold,
    splitString = splitString,
    indexOf = indexOf,
    calculateDistance = calculateDistance,
    findCityByTownHallUnitNumber = findCityByTownHallUnitNumber,
    findCityById = findCityById,
    isSupplyBuilding = isSupplyBuilding,
    isHouse = isHouse,
    findCityByEntityUnitNumber = findCityByEntityUnitNumber,
}