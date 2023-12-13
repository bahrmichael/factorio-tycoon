if game.forces.player.technologies["tycoon-baking"].researched then
    game.forces.player.technologies["tycoon-milking"].researched = true
end

if game.forces.player.technologies["tycoon-residential-housing"].researched then
    game.forces.player.technologies["tycoon-milking"].researched = true
    game.forces.player.technologies["tycoon-bottling"].researched = true
end