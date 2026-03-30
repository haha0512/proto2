-- Facility placement, draw, and manual ally spawning.
local C      = require("src.constants")
local player = require("src.player")

local facility = {}

facility.list = {}

facility.defs = {
    farmstead = {
        cost      = 80,
        spawnCost = 20,
        unitCap   = 4,
        unitClass = "farmer",
        asset     = "farmstead",
        label     = "Farmstead",
        costLabel = "$80",
    },
    arcane_tower = {
        cost      = 80,
        spawnCost = 20,
        unitCap   = 4,
        unitClass = "mage",
        asset     = "arcane_tower",
        label     = "Arcane Tower",
        costLabel = "$80",
    },
    barracks = {
        cost      = 80,
        spawnCost = 20,
        unitCap   = 4,
        unitClass = "soldier",
        asset     = "barracks",
        label     = "Barracks",
        costLabel = "$80",
    },
}

function facility.place(ftype, gx, gy, wx, wy)
    local def = facility.defs[ftype]
    local f = {
        facilityType = ftype,
        gridX        = gx,
        gridY        = gy,
        worldX       = wx,
        worldY       = wy,
        asset        = def.asset,
        label        = def.label,
        unitCap      = def.unitCap,
        spawnedUnits = {},
    }
    table.insert(facility.list, f)
    return f
end

-- Called when the player clicks on a facility.  Spawns one ally if affordable
-- and under cap; returns true if a unit was spawned.
function facility.trySpawnAlly(f)
    local def = facility.defs[f.facilityType]
    if not def then return false end
    local cap  = f.unitCap + player.barracksCapBonus
    if #f.spawnedUnits >= cap then return false end
    local cost = math.floor(def.spawnCost * player.spawnCostMult)
    if not player.canAfford(cost) then return false end

    local unit = require("src.unit")
    player.spend(cost)
    local spawnX = math.random(16, C.SCREEN_W - 16)
    local spawnY = C.GATE_Y - 12
    local ally   = unit.newAlly(spawnX, spawnY, f, def.unitClass)
    table.insert(f.spawnedUnits, ally)
    return true
end

-- Returns the facility (if any) whose hitbox contains (x, y), else nil.
function facility.facilityAt(x, y)
    for _, f in ipairs(facility.list) do
        if math.abs(x - f.worldX) <= 34 and math.abs(y - f.worldY) <= 28 then
            return f
        end
    end
    return nil
end

function facility.update(dt)
end

function facility.clearAll()
    facility.list = {}
end

function facility.draw()
    local assets = require("src.assets")
    local font   = assets.fonts.tiny
    love.graphics.setFont(font)
    for _, f in ipairs(facility.list) do
        assets.draw(f.asset, f.worldX, f.worldY)

        local assetDesc = assets.getDesc(f.asset)
        local labelY    = f.worldY + (assetDesc and assetDesc.h or 48) / 2 + 4

        love.graphics.setColor(C.COL.white)
        local tw = font:getWidth(f.label)
        love.graphics.print(f.label, f.worldX - tw / 2, labelY)

        local def = facility.defs[f.facilityType]
        if def then
            local cap      = f.unitCap + player.barracksCapBonus
            local cost     = math.floor(def.spawnCost * player.spawnCostMult)
            local infoStr  = string.format("%d/%d  $%d", #f.spawnedUnits, cap, cost)
            local canSpawn = #f.spawnedUnits < cap and player.canAfford(cost)
            love.graphics.setColor(canSpawn and C.COL.money or C.COL.card_text_dim)
            local iw = font:getWidth(infoStr)
            love.graphics.print(infoStr, f.worldX - iw / 2, labelY + 10)
        end
    end
end

return facility
