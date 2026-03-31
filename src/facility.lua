-- Facility placement, auto-spawn, and tier-upgrade system.
-- Allies are generated automatically over time; no per-unit cost.
-- Stacking two same-type facilities (clicking an existing T1 while in build mode)
-- upgrades it to tier 2: stronger units, faster spawn rate.
local C      = require("src.constants")
local player = require("src.player")

local facility = {}

facility.list = {}

facility.defs = {
    farmstead = {
        cost           = 120,
        upgradeCost    = 160,
        unitClass      = "farmer",
        unitClass2     = "farmer2",
        spawnInterval  = 3,    -- seconds between auto-spawns (tier 1)
        spawnInterval2 = 2,    -- seconds between auto-spawns (tier 2)
        unitCap        = 4,
        asset          = "farmstead",
        asset2         = "farmstead2",
        label          = "Farmstead",
    },
    arcane_tower = {
        cost           = 120,
        upgradeCost    = 160,
        unitClass      = "mage",
        unitClass2     = "mage2",
        spawnInterval  = 3,
        spawnInterval2 = 2,
        unitCap        = 4,
        asset          = "arcane_tower",
        asset2         = "arcane_tower2",
        label          = "Arcane Tower",
    },
    barracks = {
        cost           = 120,
        upgradeCost    = 160,
        unitClass      = "soldier",
        unitClass2     = "soldier2",
        spawnInterval  = 3,
        spawnInterval2 = 2,
        unitCap        = 4,
        asset          = "barracks",
        asset2         = "barracks2",
        label          = "Barracks",
    },
}

function facility.place(ftype, gx, gy, wx, wy)
    local def = facility.defs[ftype]
    local f = {
        facilityType = ftype,
        tier         = 1,
        gridX        = gx,
        gridY        = gy,
        worldX       = wx,
        worldY       = wy,
        asset        = def.asset,
        label        = def.label,
        unitCap      = def.unitCap,
        spawnTimer   = def.spawnInterval,   -- start at full interval (grace period)
        spawnedUnits = {},
    }
    table.insert(facility.list, f)
    return f
end

-- Upgrade a tier-1 facility to tier 2.  Cost is paid by the caller.
function facility.upgrade(f)
    local def = facility.defs[f.facilityType]
    f.tier      = 2
    f.asset     = def.asset2
    -- Reset timer so the upgraded facility starts its first T2 spawn fresh.
    f.spawnTimer = def.spawnInterval2
end

-- Auto-spawn: each facility ticks its own spawn timer.
function facility.update(dt)
    local unit = require("src.unit")
    for _, f in ipairs(facility.list) do
        local def = facility.defs[f.facilityType]
        if def then
            local cap = f.unitCap + player.facilityCapBonus
            if #f.spawnedUnits < cap then
                f.spawnTimer = f.spawnTimer - dt
                if f.spawnTimer <= 0 then
                    local baseInterval = f.tier == 2 and def.spawnInterval2 or def.spawnInterval
                    f.spawnTimer = baseInterval * player.spawnRateMult
                    local class  = f.tier == 2 and def.unitClass2 or def.unitClass
                    local spawnX = math.random(16, C.SCREEN_W - 16)
                    local spawnY = C.GATE_Y - 12
                    local ally   = unit.newAlly(spawnX, spawnY, f, class)
                    table.insert(f.spawnedUnits, ally)
                end
            end
        end
    end
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

function facility.clearAll()
    facility.list = {}
end

-- Remove a specific facility from the list (used after a successful drag-merge).
function facility.remove(f)
    for i = #facility.list, 1, -1 do
        if facility.list[i] == f then
            table.remove(facility.list, i)
            return
        end
    end
end

function facility.draw()
    local assets    = require("src.assets")
    local ui        = require("src.ui")
    local font      = assets.fonts.tiny
    love.graphics.setFont(font)

    local halfCellW = C.CELL_W / 2
    local halfCellH = C.CELL_H / 2
    local dragged   = ui.drag.active and ui.drag.facility

    for _, f in ipairs(facility.list) do
        local def   = facility.defs[f.facilityType]
        local alpha = (dragged and f == dragged) and 0.30 or 1.0

        -- Compute layout from asset height so it stays correct if size changes.
        local assetDesc = assets.getDesc(f.asset)
        local aH        = assetDesc and assetDesc.h or 26
        local halfAH    = aH / 2
        -- Icon centered slightly above cell-center to give equal margins to
        -- the label above and info line below.
        -- With aH=26: iconCY = worldY-2, label at worldY-15, info at worldY+13.
        local iconCY = f.worldY - 2
        local labelY = iconCY - halfAH - 2 - 9   -- 9 = font height, 2 = gap
        local infoY  = iconCY + halfAH + 2

        assets.draw(f.asset, f.worldX, iconCY, alpha)

        -- Highlight valid drop targets while dragging.
        if dragged and f ~= dragged
                and f.facilityType == dragged.facilityType
                and f.tier == 1 then
            local def2       = facility.defs[f.facilityType]
            local canUpgrade = def2 and player.canAfford(def2.upgradeCost)
            local hcol = canUpgrade and C.COL.money or C.COL.card_text_dim
            love.graphics.setColor(hcol[1], hcol[2], hcol[3], 0.85)
            love.graphics.setLineWidth(2.5)
            love.graphics.rectangle("line",
                f.worldX - halfCellW, f.worldY - halfCellH,
                C.CELL_W, C.CELL_H, 3, 3)
            -- Upgrade cost overlaid on the icon area.
            love.graphics.setColor(hcol)
            local upStr = "T2 $" .. (def2 and def2.upgradeCost or "?")
            love.graphics.printf(upStr, f.worldX - halfCellW,
                iconCY - 5, C.CELL_W, "center")
        end

        -- Label at top of cell.
        local tierTag = f.tier == 2 and " \226\152\133" or ""   -- UTF-8 ★
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.printf(f.label .. tierTag,
            f.worldX - halfCellW, labelY, C.CELL_W, "center")

        -- Info line at bottom of cell.
        if def then
            local cap      = f.unitCap + player.facilityCapBonus
            local timer    = math.max(0, f.spawnTimer)
            local atCap    = #f.spawnedUnits >= cap
            local countStr = string.format("%d/%d", #f.spawnedUnits, cap)
            local timeStr  = atCap and "full" or string.format("%.0fs", timer)
            love.graphics.setColor(
                C.COL.ui_text[1], C.COL.ui_text[2], C.COL.ui_text[3],
                0.70 * alpha)
            love.graphics.printf(countStr .. " | " .. timeStr,
                f.worldX - halfCellW, infoY, C.CELL_W, "center")
        end
    end

    -- Drag ghost: facility icon follows the cursor with cost label below it.
    if dragged then
        local mx, my = love.mouse.getPosition()
        mx = mx - C.SIDE_W
        local dgDesc = assets.getDesc(dragged.asset)
        local dgHalfH = dgDesc and dgDesc.h / 2 or 13
        assets.draw(dragged.asset, mx, my, 0.80)
        local def2 = facility.defs[dragged.facilityType]
        if def2 then
            local canUpgrade = player.canAfford(def2.upgradeCost)
            local lcol = canUpgrade and C.COL.money or C.COL.card_text_dim
            love.graphics.setColor(lcol)
            love.graphics.printf("T2 $" .. def2.upgradeCost,
                mx - halfCellW, my + dgHalfH + 3, C.CELL_W, "center")
        end
    end
end

return facility
