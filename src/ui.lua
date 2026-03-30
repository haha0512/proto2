-- HUD, toolbar, level-up overlay, game-over overlay, menu screen.
local C      = require("src.constants")
local player = require("src.player")
local wave   = require("src.wave")
local map    = require("src.map")

local ui = {}

-- Build mode state (read by input.lua, drawn here)
ui.buildMode = { active = false, facilityType = nil }

-- Available facility types for the current level (set by setAvailableFacilities).
ui.availableFacilities = { "farmstead" }

-- Per-type button rects, keyed by facility type string.  Populated each frame
-- by drawToolbar so input.lua can do hit-testing without duplicating the layout.
ui.facilityButtons = {}

-- Button rectangles (used by input.lua for hit testing)
ui.buttons = {
    menuStart = { x = 150, y = 360, w = 100, h = 40 },
    restart   = { x = 150, y = 430, w = 100, h = 40 },
}

function ui.setAvailableFacilities(list)
    ui.availableFacilities = list
    ui.facilityButtons = {}
end

-- Run-over overlay button rects (populated by drawRunOverOverlay each frame)
ui.runOverButtons = {
    missions = { x = 0, y = 0, w = 0, h = 0 },
    shop     = { x = 0, y = 0, w = 0, h = 0 },
}

-- Card rects for level-up overlay (populated by drawLevelUpOverlay each frame)
ui.cardRects = {}

-- ── Helper: filled rounded-ish rect ──────────────────────────────────────────
local function fillRect(x, y, w, h, col, alpha)
    love.graphics.setColor(col[1], col[2], col[3], alpha or 1)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)
end

local function strokeRect(x, y, w, h, col, alpha)
    love.graphics.setColor(col[1], col[2], col[3], alpha or 1)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", x, y, w, h, 4, 4)
end

local function drawBar(x, y, w, h, ratio, bgCol, fgCol)
    love.graphics.setColor(bgCol)
    love.graphics.rectangle("fill", x, y, w, h, 2, 2)
    love.graphics.setColor(fgCol)
    love.graphics.rectangle("fill", x, y, w * math.max(0, math.min(1, ratio)), h, 2, 2)
end

-- ── HUD (shown during playing / gameover) ────────────────────────────────────
function ui.drawHUD()
    local assets = require("src.assets")
    local fm     = assets.fonts.small
    local ft     = assets.fonts.tiny
    love.graphics.setFont(fm)

    -- Semi-transparent HUD panel at top
    local hudH = 56
    fillRect(0, 0, C.SCREEN_W, hudH, C.COL.ui_bg, 0.88)

    -- Row 1: Level + EXP bar + Money
    local expRatio = (player.expToNext > 0) and (player.exp / player.expToNext) or 0
    local lvlStr   = "Lv." .. player.level
    love.graphics.setColor(C.COL.ui_text)
    love.graphics.print(lvlStr, 6, 5)
    local lvlW = fm:getWidth(lvlStr)

    drawBar(lvlW + 10, 8, C.SCREEN_W - lvlW - 20 - 80, 12, expRatio, C.COL.exp_bg, C.COL.exp_fg)
    strokeRect(lvlW + 10, 8, C.SCREEN_W - lvlW - 20 - 80, 12, C.COL.sep, 0.5)

    local moneyStr = "$" .. math.floor(player.money)
    love.graphics.setColor(C.COL.money)
    love.graphics.print(moneyStr, C.SCREEN_W - fm:getWidth(moneyStr) - 6, 5)

    -- Row 2: Wave state
    local waveStr
    if wave.state == "breather" then
        if wave.number == 0 then
            waveStr = string.format("Get ready! %.1fs", math.max(0, wave.breatherTimer))
        else
            waveStr = string.format("Wave %d — next in %.1fs", wave.number, math.max(0, wave.breatherTimer))
        end
    elseif wave.state == "spawning" then
        waveStr = string.format("Wave %d  [%d left]", wave.number, wave.enemiesQueued)
    elseif wave.state == "waitingForClear" then
        waveStr = string.format("Wave %d — Clear!", wave.number)
    else
        waveStr = "Wave " .. wave.number
    end
    love.graphics.setColor(C.COL.ui_text)
    love.graphics.print(waveStr, 6, 24)

    -- Row 2 right: Gate HP
    local gateStr = string.format("Gate: %d/%d", math.max(0, map.gate.hp), map.gate.maxHp)
    local gateRatio = map.gate.hp / map.gate.maxHp
    local gsW = fm:getWidth(gateStr)
    local barX = C.SCREEN_W - gsW - 60 - 10
    drawBar(barX, 27, 55, 10, gateRatio, C.COL.gate_hp_bg, C.COL.gate_hp_fg)
    love.graphics.setColor(C.COL.gate_hp_fg)
    love.graphics.print(gateStr, C.SCREEN_W - gsW - 6, 24)

    -- Row 3: facility count hint
    love.graphics.setFont(ft)
    local facility = require("src.facility")
    local facCount = #facility.list
    love.graphics.setColor(C.COL.ui_text[1], C.COL.ui_text[2], C.COL.ui_text[3], 0.6)
    love.graphics.print(string.format("Facilities: %d/%d", facCount, C.MAX_FACILITIES), 6, 42)

    local passStr = string.format("+%d/s", math.floor(player.passiveIncomePerSec))
    love.graphics.setColor(C.COL.money[1], C.COL.money[2], C.COL.money[3], 0.7)
    love.graphics.print(passStr, C.SCREEN_W - ft:getWidth(passStr) - 6, 42)
