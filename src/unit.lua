-- Unit factory, frontline-aware update, and draw.
-- Allies march forward continuously; when frontlines meet both sides stop
-- advancing and seek the nearest opponent horizontally.
local C      = require("src.constants")
local combat = require("src.combat")
local player = require("src.player")

local unit  = {}

unit.allies  = {}
unit.enemies = {}

local _nextId = 1

local UnitDefs = {
    -- Ally classes
    farmer  = { speed = 70, hp = 100, damage = 18, atkRange = 40, atkCooldown = 0.65, radius = 9,  reward = 0,  expValue = 0, asset = "ally_farmer"  },
    mage    = { speed = 60, hp = 80,  damage = 26, atkRange = 80, atkCooldown = 0.85, radius = 8,  reward = 0,  expValue = 0, asset = "ally_mage"    },
    soldier = { speed = 80, hp = 120, damage = 20, atkRange = 42, atkCooldown = 0.60, radius = 10, reward = 0,  expValue = 0, asset = "ally_soldier" },
    -- Enemy classes
    plant   = { speed = 38, hp = 180, damage = 20, atkRange = 38, atkCooldown = 0.75, radius = 13, reward = 12, expValue = 1, asset = "enemy_plant"  },
    ghost   = { speed = 75, hp = 115, damage = 22, atkRange = 44, atkCooldown = 0.70, radius = 11, reward = 12, expValue = 1, asset = "enemy_ghost"  },
    alien   = { speed = 65, hp = 145, damage = 26, atkRange = 55, atkCooldown = 0.70, radius = 10, reward = 12, expValue = 1, asset = "enemy_alien"  },
}

-- unitClass must be one of: "farmer", "mage", "soldier"
function unit.newAlly(x, y, sourceBarracks, unitClass)
    local def = UnitDefs[unitClass] or UnitDefs.farmer
    local u = {
        id             = _nextId,
        unitType       = "ally",
        unitClass      = unitClass or "farmer",
        x              = x,
        y              = y,
        hp             = math.floor(def.hp * player.allyHpMult),
        maxHp          = math.floor(def.hp * player.allyHpMult),
        speed          = def.speed * player.allySpeedMult,
        damage         = math.floor(def.damage * player.allyDamageMult),
        atkRange       = def.atkRange,
        atkCooldown    = def.atkCooldown,
        atkTimer       = 0,
        radius         = def.radius,
        target         = nil,
        dead           = false,
        reward         = def.reward,
        expValue       = def.expValue,
        asset          = def.asset,
        sourceBarracks = sourceBarracks,
    }
    _nextId = _nextId + 1
    table.insert(unit.allies, u)
    return u
end

-- unitClass must be one of: "plant", "ghost", "alien"
-- hpMult and dmgMult are wave-scaling multipliers applied to the class base stats.
-- isStream marks enemies spawned by the continuous stream (not counted for wave completion).
function unit.newEnemy(x, y, unitClass, hpMult, dmgMult, isStream)
    local def = UnitDefs[unitClass] or UnitDefs.plant
    hpMult  = hpMult  or 1
    dmgMult = dmgMult or 1
    local hp = math.floor(def.hp * hpMult)
    local u = {
        id             = _nextId,
        unitType       = "enemy",
        unitClass      = unitClass or "plant",
        isStream       = isStream or false,
        x              = x,
        y              = y,
        hp             = hp,
        maxHp          = hp,
        speed          = def.speed * player.enemySpeedMult,
        damage         = math.floor(def.damage * dmgMult),
        atkRange       = def.atkRange,
        atkCooldown    = def.atkCooldown,
        atkTimer       = 0,
        radius         = def.radius,
        target         = nil,
        dead           = false,
        reward         = def.reward,
        expValue       = def.expValue,
        asset          = def.asset,
        sourceBarracks = nil,
    }
    _nextId = _nextId + 1
    table.insert(unit.enemies, u)
    return u
end

