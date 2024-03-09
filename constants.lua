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

    STARTING_SURFACE_ID = 1,

    RESIDENTIAL_HOUSE_RATIO = 3,
    HIGHRISE_HOUSE_RATIO = 5,

    -- This array is ordered from most expensive to cheapest, so that
    -- we do expensive upgrades first (instead of just letting the road always expand).
    -- Sepcial buildings (like the treasury) are an exception that should ideally come first.
    CONSTRUCTION_MATERIALS = {
        specialBuildings = {{
            name = "stone-brick",
            required = 1,
        }, {
            name = "iron-plate",
            required = 1,
        }},
        highrise = {{
            name = "concrete",
            required = 50,
        }, {
            name = "steel-plate",
            required = 25,
        }, {
            name = "small-lamp",
            required = 5,
        }, {
            name = "pump",
            required = 2,
        }, {
            name = "pipe",
            required = 10,
        }},
        residential = {{
            name = "stone-brick",
            required = 30,
        }, {
            name = "iron-plate",
            required = 20,
        }, {
            name = "steel-plate",
            required = 10,
        }, {
            name = "small-lamp",
            required = 2,
        }},
        simple = {{
            name = "stone-brick",
            required = 10,
        }, {
            name = "iron-plate",
            required = 5,
        }},
    }
}

return CONSTANTS