end

-- ── Toolbar ───────────────────────────────────────────────────────────────────
function ui.drawToolbar()
    local assets   = require("src.assets")
    local facility = require("src.facility")
    local fm       = assets.fonts.small
    local ft       = assets.fonts.tiny
    local bm       = ui.buildMode

    fillRect(0, C.TOOLBAR_Y, C.SCREEN_W, C.TOOLBAR_H, C.COL.toolbar_bg, 1)
    love.graphics.setColor(C.COL.sep)
    love.graphics.setLineWidth(1)
    love.graphics.line(0, C.TOOLBAR_Y, C.SCREEN_W, C.TOOLBAR_Y)

    local n     = #ui.availableFacilities
    local gap   = 6
    local btnW  = math.floor((C.SCREEN_W - 16 - gap * (n - 1)) / n)
    local btnH  = C.TOOLBAR_H - 12
    local btnY  = C.TOOLBAR_Y + 6

    ui.facilityButtons = {}

    for i, ftype in ipairs(ui.availableFacilities) do
        local btnX = 8 + (i - 1) * (btnW + gap)
        local btn  = { x = btnX, y = btnY, w = btnW, h = btnH }
        ui.facilityButtons[ftype] = btn

        local def       = facility.defs[ftype]
        local selected  = bm.active and bm.facilityType == ftype
        local canAfford = player.canAfford(def.cost)
        local tooMany   = #facility.list >= C.MAX_FACILITIES

        local bgCol
        if selected then
            bgCol = C.COL.btn_selected
        elseif not canAfford or tooMany then
            bgCol = C.COL.btn_disabled
        else
            bgCol = C.COL.btn_normal
        end

        fillRect(btn.x, btn.y, btn.w, btn.h, bgCol, 1)
        if selected then
            strokeRect(btn.x, btn.y, btn.w, btn.h, C.COL.money, 0.9)
        else
            strokeRect(btn.x, btn.y, btn.w, btn.h, C.COL.sep, 0.5)
        end

        -- Icon
        local iconX = btn.x + 20
        local iconY = btn.y + btn.h / 2
        assets.draw(def.asset, iconX, iconY)

        -- Labels
        local textCol = (canAfford and not tooMany) and C.COL.ui_text or C.COL.card_text_dim
        love.graphics.setColor(textCol)
        love.graphics.setFont(fm)
        love.graphics.print(def.label, btn.x + 38, btn.y + 6)
        love.graphics.setFont(ft)
        love.graphics.setColor(C.COL.money[1], C.COL.money[2], C.COL.money[3],
            (canAfford and not tooMany) and 1 or 0.45)
        love.graphics.print(def.costLabel, btn.x + 38, btn.y + 24)

        if tooMany then
            love.graphics.setColor(C.COL.card_text_dim)
            love.graphics.print("(base full)", btn.x + 38, btn.y + 38)
        end
    end

    -- Cancel hint when in build mode
    if bm.active then
        love.graphics.setFont(assets.fonts.tiny)
        love.graphics.setColor(C.COL.ui_text[1], C.COL.ui_text[2], C.COL.ui_text[3], 0.6)
        local hint = "Right-click or press ESC to cancel"
        love.graphics.print(hint, C.SCREEN_W / 2 - assets.fonts.tiny:getWidth(hint) / 2,
            C.TOOLBAR_Y - 14)
    end