function unit.clearAll()
    unit.allies  = {}
    unit.enemies = {}
    _nextId = 1
end

-- ── Update helpers ────────────────────────────────────────────────────────────

local function dist(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

-- Full 2D movement toward (tx, ty).  The shared frontline Y clamp in updateAll
-- handles containment, so no special Y-restriction is needed here.
local function moveToward(u, tx, ty, dt)
    local dx = tx - u.x
    local dy = ty - u.y
    local d  = math.sqrt(dx * dx + dy * dy)
    if d < 0.5 then return end
    u.x = u.x + (dx / d) * u.speed * dt
    u.y = u.y + (dy / d) * u.speed * dt
end

-- ── Spread-aware target selection ────────────────────────────────────────────

-- Finds the best target for `u` from `candidates`, preferring less-targeted ones.
-- `friendlies` is u's own side — used to count how many already target each candidate.
-- `minY`: skip candidates with y < minY (so allies won't chase enemies above the wall).
-- Each extra friendly already targeting a candidate adds CROWD_PENALTY to its score.
local CROWD_PENALTY = 50

local function findSpreadTarget(u, candidates, friendlies, searchR, minY)
    local targeting = {}
    for _, f in ipairs(friendlies) do
        if not f.dead and f ~= u and f.target and f.target.id and not f.target.dead then
            local id = f.target.id
            targeting[id] = (targeting[id] or 0) + 1
        end
    end

    local best, bestScore = nil, math.huge
    for _, c in ipairs(candidates) do
        if not c.dead and (minY == nil or c.y >= minY) then
            local dx = u.x - c.x
            local dy = u.y - c.y
            local d  = math.sqrt(dx * dx + dy * dy)
            if d <= searchR then
                local score = d + (targeting[c.id] or 0) * CROWD_PENALTY
                if score < bestScore then
                    bestScore = score
                    best = c
                end
            end
        end
    end
    return best
end

-- ── Per-unit update ───────────────────────────────────────────────────────────

-- Search radius used when no frontline (free march) vs combat engaged.
-- Deliberately capped even in combat so units don't lunge across the screen.
local SEARCH_R_MARCH  = 120   -- ally: atkRange*~3, enemy: atkRange*~3
local SEARCH_R_COMBAT = 160   -- wider once frontline forms, but not infinite
-- A locked-on target is kept until the enemy moves this far outside search radius.
local TARGET_KEEP_MULT = 1.6  -- drop target when dist > searchR * this

local function updateAlly(u, dt, frontlineY)
    if u.dead then return end

    -- Drop dead target only; distance-based dropping caused stalls when
    -- an enemy was far away horizontally but within frontline lock.
    if u.target and u.target.dead then u.target = nil end

    local searchR = frontlineY and SEARCH_R_COMBAT or SEARCH_R_MARCH

    if not u.target then
        -- Prefer nearby targets; fall back to globally nearest with no Y
        -- filter so the last enemy is never missed even if pushed near the
        -- ally limit wall (enemies can move upward when chasing allies).
        u.target = findSpreadTarget(u, unit.enemies, unit.allies, searchR, C.ALLY_LIMIT_Y)
        if not u.target then
            u.target = findSpreadTarget(u, unit.enemies, unit.allies, math.huge, nil)
        end
    end

    if u.target then
        local d = dist(u, u.target)
        if d <= u.atkRange then
            u.atkTimer = u.atkTimer - dt
            if u.atkTimer <= 0 then
                u.atkTimer = u.atkCooldown
                combat.applyDamage(u, u.target)
            end
        else
            -- Move in full 2D toward the target.  The frontline hard-clamp in
            -- updateAll is skipped for targeted units so they can pathfind around
            -- horizontally separated enemies.
            moveToward(u, u.target.x, u.target.y, dt)
        end
    else
        -- No enemies alive — march forward.
        if u.y > C.ALLY_LIMIT_Y then
            u.y = u.y - u.speed * dt
        end
    end
    -- Ally limit hard wall (always enforced).
    u.y = math.max(u.y, C.ALLY_LIMIT_Y)
end

local function updateEnemy(u, dt, gate, frontlineY)
    if u.dead then return end

    -- Drop dead target (keep gate reference).
    if u.target and u.target ~= gate and u.target.dead then u.target = nil end

    local searchR = frontlineY and SEARCH_R_COMBAT or SEARCH_R_MARCH

    -- Acquire target: prefer nearby allies; fall back to globally nearest.
    if not u.target or u.target == gate then
        local found = findSpreadTarget(u, unit.allies, unit.enemies, searchR, nil)
        if not found then
            found = findSpreadTarget(u, unit.allies, unit.enemies, math.huge, nil)
        end
        if found then u.target = found end
    end

    if u.target and u.target ~= gate then
        local d = dist(u, u.target)
        if d <= u.atkRange then
            u.atkTimer = u.atkTimer - dt
            if u.atkTimer <= 0 then
                u.atkTimer = u.atkCooldown
                combat.applyDamage(u, u.target)
            end
        else
            -- Full 2D navigation toward target (frontline clamp skipped for
            -- targeted units so horizontally separated units can reach each other).
            moveToward(u, u.target.x, u.target.y, dt)
        end
    elseif u.y >= C.GATE_Y then
        u.target = gate
        u.atkTimer = u.atkTimer - dt
        if u.atkTimer <= 0 then
            u.atkTimer = u.atkCooldown
            combat.applyGateDamage(u, gate)
        end
    else
        u.target = nil
        u.y = u.y + u.speed * dt
    end
end

-- ── Separation: push overlapping units apart, anchoring combat units ──────────

-- A unit is "anchored" (immovable during separation) when it is actively
-- fighting: it has a live target within attack range.
local function inCombat(u)
    if not u.target or u.target == true or (u.target.dead ~= nil and u.target.dead) then
        return false
    end
    local dx = u.x - u.target.x
    local dy = u.y - u.target.y
    return math.sqrt(dx * dx + dy * dy) <= u.atkRange
end

-- Applies overlap resolution between two units, respecting their anchor state.
-- Anchored units receive no push; the full correction goes to the free unit.
-- If both are free the push is split evenly; if both are anchored nothing moves.
local function resolvePair(a, b, nx, ny, push, aFixed, bFixed)
    if aFixed and bFixed then
        return
    elseif aFixed then
        b.x = b.x - nx * push
        b.y = b.y - ny * push
    elseif bFixed then
        a.x = a.x + nx * push
        a.y = a.y + ny * push
    else
        local half = push * 0.5
        a.x = a.x + nx * half
        a.y = a.y + ny * half
        b.x = b.x - nx * half
        b.y = b.y - ny * half
    end
end

local function separateUnits(list)
    for i = 1, #list do
        local a = list[i]
        if not a.dead then
            local aFixed = inCombat(a)
            for j = i + 1, #list do
                local b = list[j]
                if not b.dead then
                    local dx      = a.x - b.x
                    local dy      = a.y - b.y
                    local d       = math.sqrt(dx * dx + dy * dy)
                    local minDist = a.radius + b.radius
                    if d < minDist then
                        local push = minDist - d
                        if d > 0.01 then
                            resolvePair(a, b, dx / d, dy / d, push, aFixed, inCombat(b))
                        else
                            resolvePair(a, b, 1, 0, push, aFixed, inCombat(b))
                        end
                    end
                end
            end
        end
    end
    for _, u in ipairs(list) do
        if not u.dead then
            u.x = math.max(u.radius, math.min(C.SCREEN_W - u.radius, u.x))
        end
    end
end

local function separateTeams(allies, enemies)
    for _, a in ipairs(allies) do
        if not a.dead then
            local aFixed = inCombat(a)
            for _, e in ipairs(enemies) do
                if not e.dead then
                    local dx      = a.x - e.x
                    local dy      = a.y - e.y
                    local d       = math.sqrt(dx * dx + dy * dy)
                    local minDist = a.radius + e.radius
                    if d < minDist then
                        local push = minDist - d
                        if d > 0.01 then
                            resolvePair(a, e, dx / d, dy / d, push, aFixed, inCombat(e))
                        else
                            resolvePair(a, e, 1, 0, push, aFixed, inCombat(e))
                        end
                    end
                end
            end
        end
    end
    for _, a in ipairs(allies) do
        if not a.dead then
            a.x = math.max(a.radius, math.min(C.SCREEN_W - a.radius, a.x))
        end
    end
    for _, e in ipairs(enemies) do
        if not e.dead then
            e.x = math.max(e.radius, math.min(C.SCREEN_W - e.radius, e.x))
        end
    end
end

-- ── updateAll: single shared frontline, tick every unit ─────────────────────

function unit.updateAll(dt, gate)
    -- Leading ally  = smallest Y (allies advance upward = decreasing Y).
    -- Leading enemy = largest  Y (enemies advance downward = increasing Y).
    local allyFrontY  = math.huge
    local enemyFrontY = -math.huge
    for _, a in ipairs(unit.allies) do
        if not a.dead then allyFrontY  = math.min(allyFrontY,  a.y) end
    end
    for _, e in ipairs(unit.enemies) do
        if not e.dead then enemyFrontY = math.max(enemyFrontY, e.y) end
    end

    -- One shared frontline = midpoint between the two leading units.
    -- Nil when no contact yet so units march freely.
    local CONTACT_BUFFER = 30
    local frontlineY = nil
    if allyFrontY ~= math.huge and enemyFrontY ~= -math.huge
            and allyFrontY <= enemyFrontY + CONTACT_BUFFER then
        frontlineY = (allyFrontY + enemyFrontY) * 0.5
    end

    for _, a in ipairs(unit.allies)  do updateAlly(a,  dt, frontlineY)        end
    for _, e in ipairs(unit.enemies) do updateEnemy(e, dt, gate, frontlineY)  end

    separateUnits(unit.allies)
    separateUnits(unit.enemies)
    separateTeams(unit.allies, unit.enemies)

    -- Enforce the shared frontline hard wall after movement + separation.
    -- Units that have an active target are exempt: they need to navigate in full 2D
    -- to reach enemies that are horizontally offset from the frontline.
    if frontlineY then
        for _, a in ipairs(unit.allies) do
            if not a.dead and not a.target then
                a.y = math.max(a.y, frontlineY)
            end
        end
        for _, e in ipairs(unit.enemies) do
            if not e.dead and not e.target then
                e.y = math.min(e.y, frontlineY)
            end
        end
    end

    -- Ally limit wall (always enforced regardless of frontline).
    for _, a in ipairs(unit.allies) do
        if not a.dead then a.y = math.max(a.y, C.ALLY_LIMIT_Y) end
    end

    -- Gate hard wall: enemies cannot push past the gate regardless of separation.
    for _, e in ipairs(unit.enemies) do
        if not e.dead then e.y = math.min(e.y, C.GATE_Y) end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────────

local function drawHPBar(u)
    local barW = 20
    local barH = 3
    local bx   = u.x - barW / 2
    local by   = u.y - u.radius - 6
    love.graphics.setColor(C.COL.hp_bg)
    love.graphics.rectangle("fill", bx, by, barW, barH)
    local col = u.unitType == "ally" and C.COL.hp_ally or C.COL.hp_enemy
    love.graphics.setColor(col)
    love.graphics.rectangle("fill", bx, by, barW * math.max(0, u.hp / u.maxHp), barH)
end

function unit.draw()
    local assets = require("src.assets")
    for _, a in ipairs(unit.allies) do
        if not a.dead then
            assets.draw(a.asset, a.x, a.y)
            drawHPBar(a)
        end
    end
    for _, e in ipairs(unit.enemies) do
        if not e.dead then
            assets.draw(e.asset, e.x, e.y)
            drawHPBar(e)
        end
    end
end

return unit
