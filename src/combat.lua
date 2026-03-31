-- Combat utilities: targeting, damage, pruning.
-- No dependency on unit.lua — units are passed in as lists.
local player = require("src.player")
local fx     = require("src.fx")

local combat = {}

-- COUNTER[a] = b means class a counters class b.
-- Counter deals 2× damage; countered deals 0.5× damage.
-- Tier-2 allies share the same counter relationships as their tier-1 versions.
local COUNTER = {
    farmer   = "plant",
    mage     = "ghost",
    soldier  = "alien",
    farmer2  = "plant",
    mage2    = "ghost",
    soldier2 = "alien",
    plant    = "soldier",   -- also beats soldier2 (checked via countered-by lookup)
    ghost    = "farmer",
    alien    = "mage",
}

-- Reverse map: which ally class does this enemy counter?
-- Used so tier-2 allies are still countered by the appropriate enemy.
local COUNTERED_BY = {
    farmer2  = "ghost",
    mage2    = "alien",
    soldier2 = "plant",
}

local function dist(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

-- Returns the nearest non-dead unit in `list` within `range`, or nil.
function combat.findNearest(u, list, range)
    local best, bestDist = nil, math.huge
    for _, c in ipairs(list) do
        if not c.dead then
            local d = dist(u, c)
            if d <= range and d < bestDist then
                best, bestDist = c, d
            end
        end
    end
    return best, bestDist
end

-- Deals damage from attacker → target unit, applying counter multipliers.
-- If target dies and is an enemy, grants money + exp to the player.
function combat.applyDamage(attacker, target)
    local mult = 1.0
    -- Attacker counters target?
    if COUNTER[attacker.unitClass] == target.unitClass then
        mult = 2.0
    -- Target counters attacker? (covers tier-2 ally classes via COUNTERED_BY)
    elseif COUNTER[target.unitClass] == attacker.unitClass
        or (COUNTERED_BY[attacker.unitClass] == target.unitClass) then
        mult = 0.5
    end
    local dmg = math.max(1, math.floor(attacker.damage * mult))
    target.hp = target.hp - dmg
    -- Floating damage number above the target.
    fx.addFloat(target.x, target.y - target.radius - 4, dmg, target.unitType == "enemy")
    if target.hp <= 0 then
        target.dead = true
        if target.unitType == "enemy" then
            player.addMoney(target.reward + player.moneyPerKill)
            player.addExp(target.expValue)
        end
    end
end

-- Deals gate damage (gate is not a unit; just has .hp and .maxHp).
function combat.applyGateDamage(attacker, gate)
    gate.hp = math.max(0, gate.hp - attacker.damage)
end

-- Removes dead units from the lists; cleans sourceBarracks refs for dead allies.
function combat.pruneDeadUnits(alliesList, enemiesList)
    for i = #alliesList, 1, -1 do
        local a = alliesList[i]
        if a.dead then
            if a.sourceBarracks then
                local sb = a.sourceBarracks
                for j = #sb.spawnedUnits, 1, -1 do
                    if sb.spawnedUnits[j] == a then
                        table.remove(sb.spawnedUnits, j)
                        break
                    end
                end
            end
            table.remove(alliesList, i)
        end
    end
    for i = #enemiesList, 1, -1 do
        if enemiesList[i].dead then
            table.remove(enemiesList, i)
        end
    end
end

return combat