end

-- ── Build cursor ghost ────────────────────────────────────────────────────────
function ui.drawBuildCursor()
    if not ui.buildMode.active then return end
    local assets   = require("src.assets")
    local facility = require("src.facility")
    local mx, my   = love.mouse.getPosition()
    mx = mx - C.SIDE_W   -- convert window x to viewport x
    local cell     = map.snapToGrid(mx, my)
    if not cell then return end

    local def  = facility.defs[ui.buildMode.facilityType]
    local desc = assets.getDesc(def.asset)
    if not desc then return end

    local occupied  = not map.isCellFree(cell.gx, cell.gy)
    local tooMany   = #facility.list >= C.MAX_FACILITIES
    local cantAfford = not player.canAfford(def.cost)
    local bad        = occupied or tooMany or cantAfford
    local ghostCol   = bad and C.COL.cursor_bad or C.COL.cursor_ok

    love.graphics.setColor(ghostCol[1], ghostCol[2], ghostCol[3], 0.38)
    if desc.shape == "circle" then
        love.graphics.circle("fill", cell.wx, cell.wy, desc.r)
    elseif desc.shape == "rect" then
        love.graphics.rectangle("fill", cell.wx - desc.w / 2, cell.wy - desc.h / 2, desc.w, desc.h)
    end
    love.graphics.setColor(ghostCol[1], ghostCol[2], ghostCol[3], 0.70)
    if desc.shape == "circle" then
        love.graphics.circle("line", cell.wx, cell.wy, desc.r)
    elseif desc.shape == "rect" then
        love.graphics.rectangle("line", cell.wx - desc.w / 2, cell.wy - desc.h / 2, desc.w, desc.h)
    end
end

-- ── Level-up overlay ──────────────────────────────────────────────────────────
function ui.drawLevelUpOverlay()
    local upgrade = require("src.upgrade")
    local assets  = require("src.assets")
    local fm      = assets.fonts.medium
    local ft      = assets.fonts.small

    -- Dim
    love.graphics.setColor(C.COL.dim[1], C.COL.dim[2], C.COL.dim[3], 0.65)
    love.graphics.rectangle("fill", 0, 0, C.SCREEN_W, C.SCREEN_H)

    -- Title
    love.graphics.setFont(assets.fonts.large)
    love.graphics.setColor(C.COL.exp_fg)
    local title = "LEVEL UP!"
    love.graphics.print(title, C.SCREEN_W / 2 - assets.fonts.large:getWidth(title) / 2, 55)

    love.graphics.setFont(ft)
    love.graphics.setColor(C.COL.ui_text[1], C.COL.ui_text[2], C.COL.ui_text[3], 0.75)
    local sub = "Choose one upgrade:"
    love.graphics.print(sub, C.SCREEN_W / 2 - ft:getWidth(sub) / 2, 87)

    -- Cards are positioned so the bottom card clears the base zone (C.BASE_Y = 455).
    -- 3 cards × 100h + 2 gaps × 10 = 320px total; startY 115 → bottom at 435.
    local cardW = 340
    local cardH = 100
    local cardX = (C.SCREEN_W - cardW) / 2
    local startY = 115

    ui.cardRects = {}

    for i, card in ipairs(upgrade.selectedCards) do
        local cy = startY + (i - 1) * (cardH + 10)

        ui.cardRects[i] = { x = cardX, y = cy, w = cardW, h = cardH }

        fillRect(cardX, cy, cardW, cardH, C.COL.card_bg, 0.96)
        strokeRect(cardX, cy, cardW, cardH, C.COL.exp_fg, 0.7)

        love.graphics.setFont(fm)
        love.graphics.setColor(C.COL.ui_text)
        love.graphics.print(card.label, cardX + 12, cy + 12)

        love.graphics.setFont(ft)
        love.graphics.setColor(C.COL.ui_text[1], C.COL.ui_text[2], C.COL.ui_text[3], 0.85)
        love.graphics.printf(card.desc, cardX + 12, cy + 36, cardW - 24, "left")

    end
