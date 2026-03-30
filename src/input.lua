-- Centralised mouse/keyboard handler.
local C           = require("src.constants")
local GS          = require("src.gamestate")
local map         = require("src.map")
local player      = require("src.player")
local facility    = require("src.facility")
local upgrade     = require("src.upgrade")
local ui          = require("src.ui")
local meta        = require("src.meta")
local levelselect = require("src.levelselect")
local metashop    = require("src.metashop")

local input = {}

function input.handleMouse(x, y, button)
    x = x - C.SIDE_W   -- convert window x to viewport x
    local state = GS.current

    if state == "menu" then
        if button == 1 and ui.pointInRect(x, y, ui.buttons.menuStart) then
            GS.set("levelselect")
        end

    elseif state == "levelselect" then
        if button == 1 then
            -- Back to menu
            if ui.pointInRect(x, y, levelselect.backRect) then
                GS.set("menu")
                return
            end
            -- Open upgrade shop
            if ui.pointInRect(x, y, levelselect.shopRect) then
                GS.set("metashop")
                return
            end
            -- Click a level card
            for _, rect in ipairs(levelselect.cardRects) do
                if ui.pointInRect(x, y, rect) then
                    if rect.unlocked then
                        if meta.selectedLevel == rect.levelId then
                            -- Second click on selected level → deploy
                            local main = require("main")
                            main.startGame(rect.levelId)
                        else
                            -- First click → select
                            meta.selectedLevel = rect.levelId
                        end
                    end
                    return
                end
            end
        end

    elseif state == "metashop" then
        if button == 1 then
            if ui.pointInRect(x, y, metashop.backRect) then
                GS.set("levelselect")
                return
            end
            for _, rect in ipairs(metashop.buyRects) do
                if ui.pointInRect(x, y, rect) then
                    meta.buy(rect.key)
                    return
                end
            end
        end

    elseif state == "playing" then
        if button == 2 then
            ui.buildMode.active = false
            ui.buildMode.facilityType = nil
            return
        end

        if button == 1 then
            -- Toolbar buttons (toggle build mode per facility type)
            for _, ftype in ipairs(ui.availableFacilities) do
                local btn = ui.facilityButtons[ftype]
                if btn and ui.pointInRect(x, y, btn) then
                    if ui.buildMode.active and ui.buildMode.facilityType == ftype then
                        ui.buildMode.active = false
                    else
                        ui.buildMode.active = true
                        ui.buildMode.facilityType = ftype
                    end
                    return
                end
            end
            -- Click on placed facility to spawn ally (only when not in build mode)
            if not ui.buildMode.active then
                local f = facility.facilityAt(x, y)
                if f then
                    facility.trySpawnAlly(f)
                    return
                end
            end

            -- Grid placement
            if ui.buildMode.active then
                local ftype = ui.buildMode.facilityType
                local def   = facility.defs[ftype]
                local cell  = map.snapToGrid(x, y)

                if cell and map.isCellFree(cell.gx, cell.gy)
                        and #facility.list < C.MAX_FACILITIES
                        and player.canAfford(def.cost) then
                    player.spend(def.cost)
                    facility.place(ftype, cell.gx, cell.gy, cell.wx, cell.wy)
                    map.occupyCell(cell.gx, cell.gy)
                    ui.buildMode.active = false
                    ui.buildMode.facilityType = nil
                end
            end
        end

    elseif state == "levelup" then
        if button == 1 then
            for i, rect in ipairs(ui.cardRects) do
                if ui.pointInRect(x, y, rect) then
                    local card = upgrade.selectedCards[i]
                    if upgrade.apply(card) then
                        GS.set("playing")
                    end
                    return
                end
            end
        end

    elseif state == "runover" then
        if button == 1 then
            if ui.pointInRect(x, y, ui.runOverButtons.missions) then
                GS.set("levelselect")
            elseif ui.pointInRect(x, y, ui.runOverButtons.shop) then
                GS.set("metashop")
            end
        end

    elseif state == "gameover" then
        -- Legacy fallback
        if button == 1 and ui.pointInRect(x, y, ui.buttons.restart) then
            GS.set("levelselect")
        end
    end
end

function input.handleKey(key)
    if key == "escape" then
        if GS.current == "playing" and ui.buildMode.active then
            ui.buildMode.active = false
            ui.buildMode.facilityType = nil
        end
    end
end

return input
