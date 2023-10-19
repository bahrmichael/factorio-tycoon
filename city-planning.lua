local Constants = require("constants")
local SEGMENTS = require("segments")
local CONSUMPTION = require("consumption")
local Queue = require("queue")

local function getGridSize(grid)
    return #grid
end

local function getOffsetX(city)
    return (-1 * (getGridSize(city.grid) - 1) / 2) * Constants.CELL_SIZE + (city.center.x or 0)
end

local function getOffsetY(city)
    return (-1 * (getGridSize(city.grid) - 1) / 2) * Constants.CELL_SIZE + (city.center.y or 0)
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
-- every 1 minute
local EXPANSION_TICKS = 3600

local function isInRangeOfCity(city, position)
    local cityCenter = city.center
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
    for i = 1, 10, 1 do -- todo: abort after first successful build
        local chunk = game.surfaces[1].get_random_chunk()
        if chunk ~= nil then
            if game.forces.player.is_chunk_charted(game.surfaces[1], chunk) then
                local position = { x = chunk.x * 32, y = chunk.y * 32 }
                if not isInRangeOfAnyCity(position) then
                    local newCityPosition = game.surfaces[1].find_non_colliding_position("tycoon-town-center-virtual", position, 400, 5, true)
                    if newCityPosition ~= nil then
                        local isChunkCharted = game.forces.player.is_chunk_charted(game.surfaces[1], {
                            x = math.floor(newCityPosition.x / 32),
                            y = math.floor(newCityPosition.y / 32),
                        })
                        if isChunkCharted then
                            return newCityPosition
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function translateStarterCell(cell)
    if cell == "intersection" then
        cell = {
            type = "road",
            roadSockets = {"south", "north", "east", "west"}
        }
    elseif cell == "linear.horizontal" then
        cell = {
            type = "road",
            roadSockets = {"east", "west"}
        }
    elseif cell == "linear.vertical" then
        cell = {
            type = "road",
            roadSockets = {"south", "north"}
        }
    elseif cell == "town-hall" then
        cell = {
            type = "building"
        }
    else
        cell = {
            type = "road",
            roadSockets = {"south", "north", "east", "west"}
        }
        -- assert(false, "Should not reach this branch in translateStarterCell.")
    end
    return cell
end

local function initializeCity(city, position)
    city.grid = {
        {{"corner.rightToBottom"},    {"linear.horizontal"}, {"corner.bottomToLeft"}},
        {{"linear.vertical"}, {"town-hall"},         {"linear.vertical"}},
        {{"corner.topToRight"},    {"linear.horizontal"}, {"corner.leftToTop"}},
    }

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

    for y = 1, getGridSize(city.grid) do
        for x = 1, getGridSize(city.grid) do
            local cell = safeGridAccess(city, {x=x, y=y}, "initializeCity")
            if cell ~= nil then
                local map = SEGMENTS.getMapForKey(cell[1])
                local startCoordinates = {
                    y = ((y * Constants.CELL_SIZE) + getOffsetY(city)),
                    x = ((x * Constants.CELL_SIZE) + getOffsetX(city)),
                }
                clearCell(startCoordinates.y, startCoordinates.x)
                if map ~= nil then
                    printTiles(startCoordinates.y, startCoordinates.x, map, "concrete")
                end
                if cell[1] == "town-hall" then
                    local townHall = game.surfaces[1].create_entity{
                        name = "tycoon-town-hall",
                        position = {x = startCoordinates.x - 1 + Constants.CELL_SIZE / 2, y = startCoordinates.y - 1 + Constants.CELL_SIZE / 2},
                        force = "neutral",
                        move_stuck_players = true
                    }
                    game.surfaces[1].create_entity{
                        name = "hiddenlight-60",
                        position = {x = startCoordinates.x - 1 + Constants.CELL_SIZE / 2, y = startCoordinates.y - 1 + Constants.CELL_SIZE / 2},
                        force = "neutral",
                    }
                    townHall.destructible = false
                    city.special_buildings.town_hall = townHall
                    global.tycoon_city_buildings[townHall.unit_number] = {
                        cityId = city.id,
                        entity_name = townHall.name,
                        entity = townHall
                    }

                    rendering.draw_circle{
                        color = {0.1, 0.1, 0.6, 0.01},
                        radius = 250,
                        filled = true,
                        target = townHall,
                        surface = game.surfaces[1],
                        draw_on_ground = true,
                    }
                end
            end
        end
    end

    for i = 1, #city.grid, 1 do
        for j = 1, #city.grid, 1 do
            local c = safeGridAccess(city, {y=i, x=j})
            -- todo: rather replace this with a proper initial grid (no need for translation then)
            assert(c ~= nil or #c == 0, "Failed to translate starter cells of city.")
            city.grid[i][j] = translateStarterCell(c[1])
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
    local cityId = #global.tycoon_cities + 1
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
        name = "City #" .. cityId,
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
    CONSUMPTION.updateNeeds(global.tycoon_cities[cityId])
end

script.on_nth_tick(EXPANSION_TICKS, function ()
    if not game.forces.player.technologies["tycoon-multiple-cities"].researched then
        return
    end

    local cityPlanningCenters = game.surfaces[1].find_entities_filtered{
        name = "tycoon-city-planning-center"
    }

    local totalAvailableFunds = 0
    for _, c in ipairs(cityPlanningCenters) do
        local availableFunds = c.get_item_count("tycoon-currency")
        totalAvailableFunds = totalAvailableFunds + availableFunds
    end

    -- improve this function to scale up
    local requiredFunds = #(global.tycoon_cities or {}) * COST_PER_CITY
    if requiredFunds > totalAvailableFunds then
        return
    end

    -- sort the centers with most currency first, so that we need to remove from fewer centers
    table.sort(cityPlanningCenters, function (a, b)
        return a.get_item_count("tycoon-currency") > b.get_item_count("tycoon-currency")
    end)

    for _, c in ipairs(cityPlanningCenters) do
        local availableCount = c.get_item_count("tycoon-currency")
        local removed = c.remove_item({name = "tycoon-currency", count = math.min(requiredFunds, availableCount)})
        requiredFunds = requiredFunds - removed
        if requiredFunds <= 0 then
            break
        end
    end

    local newCityPosition = findNewCityPosition()
    if newCityPosition ~= nil then
        addCity(newCityPosition)
        -- game.surfaces[1].create_entity{
        --     name = "tycoon-town-hall",
        --     position = {x = newCityPosition.x - 1 + Constants.CELL_SIZE / 2, y = newCityPosition.y - 1 + Constants.CELL_SIZE / 2},
        --     force = "neutral",
        --     move_stuck_players = true
        -- }
        game.print("Created new city at x=" .. newCityPosition.x .. " y=" .. newCityPosition.y)
        -- game.forces.player.add_chart_tag(game.surfaces[1],
        --     {
        --         position = {x = newCityPosition.x, y = newCityPosition.y},
        --         text = "Another Town Center"
        --     }
        -- )
    end

    -- todo: return isk if nothing was built
end)

script.on_nth_tick(60, function()
    if #(global.tycoon_cities or {}) > 0 and game.tick >= 60 then
        return
    end

    global.tycoon_cities = {}
    local position = game.surfaces[1].find_non_colliding_position("tycoon-town-center-virtual", {0, 0}, 200, 5, true)
    addCity(position)
end)