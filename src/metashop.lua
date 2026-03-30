-- Permanent upgrade shop: rendering and hit rectangles.
local C    = require("src.constants")
local meta = require("src.meta")

local metashop = {}

metashop.buyRects = {}
metashop.backRect = { x = 0, y = 0, w = 0, h = 0 }

local ROW_W  = C.SCREEN_W - 40
local ROW_X  = 20
local ROW_H  = 72
local START_Y = 82
local GAP     = 8

function metashop.draw()
    local assets = require("src.assets")
    local fm     = assets.fonts.medium
    local ft     = assets.fonts.tiny
    local fs     = assets.fonts.small

    -- Background
    love.graphics.setColor(0.04, 0.07, 0.04)
    love.graphics.rectangle("fill", 0, 0, C.SCREEN_W, C.SCREEN_H)

    -- Title
    love.graphics.setFont(assets.fonts.large)
    love.graphics.setColor(C.COL.exp_fg)
    local title = "UPGRADE BASE"
    love.graphics.print(title, C.SCREEN_W / 2 - assets.fonts.large:getWidth(title) / 2, 14)

    -- Shard count
    love.graphics.setFont(fm)
    love.graphics.setColor(C.COL.shard)
    local shardStr = "Shards: " .. meta.shards
    love.graphics.print(shardStr, C.SCREEN_W / 2 - fm:getWidth(shardStr) / 2, 50)

    -- Upgrade rows
    metashop.buyRects = {}

    for i, def in ipairs(meta.upgradeDefs) do
        local ry    = START_Y + (i - 1) * (ROW_H + GAP)
        local tier  = meta.tiers[def.key]
        local maxed = tier >= def.maxTier
        local cost  = maxed and nil or def.costs[tier + 1]
        local canBuy = not maxed and meta.shards >= cost

        -- Row background
        love.graphics.setColor(C.COL.card_bg)
        love.graphics.rectangle("fill", ROW_X, ry, ROW_W, ROW_H, 4, 4)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(C.COL.sep[1], C.COL.sep[2], C.COL.sep[3], 0.3)
        love.graphics.rectangle("line", ROW_X, ry, ROW_W, ROW_H, 4, 4)

        -- Upgrade name
        love.graphics.setFont(fs)
        love.graphics.setColor(C.COL.ui_text)
        love.graphics.print(def.label, ROW_X + 10, ry + 8)

        -- Tier pips (filled = bought)
        local pipW    = 14
        local pipGap  = 4
        local pipX    = ROW_X + 10 + fs:getWidth(def.label) + 14
        local pipY    = ry + 10
        for t = 1, def.maxTier do
            if t <= tier then
                love.graphics.setColor(C.COL.exp_fg)
            else
                love.graphics.setColor(C.COL.exp_bg)
            end
            love.graphics.rectangle("fill", pipX + (t - 1) * (pipW + pipGap), pipY, pipW, 10, 2, 2)
        end

        -- Description
        love.graphics.setFont(ft)
        love.graphics.setColor(C.COL.ui_text[1], C.COL.ui_text[2], C.COL.ui_text[3], 0.65)
        love.graphics.print(def.desc, ROW_X + 10, ry + 28)

        -- Current bonus
        love.graphics.setColor(C.COL.shard[1], C.COL.shard[2], C.COL.shard[3], 0.85)
        love.graphics.print(meta.currentBonusStr(def.key), ROW_X + 10, ry + 44)

        -- Buy button
        local btnW = 82
        local btnH = 34
        local btnX = ROW_X + ROW_W - btnW - 8
        local btnY = ry + (ROW_H - btnH) / 2
        metashop.buyRects[i] = { x = btnX, y = btnY, w = btnW, h = btnH, key = def.key }

        if maxed then
            love.graphics.setColor(C.COL.btn_disabled)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)
            love.graphics.setFont(ft)
            love.graphics.setColor(C.COL.card_text_dim)
            local txt = "MAXED"
            love.graphics.print(txt, btnX + btnW / 2 - ft:getWidth(txt) / 2,
                btnY + btnH / 2 - ft:getHeight() / 2)
        else
            love.graphics.setColor(canBuy and C.COL.btn_selected or C.COL.btn_disabled)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)
            if canBuy then
                love.graphics.setLineWidth(1)
                love.graphics.setColor(C.COL.exp_fg[1], C.COL.exp_fg[2], C.COL.exp_fg[3], 0.65)
                love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 4, 4)
            end
            love.graphics.setFont(ft)
            love.graphics.setColor(canBuy and C.COL.white or C.COL.card_text_dim)
            local txt = cost .. " shards"
            love.graphics.print(txt, btnX + btnW / 2 - ft:getWidth(txt) / 2,
                btnY + btnH / 2 - ft:getHeight() / 2)
        end
    end

    -- Back to missions button
    local btnW  = 150
    local btnH  = 36
    local btnX  = C.SCREEN_W / 2 - btnW / 2
    local btnY  = C.SCREEN_H - btnH - 16
    metashop.backRect = { x = btnX, y = btnY, w = btnW, h = btnH }
    love.graphics.setColor(C.COL.btn_normal)
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(C.COL.sep[1], C.COL.sep[2], C.COL.sep[3], 0.45)
    love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 4, 4)
    love.graphics.setFont(assets.fonts.small)
    love.graphics.setColor(C.COL.ui_text)
    local bTxt = "Back to Missions"
    love.graphics.print(bTxt, btnX + btnW / 2 - assets.fonts.small:getWidth(bTxt) / 2,
        btnY + btnH / 2 - assets.fonts.small:getHeight() / 2)
end

return metashop
