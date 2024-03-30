local Constants = require("constants")
local Util = require("util")

local function on_player_cursor_stack_changed(event)
    if global.tycoon_player_renderings == nil then
        global.tycoon_player_renderings = {}
    end
    if global.tycoon_player_renderings[event.player_index] == nil then
        global.tycoon_player_renderings[event.player_index] = {}
    end

    local player = game.players[event.player_index]
    if (player or {}).cursor_stack ~= nil then

        -- Clear any existing renderings for this player
        for _, render_id in ipairs(global.tycoon_player_renderings[event.player_index]) do
            rendering.destroy(render_id)
        end

        if player.cursor_stack.valid_for_read
            and (
                player.cursor_stack.name == "tycoon-passenger-train-station"
                or Util.isSupplyBuilding(player.cursor_stack.name)
            )
         then
            for _, city in ipairs(global.tycoon_cities or {}) do

                -- Added this condition, because there was a case where a city was gone in a multiplayer (no idea why yet),
                -- and then the game would crash upon rendering the circle.
                if (city.special_buildings or {}).town_hall ~= nil
                    and (city.special_buildings or {}).town_hall.valid
                    then
                    local render_id = rendering.draw_circle{
                        color = {0.1, 0.2, 0.1, 0.01},
                        -- todo: add tech that increases this range, but only up to 250 which is the max for building cities all over the map
                        radius = Constants.CITY_RADIUS,
                        filled = true,
                        target = city.special_buildings.town_hall,
                        surface = game.surfaces[city.surface_index],
                        draw_on_ground = true,
                    }

                    table.insert(global.tycoon_player_renderings[event.player_index], render_id)
                end
            end
        end
    end
end

return {
    on_player_cursor_stack_changed = on_player_cursor_stack_changed
}