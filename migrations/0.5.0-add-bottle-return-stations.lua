if (game.forces.player.technologies["tycoon-bottling"] or {}).researched then
    for _, city in pairs(global.tycoon_cities or {}) do
        table.insert(city.priority_buildings, {name = "tycoon-bottle-return-station", priority = 5})
    end
end