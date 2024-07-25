local Gui = require("gui")

local function on_shortcut(event)
    if event.prototype_name == "tycoon-cities-overview"
        or event.input_name == "tycoon-cities-overview"
        then
        local player = game.players[event.player_index]

        local guiKey = "multiple_cities_overview"
        local gui = player.gui.center[guiKey]
        if gui ~= nil then
            -- If there already was a gui, then we need to close it
            gui.destroy()
        else
            local frame = player.gui.center.add{
                type = "frame",
                name = guiKey,
                direction = "vertical"
            }

            Gui.addMultipleCitiesOverview(frame, event.player_index)
        end
    end
end

return {
    on_shortcut = on_shortcut
}
