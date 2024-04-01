globals = {"data", "game", "global", "defines", "log", "settings", "rendering", "script", "remote", "DEBUG"}
-- https://luacheck.readthedocs.io/en/stable/warnings.html#list-of-warnings
ignore = {
    "612", "614", 
    -- The codes in the next line should be dropped eventually. Allowing them
    -- for now to minimize disruption.
    "211", "631", "211", "542", "611", "213", "311", "212", 
    -- This one may be a bit harder to fix, because luacheck thinks table.deepcopy doesn't exist.
    "143"
}