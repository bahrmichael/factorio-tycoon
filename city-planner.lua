local GridUtil = require("grid-util")
local Segments = require("segments")
local Consumption = require("consumption")
local Constants = require("constants")
local DataConstants = require("data-constants")
local Queue = require("queue")
local Util = require("util")

local function printTiles(startY, startX, map, tileName, surface_index)
    local x, y = startX, startY
    for _, value in ipairs(map) do
        for i = 1, #value do
            local char = string.sub(value, i, i)
            if char == "1" then
                game.surfaces[surface_index].set_tiles({ { name = tileName, position = { x, y } } })
            end
            x = x + 1
        end
        x = startX
        y = y + 1
    end
end

-- With an additional space of 200 the cities still spawned relatively close to each other, so I raised it to 400
local MIN_DISTANCE = Constants.CITY_RADIUS * 2 + 400
local COST_PER_CITY = 1000

local function isInRangeOfCity(city, position, surface_index)
    if city.surface_index ~= surface_index then
        return false
    end
    local distance = Util.calculateDistance(city.center, position)
    return distance < MIN_DISTANCE
end

local function isInRangeOfAnyCity(position, surface_index)
    for _, city in ipairs(global.tycoon_cities) do
        if isInRangeOfCity(city, position, surface_index) then
            return true
        end
    end
    return false
end

local function find_random_city_position(surface_index)
    local chunk = game.surfaces[surface_index].get_random_chunk()
    if chunk ~= nil then
        if game.forces.player.is_chunk_charted(game.surfaces[surface_index], chunk) then
            return Util.chunkToPosition(chunk)
        end
    end
    return nil
end

local function findNewCityPosition(isInitialTown, surface_index)
    local scorings = {}
    -- make up to 10 attempts
    for i = 1, 10, 1 do
        local position = isInitialTown and { x = math.random(-50, 50), y = math.random(-50, 50) } or find_random_city_position(surface_index)
        if position ~= nil and (isInitialTown or not isInRangeOfAnyCity(position, surface_index)) then
            local newCityPosition = game.surfaces[surface_index].find_non_colliding_position("tycoon-town-center-virtual", position,
                Constants.CITY_RADIUS, 5, true)
            if newCityPosition ~= nil then
                local isChunkCharted = isInitialTown or game.forces.player.is_chunk_charted(game.surfaces[surface_index], {
                    x = math.floor(newCityPosition.x / 32),
                    y = math.floor(newCityPosition.y / 32),
                })
                if isChunkCharted then
                    local skip = false
                    local record = {
                        position = {
                            x = math.floor(newCityPosition.x),
                            y = math.floor(newCityPosition.y),
                        },
                    }
                    if not isInitialTown then
                        local playerEntities = game.surfaces[surface_index].find_entities_filtered {
                            position = newCityPosition,
                            radius = Constants.CITY_RADIUS,
                            force = game.forces.player,
                            limit = 1
                        }
                        skip = #playerEntities > 0
                    end
                    if not skip then
                        local radius = 50 / i + 18
                        local tiles = game.surfaces[surface_index].find_tiles_filtered {
                            position = newCityPosition,
                            radius = radius,         -- The initial grid is 6x3=18, so 50 allows for 32 more, or 16 on each side, which is nearly 3 more cells. That should give the city enough space to grow outwards.
                            name = {
                                "deepwater",
                                "deepwater-green",
                                "out-of-map",
                                "water",
                                "water-green",
                                "water-shallow",
                                "water-mud",
                                "water-wube",
                            },
                        }
                        local entities = game.surfaces[surface_index].find_entities_filtered({
                            position = newCityPosition,
                            radius = radius,         -- The initial grid is 6x3=18, so 50 allows for 32 more, or 16 on each side, which is nearly 3 more cells. That should give the city enough space to grow outwards.
                            name = { "character", "tycoon-town-hall" },
                            type = { "tree", "simple-entity", "fish" },
                            invert = true
                        })
                        record.entities = #entities
                        record.tiles = #tiles

                        table.insert(scorings, record)
                    end
                end
            end
        end
    end

    local tilesFactor = 3 / game.surfaces[surface_index].map_gen_settings.water -- water is a percentage value
    local autoplaceTotal = 0
    local autoplaceCounter = 0
    for _, value in pairs(game.surfaces[surface_index].map_gen_settings.autoplace_controls) do
        autoplaceTotal = autoplaceTotal + value.frequency
        autoplaceCounter = autoplaceCounter + 1
    end
    local entitiesFactor = 2 / (autoplaceTotal / autoplaceCounter)
    local distanceWeight = 0
    if isInitialTown then
        distanceWeight = 2
    end
    local function weight(s)
        return math.pow(s.position.y, distanceWeight)
            + math.pow(s.position.x, distanceWeight)
            + math.pow(s.entities, entitiesFactor)
            + math.pow(s.tiles, tilesFactor)
    end
    table.sort(scorings, function(a, b)
        return weight(a) < weight(b)
    end)
    return (scorings[1] or {}).position
