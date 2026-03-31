-- Level definitions for the roguelike campaign.
local levels = {}

levels.defs = {
    {
        id = 1, name = "Infestation", waves = 4, enemyMult = 1.00,
        desc = "Your crops have turned. A small raiding force tests your defenses.",
        availableFacilities = { "farmstead" },
        waveComps = {
            { plant = 1.0 },  -- waves 1-4: all plants (fallback covers missing entries)
        },
    },
    {
        id = 2, name = "Haunted Harvest", waves = 7, enemyMult = 1.15,
        desc = "The dead are restless. Something worse than weeds stirs in the fields.",
        availableFacilities = { "farmstead", "arcane_tower" },
        waveComps = {
            { plant = 1.00 },                    -- wave 1
            { plant = 1.00 },                    -- wave 2
            { plant = 0.60, ghost = 0.40 },      -- wave 3
            { plant = 0.60, ghost = 0.40 },      -- wave 4
            { plant = 0.25, ghost = 0.75 },      -- wave 5
            { plant = 0.25, ghost = 0.75 },      -- wave 6
            { plant = 0.10, ghost = 0.90 },      -- wave 7
        },
    },
    {
        id = 3, name = "First Contact", waves = 10, enemyMult = 1.35,
        desc = "They come from beyond the stars. Adapt or fall.",
        availableFacilities = { "farmstead", "arcane_tower", "barracks" },
        waveComps = {
            { plant = 0.50, ghost = 0.50 },                       -- wave 1
            { plant = 0.50, ghost = 0.50 },                       -- wave 2
            { plant = 0.35, ghost = 0.35, alien = 0.30 },         -- wave 3
            { plant = 0.35, ghost = 0.35, alien = 0.30 },         -- wave 4
            { plant = 0.20, ghost = 0.30, alien = 0.50 },         -- wave 5
            { plant = 0.20, ghost = 0.30, alien = 0.50 },         -- wave 6
            { plant = 0.20, ghost = 0.30, alien = 0.50 },         -- wave 7
            { plant = 0.33, ghost = 0.34, alien = 0.33 },         -- wave 8
            { plant = 0.33, ghost = 0.34, alien = 0.33 },         -- wave 9
            { plant = 0.33, ghost = 0.34, alien = 0.33 },         -- wave 10
        },
    },
    {
        id = 4, name = "Onslaught", waves = 14, enemyMult = 1.65,
        desc = "Overwhelming numbers. Hold the line.",
        availableFacilities = { "farmstead", "arcane_tower", "barracks" },
        waveComps = {
            { plant = 0.33, ghost = 0.33, alien = 0.34 },  -- all waves
        },
    },
    {
        id = 5, name = "Apocalypse", waves = 20, enemyMult = 2.10,
        desc = "The final assault. Survive or fall forever.",
        availableFacilities = { "farmstead", "arcane_tower", "barracks" },
        waveComps = {
            { plant = 0.33, ghost = 0.33, alien = 0.34 },  -- all waves
        },
    },
}

-- Shards earned based on run performance.
function levels.shardReward(wavesCompleted, cleared, gateHpRatio)
    local shards = wavesCompleted * 3
    if cleared then
        shards = shards + 10
        if gateHpRatio > 0.5 then shards = shards + 5 end
    end
    return math.max(1, shards)
end

return levels
