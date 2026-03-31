-- Visual effects: attack animations and floating damage numbers.
local fx = {}

fx.effects = {}
fx.floats  = {}

-- ── Spawners ─────────────────────────────────────────────────────────────────

-- Melee impact burst at (x, y).
function fx.addMelee(x, y, color)
    table.insert(fx.effects, {
        type = "melee", x = x, y = y,
        timer = 0.22, maxTimer = 0.22,
        color = color,
    })
end

-- Projectile traveling from (x1,y1) to (x2,y2).
function fx.addProjectile(x1, y1, x2, y2, color)
    table.insert(fx.effects, {
        type = "projectile",
        x1 = x1, y1 = y1, x2 = x2, y2 = y2,
        timer = 0.18, maxTimer = 0.18,
        color = color,
    })
end

-- Expanding AOE ring centered at (x, y) growing out to radius.
function fx.addAoe(x, y, radius, color)
    table.insert(fx.effects, {
        type = "aoe", x = x, y = y,
        radius = radius,
        timer = 0.42, maxTimer = 0.42,
        color = color,
    })
end

-- Floating damage number rising above (x, y).
-- isEnemy = true → white (enemy took damage); false → red (ally took damage).
function fx.addFloat(x, y, amount, isEnemy)
    table.insert(fx.floats, {
        x     = x + math.random(-6, 6),
        y     = y,
        vy    = -50,
        text  = tostring(amount),
        timer = 0.85, maxTimer = 0.85,
        isEnemy = isEnemy,
    })
end

-- ── Update ────────────────────────────────────────────────────────────────────

function fx.update(dt)
    for i = #fx.effects, 1, -1 do
        local e = fx.effects[i]
        e.timer = e.timer - dt
        if e.timer <= 0 then table.remove(fx.effects, i) end
    end
    for i = #fx.floats, 1, -1 do
        local f = fx.floats[i]
        f.timer = f.timer - dt
        f.y     = f.y + f.vy * dt
        if f.timer <= 0 then table.remove(fx.floats, i) end
    end
end

-- ── Draw ──────────────────────────────────────────────────────────────────────

function fx.draw()
    local assets = require("src.assets")

    for _, e in ipairs(fx.effects) do
        local t     = e.timer / e.maxTimer   -- 1→0  (remaining ratio)
        local alpha = t                       -- linear fade-out

        if e.type == "melee" then
            -- Six lines radiating outward from the impact point.
            love.graphics.setColor(e.color[1], e.color[2], e.color[3], alpha)
            love.graphics.setLineWidth(1.8)
            local innerR = 3 + (1 - t) * 4
            local outerR = innerR + 8
            for k = 1, 6 do
                local a = (k / 6) * math.pi * 2
                love.graphics.line(
                    e.x + math.cos(a) * innerR, e.y + math.sin(a) * innerR,
                    e.x + math.cos(a) * outerR, e.y + math.sin(a) * outerR)
            end
            -- Faint central flash.
            love.graphics.setColor(e.color[1], e.color[2], e.color[3], alpha * 0.45)
            love.graphics.circle("fill", e.x, e.y, innerR * 0.65)

        elseif e.type == "projectile" then
            -- Dot traveling from source to target with a short trailing line.
            local progress = 1 - t
            local px = e.x1 + (e.x2 - e.x1) * progress
            local py = e.y1 + (e.y2 - e.y1) * progress
            love.graphics.setColor(e.color[1], e.color[2], e.color[3], alpha)
            love.graphics.circle("fill", px, py, 4)
            local tp = math.max(0, progress - 0.22)
            local tx = e.x1 + (e.x2 - e.x1) * tp
            local ty = e.y1 + (e.y2 - e.y1) * tp
            if math.abs(px - tx) + math.abs(py - ty) > 1 then
                love.graphics.setColor(e.color[1], e.color[2], e.color[3], alpha * 0.35)
                love.graphics.setLineWidth(2.5)
                love.graphics.line(tx, ty, px, py)
            end

        elseif e.type == "aoe" then
            -- Ring expanding from 0 to full radius, with faint fill.
            local progress = 1 - t
            local r = math.max(1, e.radius * progress)
            love.graphics.setColor(e.color[1], e.color[2], e.color[3], alpha * 0.80)
            love.graphics.setLineWidth(2.5)
            love.graphics.circle("line", e.x, e.y, r)
            love.graphics.setColor(e.color[1], e.color[2], e.color[3], alpha * 0.13)
            love.graphics.circle("fill", e.x, e.y, r)
        end
    end

    -- Floating damage numbers: fade out over the last 0.28 s.
    love.graphics.setFont(assets.fonts.small)
    for _, f in ipairs(fx.floats) do
        local alpha = math.min(1, f.timer / 0.28)
        local col   = f.isEnemy and {1, 1, 1} or {1, 0.18, 0.18}
        love.graphics.setColor(col[1], col[2], col[3], alpha)
        local tw = assets.fonts.small:getWidth(f.text)
        love.graphics.print(f.text, math.floor(f.x - tw / 2), math.floor(f.y))
    end
end

function fx.clear()
    fx.effects = {}
    fx.floats  = {}
end

return fx
