local Constants = require("constants")

--- @class Need
--- @field provided number
--- @field required number

--- @class CityStats
--- @field basic_needs { string: Need }
--- @field additional_needs { string: Need }

--- @class SpecialBuildings
--- @field town_hall any
--- @field other {string: any[]}

--- @class City
--- @field stats CityStats
--- @field citizens { string: number }
--- @field special_buildings SpecialBuildings
--- @field generator any

local basicNeeds = {
    water = 10,
    simple = {
        {
            amount = 3,
            resource = "tycoon-apple",
        }
    },
    residential = {
        {
            amount = 2,
            resource = "tycoon-milk-bottle",
        },
        {
            amount = 2,
            resource = "tycoon-meat",
        },
        {
            amount = 4,
            resource = "tycoon-bread",
        },
        {
            amount = 2,
            resource = "tycoon-fish-filet",
        },
    },
    highrise = {
        {
            amount = 1,
            resource = "tycoon-smoothie",
        },
        {
            amount = 2,
            resource = "tycoon-apple-cake",
        },
        {
            amount = 3,
            resource = "tycoon-cheese",
        },
        {
            amount = 1,
            resource = "tycoon-burger",
        },
        {
            amount = 1,
            resource = "tycoon-dumpling",
        }
    }
}

local additionalNeeds = {
    simple = {
        {
            amount = 1,
            resource = "tycoon-cooking-pan",
        },
        {
            amount = 1,
            resource = "tycoon-cooking-pot",
        },
        {
            amount = 1,
            resource = "tycoon-cutlery",
        }
    },
    residential = {
        {
            amount = 1,
            resource = "tycoon-bicycle",
        },
        {
            amount = 2,
            resource = "tycoon-candle",
        },
        {
            amount = 3,
            resource = "tycoon-soap",
        },
        {
            amount = 5,
            resource = "tycoon-gloves",
        },
        {
            amount = 1,
            resource = "tycoon-television",
        },
    },
    highrise = {
        {
            amount = 1,
            resource = "tycoon-smartphone",
        },
        {
            amount = 1,
            resource = "tycoon-laptop",
        }
    }
}

--- @param city City
--- @param resource string
--- @param amount number
local function setAdditionalNeedsRequired(city, resource, amount)
    if city.stats.additional_needs == nil then
        city.stats.additional_needs = {}
    end
    if city.stats.additional_needs[resource] == nil then
        city.stats.additional_needs[resource] = {
            provided = 0,
            required = 0,
        }
    end
    city.stats.additional_needs[resource].required = math.floor(amount)
end

--- @param city City
--- @param resource string
--- @param amount number
local function setAdditionalNeedsProvided(city, resource, amount)
    if city.stats.additional_needs == nil then
        city.stats.additional_needs = {}
    end
    if city.stats.additional_needs[resource] == nil then
        city.stats.additional_needs[resource] = {
            provided = 0,
            required = 0,
        }
    end
    city.stats.additional_needs[resource].provided = math.floor(amount)
end

--- @param city City
--- @param resource string
--- @param amount number
local function setBasicNeedsRequired(city, resource, amount)
    if city.stats.basic_needs[resource] == nil then
        city.stats.basic_needs[resource] = {
            provided = 0,
            required = 0,
        }
    end
    city.stats.basic_needs[resource].required = math.floor(amount)
end

--- @param city City
--- @param resource string
--- @param amount number
local function setBasicNeedsProvided(city, resource, amount)
    if city.stats.basic_needs[resource] == nil then
        city.stats.basic_needs[resource] = {
            provided = 0,
            required = 0,
        }
    end
    city.stats.basic_needs[resource].provided = math.floor(amount)
end

local DAY_TO_MINUTE_FACTOR = (60*60) / 25000

--- @param amountPerDay number
--- @param citizenCount number
local function getRequiredAmount(amountPerDay, citizenCount)
    return math.ceil(amountPerDay * DAY_TO_MINUTE_FACTOR * citizenCount)
end

--- @param city City
local function updateBasicNeeds(city)
    local needs = {
        water = 0
    }
    for citizenTier, citizenCount in pairs(city.citizens) do
        for _, need in ipairs(basicNeeds[citizenTier]) do
            if needs[need.resource] == nil then
                needs[need.resource] = 0
            end
            needs[need.resource] = needs[need.resource] + getRequiredAmount(need.amount, citizenCount)
        end
        needs.water = needs.water + basicNeeds.water * citizenCount
    end

    for resource, amount in pairs(needs) do
        setBasicNeedsRequired(city, resource, amount)
    end
