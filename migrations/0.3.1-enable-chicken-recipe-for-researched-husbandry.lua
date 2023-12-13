if game.forces.player.technologies["tycoon-husbandry"].researched then
    game.forces.player.recipes["tycoon-grow-chicken-with-grain"].enabled = true
end

if game.forces.player.technologies["tycoon-meat-processing"].researched then
    game.forces.player.recipes["tycoon-chicken-to-meat"].enabled = true
end