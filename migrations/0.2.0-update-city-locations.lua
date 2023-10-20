for _, city in ipairs(global.tycoon_cities or {}) do
    city.center.x = city.center.x + 3
    city.center.y = city.center.y + 3
end
