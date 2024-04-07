--local Constants = require("constants")
--local Util = require("util")


--- @event on_surface_cleared
--- @param surface_index uint
--- @param name @defines.events
--- @param tick uint

--- NOTE: This is not called when the default surface is created as it will always exist.
--- @event on_surface_created
--- @param surface_index uint
--- @param name @defines.events
--- @param tick uint

--- @event on_surface_deleted
--- @param surface_index uint
--- @param name @defines.events
--- @param tick uint

--- @event on_surface_imported
--- @param surface_index uint
--- @param original_name string
--- @param name @defines.events
--- @param tick uint

--- @event on_surface_renamed
--- @param surface_index uint
--- @param old_name string
--- @param new_name string
--- @param name @defines.events
--- @param tick uint


-- module
local M = {}

function M.on_surface_cleared(event)
    log("event: ".. tostring(event.name) .." surface: ".. tostring(event.surface_index))
end

function M.on_surface_created(event)
    log("event: ".. tostring(event.name) .." surface: ".. tostring(event.surface_index))
end

function M.on_surface_deleted(event)
    log("event: ".. tostring(event.name) .." surface: ".. tostring(event.surface_index))
end

function M.on_surface_imported(event)
    log("event: ".. tostring(event.name) .." surface: ".. tostring(event.surface_index))
end

function M.on_surface_renamed(event)
    log("event: ".. tostring(event.name) .." surface: ".. tostring(event.surface_index))
end


return M
