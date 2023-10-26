local Constants = require("constants")

local function getGridSize(grid)
    return #grid
end

--- @param city City
local function getOffsetX(city)
    return city.center.x - ((getGridSize(city)) / 2) * Constants.CELL_SIZE
end

--- @param city City
local function getOffsetY(city)
    return city.center.y - ((getGridSize(city)) / 2) * Constants.CELL_SIZE
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
            game.print({"", {"tycoon-grid-access-warning", {"tycoon-grid-access-cell"}, sendWarningForMethod}})
        end
        return nil
    end
    return cell
end

local function translateCityGridToTileCoordinates(city, coordinates)
    return {
        y = ((coordinates.y - 1) * Constants.CELL_SIZE + getOffsetY(city)),
        x = ((coordinates.x - 1) * Constants.CELL_SIZE + getOffsetX(city)),
    }
end

return {
    getGridSize = getGridSize,
    getOffsetX = getOffsetX,
    getOffsetY = getOffsetY,
    safeGridAccess = safeGridAccess,
    translateCityGridToTileCoordinates = translateCityGridToTileCoordinates,
}