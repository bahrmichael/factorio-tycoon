if (game.forces.player.technologies["tycoon-main-dish"] or {}).researched then
    game.forces.player.recipes["tycoon-patty"].enabled = true
end