end

-- ── Game-over overlay ─────────────────────────────────────────────────────────
function ui.drawGameOverOverlay()
    local assets = require("src.assets")

    love.graphics.setColor(C.COL.dim[1], C.COL.dim[2], C.COL.dim[3], 0.72)
    love.graphics.rectangle("fill", 0, 0, C.SCREEN_W, C.SCREEN_H)

    love.graphics.setFont(assets.fonts.title)
    love.graphics.setColor(C.COL.hp_enemy)
    local go = "GAME OVER"
    love.graphics.print(go, C.SCREEN_W / 2 - assets.fonts.title:getWidth(go) / 2, 220)

    love.graphics.setFont(assets.fonts.medium)
    love.graphics.setColor(C.COL.ui_text)
    local wstr = "Waves survived: " .. wave.number
    love.graphics.print(wstr, C.SCREEN_W / 2 - assets.fonts.medium:getWidth(wstr) / 2, 300)

    -- Restart button
    local btn = ui.buttons.restart
    fillRect(btn.x, btn.y, btn.w, btn.h, C.COL.btn_selected, 1)
    strokeRect(btn.x, btn.y, btn.w, btn.h, C.COL.exp_fg, 0.8)
    love.graphics.setFont(assets.fonts.small)
    love.graphics.setColor(C.COL.white)
    local rtxt = "Play Again"
    love.graphics.print(rtxt, btn.x + btn.w / 2 - assets.fonts.small:getWidth(rtxt) / 2,
        btn.y + btn.h / 2 - assets.fonts.small:getHeight() / 2)
end

-- ── Menu screen ───────────────────────────────────────────────────────────────
function ui.drawMenu()
    local assets = require("src.assets")

    -- Background gradient-ish
    love.graphics.setColor(0.05, 0.05, 0.12)
    love.graphics.rectangle("fill", 0, 0, C.SCREEN_W, C.SCREEN_H)
    love.graphics.setColor(0.10, 0.04, 0.04, 0.6)
    love.graphics.rectangle("fill", 0, 0, C.SCREEN_W, C.SCREEN_H / 2)

    love.graphics.setFont(assets.fonts.title)
    love.graphics.setColor(C.COL.gate_hp_fg)
    local t1 = "BASE"
    love.graphics.print(t1, C.SCREEN_W / 2 - assets.fonts.title:getWidth(t1) / 2, 200)
    love.graphics.setColor(C.COL.ally)
    local t2 = "COMMANDER"
    love.graphics.print(t2, C.SCREEN_W / 2 - assets.fonts.title:getWidth(t2) / 2, 248)

    love.graphics.setFont(assets.fonts.small)
    love.graphics.setColor(C.COL.ui_text[1], C.COL.ui_text[2], C.COL.ui_text[3], 0.7)
    local sub = "Defend your gate. Build. Survive."
    love.graphics.print(sub, C.SCREEN_W / 2 - assets.fonts.small:getWidth(sub) / 2, 308)

    local btn = ui.buttons.menuStart
    fillRect(btn.x, btn.y, btn.w, btn.h, C.COL.btn_selected, 1)
    strokeRect(btn.x, btn.y, btn.w, btn.h, C.COL.exp_fg, 0.9)
    love.graphics.setFont(assets.fonts.medium)
    love.graphics.setColor(C.COL.white)
    local stxt = "Start"
    love.graphics.print(stxt, btn.x + btn.w / 2 - assets.fonts.medium:getWidth(stxt) / 2,
        btn.y + btn.h / 2 - assets.fonts.medium:getHeight() / 2)

    love.graphics.setFont(assets.fonts.tiny)
    love.graphics.setColor(C.COL.ui_text[1], C.COL.ui_text[2], C.COL.ui_text[3], 0.4)
    local hint = "Click to place buildings  |  Right-click to cancel"
    love.graphics.print(hint, C.SCREEN_W / 2 - assets.fonts.tiny:getWidth(hint) / 2, 430)
end

