local OneSecond = 60

local CONSTANTS = {
    -- Each cell has 6x6 tiles
    CELL_SIZE = 6,
    CITY_GROWTH_TICKS = OneSecond * 30,
    CITY_RADIUS = 150,
    -- Minimum ticks until we try adding another city
    MORE_CITIES_TICKS = OneSecond * 60,
    INITIAL_CITY_TICK = 30,
    PASSENGER_SPAWNING_TICKS = OneSecond * 2,
}

return CONSTANTS