-- Simple finite-state machine: just tracks the current state name.
-- Behaviors for each state are defined in main.lua.
local GS = {}

GS.current = "menu"

function GS.set(name)
    GS.current = name
end

return GS
