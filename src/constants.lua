local C = {}

C.SCREEN_W  = 400
C.SCREEN_H  = 700
C.WINDOW_W  = 800
C.SIDE_W    = (C.WINDOW_W - C.SCREEN_W) / 2   -- 200px wall on each side

-- Zone layout (top-to-bottom)
C.SPAWN_H   = math.floor(C.SCREEN_H * 0.20)         -- 140px  (y 0..140)
C.COMBAT_Y  = C.SPAWN_H                               -- 140
C.COMBAT_H  = math.floor(C.SCREEN_H * 0.45)         -- 315px  (y 140..455)
C.BASE_Y    = C.SPAWN_H + C.COMBAT_H                 -- 455    (y 455..700)
C.BASE_H    = C.SCREEN_H - C.BASE_Y                  -- 245

C.GATE_Y       = C.BASE_Y                             -- gate sits at top of base zone
C.ALLY_LIMIT_Y = math.floor(C.SCREEN_H * 0.20)       -- 140  hard wall: allies cannot cross

-- Bottom toolbar
C.TOOLBAR_H    = 72
C.TOOLBAR_Y    = C.SCREEN_H - C.TOOLBAR_H            -- 628

-- Build grid (area above toolbar, inside base zone)
C.BUILD_AREA_Y = C.BASE_Y                             -- 455
C.BUILD_AREA_H = C.TOOLBAR_Y - C.BASE_Y              -- 173
C.GRID_COLS    = 5
C.GRID_ROWS    = 3
C.CELL_W       = C.SCREEN_W / C.GRID_COLS            -- 80
C.CELL_H       = C.BUILD_AREA_H / C.GRID_ROWS        -- ~57.7

C.MAX_FACILITIES = 6
C.START_MONEY    = 175
C.GATE_MAX_HP    = 3000

-- Colors
C.COL = {
    zone_spawn    = {0.22, 0.04, 0.04},
    zone_combat   = {0.09, 0.09, 0.12},
    zone_base     = {0.04, 0.09, 0.22},
    gate_hp_bg    = {0.22, 0.12, 0.02},
    gate_hp_fg    = {0.92, 0.76, 0.10},
    barracks      = {0.22, 0.68, 0.28},
    generator     = {0.82, 0.56, 0.10},
    ally          = {0.22, 0.55, 1.00},
    enemy         = {1.00, 0.20, 0.20},
    -- Per-class ally colors
    ally_farmer   = {0.72, 0.52, 0.25},
    ally_mage     = {0.62, 0.25, 0.85},
    ally_soldier  = {0.22, 0.55, 1.00},
    -- Per-class enemy colors
    enemy_plant   = {0.15, 0.75, 0.10},   -- vivid green
    enemy_ghost   = {0.85, 0.85, 1.00},   -- pale blue-white
    enemy_alien   = {0.90, 0.45, 0.05},   -- bright orange
    -- Facility colors
    farmstead     = {0.60, 0.40, 0.15},
    arcane_tower  = {0.50, 0.20, 0.70},
    hp_bg         = {0.15, 0.05, 0.05},
    hp_ally       = {0.15, 0.85, 0.15},
    hp_enemy      = {0.90, 0.15, 0.15},
    exp_bg        = {0.08, 0.18, 0.08},
    exp_fg        = {0.35, 0.90, 0.35},
    money         = {1.00, 0.85, 0.10},
    ui_text       = {0.95, 0.95, 0.95},
    ui_bg         = {0.07, 0.07, 0.11},
    card_bg       = {0.14, 0.14, 0.21},
    card_hover    = {0.22, 0.22, 0.34},
    card_disabled = {0.08, 0.08, 0.10},
    card_text_dim = {0.44, 0.44, 0.44},
    toolbar_bg    = {0.05, 0.05, 0.09},
    btn_normal    = {0.14, 0.14, 0.22},
    btn_selected  = {0.22, 0.45, 0.22},
    btn_disabled  = {0.10, 0.10, 0.12},
    sep           = {0.38, 0.38, 0.48},
    grid_line     = {0.38, 0.38, 0.62},
    cursor_ok     = {0.80, 0.80, 0.30},
    cursor_bad    = {0.90, 0.20, 0.20},
    ally_limit    = {0.28, 0.28, 0.88},
    white         = {1, 1, 1},
    black         = {0, 0, 0},
    dim           = {0, 0, 0},
    shard         = {0.20, 0.80, 0.85},
}

return C
