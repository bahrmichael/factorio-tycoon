local Constants = require("constants")

local function show_info_messages()
    local mgs = game.surfaces[Constants.STARTING_SURFACE_ID].map_gen_settings
    if not global.tycoon_intro_message_displayed then
        game.print({"", "[color=orange]Factorio Tycoon:[/color] ", {"tycooon-intro-message-welcome"}})
        if game.surfaces[Constants.STARTING_SURFACE_ID].map_gen_settings.autoplace_controls["enemy-base"].size > 0 then
            game.print({"", "[color=orange]Factorio Tycoon:[/color] ", {"tycooon-intro-message-peaceful-warning"}})
        end
        global.tycoon_intro_message_displayed = true
    end

    if not global.tycoon_warning_mapgen_displayed then
        if mgs.water == 0 then
            game.print({"", "[color=orange]Factorio Tycoon:[/color] ", {"tycoon-warning-mapgen-pre"}, " ", {"tycoon-warning-mapgen-water"}})
        end
        if     tonumber(mgs.property_expression_names["control-setting:moisture:bias"] or 0) < 0
            or tonumber(mgs.property_expression_names["control-setting:aux:bias"] or 0) < 0 then
            game.print({"", "[color=orange]Factorio Tycoon:[/color] ", {"tycoon-warning-mapgen-pre"}, " ", {"tycoon-warning-mapgen-difficulty"}})
        end
        global.tycoon_warning_mapgen_displayed = true
    end

    -- todo: mention 1 minute consumption and update cycle
    
    -- show the primary industries message after 10 minutes
    if not global.tycoon_info_message_primary_industries_displayed and game.tick > 60 * 60 * 10 then
        game.print({"", "[color=orange]Factorio Tycoon:[/color] ", {"tycooon-info-message-primary-industries"}})
        global.tycoon_info_message_primary_industries_displayed = true
    end
end

return {
    show_info_messages = show_info_messages
}