end

local function initialGrid()
    return {
        {
            {
                type = "road",
                roadSockets = { "south", "north", "east", "west" },
                initKey = "corner.rightToBottom"
            },
            {
                type = "road",
                roadSockets = { "east", "west" },
                initKey = "linear.horizontal"
            },
            {
                type = "road",
                roadSockets = { "south", "north", "east", "west" },
                initKey = "corner.bottomToLeft"
            }
        },
        {
            {
                type = "road",
                roadSockets = { "south", "north" },
                initKey = "linear.vertical"
            },
            {
                type = "building",
                initKey = "town-hall"
            },
            {
                type = "road",
                roadSockets = { "south", "north" },
                initKey = "linear.vertical"
            },
        },
        {
            {
                type = "road",
                roadSockets = { "south", "north", "east", "west" },
                initKey = "corner.topToRight"
            },
            {
                type = "road",
                roadSockets = { "east", "west" },
                initKey = "linear.horizontal"
            },
            {
                type = "road",
                roadSockets = { "south", "north", "east", "west" },
                initKey = "corner.leftToTop"
            }
        }
    }
end

local function initializeCity(city)
    city.grid = initialGrid()

    local function clearCell(y, x)
        local area = {
            -- Add 1 tile of border around it, so that it looks a bit nicer
            { x - 1,                       y - 1 },
            { x + Constants.CELL_SIZE + 1, y + Constants.CELL_SIZE + 1 }
        }
        local removables = game.surfaces[city.surface_index].find_entities_filtered({
            area = area,
            name = { "character", "tycoon-town-hall" },
            invert = true
        })
        for _, entity in ipairs(removables) do
            if entity.valid then
                entity.destroy()
            end
        end
    end

    for y = 1, GridUtil.getGridSize(city.grid) do
        for x = 1, GridUtil.getGridSize(city.grid) do
            local cell = GridUtil.safeGridAccess(city, { x = x, y = y }, "initializeCity")
            if cell ~= nil then
                local map = Segments.getMapForKey(cell.initKey)
                local startCoordinates = GridUtil.translateCityGridToTileCoordinates(city, { x = x, y = y })
                clearCell(startCoordinates.y, startCoordinates.x)
                if map ~= nil then
                    printTiles(startCoordinates.y, startCoordinates.x, map, "concrete", city.surface_index)
                end
                if cell.initKey == "town-hall" then
                    local thPosition = {
                        x = startCoordinates.x - 1 + Constants.CELL_SIZE / 2,
                        y = startCoordinates.y - 1 + Constants.CELL_SIZE / 2,
                    }
                    local townHall = game.surfaces[city.surface_index].create_entity {
                        name = "tycoon-town-hall",
                        position = thPosition,
                        force = "neutral",
                        move_stuck_players = true
                    }
                    game.surfaces[city.surface_index].create_entity {
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
    -- BUG: town hall is always +1.5 cells to the right-bottom and graphics are off-by-one
    -- can't set city.center to actual position of town hall, so lets just make it integer
    city.center = { x = math.floor(city.center.x), y = math.floor(city.center.y) }

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

    table.insert(city.priority_buildings, { name = "tycoon-treasury", priority = 10 })

    Consumption.updateNeeds(city)
end

local function addCity(position, surface_index, predefinedCityName)
    if global.tycoon_cities == nil then
        global.tycoon_cities = {}
    end
    local cityId = #global.tycoon_cities + 1
    local cityName = predefinedCityName or DataConstants.CityNames[(cityId % #DataConstants.CityNames) + 1]
    local generatorSalt = cityId * 1337
    table.insert(global.tycoon_cities, {
        id = cityId,
        surface_index = surface_index,
        generator = game.create_random_generator(game.surfaces[surface_index].map_gen_settings.seed + generatorSalt),
        grid = {},
        pending_cells = {},
        priority_buildings = {},
        special_buildings = {
            town_hall = nil,
            other = {}
        },
        -- WARN: don't floor it here yet - initializeCity() will make displaced grid
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
    initializeCity(global.tycoon_cities[cityId])

    game.print({ "",
        "[color=orange]Factorio Tycoon:[/color] ", { "tycooon-new-city", cityName }, ": ",
        "[gps=" .. (math.floor(position.x) + 1.5 * Constants.CELL_SIZE) .. "," .. (math.floor(position.y) + 1.5 * Constants.CELL_SIZE) .. "]",
    })
    return cityName
end

local function getRequiredFundsForNextCity()
    return math.pow(#(global.tycoon_cities or {}), 2) * COST_PER_CITY
end

local function getTotalAvailableFunds()
    -- We're only checking the starting surface id for planning centers, because that feature will probably be dropped soon.
    local urbanPlanningCenters = game.surfaces[Constants.STARTING_SURFACE_ID].find_entities_filtered {
        name = "tycoon-urban-planning-center"
    }

    local totalAvailableFunds = 0
    for _, c in ipairs(urbanPlanningCenters or {}) do
        local availableFunds = c.get_item_count("tycoon-currency")
        totalAvailableFunds = totalAvailableFunds + availableFunds
    end

    return totalAvailableFunds
end

local function addMoreCities(isInitialCity, skipPayment)
    local surface_index = Constants.STARTING_SURFACE_ID
    if global.tycoon_cities == nil then
        global.tycoon_cities = {}
    end
    if #global.tycoon_cities >= #DataConstants.CityNames then
        if not global.tycoon_city_limit_warning_6 then
            game.print({ "", "[color=orange]Factorio Tycoon:[/color] ", "Currently you can only build up to " ..
            #DataConstants.CityNames .. " cities. Feel free to use the currency for research going forward." })
            global.tycoon_city_limit_warning_6 = true
        end
        return false
    end

    local requiredFunds = getRequiredFundsForNextCity()
    if not skipPayment then
        if not (game.forces.player.technologies["tycoon-multiple-cities"] or {}).researched then
            return false
        end

        local totalAvailableFunds = getTotalAvailableFunds()
        if requiredFunds > totalAvailableFunds then
            return false
        end
    end

    local newCityPosition = findNewCityPosition(isInitialCity, surface_index)
    if newCityPosition ~= nil then
        local cityName = addCity(newCityPosition, surface_index)
        -- disabled for now, moved into addCity() above
        if false then
        game.print({ "", "[color=orange]Factorio Tycoon:[/color] ", { "tycooon-new-city", cityName }, ": ", "[gps=" ..
        (newCityPosition.x + 1.5 * Constants.CELL_SIZE) .. "," .. (newCityPosition.y + 1.5 * Constants.CELL_SIZE) .. "]" })
        end

        if not skipPayment then
            local urbanPlanningCenters = game.surfaces[surface_index].find_entities_filtered {
                name = "tycoon-urban-planning-center"
            } or {}
            -- sort the centers with most currency first, so that we need to remove from fewer centers
            table.sort(urbanPlanningCenters, function(a, b)
                return a.get_item_count("tycoon-currency") > b.get_item_count("tycoon-currency")
            end)
            for _, c in ipairs(urbanPlanningCenters) do
                local availableCount = c.get_item_count("tycoon-currency")
                local removed = c.remove_item({ name = "tycoon-currency", count = math.min(requiredFunds, availableCount) })
                requiredFunds = requiredFunds - removed
                if requiredFunds <= 0 then
                    break
                end
            end
        end

        return true
    end

    return false
end

local function tag_cities()
    for _, city in ipairs(global.tycoon_cities or {}) do
        -- We need to initialize the tag here, because tags can only be placed on charted chunks.
        -- And the game needs a moment to start and chart the initial chunks, even if it can already place entities.
        if city.tag == nil or not (city.tag or {}).valid then
            local tag = game.forces.player.add_chart_tag(game.surfaces[city.surface_index],
                {
                    position = city.center,
                    text = city.name
                }
            )
            city.tag = tag
        end
        -- append population
        if (city.tag or {}).valid then
            if (settings.global["tycoon-tags-show-population"] or {}).value then
                local count = 0
                for _, n in pairs(city.citizens) do
                    count = count + n
                end
                city.tag.text = city.name .." [color=gray][".. tostring(count) .."][/color]"
            else
                -- won't lag (called every ~30s), otherwise tail is left
                city.tag.text = city.name
            end
        end
    end
end

local function build_initial_city()
    if (settings.startup["tycoon-spawn-initial-city"] or {}).value and #(global.tycoon_cities or {}) == 0 then
        addMoreCities(true, true)
    end
end

return {
    addMoreCities = addMoreCities,
    getRequiredFundsForNextCity = getRequiredFundsForNextCity,
    getTotalAvailableFunds = getTotalAvailableFunds,
    addCity = addCity,
    tag_cities = tag_cities,
    build_initial_city = build_initial_city,
}
