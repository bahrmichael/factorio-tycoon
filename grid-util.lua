local Constants = require("constants")

local function getGridSize(grid)
    return #grid
end

--- @param city City
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

--- @param city City
--- @param coordinates Coordinates
--- @param value Cell
--- @return any | nil cell
local function safeGridSet(city, coordinates, value)
    local row = city.grid[coordinates.y]
    if row ~= nil then
        -- make sure we don't set local
        city.grid[coordinates.y][coordinates.x] = value
        return row[coordinates.x]
    end
end

--- @param city City
local function getOffsetX(city)
    -- -3 is because the center starts at the top left of the initial 3x3 grid. so at the beginning there must be no additional offset.
    -- but then it should grow by one for each grid expansion (each expansion is 2 rows and columns, so we divide it by 2)
    return city.center.x - ((getGridSize(city.grid) - 3) / 2) * Constants.CELL_SIZE
end

--- @param city City
local function getOffsetY(city)
    return city.center.y - ((getGridSize(city.grid) - 3) / 2) * Constants.CELL_SIZE
end

local function translateCoordinateDistance(coordinates)
    -- -1 because for the 1x1 cell, we want to start at the top left most city center start coordinates, so they need to shift by 0/0
    return {
        y = (coordinates.y - 1) * Constants.CELL_SIZE,
        x = (coordinates.x - 1) * Constants.CELL_SIZE,
    }
end

local function translateCityGridToTileCoordinates(city, coordinates)
    local distance = translateCoordinateDistance(coordinates)
    local y = distance.y + getOffsetY(city)
    local x = distance.x + getOffsetX(city)
    return {
        x = x,
        y = y,
    }
end

local function translateToGrid(city, position)
    local x = 1 + math.floor(math.floor(position.x - getOffsetX(city)) / Constants.CELL_SIZE)
    local y = 1 + math.floor(math.floor(position.y - getOffsetY(city)) / Constants.CELL_SIZE)
    return {x = x, y = y}
end

return {
    getGridSize = getGridSize,
    getOffsetX = getOffsetX,
    getOffsetY = getOffsetY,
    safeGridAccess = safeGridAccess,
    safeGridSet = safeGridSet,
    translateCityGridToTileCoordinates = translateCityGridToTileCoordinates,
    translateToGrid = translateToGrid,
}
