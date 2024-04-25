local Constants = require("constants")
local Util = require("util")

--- @param city City
--- @param filter string | nil
local function countCitizens(city, filter)
    local total = 0
    for tier, count in pairs(city.citizens) do
        if filter == nil then
            total = total + count
        elseif filter == tier then
            total = total + count
        end
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
        entities = game.surfaces[city.surface_index].find_entities_filtered{
            name=name,
            position=city.center,
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

--- @param city City
--- @param excludedNames string[] | nil
--- @return string | nil name
local function getRandomCityName(city, excludedNames)
    if #(global.tycoon_cities or {}) == 0 then
        return nil
    end
    -- up to 10 attempts at getting a random entry that's different to the current name
    for i = 1, 10, 1 do
        local r = global.tycoon_cities[city.generator(#global.tycoon_cities)].name
        if r ~= city.name then
            if excludedNames ~= nil and #excludedNames > 0 then
                if not Util.indexOf(excludedNames, r) then
                    return r
                end
            else
                return r
            end
        end
    end
    return nil
end

--- @param cityName string
--- @return number | nil
local function get_max_departing_passengers_for_destination(cityName)
    local destinationCity = nil
    for id, city in ipairs(global.tycoon_cities or {}) do
        if city.name == cityName then
            destinationCity = city
            break
        end
    end

    if destinationCity == nil then
        return nil
    end

    local citizenCount = countCitizens(destinationCity)
    -- This function gives us a value that scales to 2/3 at x=1000 and to 0.9 at 5000
    local citizenFactor = citizenCount / (citizenCount + 500)
    return math.floor(citizenCount / 10 * citizenFactor)
end

--- @param city City
local function spawnPassengers(city)
    if not (game.forces.player.technologies["tycoon-public-transportation"] or {}).researched then
        return
    end

    local residentialCount = countCitizens(city, "residential")
    local highriseCount = countCitizens(city, "highrise")

    local citizenCount = countCitizens(city)
    -- This function gives us a value that scales to 2/3 at x=1000 and to 0.9 at 5000
    local citizenFactor = citizenCount / (citizenCount + 500)

    -- Residential housing have 20 citizens and highrise have 100. That means we generate up to 1 per residential and up to 5 per highrise house.
    local newPassengerCount = math.floor((residentialCount * 0.05 + highriseCount * 0.05) * citizenFactor * city.generator())
    if newPassengerCount > 0 then
        local trainStations = listSpecialCityBuildings(city, "tycoon-passenger-train-station")
        if #trainStations > 0 then
            local selectedTrainStation = trainStations[city.generator(#trainStations)]
            if selectedTrainStation ~= nil and selectedTrainStation.valid then

                local passengerLimit = (global.tycoon_train_station_limits or {})[selectedTrainStation.unit_number] or 80
                local departingPassengers = 0
                for name, count in pairs(selectedTrainStation.get_inventory(1).get_contents()) do
                    if name ~= "tycoon-passenger-" .. string.lower(city.name) and string.find(name, "tycoon-passenger-", 1, true) then
                        departingPassengers = departingPassengers + count
                    end
                end
                if (departingPassengers + newPassengerCount) >= passengerLimit then
                    return
                end

                -- todo: check if train station has enough space, otherwise distribute passengers

                local excludedCityNames = {}
                if global.tycoon_train_station_passenger_filters ~= nil and global.tycoon_train_station_passenger_filters[selectedTrainStation.unit_number] ~= nil then
                    for cityId, state in pairs(global.tycoon_train_station_passenger_filters[selectedTrainStation.unit_number]) do
                        if state == false then
                            table.insert(excludedCityNames, global.tycoon_cities[cityId].name)
                        end
                    end
                end

                local destination = getRandomCityName(city, excludedCityNames)
                if destination == nil then
                    return
                end

                local currentPassengersForDestination = 0
                for name, count in pairs(selectedTrainStation.get_inventory(1).get_contents()) do
                    if name == "tycoon-passenger-" .. string.lower(destination) then
                        currentPassengersForDestination = currentPassengersForDestination + count
                    end
                end
                local maxForDestination = get_max_departing_passengers_for_destination(destination)
                if maxForDestination == nil or maxForDestination == 0 then
                    return
                end


                local passenger = "tycoon-passenger-" .. string.lower(destination)
                local insertedPassengerCount = selectedTrainStation.insert{name = passenger, count = math.min(newPassengerCount, maxForDestination)}
                for player_index, _ in pairs(game.players) do
                    game.players[player_index].create_local_flying_text{
                        text = {"", {"tycoon-passengers-new", insertedPassengerCount}},
                        position = selectedTrainStation.position,
                    }
                end

                for i = 1, #selectedTrainStation.get_inventory(1), 1 do
                    local p = selectedTrainStation.get_inventory(1)[i]
                    if p ~= nil and p.valid and p.valid_for_read and p.name == passenger and (p.tags or {}).created == nil then
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

local function getCredits(passenger)
    
    local originCity = findCityByName(passenger.origin)
    local destinationCity = findCityByName(passenger.destination)
    if originCity == nil or destinationCity == nil then
        game.print("The tycoon mod has encountered a problem: Credits for a passenger couldn't be awarded because the origin or destination city could not be found.")
        return 0
    end
    
    local distance = Util.calculateDistance(originCity.center, destinationCity.center)
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
                    local applicableReward = math.ceil(reward)
                    randomTreasury.insert{name = "tycoon-currency", count = applicableReward}
                end
            end
        end
    end
end

return {
    spawnPassengers = spawnPassengers,
    clearPassengers = clearPassengers,
}