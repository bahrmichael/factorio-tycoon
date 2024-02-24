local Constants = require("constants")

local function add_to_global_primary_industries(entity)
    if entity == nil then
        return
    end
    if global.tycoon_primary_industries == nil then
        global.tycoon_primary_industries = {}
    end
    if global.tycoon_primary_industries[entity.name] == nil then
        global.tycoon_primary_industries[entity.name] = {}
    end
    table.insert(global.tycoon_primary_industries[entity.name], entity.unit_number, entity)
end

local function getItemForPrimaryProduction(name)
    if name == "tycoon-apple-farm" then
        return "tycoon-apple"
    elseif name == "tycoon-wheat-farm" then
        return "tycoon-wheat"
    elseif name == "tycoon-fishery" then
        return "raw-fish"
    else
        return "Unknown"
    end
end

-- TODO: use localized names from locale/$LANG/entity-names.cfg and remove this table
local LOCALIZE_PRIMARY = {
    ["tycoon-apple-farm"] = "Apple Farm",
    ["tycoon-wheat-farm"] = "Wheat Farm",
    ["tycoon-fishery"] = "Fishery",
}
local function localizePrimaryProductionName(name)
    local length = (settings.global["tycoon-tags-text-length"] or {}).value
    local text = LOCALIZE_PRIMARY[name] or "Primary Production"
    return text:sub(1, length)
end

-- WARN: multiple forces are not supported, only one is: "player"
local function getFixedRecipeForIndustry(industryName)
    local level = (game.forces.player.technologies[industryName .. "-productivity"] or {}).level or 1
    if industryName == "tycoon-apple-farm" then
        local recipe = "tycoon-grow-apples-with-water-" .. level
        return recipe
    elseif industryName == "tycoon-wheat-farm" then
        local recipe = "tycoon-grow-wheat-with-water-" .. level
        return recipe
    elseif industryName == "tycoon-fishery" then
        local recipe = "tycoon-fishing-" .. level
        return recipe
    end
end

local function place_primary_industry_at_position(position, entity_name)
    if position ~= nil then
        -- This is mainly here to avoid two industries being right next to each other, 
        -- blocking each others pipes.
        local nearby_primary_industries_count = game.surfaces[Constants.STARTING_SURFACE_ID].count_entities_filtered{
            position = position,
            radius = 20,
            name = Constants.PRIMARY_INDUSTRIES,
            limit = 1
        }
        if nearby_primary_industries_count > 0 then
            return nil
        end
        -- Fisheries don't have a pipe input and therfore don't need this condition
        -- they are also placed near water, so this would lead to no fisheries being placed anywhere.
        if entity_name ~= "tycoon-fishery" then
            local nearby_cliffs_or_water_count = game.surfaces[Constants.STARTING_SURFACE_ID].count_tiles_filtered{
                position = position,
                radius = 10,
                name = {"cliff", "water", "deepwater"},
                limit = 1
            }
            if nearby_cliffs_or_water_count > 0 then
                return nil
            end
        end
        local tag = game.forces.player.add_chart_tag(game.surfaces[Constants.STARTING_SURFACE_ID],
            {
                position = {x = position.x, y = position.y},
                icon = {
                    type = "item",
                    name = getItemForPrimaryProduction(entity_name),
                },
                text = localizePrimaryProductionName(entity_name),
            }
        )
        if tag ~= nil then
            local entity = game.surfaces[Constants.STARTING_SURFACE_ID].create_entity{
                name = entity_name,
                position = {x = position.x, y = position.y},
                force = "neutral",
                move_stuck_players = true
            }
            if entity ~= nil and entity.valid then
                -- or any other primary industry that has productivity research
                entity.set_recipe(getFixedRecipeForIndustry(entity.name))
                entity.recipe_locked = true

                return entity
            else
                game.print("Factorio Error: The mod has encountered an issue when placing primary industries. Please report this to the developer. You can continue playing.")
            end
        end
    end
end

function distance( x1, y1, x2, y2 )
	return math.sqrt( (x2-x1)^2 + (y2-y1)^2 )
end

local function find_position_for_initial_apple_farm()
    local coordinate_candidates = {}
    for _ = 1, 5, 1 do
        
        local starting_position = {math.random(-30, 30), math.random(-30, 30)}
        local position = game.surfaces[Constants.STARTING_SURFACE_ID].find_non_colliding_position("tycoon-apple-farm", starting_position, 200, 5, true)
        if position ~= nil then
            
            local water_tiles = game.surfaces[Constants.STARTING_SURFACE_ID].find_tiles_filtered{
                position = position,
                radius = 100,
                name={"water", "deepwater"},
                limit = 1,
            }

            local town_halls = game.surfaces[Constants.STARTING_SURFACE_ID].find_entities_filtered{
                position = position,
                radius = 100,
                name = "tycoon-town-hall",
                limit = 1
            }

            local score = 0

            if #water_tiles == 0 then
                -- bad, no water nearby
            else
                local water_position = water_tiles[1].position
                local distance_to_water = distance(water_position.x, water_position.y, position.x, position.y)

                local water_score = 100 / math.pow(distance_to_water - 50, 2)

                score = score + water_score
            end

            if #town_halls == 0 then
                -- bad, no town hall nearby
            else
                local town_hall_position = town_halls[1].position
                local distance_to_town_hall = distance(town_hall_position.x, town_hall_position.y, position.x, position.y)
                
                local town_hall_score = 100 / math.pow(distance_to_town_hall - 50, 2)

                score = score + town_hall_score
            end

            table.insert(coordinate_candidates, {
                position = position,
                score = score
            })
        end
    end

    table.sort(coordinate_candidates, function (a, b)
        return a.score > b.score
    end)

    return (coordinate_candidates[1] or {}).position
end

local function spawn_initial_industry()

    if not global.tycoon_has_initial_apple_farm and #(global.tycoon_cities or {}) > 0 then
        local position = find_position_for_initial_apple_farm()
        if position == nil then
            -- we don't need to do anything here, it will be reattempted next loop
            return
        else
            local entity = place_primary_industry_at_position(position, "tycoon-apple-farm")
            if entity ~= nil then
                add_to_global_primary_industries(entity)
                global.tycoon_has_initial_apple_farm = true
            else
                -- we don't need to do anything here, it will be reattempted next loop
                return
            end
        end
    end
end

return {
    place_primary_industry_at_position = place_primary_industry_at_position,
    add_to_global_primary_industries = add_to_global_primary_industries,
    spawn_initial_industry = spawn_initial_industry,
}