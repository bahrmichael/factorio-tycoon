local OneSecond = 60
-- Factorio's chunk size, in tiles
local CHUNK_SIZE = 32  -- Lua is insane, no access from the same table

local CONSTANTS = {
    CHUNK_SIZE = CHUNK_SIZE,
    -- nothing would be generated inside this area, except for initial farms if enabled
    STARTING_RADIUS_CHUNKS = 128 / CHUNK_SIZE,
    -- NOTE: map_gen_settings.starting_area is mapped as [100%; 600%] => [1; multiplier]
    -- ex: 4(see above) * 4(here) makes SA 600% as 1024x1024 tiles total, 1 disables that setting effect
    STARTING_AREA_MULTIPLIER = 4,

    -- Each cell has 6x6 tiles
    CELL_SIZE = 6,
    CITY_STATS_LIFETIME_TICKS = OneSecond * 30,
    CITY_RADIUS = 150,
    PASSENGER_SPAWNING_TICKS = OneSecond * 2,
    -- Global number of citizens required per city, before another city will be added 
    -- 500 is a random guess. Need to verify if it's a good value through playtesting.
    NEW_CITY_THRESHOLD = 500,

    -- all special buildings, true if required for supply
    CITY_SPECIAL_BUILDINGS = {
        ["tycoon-market"] = true,
        ["tycoon-hardware-store"] = true,
        ["tycoon-water-tower"] = true,
        ["tycoon-treasury"] = false,
        ["tycoon-passenger-train-station"] = false,
        ["tycoon-bottle-return-station"] = false,
    },
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
    -- Special buildings (like the treasury) are an exception that should ideally come first.
    CONSTRUCTION_MATERIALS = {
        ["tycoon-treasury"] = {
            ["stone-brick"] = 1,
            ["iron-plate"] = 1,
        },
        ["tycoon-bottle-return-station"] = {
            ["stone-brick"] = 20,
            ["iron-plate"] = 10,
            ["steel-plate"] = 5,
        },
        highrise = {
            ["concrete"] = 50,
            ["steel-plate"] = 25,
            ["small-lamp"] = 5,
            ["pump"] = 2,
            ["pipe"] = 10,
        },
        residential = {
            ["stone-brick"] = 30,
            ["iron-plate"] = 20,
            ["steel-plate"] = 10,
            ["small-lamp"] = 2,
        },
        simple = {
            ["stone-brick"] = 10,
            ["iron-plate"] = 5,
        },
        garden = {
        },
    },
    GROUND_TILE_TYPES = {
        road = "landfill",
        simple = "landfill",
        residential = "stone-path",
        highrise = "concrete",
    },
    TREASURY_CONVERSION_RATE = {
        ["tycoon-currency"] = 150,
        ["tycoon-money-stack"] = 1
    }
}

return CONSTANTS
