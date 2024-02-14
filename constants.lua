local OneSecond = 60

local CONSTANTS = {
    -- Each cell has 6x6 tiles
    CELL_SIZE = 6,
    CITY_GROWTH_TICKS = OneSecond * 60,
    CITY_RADIUS = 150,
    -- Minimum ticks until we try adding another city
    MORE_CITIES_TICKS = OneSecond * 120,
    INITIAL_CITY_TICK = 30,
    PASSENGER_SPAWNING_TICKS = OneSecond * 2,

    CITY_SUPPLY_BUILDINGS = {"tycoon-market", "tycoon-hardware-store", "tycoon-water-tower"},
    PRIMARY_INDUSTRIES = {"tycoon-apple-farm", "tycoon-wheat-farm", "tycoon-fishery"},
    CITIZEN_COUNTS = {
        simple = 4,
        residential = 20,
        highrise = 100,
    },

    SURFACE_INDEX = 1,

    RESIDENTIAL_HOUSE_RATIO = 3,
    HIGHRISE_HOUSE_RATIO = 5,
}

return CONSTANTS