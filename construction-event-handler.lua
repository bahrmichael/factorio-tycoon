local Util = require("util")
local Constants = require("constants")
local Consumption = require("consumption")
local City = require("city")

local function invalidateSpecialBuildingsList(city, name)
    assert(city.special_buildings ~= nil, "The special buildings should never be nil. There has been one error though, so I added this assertion.")

    -- special_buildings is a cache. It gets refreshed per entity if nil.
    if city.special_buildings.other[name] ~= nil then
        city.special_buildings.other[name] = nil
    end
end

local function on_built(event)
    assert(event.created_entity, "Called on_built without a created_entity. Wrong event?")

    local entity = event.created_entity
    -- LuaEntity inherits surface_index from LuaControl
    local surface_index = entity.surface_index

    if Util.isSupplyBuilding(entity.name) or entity.name == "tycoon-passenger-train-station" then
        local nearbyTownHall = game.surfaces[surface_index].find_entities_filtered{
            position=entity.position,
            radius=Constants.CITY_RADIUS,
            name="tycoon-town-hall",
            limit=1
        }
        if #nearbyTownHall == 0 then
            if event.player_index ~= nil then
                game.players[event.player_index].print({"", {"tycoon-supply-building-not-connected"}})
            end
            return
        end

        local cityMapping = global.tycoon_city_buildings[nearbyTownHall[1].unit_number]
        assert(cityMapping ~= nil, "When building an entity we found a town hall, but it has no city mapping.")
        local cityId = cityMapping.cityId
        local city = Util.findCityById(cityId)
        assert(city ~= nil, "When building an entity we found a cityId, but there is no city for it.")

        invalidateSpecialBuildingsList(city, entity.name)

        if global.tycoon_entity_meta_info == nil then
            global.tycoon_entity_meta_info = {}
        end
        global.tycoon_entity_meta_info[entity.unit_number] = {
            cityId = cityId
        }
    end
end

local function on_removed(event)
    local unit_number = event.unit_number or (event.entity or {}).unit_number
    if unit_number == nil then
        return
    end

    if global.tycoon_city_buildings == nil then
        return
    end
    
    local building = global.tycoon_city_buildings[unit_number]
    local entity = (building or {}).entity
    if entity == nil then
        return
    end

    if Util.isSupplyBuilding(building.entity_name) or building.entity_name == "tycoon-passenger-train-station" then
        
        local nearby_town_hall = game.surfaces[entity.surface_index].find_entities_filtered{
            position=building.entity.position,
            radius=Constants.CITY_RADIUS,
            name="tycoon-town-hall",
            limit=1
        }
        if #nearby_town_hall == 0 then
            -- If there's no town hall in range then it probably was destroyed
            -- todo: how should we handle that situation? Is the whole city gone?
            -- probably in the "destroyed" event, because the player can't mine the town hall
            return
        end

        local city_mapping = global.tycoon_city_buildings[nearby_town_hall[1].unit_number]
        assert(city_mapping ~= nil, "When mining an entity an entity we found a town hall, but it has no city mapping.")
        local cityId = city_mapping.cityId
        local city = Util.findCityById(cityId)
        assert(city ~= nil, "When mining an entity we found a cityId, but there is no city for it.")

        invalidateSpecialBuildingsList(city, building.entity_name)
    elseif Util.isHouse(building.entity_name) then
        
        local housing_type
        if string.find(building.entity_name, "tycoon-house-simple-", 1, true) then
            housing_type = "simple"
        elseif string.find(building.entity_name, "tycoon-house-residential-", 1, true) then
            housing_type = "residential"
        elseif string.find(building.entity_name, "tycoon-house-highrise-", 1, true) then
            housing_type = "highrise"
        end

        assert(housing_type, "Uknown housing_type in on_removed: " .. housing_type)
        
        local cityId = building.cityId
        local city = Util.findCityById(cityId)
        if city ~= nil then
            City.growCitizenCount(city, -1 * Constants.CITIZEN_COUNTS[housing_type], housing_type)
        end

        if global.tycoon_house_lights ~= nil then
            local light = global.tycoon_house_lights[unit_number]
            if light ~= nil then
                if light.valid then
                    light.destroy()
                end
                global.tycoon_house_lights[unit_number] = nil
            end
        end
    end

    -- todo: mark cell as unused again, clear paving if necessary
end

return {
    on_built = on_built,
    on_removed = on_removed,
}