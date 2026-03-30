local C = require("src.constants")

local map = {}

map.gate = {
    x     = 0,
    y     = C.GATE_Y - 8,
    w     = C.SCREEN_W,
    h     = 8,
    hp    = C.GATE_MAX_HP,
    maxHp = C.GATE_MAX_HP,
}

-- Occupied grid cells: key "gx,gy" -> true
map.occupiedCells = {}

function map.resetGate()
    map.gate.hp    = C.GATE_MAX_HP
    map.gate.maxHp = C.GATE_MAX_HP
end

function map.resetGrid()
    map.occupiedCells = {}
end

-- Returns {gx, gy, wx, wy} or nil if outside build area
function map.snapToGrid(x, y)
    local relX = x
    local relY = y - C.BUILD_AREA_Y
    if relY < 0 or relY >= C.BUILD_AREA_H then return nil end
    if relX < 0 or relX >= C.SCREEN_W then return nil end
    local gx = math.floor(relX / C.CELL_W)  + 1
    local gy = math.floor(relY / C.CELL_H)  + 1
    if gx < 1 or gx > C.GRID_COLS or gy < 1 or gy > C.GRID_ROWS then
        return nil
    end
    local wx = (gx - 0.5) * C.CELL_W
    local wy = C.BUILD_AREA_Y + (gy - 0.5) * C.CELL_H
    return { gx = gx, gy = gy, wx = wx, wy = wy }
end

function map.isCellFree(gx, gy)
    return not map.occupiedCells[gx .. "," .. gy]
end

function map.occupyCell(gx, gy)
    map.occupiedCells[gx .. "," .. gy] = true
end

function map.freeCell(gx, gy)
    map.occupiedCells[gx .. "," .. gy] = nil
end

-- ── Draw helpers ─────────────────────────────────────────────────────────────

function map.drawSideWalls()
    local sw = C.SIDE_W
    local sh = C.SCREEN_H
    local rx = C.SIDE_W + C.SCREEN_W   -- right wall start (window coords)

    local bW  = 40    -- brick width
    local bH  = 20    -- brick height
    local gap = 2     -- mortar gap

    -- Mortar background
    love.graphics.setColor(0.07, 0.06, 0.05)
    love.graphics.rectangle("fill", 0,  0, sw, sh)
    love.graphics.rectangle("fill", rx, 0, sw, sh)

    -- Bricks
    local row = 0
    local y   = 0
    while y < sh do
        local offset = (row % 2 == 0) and 0 or (bW / 2)
        local bx = -offset
        while bx < sw do
            local by = y  + gap / 2
            local bh = bH - gap

            -- left wall brick
            local lx = math.max(0, bx + gap / 2)
            local lw = math.min(bx + gap / 2 + bW - gap, sw) - lx
            if lw > 0 then
                love.graphics.setColor(0.15, 0.13, 0.11)
                love.graphics.rectangle("fill", lx, by, lw, bh)
                love.graphics.setColor(0.21, 0.18, 0.15)
                love.graphics.rectangle("fill", lx, by, lw, 1)     -- top highlight
                love.graphics.setColor(0.10, 0.09, 0.08)
                love.graphics.rectangle("fill", lx, by + bh - 1, lw, 1) -- bottom shadow
            end

            -- right wall brick (mirrored)
            local rlx = math.max(rx, rx + bx + gap / 2)
            local rlw = math.min(rx + bx + gap / 2 + bW - gap, rx + sw) - rlx
            if rlw > 0 then
                love.graphics.setColor(0.15, 0.13, 0.11)
                love.graphics.rectangle("fill", rlx, by, rlw, bh)
                love.graphics.setColor(0.21, 0.18, 0.15)
                love.graphics.rectangle("fill", rlx, by, rlw, 1)
                love.graphics.setColor(0.10, 0.09, 0.08)
                love.graphics.rectangle("fill", rlx, by + bh - 1, rlw, 1)
            end

            bx = bx + bW
        end
        y   = y   + bH
        row = row + 1
    end

    -- Inner edge: shadow strip against the viewport
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", sw - 4, 0, 4, sh)
    love.graphics.rectangle("fill", rx,     0, 4, sh)
end



function map.drawZones()
    -- Combat + spawn zone share one colour (no visual split at the top)
    love.graphics.setColor(C.COL.zone_combat)
    love.graphics.rectangle("fill", 0, 0, C.SCREEN_W, C.BASE_Y)
    -- Base zone
    love.graphics.setColor(C.COL.zone_base)
    love.graphics.rectangle("fill", 0, C.BASE_Y, C.SCREEN_W, C.BASE_H)

    -- Separator between combat area and base
    love.graphics.setColor(C.COL.sep)
    love.graphics.setLineWidth(1)
    love.graphics.line(0, C.BASE_Y, C.SCREEN_W, C.BASE_Y)

    -- Ally limit line (hard wall at 10% from top)
    love.graphics.setColor(C.COL.ally_limit[1], C.COL.ally_limit[2], C.COL.ally_limit[3], 0.55)
    love.graphics.setLineWidth(1.5)
    love.graphics.line(0, C.ALLY_LIMIT_Y, C.SCREEN_W, C.ALLY_LIMIT_Y)
end

function map.drawGate()
    local g = map.gate
    -- Background (depleted portion)
    love.graphics.setColor(C.COL.gate_hp_bg)
    love.graphics.rectangle("fill", g.x, g.y, g.w, g.h)
    -- HP portion
    love.graphics.setColor(C.COL.gate_hp_fg)
    local ratio = math.max(0, g.hp / g.maxHp)
    love.graphics.rectangle("fill", g.x, g.y, g.w * ratio, g.h)
    -- Border
    love.graphics.setColor(C.COL.sep)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", g.x, g.y, g.w, g.h)
end

function map.drawGrid(active)
    if not active then return end
    love.graphics.setColor(C.COL.grid_line[1], C.COL.grid_line[2], C.COL.grid_line[3], 0.22)
    love.graphics.setLineWidth(1)
    for gx = 0, C.GRID_COLS do
        local px = gx * C.CELL_W
        love.graphics.line(px, C.BUILD_AREA_Y, px, C.TOOLBAR_Y)
    end
    for gy = 0, C.GRID_ROWS do
        local py = C.BUILD_AREA_Y + gy * C.CELL_H
        love.graphics.line(0, py, C.SCREEN_W, py)
    end
end

return map
