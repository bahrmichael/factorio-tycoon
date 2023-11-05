local GridUtil = require("grid-util")
local Segments = require("segments")
local Consumption = require("consumption")
local Constants = require("constants")
local DataConstants = require("data-constants")
local Queue = require("queue")

local function printTiles(startY, startX, map, tileName)
    local x, y = startX, startY
    for _, value in ipairs(map) do
        for i = 1, #value do
            local char = string.sub(value, i, i)
            if char == "1" then
                game.surfaces[1].set_tiles({{name = tileName, position = {x, y}}})
            end
            x = x + 1
        end
        x = startX
        y = y + 1
    end
end

--- @param p1 Coordinates
--- @param p2 Coordinates
--- @return number The distance between the two points.
local function calculateDistance(p1, p2)
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    return math.sqrt(dx * dx + dy * dy)
end

local MIN_DISTANCE = Constants.CITY_RADIUS * 2 + 200
local COST_PER_CITY = 1000

local function isInRangeOfCity(city, position)
    local distance = calculateDistance(city.center, position)
    return distance < MIN_DISTANCE
end

local function isInRangeOfAnyCity(position)
    for _, city in ipairs(global.tycoon_cities) do
        if isInRangeOfCity(city, position) then
            return true
        end
    end
    return false
end

local function findNewCityPosition()
    -- make up to 10 attempts
    for i = 1, 10, 1 do
        local chunk = game.surfaces[1].get_random_chunk()
        if chunk ~= nil then
            if game.forces.player.is_chunk_charted(game.surfaces[1], chunk) then
                local position = { x = chunk.x * 32, y = chunk.y * 32 }
                if not isInRangeOfAnyCity(position) then
                    local newCityPosition = game.surfaces[1].find_non_colliding_position("tycoon-town-center-virtual", position, Constants.CITY_RADIUS, 5, true)
                    if newCityPosition ~= nil then
                        local isChunkCharted = game.forces.player.is_chunk_charted(game.surfaces[1], {
                            x = math.floor(newCityPosition.x / 32),
                            y = math.floor(newCityPosition.y / 32),
                        })
                        if isChunkCharted then
                            local playerEntities = game.surfaces[1].find_entities_filtered{
                                position = newCityPosition,
                                radius = Constants.CITY_RADIUS,
                                force = game.forces.player,
                                limit = 1
                            }
                            if #playerEntities == 0 then
                                return {
                                    x = math.floor(newCityPosition.x),
                                    y = math.floor(newCityPosition.y),
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function initialGrid()
    return {
        {
            {
                type = "road",
                roadSockets = {"south", "north", "east", "west"},
                initKey = "corner.rightToBottom"
            },
            {
                type = "road",
                roadSockets = {"east", "west"},
                initKey = "linear.horizontal"
            },
            {
                type = "road",
                roadSockets = {"south", "north", "east", "west"},
                initKey = "corner.bottomToLeft"
            }
        },
        {
            {
                type = "road",
                roadSockets = {"south", "north"},
                initKey = "linear.vertical"
            },
            {
                type = "building",
                initKey = "town-hall"
            },
            {
                type = "road",
                roadSockets = {"south", "north"},
                initKey = "linear.vertical"
            },
        },
        {
            {
                type = "road",
                roadSockets = {"south", "north", "east", "west"},
                initKey = "corner.topToRight"
            },
            {
                type = "road",
                roadSockets = {"east", "west"},
                initKey = "linear.horizontal"
            },
            {
                type = "road",
                roadSockets = {"south", "north", "east", "west"},
                initKey = "corner.leftToTop"
            }
        }
    }
end

local function initializeCity(city, position)
    city.grid = initialGrid()

    local function clearCell(y, x)
        local area = {
            -- Add 1 tile of border around it, so that it looks a bit nicer
            {x - 1, y - 1},
            {x + Constants.CELL_SIZE + 1, y + Constants.CELL_SIZE + 1}
        }
        local removables = game.surfaces[1].find_entities_filtered({
            area=area,
            name={"character", "tycoon-town-hall"},
            invert=true
        })
        for _, entity in ipairs(removables) do
            if entity.valid then
                entity.destroy()
            end
        end
    end

    for y = 1, GridUtil.getGridSize(city.grid) do
        for x = 1, GridUtil.getGridSize(city.grid) do
            local cell = GridUtil.safeGridAccess(city, {x=x, y=y}, "initializeCity")
            if cell ~= nil then
                local map = Segments.getMapForKey(cell.initKey)
                local startCoordinates = GridUtil.translateCityGridToTileCoordinates(city, {x=x, y=y})
                clearCell(startCoordinates.y, startCoordinates.x)
                if map ~= nil then
                    printTiles(startCoordinates.y, startCoordinates.x, map, "concrete")
                end
                if cell.initKey == "town-hall" then
                    local thPosition = {
                        x = startCoordinates.x - 1 + Constants.CELL_SIZE / 2, 
                        y = startCoordinates.y - 1 + Constants.CELL_SIZE / 2,
                    }
                    local townHall = game.surfaces[1].create_entity{
                        name = "tycoon-town-hall",
                        position = thPosition,
                        force = "neutral",
                        move_stuck_players = true
                    }
                    game.surfaces[1].create_entity{
                        name = "hiddenlight-60",
                        position = thPosition,
                        force = "neutral",
                    }
                    townHall.destructible = false
                    city.special_buildings.town_hall = townHall
                    global.tycoon_city_buildings[townHall.unit_number] = {
                        cityId = city.id,
                        entity_name = townHall.name,
                        entity = townHall
                    }
                end
            end
        end
    end

    local possibleRoadEnds = {
        {
            coordinates = {
                x = 1,
                y = 1,
            },
            direction = "west"
        },
        {
            coordinates = {
                x = 1,
                y = 1,
            },
            direction = "north"
        },

        {
            coordinates = {
                x = 3,
                y = 1,
            },
            direction = "east"
        },
        {
            coordinates = {
                x = 3,
                y = 1,
            },
            direction = "north"
        },

        {
            coordinates = {
                x = 3,
                y = 3,
            },
            direction = "east"
        },
        {
            coordinates = {
                x = 3,
                y = 3,
            },
            direction = "south"
        },

        {
            coordinates = {
                x = 1,
                y = 3,
            },
            direction = "west"
        },
        {
            coordinates = {
                x = 1,
                y = 3,
            },
            direction = "south"
        },
    }

    city.roadEnds = Queue.new()

    -- We're adding some randomness here
    -- Instead of adding 8 road connections to the town center, we pick between 4 and 8.
    -- This makes individual towns feel a bit more diverse.
    local roadEndCount = city.generator(4, 8)
    for i = 1, roadEndCount, 1 do
        Queue.pushright(city.roadEnds, table.remove(possibleRoadEnds, city.generator(#possibleRoadEnds)))
    end

    table.insert(city.priority_buildings, {name = "tycoon-treasury", priority = 10})
end

local function addCity(position)
    if global.tycoon_cities == nil then
        global.tycoon_cities = {}
    end
    local cityId = #global.tycoon_cities + 1
    local cityName = DataConstants.CityNames[(cityId % #DataConstants.CityNames) + 1]
    local generatorSalt = cityId * 1337
    table.insert(global.tycoon_cities, {
        id = cityId,
        generator = game.create_random_generator(game.surfaces[1].map_gen_settings.seed + generatorSalt),
        grid = {},
        pending_cells = {},
        priority_buildings = {},
        special_buildings = {
            town_hall = nil,
            other = {}
        },
        center = position,
        name = cityName,
        stats = {
            basic_needs = {},
            construction_materials = {}
        },
        citizens = {
            simple = 0,
            residential = 0,
            highrise = 0,
        },
    })
    initializeCity(global.tycoon_cities[cityId], position)
    Consumption.updateNeeds(global.tycoon_cities[cityId])

    return cityName
end

local function getRequiredFundsForNextCity()
    -- improve this function to scale up
    return math.pow(#(global.tycoon_cities or {}), 2) * COST_PER_CITY
end

local function getTotalAvailableFunds()
    local urbanPlanningCenters = game.surfaces[1].find_entities_filtered{
        name = "tycoon-urban-planning-center"
    }

    local totalAvailableFunds = 0
    for _, c in ipairs(urbanPlanningCenters) do
        local availableFunds = c.get_item_count("tycoon-currency")
        totalAvailableFunds = totalAvailableFunds + availableFunds
    end

    return totalAvailableFunds
end

local function addMoreCities()
    if not (game.forces.player.technologies["tycoon-multiple-cities"] or {}).researched then
        return
    end

    local urbanPlanningCenters = game.surfaces[1].find_entities_filtered{
        name = "tycoon-urban-planning-center"
    }

    local totalAvailableFunds = getTotalAvailableFunds()
    local requiredFunds = getRequiredFundsForNextCity()

    if requiredFunds > totalAvailableFunds then
        return
    end

    local newCityPosition = findNewCityPosition()
    if newCityPosition ~= nil then
        local cityName = addCity(newCityPosition)
        game.print({"", "[color=orange]Factorio Tycoon:[/color] ", {"tycooon-new-city", cityName}, ": ", "[gps=" .. (newCityPosition.x + 1.5 * Constants.CELL_SIZE) .. "," .. (newCityPosition.y + 1.5 * Constants.CELL_SIZE) .. "]"})

        -- sort the centers with most currency first, so that we need to remove from fewer centers
        table.sort(urbanPlanningCenters, function (a, b)
            return a.get_item_count("tycoon-currency") > b.get_item_count("tycoon-currency")
        end)
        for _, c in ipairs(urbanPlanningCenters) do
            local availableCount = c.get_item_count("tycoon-currency")
            local removed = c.remove_item({name = "tycoon-currency", count = math.min(requiredFunds, availableCount)})
            requiredFunds = requiredFunds - removed
            if requiredFunds <= 0 then
                break
            end
        end
    end

end

return {
    addCity = addCity,
    addMoreCities = addMoreCities,
    getRequiredFundsForNextCity = getRequiredFundsForNextCity,
    getTotalAvailableFunds = getTotalAvailableFunds,
    findNewCityPosition = findNewCityPosition,
}