-- Wave scheduler: escalating enemy spawns with breather periods between waves.
local C      = require("src.constants")
local player = require("src.player")

local wave = {}

wave.number        = 0
wave.state         = "breather"   -- "spawning" | "waitingForClear" | "breather"
wave.spawnTimer    = 0
wave.spawnInterval = 3.0
wave.breatherTimer = 0
wave.breatherDur   = 0.8
wave.enemiesQueued = 0
wave.currentDef    = {}
wave.maxWaves      = 99999   -- set per level; effectively infinite by default
wave.enemyMult     = 1.0     -- enemy stat multiplier set per level
wave.levelComplete = false   -- set true when last wave is cleared
wave.waveComps     = {}      -- per-wave enemy class compositions; set per level

-- Picks a random enemy class weighted by the composition table.
-- comp = { plant=0.6, ghost=0.4 } etc.  Falls back to "plant" if empty.
local ENEMY_ORDER = { "plant", "ghost", "alien" }
local function pickEnemyClass(comp)
    local r = math.random()
    local cumulative = 0
    for _, class in ipairs(ENEMY_ORDER) do
        cumulative = cumulative + (comp[class] or 0)
        if r <= cumulative then return class end
    end
    return "plant"
end

local function startNextWave()
    wave.number = wave.number + 1
    local n     = wave.number
    local unit  = require("src.unit")

    -- Stat scaling multipliers (applied to each class's own base stats)
    local hpMult  = wave.enemyMult * (1 + n * 0.09)
    local dmgMult = wave.enemyMult * (1 + n * 0.06)

    -- Use the composition for this wave; fall back to the last defined entry.
    local comp = wave.waveComps[n] or wave.waveComps[#wave.waveComps] or { plant = 1.0 }

    local count = 5 + n * 3
    for _ = 1, count do
        local spawnX = math.random(16, C.SCREEN_W - 16)
        local spawnY = math.random(-60, -10)
        local class  = pickEnemyClass(comp)
        unit.newEnemy(spawnX, spawnY, class, hpMult, dmgMult)
    end

    wave.state = "waitingForClear"
end

function wave.update(dt)
    local unit = require("src.unit")

    -- ── Continuous stream: trickle of enemies throughout every wave ───────────
    -- Runs from wave 1 onward; stops once the last wave has started so the
    -- final push is cleanly just that wave's enemies.
    if wave.number > 0 and wave.number < wave.maxWaves then
        wave.streamTimer = wave.streamTimer - dt
        if wave.streamTimer <= 0 then
            local n        = wave.number
            local interval = math.max(1.5, 5.0 - n * 0.25)
            local batch    = math.min(5, 2 + math.floor(n / 3))
            wave.streamTimer = interval

            local hpMult  = wave.enemyMult * (1 + n * 0.09)
            local dmgMult = wave.enemyMult * (1 + n * 0.06)
            local comp    = wave.waveComps[n] or wave.waveComps[#wave.waveComps] or { plant = 1.0 }
            for _ = 1, batch do
                local spawnX = math.random(16, C.SCREEN_W - 16)
                local spawnY = math.random(-60, -10)
                unit.newEnemy(spawnX, spawnY, pickEnemyClass(comp), hpMult, dmgMult, true)
            end
        end
    end

    -- ── Wave state machine ────────────────────────────────────────────────────
    if wave.state == "spawning" then
        -- no longer used, kept for safety
        wave.state = "waitingForClear"

    elseif wave.state == "waitingForClear" then
        -- Only count non-stream enemies; stream enemies don't gate wave progress.
        local waveCount = 0
        for _, e in ipairs(unit.enemies) do
            if not e.isStream then waveCount = waveCount + 1 end
        end
        if waveCount == 0 then
            if wave.number >= wave.maxWaves then
                wave.levelComplete = true
            else
                wave.breatherTimer = wave.breatherDur
                wave.state         = "breather"
            end
        end

    elseif wave.state == "breather" then
        wave.breatherTimer = wave.breatherTimer - dt
        if wave.breatherTimer <= 0 then
            startNextWave()
        end
    end
end

function wave.reset()
    wave.number        = 0
    wave.state         = "breather"
    wave.breatherTimer = 1.5     -- short grace period before wave 1
    wave.spawnTimer    = 0
    wave.enemiesQueued = 0
    wave.currentDef    = {}
    wave.maxWaves      = 99999
    wave.enemyMult     = 1.0
    wave.levelComplete = false
    wave.waveComps     = { { plant = 1.0 } }
    wave.streamTimer   = 7.0
end

wave.reset()

return wave
