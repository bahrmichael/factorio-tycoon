local Constants = require("constants")
local PrimaryIndustries = require("primary-industries")
local Util = require("util")
local TagsQueue = require("tags-queue")

local function randomPrimaryIndustry()
    return Constants.PRIMARY_INDUSTRIES[global.tycoon_global_generator(#Constants.PRIMARY_INDUSTRIES)]
end

local function insideStartingArea(chunk)
    -- NOTE: slider thingy, but can be changed only when biters are enabled and docs says it's circular
    -- a. looks like 1 means something like 256x256[8x8], so radius could be 4 chunks
    -- b. restart shows 512x512[16x16] generated map, so it could be even 8

    -- fit [100%;600%] into [1;multiplier]
    local sa = Constants.STARTING_RADIUS_CHUNKS * Util.lerp(Util.factorioSliderInverse(
        Util.clamp(game.surfaces[Constants.STARTING_SURFACE_ID].map_gen_settings.starting_area, 1, 6)
    ), 1, Constants.STARTING_AREA_MULTIPLIER)

    -- we want [-sa;sa), but abs() include positive ones
    --return math.abs(chunk.x) <= sa and math.abs(chunk.y) <= sa
    return chunk.x >= -sa and chunk.x < sa and chunk.y >= -sa and chunk.y < sa
end


--
-- event handlers: on_chunk_*()
--

local function on_chunk_generated(event)
    -- WARN: not a typo: '.surface.index', not '.surface_index'! see docs...
    if event.surface.index == Constants.STARTING_SURFACE_ID and insideStartingArea(event.position) then
        return
    end
end

-- WARN: might be called very frequently, for ex: when there are biters wandering - avoid useless stuff
local function on_chunk_charted(event)
    if event.surface_index == Constants.STARTING_SURFACE_ID and insideStartingArea(event.position) then
        return
    end

    -- place pending tags
    local pos_name = TagsQueue.get(event.position, event.surface_index)
    if pos_name ~= nil then
        PrimaryIndustries.tagIndustry(table.unpack(pos_name))
    end

    if global.tycoon_global_generator() < 0.25 then
        local entity_name = randomPrimaryIndustry()
        local position
        if entity_name == "tycoon-fishery" then
            local water_tile_count = game.surfaces[event.surface_index].count_tiles_filtered{
                area = event.area,
                name = { "water", "deepwater" }
            }

            local water_ratio = (water_tile_count / Constants.CHUNK_SIZE^2)
            local has_enough_water = water_ratio > 0.25 and water_ratio < 0.9
            if not has_enough_water then
                return
            end

            position = game.surfaces[event.surface_index].find_non_colliding_position(entity_name, event.area.left_top, 100, 1, true)
        else
            position = game.surfaces[event.surface_index].find_non_colliding_position_in_box(entity_name, event.area, 2, true)
        end

        if position ~= nil then
            local min_distance = 500
            if entity_name == "tycoon-fishery" then
                -- map_gen_settings.water is a percentage value. As the amount of water on the map decreases, we want to spawn more fisheries per given area.
                -- Don't go below 50 though.
                -- The game slider allows between 17% and 600%.
                -- 17% * 200 = 34
                -- 600% * 200 = 1200
                min_distance = math.max(200 * game.surfaces[event.surface_index].map_gen_settings.water, 50)
            end
            local nearby_same_primary_industries_count = game.surfaces[event.surface_index].count_entities_filtered{
                position=position,
                radius=min_distance,
                name=entity_name,
                limit=1
            }
            if nearby_same_primary_industries_count == 0 then
                local entity = PrimaryIndustries.place_primary_industry_at_position(position, entity_name, event.surface_index)
                PrimaryIndustries.add_to_global_primary_industries(entity)
            end
        end
    end
end

local function on_chunk_deleted(event)
    -- if event.surface_index ~= Constants.STARTING_SURFACE_ID then
    --     return
    -- end

    PrimaryIndustries.cleanup_global_primary_industries()

    local count = 0
    for i, chunk in pairs(event.positions) do
        -- remove pending tags
        local t = TagsQueue.get(chunk, event.surface_index)
        if t ~= nil then
            TagsQueue.delete(chunk, event.surface_index)
            count = count + 1
        end
    end
    log("tycoon_tags_queue removed: ".. tostring(count))
end


return {
    on_chunk_generated = on_chunk_generated,
    on_chunk_charted = on_chunk_charted,
    on_chunk_deleted = on_chunk_deleted,
}