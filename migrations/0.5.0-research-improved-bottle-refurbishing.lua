if (game.forces.player.technologies["tycoon-bottling"] or {}).researched and (game.forces.player.technologies["tycoon-hygiene"] or {}).researched then
    game.forces.player.recipes["tycoon-refurbish-bottle-with-soap"].enabled = true
end