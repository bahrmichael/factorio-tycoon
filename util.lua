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
--- @return number Number of lower tier houses needed.
local function countPendingLowerTierHouses(lowerTierBuildingCounts, higherTierBuildingCounts)
    local higherTierExpectation = higherTierBuildingCounts * 3
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


return {
    countPendingLowerTierHouses = countPendingLowerTierHouses,
    hasReachedLowerTierThreshold = hasReachedLowerTierThreshold,
    lowerTierThreshold = lowerTierThreshold,
    splitString = splitString,
    indexOf = indexOf,
    calculateDistance = calculateDistance,
}