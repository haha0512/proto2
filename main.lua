-- Entry point.  Thin router: loads modules, delegates per frame to gamestate.
local C           = require("src.constants")
local GS          = require("src.gamestate")
local assets      = require("src.assets")
local map         = require("src.map")
local player      = require("src.player")
local unit        = require("src.unit")
local facility    = require("src.facility")
local wave        = require("src.wave")
local combat      = require("src.combat")
local upgrade     = require("src.upgrade")
local ui          = require("src.ui")
local input       = require("src.input")
local meta        = require("src.meta")
local levels      = require("src.levels")
local levelselect = require("src.levelselect")
local metashop    = require("src.metashop")

local main = {}   -- exposed so input.lua can call main.startGame()

-- Start a run for the given level ID (defaults to meta.selectedLevel).
function main.startGame(levelId)
    meta.selectedLevel = levelId or meta.selectedLevel
    local lvlDef = levels.defs[meta.selectedLevel]

    player.reset()
    wave.reset()
    wave.maxWaves  = lvlDef.waves
    wave.enemyMult = lvlDef.enemyMult
    wave.waveComps = lvlDef.waveComps or { { plant = 1.0 } }
    unit.clearAll()
    facility.clearAll()
    map.resetGate()
    map.resetGrid()
    ui.setAvailableFacilities(lvlDef.availableFacilities or { "farmstead" })

    -- Apply permanent meta bonuses on top of the reset defaults
    player.allyDamageMult      = player.allyDamageMult * meta.allyDamageMult
    player.allyHpMult          = player.allyHpMult     * meta.allyHpMult
    player.money               = player.money          + meta.startMoneyBonus
    player.passiveIncomePerSec = player.passiveIncomePerSec + meta.incomeBonus
    map.gate.maxHp = C.GATE_MAX_HP + meta.gateHpBonus
    map.gate.hp    = map.gate.maxHp

    ui.buildMode.active       = false
    ui.buildMode.facilityType = nil
    GS.set("playing")
end

-- Called when a run ends (either gate destroyed or all waves cleared).
function main.endRun(cleared)
    local gateRatio    = map.gate.hp / map.gate.maxHp
    local shardsEarned = levels.shardReward(wave.number, cleared, gateRatio)

    meta.shards = meta.shards + shardsEarned
    if cleared then
        meta.clearedLevels[meta.selectedLevel] = true
    end

    local lvlDef = levels.defs[meta.selectedLevel]
    meta.runResult = {
        levelId        = meta.selectedLevel,
        levelName      = lvlDef.name,
        wavesCompleted = wave.number,
        cleared        = cleared,
        gateHpRatio    = gateRatio,
        shardsEarned   = shardsEarned,
    }

    GS.set("runover")
end

-- ── Love2D callbacks ──────────────────────────────────────────────────────────

function love.load()
    math.randomseed(os.time())
    assets.load()
    GS.set("menu")
end

function love.update(dt)
    -- Cap dt to avoid spiral of death on lag spikes
    dt = math.min(dt, 0.05)

    if GS.current == "playing" then
        if player.passiveIncomePerSec > 0 then
            player.addMoney(player.passiveIncomePerSec * dt)
        end

        wave.update(dt)
        facility.update(dt)
        unit.updateAll(dt, map.gate)
        combat.pruneDeadUnits(unit.allies, unit.enemies)

        -- Check gate destroyed (loss)
        if map.gate.hp <= 0 then
            main.endRun(false)
            return
        end

        -- Check all waves cleared (win)
        if wave.levelComplete then
            wave.levelComplete = false
            main.endRun(true)
            return
        end

        -- Check level-up
        if player.consumeLevelUp() then
            upgrade.beginSelection()
            GS.set("levelup")
            return
        end
    end
    -- levelup, runover, levelselect, metashop have no update logic
end

function love.draw()
    love.graphics.setColor(1, 1, 1)

    local gs = GS.current

    map.drawSideWalls()

    love.graphics.push()
    love.graphics.translate(C.SIDE_W, 0)

    if gs == "menu" then
        ui.drawMenu()

    elseif gs == "levelselect" then
        levelselect.draw()

    elseif gs == "metashop" then
        metashop.draw()

    elseif gs == "playing" or gs == "levelup" then
        map.drawZones()
        map.drawGrid(ui.buildMode.active)
        map.drawGate()
        facility.draw()
        unit.draw()
        ui.drawBuildCursor()
        ui.drawToolbar()
        ui.drawHUD()

        if gs == "levelup" then
            ui.drawLevelUpOverlay()
        end

    elseif gs == "runover" then
        map.drawZones()
        map.drawGate()
        facility.draw()
        unit.draw()
        ui.drawToolbar()
        ui.drawHUD()
        ui.drawRunOverOverlay()

    elseif gs == "gameover" then
        -- Legacy fallback — should not be reached in normal flow
        map.drawZones()
        map.drawGate()
        ui.drawGameOverOverlay()
    end

    love.graphics.pop()
end

function love.mousepressed(x, y, button)
    input.handleMouse(x, y, button)
end

function love.keypressed(key)
    input.handleKey(key)
end

return main
