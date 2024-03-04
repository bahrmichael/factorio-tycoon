local Constants = require("constants")
local PrimaryIndustries = require("primary-industries")

local function randomPrimaryIndustry()
    return Constants.PRIMARY_INDUSTRIES[global.tycoon_global_generator(#Constants.PRIMARY_INDUSTRIES)]
end




local function on_chunk_charted(event)
    if math.abs(event.position.x) < 5 and math.abs(event.position.y) < 5 then
        return
    end

    if global.tycoon_global_generator() < 0.25 then
        local entity_name = randomPrimaryIndustry()
        local position
        if entity_name == "tycoon-fishery" then
            local water_tile_count = game.surfaces[Constants.STARTING_SURFACE_ID].count_tiles_filtered{
                area = event.area,
                name = { "water", "deepwater" }
            }

            local water_ratio = (water_tile_count / Constants.CHUNK_SIZE^2)
            local has_enough_water = water_ratio > 0.25 and water_ratio < 0.9
            if not has_enough_water then
                return
            end

            position = game.surfaces[Constants.STARTING_SURFACE_ID].find_non_colliding_position(entity_name, event.area.left_top, 100, 1, true)
        else
            position = game.surfaces[Constants.STARTING_SURFACE_ID].find_non_colliding_position_in_box(entity_name, event.area, 2, true)
        end

        if position ~= nil then
            local min_distance = 500
            if entity_name == "tycoon-fishery" then
                -- map_gen_settings.water is a percentage value. As the amount of water on the map decreases, we want to spawn more fisheries per given area.
                -- Don't go below 50 though.
                -- The game slider allows between 17% and 600%.
                -- 17% * 200 = 34
                -- 600% * 200 = 1200
                min_distance = math.max(200 * game.surfaces[Constants.STARTING_SURFACE_ID].map_gen_settings.water, 50)
            end
            local nearby_same_primary_industries_count = game.surfaces[Constants.STARTING_SURFACE_ID].count_entities_filtered{
                position=position,
                radius=min_distance,
                name=entity_name,
                limit=1
            }
            if nearby_same_primary_industries_count == 0 then
                local entity = PrimaryIndustries.place_primary_industry_at_position(position, entity_name)
                PrimaryIndustries.add_to_global_primary_industries(entity)
            end
        end
    end
end

return {
    on_chunk_charted = on_chunk_charted
}