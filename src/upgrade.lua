-- Upgrade pool, random card selection, and application.
local player   = require("src.player")

local upgrade = {}

local pool = {
    {
        id    = "ally_damage",
        label = "+Ally Damage",
        desc  = "All allies deal 25% more damage",
        cost  = 50,
        apply = function()
            player.allyDamageMult = player.allyDamageMult * 1.25
        end,
    },
    {
        id    = "ally_hp",
        label = "+Ally HP",
        desc  = "All allies have 30% more HP",
        cost  = 50,
        apply = function()
            player.allyHpMult = player.allyHpMult * 1.30
        end,
    },
    {
        id    = "ally_speed",
        label = "+Ally Speed",
        desc  = "All allies move 20% faster",
        cost  = 40,
        apply = function()
            player.allySpeedMult = player.allySpeedMult * 1.20
        end,
    },
    {
        id    = "barracks_rate",
        label = "Cheaper Allies",
        desc  = "Allies cost 25% less to spawn",
        cost  = 0,
        apply = function()
            player.spawnCostMult = player.spawnCostMult * 0.75
        end,
    },
    {
        id    = "barracks_cap",
        label = "+Unit Cap",
        desc  = "Each Barracks allows 1 more ally",
        cost  = 70,
        apply = function()
            player.barracksCapBonus = player.barracksCapBonus + 1
        end,
    },
    {
        id    = "money_per_kill",
        label = "+Gold per Kill",
        desc  = "Earn +5 gold for each enemy killed",
        cost  = 45,
        apply = function()
            player.moneyPerKill = player.moneyPerKill + 5
        end,
    },
    {
        id    = "passive_income",
        label = "Passive Income",
        desc  = "Gain +3 gold per second, always",
        cost  = 65,
        apply = function()
            player.passiveIncomePerSec = player.passiveIncomePerSec + 3
        end,
    },
    {
        id    = "gate_repair",
        label = "Repair Gate",
        desc  = "Restore 80 HP to the gate",
        cost  = 80,
        apply = function()
            local map  = require("src.map")
            map.gate.hp = math.min(map.gate.hp + 80, map.gate.maxHp)
        end,
    },
}

upgrade.selectedCards = {}

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function upgrade.beginSelection()
    local copy = {}
    for _, u in ipairs(pool) do table.insert(copy, u) end
    shuffle(copy)
    upgrade.selectedCards = { copy[1], copy[2], copy[3] }
end

-- Upgrades are always free; just apply and return.
function upgrade.apply(card)
    card.apply()
    return true
end

return upgrade
