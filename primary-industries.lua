local Constants = require("constants")
local Util = require("util")
local TagsQueue = require("tags-queue")

local all_resource_names_cached = nil
local function get_all_resource_names()
    if all_resource_names_cached == nil then
        all_resource_names_cached = {}
        for name, _cat in pairs(game.get_filtered_entity_prototypes{{filter="type", type="resource"}}) do
            table.insert(all_resource_names_cached, name)
        end
    end
    return all_resource_names_cached
end

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
    -- WARN: do not insert with unit_number as it converts array to a dict
    table.insert(global.tycoon_primary_industries[entity.name], entity)
end

local function cleanup_global_primary_industries()
    -- TODO: when called from on_chunk_deleted() - it doesn't clean fully, adding some delay might help (but how?)...
    -- unless we have some array issue here, again. deleting 1K map keep-radius=2 count: 15 14 4 => 7 7 2 (?)
    local count = 0
    for name, _ in pairs(global.tycoon_primary_industries or {}) do
        for k, entity in pairs(global.tycoon_primary_industries[name] or {}) do
            if not entity.valid then
                table.remove(global.tycoon_primary_industries[name], k)
                count = count + 1
            end
        end
    end
    if count ~= 0 then
        log("tycoon_primary_industries removed: ".. tostring(count))
    end
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

local function tagIndustry(pos, entity_name, surface_index)

    -- WARN: this will fail when called from on_chunk_generated() instead of on_chunk_charted()
    local tag = game.forces.player.add_chart_tag(game.surfaces[surface_index], {
        position = pos,
        icon = {
            type = "item",
            name = getItemForPrimaryProduction(entity_name),
        },
        text = localizePrimaryProductionName(entity_name),
    })

    -- to accomodate that ^, we keep failed tags in a queue
    -- using chunk coords, so that on_chunk_*() handlers can easily check by key
    local chunk_position = Util.positionToChunk(pos)
    if tag == nil then
        TagsQueue.set(chunk_position, surface_index, entity_name, pos)
    else
        TagsQueue.delete(chunk_position, surface_index)
    end

    return tag
end

local function place_primary_industry_at_position(position, entity_name, surface_index)
    -- half a chunk should be enough, unless we have new farms >14x14 (not recommended!)
    local PRIMARY_INDUSTRY_NEARBY_RADIUS = Constants.CHUNK_SIZE/2
    local nearby_count = 0
    if position ~= nil then
        -- This is mainly here to avoid two industries being right next to each other, 
        -- blocking each others pipes.
        local nearby_primary_industries_count = game.surfaces[surface_index].count_entities_filtered{
            position = position,
            radius = PRIMARY_INDUSTRY_NEARBY_RADIUS,
            name = Constants.PRIMARY_INDUSTRIES,
            limit = 1
        }
        if nearby_primary_industries_count > 0 then
            return nil
        end
        -- Fisheries don't have a pipe input and therfore don't need this condition
        -- they are also placed near water, so this would lead to no fisheries being placed anywhere.
        if entity_name ~= "tycoon-fishery" then
            local nearby_cliffs_or_water_count = game.surfaces[surface_index].count_tiles_filtered{
                position = position,
                radius = PRIMARY_INDUSTRY_NEARBY_RADIUS,
                name = {"cliff", "water", "deepwater"},
                limit = 1
            }
            if nearby_cliffs_or_water_count > 0 then
                return nil
            end
        end

        -- check nearby resources
        if not (settings.global["tycoon-skip-check-resources"] or {}).value then
            nearby_count = game.surfaces[surface_index].count_entities_filtered{
                position = position,
                radius = PRIMARY_INDUSTRY_NEARBY_RADIUS,
                name = get_all_resource_names(),
                limit = 1
            }
        end
        if nearby_count > 0 then
            return nil
        end

        tagIndustry(position, entity_name, surface_index)

        local entity = game.surfaces[surface_index].create_entity{
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

local function find_position_for_initial_apple_farm()
    local surface_index = Constants.STARTING_SURFACE_ID
    local coordinate_candidates = {}
    for _ = 1, 5, 1 do
        
        local starting_position = {math.random(-30, 30), math.random(-30, 30)}
        local position = game.surfaces[surface_index].find_non_colliding_position("tycoon-apple-farm", starting_position, 200, 5, true)
        if position ~= nil then
            
            local water_tiles = game.surfaces[surface_index].find_tiles_filtered{
                position = position,
                radius = 100,
                name={"water", "deepwater"},
                limit = 1,
            }

            local town_halls = game.surfaces[surface_index].find_entities_filtered{
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
                local distance_to_water = Util.calculateDistance(water_position, position)

                local water_score = 100 / math.pow(distance_to_water - 50, 2)

                score = score + water_score
            end

            if #town_halls == 0 then
                -- bad, no town hall nearby
            else
                local town_hall_position = town_halls[1].position
                local distance_to_town_hall = Util.calculateDistance(town_hall_position, position)

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
            local entity = place_primary_industry_at_position(position, "tycoon-apple-farm", Constants.STARTING_SURFACE_ID)
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
    cleanup_global_primary_industries = cleanup_global_primary_industries,
    spawn_initial_industry = spawn_initial_industry,
    getFixedRecipeForIndustry = getFixedRecipeForIndustry,
    tagIndustry = tagIndustry,
}