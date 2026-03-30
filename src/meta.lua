-- Persistent meta-progression: shards, cleared levels, permanent stat upgrades.
local meta = {}

meta.shards        = 0
meta.clearedLevels = {}   -- { [levelId] = true }
meta.selectedLevel = 1

-- Permanent upgrade tiers (0 = not bought, max 3 each)
meta.tiers = {
    allyDamage  = 0,
    allyHp      = 0,
    startMoney  = 0,
    gateHp      = 0,
    income      = 0,
}

meta.upgradeDefs = {
    { key = "allyDamage",  label = "Weapon Forging",   desc = "+12% ally damage per tier",    costs = { 8, 20, 40 }, maxTier = 3 },
    { key = "allyHp",      label = "Armor Plating",    desc = "+15% ally HP per tier",        costs = { 8, 20, 40 }, maxTier = 3 },
    { key = "startMoney",  label = "War Chest",         desc = "+50 starting gold per tier",   costs = { 5, 12, 25 }, maxTier = 3 },
    { key = "gateHp",      label = "Fortify Gate",      desc = "+40 max gate HP per tier",     costs = { 6, 15, 30 }, maxTier = 3 },
    { key = "income",      label = "Supply Lines",      desc = "+2 gold/sec per tier",         costs = { 8, 20, 40 }, maxTier = 3 },
}

-- Derived bonuses applied to each run (recomputed after any purchase).
meta.allyDamageMult  = 1.0
meta.allyHpMult      = 1.0
meta.startMoneyBonus = 0
meta.gateHpBonus     = 0
meta.incomeBonus     = 0

-- Populated at end of each run for the runover overlay to display.
meta.runResult = {
    levelId        = 1,
    levelName      = "Skirmish",
    wavesCompleted = 0,
    cleared        = false,
    gateHpRatio    = 1.0,
    shardsEarned   = 0,
}

function meta.computeBonus()
    meta.allyDamageMult  = 1.0 + meta.tiers.allyDamage * 0.12
    meta.allyHpMult      = 1.0 + meta.tiers.allyHp     * 0.15
    meta.startMoneyBonus = meta.tiers.startMoney * 50
    meta.gateHpBonus     = meta.tiers.gateHp     * 40
    meta.incomeBonus     = meta.tiers.income     * 2
end

-- Human-readable string of the current bonus for a given upgrade key.
function meta.currentBonusStr(key)
    local tier = meta.tiers[key]
    if tier == 0 then return "No bonus yet" end
    if key == "allyDamage" then
        return string.format("+%d%% ally dmg", math.floor((meta.allyDamageMult - 1) * 100))
    elseif key == "allyHp" then
        return string.format("+%d%% ally HP", math.floor((meta.allyHpMult - 1) * 100))
    elseif key == "startMoney" then
        return string.format("+%d starting gold", meta.startMoneyBonus)
    elseif key == "gateHp" then
        return string.format("+%d gate HP", meta.gateHpBonus)
    elseif key == "income" then
        return string.format("+%d gold/sec", meta.incomeBonus)
    end
    return ""
end

function meta.canBuy(key)
    for _, def in ipairs(meta.upgradeDefs) do
        if def.key == key then
            local tier = meta.tiers[key]
            if tier >= def.maxTier then return false end
            return meta.shards >= def.costs[tier + 1]
        end
    end
    return false
end

function meta.buy(key)
    if not meta.canBuy(key) then return false end
    for _, def in ipairs(meta.upgradeDefs) do
        if def.key == key then
            local cost = def.costs[meta.tiers[key] + 1]
            meta.shards    = meta.shards - cost
            meta.tiers[key] = meta.tiers[key] + 1
            meta.computeBonus()
            return true
        end
    end
    return false
end

function meta.isLevelUnlocked(id)
    if id == 1 then return true end
    return meta.clearedLevels[id - 1] == true
end

meta.computeBonus()

return meta