end

--- @param city City
local function updateAdditionalNeeds(city)
    local needs = {}
    for citizenTier, citizenCount in pairs(city.citizens) do
        for _, need in ipairs(additionalNeeds[citizenTier]) do
            if needs[need.resource] == nil then
                needs[need.resource] = 0
            end
            needs[need.resource] = needs[need.resource] + getRequiredAmount(need.amount, citizenCount)
        end
    end

    for resource, amount in pairs(needs) do
        setAdditionalNeedsRequired(city, resource, amount)
    end
end

--- @param city City
local function updateNeeds(city)
    updateBasicNeeds(city)
    updateAdditionalNeeds(city)
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
local function updateProvidedAmounts(city)
    local markets = listSpecialCityBuildings(city, "tycoon-market")

    -- BASIC NEEDS
    if #markets >= 1 then
        for resource, _ in pairs(city.stats.basic_needs) do
            if resource ~= "water" then
                local totalAvailable = 0
                for _, market in ipairs(markets) do
                    local availableCount = market.get_item_count(resource)
                    totalAvailable = totalAvailable + availableCount
                end
                setBasicNeedsProvided(city, resource, totalAvailable)
            end
        end
    else
        for resource, _ in pairs(city.stats.basic_needs) do
            if resource ~= "water" then
                setBasicNeedsProvided(city, resource, 0)
            end
        end
    end

    -- ADDITIONAL NEEDS
    if #markets >= 1 then
        for resource, _ in pairs(city.stats.additional_needs or {}) do
            local totalAvailable = 0
            for _, market in ipairs(markets) do
                local availableCount = market.get_item_count(resource)
                totalAvailable = totalAvailable + availableCount
            end
            setAdditionalNeedsProvided(city, resource, totalAvailable)
        end
    else
        for resource, _ in pairs(city.stats.additional_needs) do
            setAdditionalNeedsProvided(city, resource, 0)
        end
    end
    
    local waterTowers = listSpecialCityBuildings(city, "tycoon-water-tower")
    if #waterTowers >= 1 then
        local totalAvailable = 0
        for _, waterTower in ipairs(waterTowers) do
            local availableCount = waterTower.get_fluid_count("water")
            totalAvailable = totalAvailable + availableCount
        end
        setBasicNeedsProvided(city, "water", totalAvailable)
    else
        setBasicNeedsProvided(city, "water", 0)
    end
end

--- @param city City
--- @param needs any | nil
--- @return number[] supplyLevels
local function getSupplyLevels(city, needs)
    assert(needs ~= nil, "Expected needs in getSupplyLevels to not be nil.")
    updateProvidedAmounts(city)

    local waterDemand = (needs or {}).water

    if waterDemand ~= nil and (waterDemand.provided < waterDemand.required or waterDemand.provided == 0) then
        return { 0 }
    end

    local supplyLevels = {}

    for resource, amounts in pairs(needs) do
        if resource == "water" then
            -- noop
        elseif (amounts == nil or amounts.provided == nil or amounts.provided == 0) then
            table.insert(supplyLevels, 0)
        elseif (amounts == nil or amounts.required == nil or amounts.required == 0) then
            if (amounts ~= nil and amounts.provided ~= nil and amounts.provided > 0) then
                table.insert(supplyLevels, 1)
            else
                table.insert(supplyLevels, 0)
            end
        else
            local supplyLevel = amounts.provided / amounts.required
            table.insert(supplyLevels, math.min(supplyLevel, 1))
        end
    end

    return supplyLevels
end

-- This value should match the one in university-science.lua
-- local kwPerCurrency = 300

local resourcePrices = {
    water = 0,
    ["tycoon-apple"] = 0.5,
    ["tycoon-meat"] = 1.675,
    ["tycoon-milk"] = 0.32,
    ["tycoon-milk-bottle"] = 0.95,
    ["tycoon-bread"] = 1.28375,
    ["tycoon-fish-filet"] = 1.2666666666667,
    ["tycoon-smoothie"] = 2.2,
    ["tycoon-apple-cake"] = 11.590416666667,
    ["tycoon-cheese"] = 1.78,
    ["tycoon-burger"] = 11.822083333333,
    ["tycoon-dumpling"] = 4.38375,
    ["iron-plate"] = 1.3,
    ["steel-plate"] = 10.5,
    ["stone-brick"] = 1.8,
    ["concrete"] = 1.3666666666667,
    ["small-lamp"] = 7.5416666666667,
    ["pump"] = 33.333333333333,
    ["pipe"] = 1.5083333333333,
    ["tycoon-cooking-pan"] = 11.670833333333,
    ["tycoon-cooking-pot"] = 11.670833333333,
    ["tycoon-cutlery"] = 3.5666666666667,
    ["tycoon-bicycle"] = 21.792592592593,
    ["tycoon-candle"] = 3.7731481481481,
    ["tycoon-soap"] = 1.5462962962963,
    ["tycoon-gloves"] = 0.99537037037037,
    ["tycoon-television"] = 54.084259259259,
    ["tycoon-smartphone"] = 217.97490740741,
    ["tycoon-laptop"] = 840.21583333333,
}

