local Constants = require("constants")
local Util = require("util")
local City = require("city")

local function on_player_cursor_stack_changed(event)
    if storage.tycoon_player_renderings == nil then
        storage.tycoon_player_renderings = {}
    end
    if storage.tycoon_player_renderings[event.player_index] == nil then
        storage.tycoon_player_renderings[event.player_index] = {}
    end

    local player = game.players[event.player_index]
    if (player or {}).cursor_stack ~= nil then

        -- Clear any existing renderings for this player
        for _, render in ipairs(storage.tycoon_player_renderings[event.player_index]) do
            if render and render.valid then
                render.destroy()
            end
        end

        if player.cursor_stack.valid_for_read
            and Util.isSpecialBuilding(player.cursor_stack.name)
         then
            for _, city in ipairs(storage.tycoon_cities or {}) do

                -- Added this condition, because there was a case where a city was gone in a multiplayer (no idea why yet),
                -- and then the game would crash upon rendering the circle.
                if (city.special_buildings or {}).town_hall ~= nil
                        and (city.special_buildings or {}).town_hall.valid
                then
                    for _, triple in ipairs(City.findTriples(city)) do
                        local obj = rendering.draw_polygon {
                            color = { 0.1, 0.2, 0.1, 0.01 },
                            vertices = triple,
                            filled = true,
                            surface = game.surfaces[city.surface_index],
                            draw_on_ground = true,
                            players = { event.player_index },
                        }
                        table.insert(storage.tycoon_player_renderings[event.player_index], obj)
                    end
                end
            end
        end
    end
end

return {
    on_player_cursor_stack_changed = on_player_cursor_stack_changed
}
