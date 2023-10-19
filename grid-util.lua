local Constants = require("constants")

local function getGridSize(grid)
    return #grid
end

--- @param city City
local function getOffsetX(city)
    return -1 * (getGridSize(city.grid) - 1) / 2 + city.center.x
end

--- @param city City
local function getOffsetY(city)
    return -1 * (getGridSize(city.grid) - 1) / 2 + city.center.y
end

--- @param coordinates Coordinates
--- @param sendWarningForMethod string | nil
--- @return any | nil cell
local function safeGridAccess(city, coordinates, sendWarningForMethod)
    local row = city.grid[coordinates.y]
    if row == nil then
        if sendWarningForMethod ~= nil then
            game.print({"", {"tycoon-grid-access-warning", {"tycoon-grid-access-row"}, sendWarningForMethod}})
        end
        return nil
    end
    local cell = row[coordinates.x]
    if cell == nil then
        if sendWarningForMethod ~= nil then
            game.print({"", {"tycoon-grid-access-warning", {"tycoon-grid-access-row"}, sendWarningForMethod}})
        end
        return nil
    end
    return cell
end

local function translateCityGridToTileCoordinates(city, coordinates)
    return {
        y = (coordinates.y + getOffsetY(city)) * Constants.CELL_SIZE,
        x = (coordinates.x + getOffsetX(city)) * Constants.CELL_SIZE,
    }
end

return {
    getGridSize = getGridSize,
    getOffsetX = getOffsetX,
    getOffsetY = getOffsetY,
    safeGridAccess = safeGridAccess,
    translateCityGridToTileCoordinates = translateCityGridToTileCoordinates,
}