--- @param city City
local function countCitizens(city)
    local total = 0
    for _, count in pairs(city.citizens) do
        total = total + count
    end
    return total
end

--- @class Item
--- @field name string
--- @field required number

--- @param item Item
--- @param suppliers any[]
--- @param city City
local function consumeItem(item, suppliers, city)

    assert(item.required ~= nil and item.required >= 0, "Required amount must be a number 0 or larger.")

    if item.required == 0 then
        -- No need to consume anything if we don't need to consume anything
        return
    end

    local entitiesWithSupply = {}
    for _, entity in ipairs(suppliers) do
        local availableCount = entity.get_item_count(item.name)
        if availableCount > 0 then
            table.insert(entitiesWithSupply, entity)
        end
    end
    
    local requiredAmount = item.required
    local consumedAmount = 0
    for _, entity in ipairs(entitiesWithSupply) do
        local availableCount = entity.get_item_count(item.name)
        local removed = entity.remove_item({name = item.name, count = math.min(requiredAmount, availableCount)})
        consumedAmount = consumedAmount + removed
        requiredAmount = requiredAmount - consumedAmount
        if requiredAmount <= 0 then
            break
        end
    end

    local treasuries = listSpecialCityBuildings(city, "tycoon-treasury")
    if #treasuries > 0 then
        local randomTreasury = treasuries[city.generator(#treasuries)]
        local currencyPerUnit = resourcePrices[item.name]
        assert(currencyPerUnit ~= nil, "Missing price for " .. item.name)
        local reward = math.ceil(currencyPerUnit * consumedAmount)
        if reward > 0 then
            randomTreasury.insert{name = "tycoon-currency", count = reward}
        end
    end
end

--- @param city City
local function consumeBasicNeeds(city)

    local citizen_count = countCitizens(city)

    local markets = listSpecialCityBuildings(city, "tycoon-market")
    local waterTowers = listSpecialCityBuildings(city, "tycoon-water-tower")

    local countNeedsMet = 0

    if #markets >= 1 then
        for resource, amounts in pairs(city.stats.basic_needs) do
            if resource ~= "water" and amounts.required > 0 then
                consumeItem({
                    name = resource,
                    required = amounts.required
                }, markets, city)
            end
        end
    end
    if #waterTowers >= 1 then
        local requiredAmount = getRequiredAmount(basicNeeds.water, citizen_count)
        local waterTowersWithSupply = {}
        for _, waterTower in ipairs(waterTowers) do
            local availableCount = waterTower.get_fluid_count("water")
            if availableCount > 0 then
                table.insert(waterTowersWithSupply, waterTower)
            end
        end
        local consumedAmount = 0
        for _, waterTower in ipairs(waterTowersWithSupply) do
            local availableCount = waterTower.get_fluid_count("water")
            local removed = waterTower.remove_fluid({name = "water", amount = math.min(requiredAmount, availableCount)})
            consumedAmount = consumedAmount + removed
            requiredAmount = requiredAmount - consumedAmount
            if requiredAmount <= 0 then
                break
            end
        end
        if consumedAmount >= requiredAmount then
            countNeedsMet = countNeedsMet + 1
        end

        -- Water is a human right and should be free
    end
end


--- @param city City
local function consumeAdditionalNeeds(city)
    
    local markets = listSpecialCityBuildings(city, "tycoon-market")

    if #markets >= 1 then
        for resource, amounts in pairs(city.stats.additional_needs or {}) do
            consumeItem({
                name = resource,
                required = amounts.required
            }, markets, city)
        end
    end
end

local function getBasicNeeds(city, tier)
    if tier == "simple" then
        return {
            water = city.stats.basic_needs.water,
            ["tycoon-apple"] = city.stats.basic_needs["tycoon-apple"],
        }
    elseif tier == "residential" then
        return {
            water = city.stats.basic_needs.water,
            ["tycoon-milk-bottle"] = city.stats.basic_needs["tycoon-milk-bottle"],
            ["tycoon-meat"] = city.stats.basic_needs["tycoon-meat"],
            ["tycoon-bread"] = city.stats.basic_needs["tycoon-bread"],
            ["tycoon-fish-filet"] = city.stats.basic_needs["tycoon-fish-filet"],
        }
    elseif tier == "highrise" then
        return {
            water = city.stats.basic_needs.water,
            ["tycoon-smoothie"] = city.stats.basic_needs["tycoon-smoothie"],
            ["tycoon-apple-cake"] = city.stats.basic_needs["tycoon-apple-cake"],
            ["tycoon-cheese"] = city.stats.basic_needs["tycoon-cheese"],
            ["tycoon-burger"] = city.stats.basic_needs["tycoon-burger"],
            ["tycoon-dumpling"] = city.stats.basic_needs["tycoon-dumpling"],
        }
    else
        assert(false, "Unknown tier for getBasicNeeds: " .. tier)
    end
end

local function getAdditionalNeeds(city, tier)
    if city.stats.additional_needs == nil then
        -- edge case for when this has not been initialized (e.g. when upgrading the savegame to the latest version of this mod)
        return {}
    end
    if tier == "simple" then
        return {
            ["tycoon-cooking-pot"] = city.stats.additional_needs["tycoon-cooking-pot"],
            ["tycoon-cooking-pan"] = city.stats.additional_needs["tycoon-cooking-pan"],
            ["tycoon-cutlery"] = city.stats.additional_needs["tycoon-cutlery"],
        }
    elseif tier == "residential" then
        return {
            ["tycoon-bicycle"] = city.stats.additional_needs["tycoon-bicycle"],
            ["tycoon-candle"] = city.stats.additional_needs["tycoon-candle"],
            ["tycoon-soap"] = city.stats.additional_needs["tycoon-soap"],
            ["tycoon-gloves"] = city.stats.additional_needs["tycoon-gloves"],
            ["tycoon-television"] = city.stats.additional_needs["tycoon-television"],
        }
    elseif tier == "highrise" then
        return {
            ["tycoon-smartphone"] = city.stats.additional_needs["tycoon-smartphone"],
            ["tycoon-laptop"] = city.stats.additional_needs["tycoon-laptop"],
        }
    else
        assert(false, "Unknown tier for getAdditionalNeeds: " .. tier)
    end
end

local function get_supply_factor_scaling_factor(supply_values)
    if #(supply_values or {}) == 0 then
        return 1
    end
    return 10 / #supply_values
end

local function logistics_function(x)
    return 1 / (1 + math.exp(-(x - 5)))
end

local function calculate_ratio(city, needs)
    local levels = getSupplyLevels(city, needs)
    local factor = get_supply_factor_scaling_factor(levels)
    local total = 0
    for _, v in ipairs(levels) do
        total = total + v * factor
    end
    local ratio = logistics_function(total)
    return ratio
end

local function update_construction_timers(city, tier)

    if tier ~= "simple" and not game.forces.player.technologies["tycoon-" .. tier .. "-housing"].researched then
        return
    end

    local basic_ratio = calculate_ratio(city, getBasicNeeds(city, tier))
    local additional_ratio = calculate_ratio(city, getAdditionalNeeds(city, tier))

    -- It should scale between 1 minute and 30 minutes for basic resources
    -- Todo: maybe consider citizen count?
    local basic_max = 30 * 60 * 60;
    local basic_min = 1 * 60 * 60;
    local basic_duration = basic_min + (basic_max - basic_min) * (1 - basic_ratio)

    -- Additional needs give another reducing scaling bonus between 5 seconds and 1 minute
    local additional_max = 55 * 60;

    local additional_duration_reduction = additional_max * additional_ratio

    local resulting_duration = basic_duration - additional_duration_reduction

    if city.construction_timers == nil then
        city.construction_timers = {}
    end
    if city.construction_timers[tier] == nil then
        city.construction_timers[tier] = {
            last_construction = 0,
            construction_interval = resulting_duration,
        }
    else
        city.construction_timers[tier].construction_interval = resulting_duration
    end
end

return {
    getSupplyLevels = getSupplyLevels,
    updateNeeds = updateNeeds,
    consumeBasicNeeds = consumeBasicNeeds,
    consumeAdditionalNeeds = consumeAdditionalNeeds,
    consumeItem = consumeItem,
    resourcePrices = resourcePrices,
    update_construction_timers = update_construction_timers,
}
