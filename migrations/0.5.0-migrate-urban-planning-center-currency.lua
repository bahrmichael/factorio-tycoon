local Constants = require("constants")

local urbanPlanningCenters = game.surfaces[Constants.STARTING_SURFACE_ID].find_entities_filtered {
    name = "tycoon-urban-planning-center"
}

local totalAvailableFunds = 0
for _, c in ipairs(urbanPlanningCenters or {}) do
    local availableFunds = c.get_item_count("tycoon-currency")
    totalAvailableFunds = totalAvailableFunds + availableFunds
end

if totalAvailableFunds > 0 then
    -- Remember how much currency should be returned, and let another control mechanism return all the currency as there is space.
    global.tycoon_urban_planning_center_currency_pending = totalAvailableFunds
end
