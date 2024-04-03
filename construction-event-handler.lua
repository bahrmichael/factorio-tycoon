local Util = require("util")
local Constants = require("constants")
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

    local city = nil
    if Util.isSpecialBuilding(entity.name) then
        city = Util.findCityAtPosition(game.surfaces[surface_index], entity.position)
        if city == nil then
            if event.player_index ~= nil then
                game.players[event.player_index].print({"", {"tycoon-supply-building-not-connected"}})
            end
            return
        end

        invalidateSpecialBuildingsList(city, entity.name)

        if global.tycoon_entity_meta_info == nil then
            global.tycoon_entity_meta_info = {}
        end
        global.tycoon_entity_meta_info[entity.unit_number] = {
            cityId = city.id
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
    
    local city = nil
    local building = global.tycoon_city_buildings[unit_number]
    if building == nil then
        goto finally
    end

    city = Util.findCityByBuilding(building)
    if city == nil then
        -- If there's no town hall in range then it probably was destroyed
        -- todo: how should we handle that situation? Is the whole city gone?
        -- probably in the "destroyed" event, because the player can't mine the town hall
        goto finally
    end

    if Util.isSpecialBuilding(building.entity_name) then
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
    ::finally::
    -- remove from global finally
    global.tycoon_city_buildings[unit_number] = nil
end

return {
    on_built = on_built,
    on_removed = on_removed,
}