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
    },

    GROUND_TILE_TYPES = {
        road = "landfill",
        simple = "landfill",
        residential = "stone-path",
        highrise = "concrete",
    },
}

return CONSTANTS
