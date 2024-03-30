local Constants = require("constants")
local City = require("city")
local Util = require("util")

-- WARN: migrations are run BEFORE any init(), always need this here
if global.tycoon_cities == nil then
    global.tycoon_cities = {}
end
if global.tycoon_city_buildings == nil then
    global.tycoon_city_buildings = {}
end


-- fix all special tycoon entities on every surface
local names = {}
for name, _ in pairs(Constants.CITY_SPECIAL_BUILDINGS) do
    table.insert(names, name)
end
for _, surface in pairs(game.surfaces) do
    local entities = surface.find_entities_filtered{
        name=names,
    }
    for _, entity in ipairs(entities or {}) do
        if entity == nil or (not entity.valid) then
            log("ERROR: find_entities_filtered() returned invalid entity!")
            goto continue
        end

        local position = {
            x = math.floor(entity.position.x),
            y = math.floor(entity.position.y),
        }

        local city = Util.findCityAtPosition(surface, position)
        if city == nil then
            log(string.format("ERROR: unable to find city! position: %s name: %s", serpent.line(position), entity.name))
            game.print("no city in range, remove manually: [gps=".. position.x ..",".. position.y .."]")

            -- remove bad entry if exists
            Util.removeGlobalBuilding(entity.unit_number)
            goto continue
        end

        local building = Util.getGlobalBuilding(entity.unit_number)
        if building == nil then
            log(string.format("found lost building, position: %s name: %s", serpent.line(position), entity.name))
        end

        -- force-add with proper function
        Util.addGlobalBuilding(entity.unit_number, city.id, entity)

        ::continue::
    end
end

-- we must ensure that all entities are still valid
log(string.format("processing tycoon_city_buildings: %d", table_size(global.tycoon_city_buildings)))
local new_dict = {}
for k, building in pairs(global.tycoon_city_buildings) do
    if building.entity == nil or (not building.entity.valid) then
        goto continue
    end

    if building.position == nil then
        local city = Util.findCityById(building.cityId)
        if city == nil then
            log(string.format("ERROR: unknown building.cityId: %s", serpent.line(building.cityId)))
        end

        building.position = {
            x = math.floor(building.entity.position.x),
            y = math.floor(building.entity.position.y),
        }
    end

    new_dict[k] = building
    ::continue::
end
-- rewrite whole dict
global.tycoon_city_buildings = new_dict

-- check every city
for _, city in pairs(global.tycoon_cities) do
    log(string.format("processing city id: %d grid: %d name: %s", city.id, #city.grid, city.name))

    -- drop cache
    for name, _ in pairs(Constants.CITY_SPECIAL_BUILDINGS) do
        city.special_buildings.other[name] = nil
    end

    -- check city grid
    for y = 1, #city.grid, 1 do
        for x = 1, #city.grid, 1 do
            local row = city.grid[y]
            local cell = (row or {})[x]
            if cell == nil or cell.type ~= "building" then
                goto continue
            end

            -- if building is absent
            local entity = cell.entity
            if entity == nil or (not entity.valid) then
                -- clear manually
                city.grid[y][x] = { type = "unused" }
                City.updatepossibleBuildingLocations(city, {x=x, y=y}, true)
                goto continue
            end

            local building = Util.getGlobalBuilding(entity.unit_number)
            local pos = { x = math.floor(entity.position.x), y = math.floor(entity.position.y) }
            if building == nil then
                log(string.format("ERROR: building is nil! unit: %s pos: %s",
                    serpent.line(entity.unit_number), serpent.line(pos)))
            elseif building.position.x ~= pos.x or building.position.y ~= pos.y then
                log(string.format("ERROR: positions does not match! unit: %s bld.pos: %s ent.pos: %s name: %s",
                    serpent.line(entity.unit_number), serpent.line(building.position), serpent.line(pos), entity.name))
            end

            -- force-add with proper function
            Util.addGlobalBuilding(entity.unit_number, city.id, entity)

            ::continue::
        end
    end
end
