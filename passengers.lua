local Constants = require("constants")

--- @param city City
local function countCitizens(city)
    local total = 0
    for _, count in pairs(city.citizens) do
        total = total + count
    end
    return total
end

--- @param city City
--- @param name string
local function listSpecialCityBuildings(city, name)
    local entities = {}
    if city.special_buildings.other[name] ~= nil and #city.special_buildings.other[name] > 0 then
        entities = city.special_buildings.other[name]
    else
        if not city.special_buildings.town_hall.valid then
            return {}
        end
        entities = game.surfaces[1].find_entities_filtered{
            name=name,
            position=city.special_buildings.town_hall.position,
            radius=Constants.CITY_RADIUS
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

--- @param currentCity string
--- @return string | nil name
local function getRandomCityName(currentCityName)
    if #(global.tycoon_cities or {}) == 0 then
        return nil
    end
    -- up to 10 attempts at getting a random entry that's different to the current name
    for i = 1, 10, 1 do
        local r = global.tycoon_cities[math.random(#global.tycoon_cities)].name
        if r ~= currentCityName then
            return r
        end
    end
    return nil
end

--- @param city City
local function spawnPassengers(city)
    if not (game.forces.player.technologies["tycoon-public-transportation"] or {}).researched then
        return
    end

    -- todo: add train stations to special buildings
    local citizenCount = countCitizens(city)
    local newPassengerCount = math.random(0, 1) -- todo: find a better approach to increase the number of new citizens with city growth
    if newPassengerCount > 0 then
        local trainStations = listSpecialCityBuildings(city, "tycoon-passenger-train-station")
        if #trainStations > 0 then
            local selectedTrainStation = trainStations[math.random(#trainStations)]
            if selectedTrainStation ~= nil and selectedTrainStation.valid then

                local passengerLimit = (global.tycoon_train_station_limits or {})[selectedTrainStation.unit_number] or 100
                local departingPassengers = 0
                for name, count in pairs(selectedTrainStation.get_inventory(1).get_contents()) do
                    if name ~= "tycoon-passenger-" .. string.lower(city.name) and string.find(name, "tycoon-passenger-", 1, true) then
                        departingPassengers = departingPassengers + count
                    end
                end
                if departingPassengers >= passengerLimit then
                    return
                end

                -- todo: check if train station has enough space, otherwise distribute passengers
                local destination = getRandomCityName(city.name)
                if destination == nil then
                    return
                end
                local passenger = "tycoon-passenger-" .. string.lower(destination)
                selectedTrainStation.insert{name = passenger, count = newPassengerCount}

                -- selectedTrainStation.get_inventory(1).find_item_stack("tycoon-passenger-gearford")
                for i = 1, #selectedTrainStation.get_inventory(1), 1 do
                    local p = selectedTrainStation.get_inventory(1)[i]
                    if p ~= nil and p.valid and p.valid_for_read and p.name == passenger and p.tags.created == nil then
                        p.set_tag("created", game.tick)
                        p.set_tag("origin", string.lower(city.name))
                        p.set_tag("destination", string.lower(destination))
                    end
                end
            end
        end
    end
end

local function findCityByName(name)
    for _, city in ipairs((global.tycoon_cities or {})) do
        if string.lower(city.name) == name then
            return city
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

local function getCredits(passenger)
    
    local originCity = findCityByName(passenger.origin)
    local destinationCity = findCityByName(passenger.destination)
    if originCity == nil or destinationCity == nil then
        game.print("The tycoon mod has encountered a problem: Credits for a passenger couldn't be awarded because the origin or destination city could not be found.")
        return 0
    end
    
    local distance = calculateDistance(originCity.center, destinationCity.center)
    local ticksNeeded = game.tick - passenger.created
    -- With vanilla, robot research brings them to 9 tiles per second when level 6 is researched (the first one that needs space science).
    local fullRewardForDistance = math.ceil(distance / 100)
    local fastestDelivery = distance / 9
    local rewardRate = fastestDelivery / ticksNeeded
    local reward = fullRewardForDistance * rewardRate
    return reward
end

--- @param city City
local function clearPassengers(city)
    if not (game.forces.player.technologies["tycoon-public-transportation"] or {}).researched then
        return
    end

    local passengerName = "tycoon-passenger-" .. string.lower(city.name)

    local trainStations = listSpecialCityBuildings(city, "tycoon-passenger-train-station")
    local treasuries = listSpecialCityBuildings(city, "tycoon-treasury")
    if #trainStations > 0 then
        for _, trainStation in ipairs(trainStations) do

            local cleared = {}

            for i = 1, #trainStation.get_inventory(1), 1 do
                local p = trainStation.get_inventory(1)[i]
                if p ~= nil and p.valid and p.valid_for_read and p.name == passengerName then
                    table.insert(cleared, {
                        origin = p.tags.origin,
                        created = p.tags.created,
                        destination = p.tags.destination,
                    })
                end
            end

            local passengersForCurrentCity = trainStation.get_item_count("tycoon-passenger-" .. string.lower(city.name))
            if passengersForCurrentCity > 0 then
                trainStation.remove_item{name = "tycoon-passenger-" .. string.lower(city.name), count = passengersForCurrentCity}

                local reward = 0
                for _, v in ipairs(cleared) do
                    reward = reward + getCredits(v)
                end

                if #treasuries > 0 and reward > 0 then
                    local randomTreasury = treasuries[city.generator(#treasuries)]
                    randomTreasury.insert{name = "tycoon-currency", count = math.ceil(reward)}
                end
            end
        end
    end
end

return {
    spawnPassengers = spawnPassengers,
    clearPassengers = clearPassengers,
}