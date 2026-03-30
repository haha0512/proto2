local C = require("src.constants")

local player = {}

function player.reset()
    player.money    = C.START_MONEY
    player.exp      = 0
    player.level    = 1
    -- Fibonacci kill requirements: 2, 3, 5, 8, 13 ...
    -- expValue per enemy kill = 1, so expToNext = kills needed.
    player.fibPrev   = 2   -- f(n-1), used to compute next term on level-up
    player.expToNext = 2   -- f(n)   = kills needed to reach next level

    -- Stat multipliers (modified by upgrades at runtime)
    player.allyDamageMult       = 1.0
    player.allyHpMult           = 1.0
    player.allySpeedMult        = 1.0
    player.moneyPerKill         = 0      -- flat gold bonus per kill
    player.passiveIncomePerSec  = 5      -- base gold/sec
    player.spawnCostMult        = 1.0    -- multiplied when computing ally spawn cost
    player.barracksCapBonus     = 0      -- +N to each barracks unit cap
    player.enemySpeedMult       = 1.0    -- < 1 = slower enemies

    player._leveledUp = false
end

function player.canAfford(cost)
    return player.money >= cost
end

function player.spend(cost)
    player.money = player.money - cost
end

function player.addMoney(amount)
    player.money = player.money + amount
end

function player.addExp(amount)
    player.exp = player.exp + amount
    if player.exp >= player.expToNext then
        player.exp       = player.exp - player.expToNext
        player.level     = player.level + 1
        local nextFib    = player.fibPrev + player.expToNext
        player.fibPrev   = player.expToNext
        player.expToNext = nextFib
        player._leveledUp = true
    end
end

-- Returns true once per level-up event, then resets the flag.
function player.consumeLevelUp()
    if player._leveledUp then
        player._leveledUp = false
        return true
    end
    return false
end

player.reset()

return player
