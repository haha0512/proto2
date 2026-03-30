-- Level select screen: rendering and hit rectangles.
local C      = require("src.constants")
local levels = require("src.levels")
local meta   = require("src.meta")

local levelselect = {}

levelselect.cardRects = {}
levelselect.backRect  = { x = 0, y = 0, w = 0, h = 0 }
levelselect.shopRect  = { x = 0, y = 0, w = 0, h = 0 }

local CARD_W  = 360
local CARD_H  = 76
local CARD_X  = (C.SCREEN_W - CARD_W) / 2
local START_Y = 72
local GAP     = 8

function levelselect.draw()
    local assets = require("src.assets")

    -- Background
    love.graphics.setColor(0.05, 0.05, 0.12)
    love.graphics.rectangle("fill", 0, 0, C.SCREEN_W, C.SCREEN_H)

    -- Title
    love.graphics.setFont(assets.fonts.large)
    love.graphics.setColor(C.COL.gate_hp_fg)
    local title = "SELECT MISSION"
    love.graphics.print(title, C.SCREEN_W / 2 - assets.fonts.large:getWidth(title) / 2, 14)

    -- Shard count (top right)
    love.graphics.setFont(assets.fonts.small)
    love.graphics.setColor(C.COL.shard)
    local shardStr = "Shards: " .. meta.shards
    love.graphics.print(shardStr, C.SCREEN_W - assets.fonts.small:getWidth(shardStr) - 8, 20)

    -- Level cards
    levelselect.cardRects = {}

    for i, def in ipairs(levels.defs) do
        local cy       = START_Y + (i - 1) * (CARD_H + GAP)
        local unlocked = meta.isLevelUnlocked(def.id)
        local cleared  = meta.clearedLevels[def.id]
        local selected = meta.selectedLevel == def.id

        levelselect.cardRects[i] = {
            x = CARD_X, y = cy, w = CARD_W, h = CARD_H,
            levelId = def.id, unlocked = unlocked,
        }

        -- Background
        local bgCol
        if not unlocked then
            bgCol = C.COL.card_disabled
        elseif selected then
            bgCol = { 0.10, 0.18, 0.32 }
        else
            bgCol = C.COL.card_bg
        end
        love.graphics.setColor(bgCol)
        love.graphics.rectangle("fill", CARD_X, cy, CARD_W, CARD_H, 4, 4)

        -- Border
        love.graphics.setLineWidth(1.5)
        if selected and unlocked then
            love.graphics.setColor(C.COL.ally)
        elseif not unlocked then
            love.graphics.setColor(C.COL.card_text_dim[1], C.COL.card_text_dim[2], C.COL.card_text_dim[3], 0.25)
        else
            love.graphics.setColor(C.COL.sep[1], C.COL.sep[2], C.COL.sep[3], 0.45)
        end
        love.graphics.rectangle("line", CARD_X, cy, CARD_W, CARD_H, 4, 4)

        if not unlocked then
            -- Locked card
            love.graphics.setFont(assets.fonts.small)
            love.graphics.setColor(C.COL.card_text_dim)
            love.graphics.print("[ LOCKED ]", CARD_X + 12, cy + 10)
            love.graphics.setFont(assets.fonts.tiny)
            love.graphics.setColor(C.COL.card_text_dim[1], C.COL.card_text_dim[2], C.COL.card_text_dim[3], 0.55)
            love.graphics.print("Clear the previous mission to unlock", CARD_X + 12, cy + 30)
            -- Dimmed name on right
            love.graphics.setColor(C.COL.card_text_dim[1], C.COL.card_text_dim[2], C.COL.card_text_dim[3], 0.35)
            local nameStr = def.id .. ". " .. def.name
            love.graphics.print(nameStr, CARD_X + CARD_W - assets.fonts.tiny:getWidth(nameStr) - 12, cy + 10)
        else
            -- Level number + name
            love.graphics.setFont(assets.fonts.medium)
            love.graphics.setColor(C.COL.ui_text)
            love.graphics.print(def.id .. ". " .. def.name, CARD_X + 12, cy + 8)

            -- Wave count + difficulty
            love.graphics.setFont(assets.fonts.tiny)
            love.graphics.setColor(C.COL.ui_text[1], C.COL.ui_text[2], C.COL.ui_text[3], 0.65)
            love.graphics.print(def.waves .. " waves", CARD_X + 12, cy + 30)

            -- Description
            love.graphics.setColor(C.COL.ui_text[1], C.COL.ui_text[2], C.COL.ui_text[3], 0.50)
            love.graphics.printf(def.desc, CARD_X + 12, cy + 46, CARD_W - 100, "left")

            -- Cleared badge
            if cleared then
                love.graphics.setColor(C.COL.exp_fg)
                love.graphics.setFont(assets.fonts.tiny)
                local badge = ">> CLEARED <<"
                love.graphics.print(badge, CARD_X + CARD_W - assets.fonts.tiny:getWidth(badge) - 12, cy + 8)
            end

            -- Selected: deploy hint bottom-right
            if selected then
                love.graphics.setFont(assets.fonts.tiny)
                love.graphics.setColor(C.COL.ally[1], C.COL.ally[2], C.COL.ally[3], 0.85)
                local hint = ">> DEPLOY"
                love.graphics.print(hint, CARD_X + CARD_W - assets.fonts.tiny:getWidth(hint) - 12, cy + CARD_H - 16)
            end
        end
    end

    -- Bottom buttons
    local btnW = 120
    local btnH = 36
    local btnY = C.SCREEN_H - btnH - 16

    -- Back to menu
    local backX = CARD_X
    levelselect.backRect = { x = backX, y = btnY, w = btnW, h = btnH }
    love.graphics.setColor(C.COL.btn_normal)
    love.graphics.rectangle("fill", backX, btnY, btnW, btnH, 4, 4)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(C.COL.sep[1], C.COL.sep[2], C.COL.sep[3], 0.4)
    love.graphics.rectangle("line", backX, btnY, btnW, btnH, 4, 4)
    love.graphics.setFont(assets.fonts.small)
    love.graphics.setColor(C.COL.ui_text)
    local bTxt = "Menu"
    love.graphics.print(bTxt, backX + btnW / 2 - assets.fonts.small:getWidth(bTxt) / 2,
        btnY + btnH / 2 - assets.fonts.small:getHeight() / 2)

    -- Upgrade shop
    local shopX = CARD_X + CARD_W - btnW
    levelselect.shopRect = { x = shopX, y = btnY, w = btnW, h = btnH }
    love.graphics.setColor(C.COL.btn_selected)
    love.graphics.rectangle("fill", shopX, btnY, btnW, btnH, 4, 4)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(C.COL.exp_fg[1], C.COL.exp_fg[2], C.COL.exp_fg[3], 0.6)
    love.graphics.rectangle("line", shopX, btnY, btnW, btnH, 4, 4)
    love.graphics.setFont(assets.fonts.small)
    love.graphics.setColor(C.COL.white)
    local sTxt = "Upgrade Base"
    love.graphics.print(sTxt, shopX + btnW / 2 - assets.fonts.small:getWidth(sTxt) / 2,
        btnY + btnH / 2 - assets.fonts.small:getHeight() / 2)
end

return levelselect
