local Util = require("util")

-- todo: replace this mapping with a brute force search
local ingredientsMap = {
    ["tycoon-meat"] = "tycoon-cows-to-meat",
    ["tycoon-cow"] = "tycoon-grow-cows-with-grain",
    ["tycoon-grain"] = "tycoon-wheat-to-grain",
    ["tycoon-bread"] = "tycoon-dough-to-bread",
    ["tycoon-dough"] = "tycoon-flour-to-dough",
    ["tycoon-flour"] = "tycoon-grain-to-flour",
    ["tycoon-milk"] = "tycoon-milk-cow",
    ["tycoon-milk-bottle"] = "tycoon-bottle-to-milk-bottle",
    ["tycoon-bottle"] = "tycoon-iron-plate-to-bottle",
    ["tycoon-fish-filet"] = "tycoon-fish-to-fish-filet",
    ["petroleum-gas"] = "basic-oil-processing",
    -- advanced oil processing doesn't only yield light oil, but it may be a good enough approximation
    ["light-oil"] = "advanced-oil-processing",
}

local catalystMap = {
    ["tycoon-milk"] = "tycoon-cow",
    ["tycoon-egg"] = "tycoon-chicken",
}

-- todo: break that down into better calculations
-- for example with iron ore, calculate it based on the mining drill's speed
-- water can remain at 0 (or calculate it based on the offshore pump)
-- milk may need to factor in multiple ingredients and outputs

-- kw/s
local resourcePriceMap = {
    -- Assuming an average oil yield of 200% (based on map observation)
    -- The amount of oil a pumpjack extracts per cycle is yield multiplied by 10 (e.g. 115% yield = 1.15, multiplied by 10 = 11.5), and cannot be higher than 1000.
    -- Without speed modules one pumpjack cycle takes one second to complete
    ["crude-oil"] = 90 / 20,
    ["water"] = 0,
    ["tycoon-wheat"] = 30 * 60 / 50,
    ["tycoon-apple"] = 30 * 300 / 50,
    ["raw-fish"] = 30 * 30 / 15,
}

local primaryResourceCrafting = {
    ["iron-ore"] = "electric-mining-drill",
    ["copper-ore"] = "electric-mining-drill",
    ["stone"] = "electric-mining-drill",
    ["coal"] = "electric-mining-drill",
}

local function mapToEntity(craftingType)
    if craftingType == "chemical" then
        return "chemical-plant";
    elseif craftingType == "tycoon-husbandry" then
        return "tycoon-stable";
    elseif craftingType == "tycoon-butchery" then
        return "tycoon-butchery";
    elseif craftingType == "oil-processing" then
        return "oil-refinery";
    elseif craftingType == "smelting" then
        -- We're using the electric furnace here to simplify the calculations
        return "electric-furnace";
    elseif craftingType == "mining" then
        return "electric-mining-drill";
    else
        return "assembling-machine-1";
    end
end

local function getEnergyForCrafting(time, craftingType)
    local craftingEntity = game.entity_prototypes[mapToEntity(craftingType)]
    -- The prototype's energy usage is per tick. We then divide by 1000 to get the k amount.
    local energy_usage = craftingEntity.energy_usage * 60 / 1000
    return energy_usage * (time / (craftingEntity.crafting_speed or craftingEntity.mining_speed))
end

-- input: string 
-- output: number
local function calculateTotalPriceForRecipe(itemName)
    local recipe = game.forces.player.recipes[ingredientsMap[itemName] or itemName]

    if recipe == nil then
        local resourcePrice = resourcePriceMap[itemName] or getEnergyForCrafting(1, "mining")
        -- assert(resourcePrice ~= nil, "Missing resource prices for " .. itemName)
        return resourcePrice
    end

    local sum = getEnergyForCrafting(recipe.energy, recipe.category);

    local ingredients = recipe.ingredients;
    for _, ingredient in ipairs(ingredients) do
        local isCatalyst = catalystMap[itemName] == ingredient.name;
        if not isCatalyst then
            local pricePerIngredientUnit = calculateTotalPriceForRecipe(ingredient.name)
            sum = sum + pricePerIngredientUnit * ingredient.amount
        end
    end

    for _, product in ipairs(recipe.products) do
        if product.name == itemName then
            return sum / product.amount
        end
    end

    assert(false, "Failed to find the resulting product for the recipe of " .. itemName)
end

-- apples should yield 0.5 currency as a baseline
local kwPerCurrency = 180 * 2
-- Just copied this to get a list of item names that we may need to calcuate
-- Copied and adjusted from consumption.lua
local resources = {
    ["tycoon-apple"] = 180 / kwPerCurrency,
    ["tycoon-meat"] = 380 / kwPerCurrency,
    ["tycoon-milk"] = 380 / kwPerCurrency,
    ["tycoon-milk-bottle"] = 9317 / kwPerCurrency,
    ["tycoon-bread"] = 9404 / kwPerCurrency,
    ["tycoon-fish-filet"] = 456 / kwPerCurrency,
    ["tycoon-smoothie"] = 9677 / kwPerCurrency,
    ["tycoon-apple-cake"] = 31432 / kwPerCurrency,
    ["tycoon-cheese"] = 18495 / kwPerCurrency,
    ["tycoon-burger"] = 30155 / kwPerCurrency,
    ["tycoon-dumpling"] = 10910 / kwPerCurrency,
    ["iron-plate"] = 8 / kwPerCurrency,
    ["steel-plate"] = 64 / kwPerCurrency,
    ["stone-brick"] = 11 / kwPerCurrency,
    ["concrete"] = 9 / kwPerCurrency,
    ["small-lamp"] = 46 / kwPerCurrency,
    ["pump"] = 201 / kwPerCurrency,
    ["pipe"] = 9 / kwPerCurrency,
    ["tycoon-cooking-pan"] = 1 / kwPerCurrency,
    ["tycoon-cooking-pot"] = 1 / kwPerCurrency,
    ["tycoon-cutlery"] = 1 / kwPerCurrency,
    ["tycoon-bicycle"] = 1 / kwPerCurrency,
    ["tycoon-candle"] = 1 / kwPerCurrency,
    ["tycoon-soap"] = 1 / kwPerCurrency,
    ["tycoon-gloves"] = 1 / kwPerCurrency,
    ["tycoon-television"] = 1 / kwPerCurrency,
    ["tycoon-smartphone"] = 1 / kwPerCurrency,
    ["tycoon-laptop"] = 1 / kwPerCurrency,
}

local function calculateAllRecipes()
    for key, _ in pairs(resources) do
        local price = calculateTotalPriceForRecipe(key)
        game.print(key .. ": " .. price / kwPerCurrency)
        local message = "    [\"" .. key .. "\"] = " .. price / kwPerCurrency .. ","
        game.write_file("recipe-prices.log", message .. "\n", true)
    end
end


return {
    calculateAllRecipes = calculateAllRecipes,
}