-- ── Run-over overlay (win or loss) ───────────────────────────────────────────
function ui.drawRunOverOverlay()
    local meta   = require("src.meta")
    local assets = require("src.assets")
    local r      = meta.runResult

    -- Dim backdrop
    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", 0, 0, C.SCREEN_W, C.SCREEN_H)

    -- Result banner
    love.graphics.setFont(assets.fonts.title)
    if r.cleared then
        love.graphics.setColor(C.COL.exp_fg)
        local txt = "MISSION CLEARED"
        love.graphics.print(txt, C.SCREEN_W / 2 - assets.fonts.title:getWidth(txt) / 2, 160)
    else
        love.graphics.setColor(C.COL.hp_enemy)
        local txt = "GATE DESTROYED"
        love.graphics.print(txt, C.SCREEN_W / 2 - assets.fonts.title:getWidth(txt) / 2, 160)
    end

    -- Level name
    love.graphics.setFont(assets.fonts.medium)
    love.graphics.setColor(C.COL.ui_text[1], C.COL.ui_text[2], C.COL.ui_text[3], 0.75)
    local lvlTxt = "Mission: " .. r.levelName
    love.graphics.print(lvlTxt, C.SCREEN_W / 2 - assets.fonts.medium:getWidth(lvlTxt) / 2, 218)

    -- Stats panel
    local panelX = C.SCREEN_W / 2 - 130
    local panelY = 255
    local panelW = 260
    local panelH = 80

    love.graphics.setColor(C.COL.ui_bg[1], C.COL.ui_bg[2], C.COL.ui_bg[3], 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 6, 6)
    love.graphics.setColor(C.COL.sep[1], C.COL.sep[2], C.COL.sep[3], 0.4)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 6, 6)

    love.graphics.setFont(assets.fonts.small)
    love.graphics.setColor(C.COL.ui_text)
    love.graphics.print("Waves cleared: " .. r.wavesCompleted, panelX + 14, panelY + 10)
    love.graphics.setColor(C.COL.shard)
    love.graphics.print("Shards earned: +" .. r.shardsEarned, panelX + 14, panelY + 30)
    love.graphics.setColor(C.COL.shard[1], C.COL.shard[2], C.COL.shard[3], 0.65)
    love.graphics.setFont(assets.fonts.tiny)
    love.graphics.print("Total shards: " .. meta.shards, panelX + 14, panelY + 56)

    -- Buttons
    local btnW = 120
    local btnH = 38
    local btnY = 365
    local gap  = 16
    local totalW = btnW * 2 + gap
    local startX = C.SCREEN_W / 2 - totalW / 2

    -- Missions button
    local mx = startX
    ui.runOverButtons.missions = { x = mx, y = btnY, w = btnW, h = btnH }
    love.graphics.setColor(C.COL.btn_normal)
    love.graphics.rectangle("fill", mx, btnY, btnW, btnH, 4, 4)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(C.COL.sep[1], C.COL.sep[2], C.COL.sep[3], 0.5)
    love.graphics.rectangle("line", mx, btnY, btnW, btnH, 4, 4)
    love.graphics.setFont(assets.fonts.small)
    love.graphics.setColor(C.COL.ui_text)
    local mTxt = "Missions"
    love.graphics.print(mTxt, mx + btnW / 2 - assets.fonts.small:getWidth(mTxt) / 2,
        btnY + btnH / 2 - assets.fonts.small:getHeight() / 2)

    -- Upgrade button
    local sx = startX + btnW + gap
    ui.runOverButtons.shop = { x = sx, y = btnY, w = btnW, h = btnH }
    love.graphics.setColor(C.COL.btn_selected)
    love.graphics.rectangle("fill", sx, btnY, btnW, btnH, 4, 4)
    love.graphics.setColor(C.COL.exp_fg[1], C.COL.exp_fg[2], C.COL.exp_fg[3], 0.6)
    love.graphics.rectangle("line", sx, btnY, btnW, btnH, 4, 4)
    love.graphics.setFont(assets.fonts.small)
    love.graphics.setColor(C.COL.white)
    local sTxt = "Upgrade Base"
    love.graphics.print(sTxt, sx + btnW / 2 - assets.fonts.small:getWidth(sTxt) / 2,
        btnY + btnH / 2 - assets.fonts.small:getHeight() / 2)
end

-- ── Helper: point in rect ─────────────────────────────────────────────────────
function ui.pointInRect(x, y, r)
    return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

return ui
