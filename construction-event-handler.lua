local Util = require("util")
local Constants = require("constants")
local City = require("city")
local CityPlanner = require("city-planner")

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
        log("on_built(): event: ".. event.name .." unit: ".. entity.unit_number .." name: ".. entity.name)
        city = Util.findCityAtPosition(game.surfaces[surface_index], entity.position)
        if city == nil or not City.is_point_within_city(city, entity.position) then
            if event.player_index ~= nil then
                game.players[event.player_index].print({"", {"tycoon-supply-building-not-connected"}})
            end
            return
        end

        invalidateSpecialBuildingsList(city, entity.name)

        -- TODO: this could be dropped in favor of Util.getGlobalBuilding()
        if global.tycoon_entity_meta_info == nil then
            global.tycoon_entity_meta_info = {}
        end
        global.tycoon_entity_meta_info[entity.unit_number] = {
            cityId = city.id
        }

        Util.addGlobalBuilding(entity.unit_number, city.id, entity)
        -- WARN: we must always register
        script.register_on_entity_destroyed(entity)
    elseif entity.name == "tycoon-town-hall" then
        log("on_built(): Town hall built: ".. entity.unit_number .." at position: ".. serpent.line(entity.position))

        local position = entity.position
        local surface = entity.surface
        local player = game.players[event.player_index]
        local minimum_distance = Constants.CITY_RADIUS * 4
        local nearest_distance = minimum_distance
        local nearest_town_hall = nil

        local nearby_town_halls = surface.find_entities_filtered{
            name = "tycoon-town-hall",
            area = {{position.x - nearest_distance, position.y - nearest_distance}, {position.x + nearest_distance, position.y + nearest_distance}}
        }
        
        for _, nearby_entity in pairs(nearby_town_halls) do
            if nearby_entity.unit_number ~= entity.unit_number then
                local distance = Util.calculateDistance(position, nearby_entity.position)
                if distance < nearest_distance then
                    nearest_distance = distance
                    nearest_town_hall = nearby_entity
                end
            end
        end

        if nearest_town_hall then
            local required_distance = minimum_distance - nearest_distance
            entity.destroy()
            player.insert{name = "tycoon-town-hall", count = 1}
            player.print({"", {"tycoon-town-hall-too-close", math.ceil(required_distance)}})
            return
        end

        city = CityPlanner.addCity({
            x = entity.position.x - Constants.CELL_SIZE - 2,
            y = entity.position.y - Constants.CELL_SIZE - 2,
        }, surface_index, nil, entity)
        if city == nil then
            entity.destroy()
            if event.player_index ~= nil then
                player.insert{name = "tycoon-town-hall", count = 1}
                game.players[event.player_index].print({"", {"tycoon-town-hall-city-failed-player"}})
            else
                entity.surface.spill_item_stack(entity.position, {name = "tycoon-town-hall", count = 1})          
                game.print({"", {"tycoon-town-hall-city-failed-general"}})
            end
            return
        end
        if global.tycoon_entity_meta_info == nil then
            global.tycoon_entity_meta_info = {}
        end
        global.tycoon_entity_meta_info[entity.unit_number] = {
            cityId = city.cityId
        }
        Util.addGlobalBuilding(entity.unit_number, city.cityId, entity)
        script.register_on_entity_destroyed(entity)
    end
end

local function on_removed(event)
    local unit_number = event.unit_number or (event.entity or {}).unit_number
    if unit_number == nil then
        return
    end

    local city = nil
    local building = Util.getGlobalBuilding(unit_number)
    if building == nil then
        return
    end

    --  67: defines.events.on_player_mined_entity
    -- 160: defines.events.on_entity_destroyed
    log(string.format("on_removed(): event: %d unit: %s valid: %s position: %s cityId: %s name: %s",
        event.name, tostring(unit_number), tostring(building.entity ~= nil and building.entity.valid),
        serpent.line(building.position), tostring(building.cityId), building.entity_name
    ))

    -- this function handles no surface_index and no entity case
    city = Util.findCityByBuilding(building)
    if city == nil then
        -- If there's no town hall in range then it probably was destroyed
        -- todo: how should we handle that situation? Is the whole city gone?
        -- probably in the "destroyed" event, because the player can't mine the town hall
        log("on_removed(): ERROR: unable to find city! building: ".. serpent.line(building))

        -- remove from global
        Util.removeGlobalBuilding(unit_number)
        return
    end

    if building.isSpecial or Util.isSpecialBuilding(building.entity_name) then
        invalidateSpecialBuildingsList(city, building.entity_name)

        -- TODO: this could be dropped in favor of Util.removeGlobalBuilding()
        if global.tycoon_entity_meta_info == nil then
            global.tycoon_entity_meta_info = {}
        end
        global.tycoon_entity_meta_info[unit_number] = nil
    else
        assert(building.position, "building.position is nil, DO FIX migration script!")
        -- todo: mark cell as unused again, clear paving if necessary
        City.freeCellAtPosition(city, building.position, unit_number)
    end

    -- remove from global
    Util.removeGlobalBuilding(unit_number)
end

return {
    on_built = on_built,
    on_removed = on_removed,
}
