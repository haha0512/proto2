-- Asset registry.  Placeholder shapes now; swap in sprites later by dropping
-- a PNG at assets/sprites/<key>.png — no code changes needed.
local C = require("src.constants")

local assets = {}
local descs  = {}

assets.fonts = {}

function assets.load()
    descs = {
        -- Ally units (tier 1)
        ally_farmer  = { shape = "circle", r = 9,  color = C.COL.ally_farmer  },
        ally_mage    = { shape = "circle", r = 8,  color = C.COL.ally_mage    },
        ally_soldier = { shape = "circle", r = 10, color = C.COL.ally_soldier },
        -- Ally units (tier 2 — larger + darker)
        ally_farmer2  = { shape = "circle", r = 13, color = C.COL.ally_farmer2  },
        ally_mage2    = { shape = "circle", r = 12, color = C.COL.ally_mage2    },
        ally_soldier2 = { shape = "circle", r = 14, color = C.COL.ally_soldier2 },
        -- Enemy units
        enemy_plant  = { shape = "circle", r = 13, color = C.COL.enemy_plant  },
        enemy_ghost  = { shape = "circle", r = 11, color = C.COL.enemy_ghost  },
        enemy_alien  = { shape = "circle", r = 10, color = C.COL.enemy_alien  },
        -- Facilities (54×26 — leaves room for label above and info below in the cell)
        farmstead    = { shape = "rect", w = 54, h = 26, color = C.COL.farmstead    },
        arcane_tower = { shape = "rect", w = 54, h = 26, color = C.COL.arcane_tower },
        barracks     = { shape = "rect", w = 54, h = 26, color = C.COL.barracks     },
        -- Facilities (tier 2 — darker)
        farmstead2    = { shape = "rect", w = 54, h = 26, color = C.COL.farmstead2    },
        arcane_tower2 = { shape = "rect", w = 54, h = 26, color = C.COL.arcane_tower2 },
        barracks2     = { shape = "rect", w = 54, h = 26, color = C.COL.barracks2     },
        generator    = { shape = "rect", w = 50, h = 48, color = C.COL.generator    },
    }
    for key, d in pairs(descs) do
        local ok, img = pcall(love.graphics.newImage, "assets/sprites/" .. key .. ".png")
        if ok then d.image = img end
    end
    assets.fonts.tiny   = love.graphics.newFont(9)
    assets.fonts.small  = love.graphics.newFont(12)
    assets.fonts.medium = love.graphics.newFont(15)
    assets.fonts.large  = love.graphics.newFont(22)
    assets.fonts.title  = love.graphics.newFont(38)
end

function assets.draw(key, x, y, alpha)
    local d = descs[key]
    if not d then return end
    alpha = alpha or 1
    if d.image then
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(d.image, x - d.image:getWidth() / 2, y - d.image:getHeight() / 2)
    elseif d.shape == "circle" then
        love.graphics.setColor(d.color[1], d.color[2], d.color[3], alpha)
        love.graphics.circle("fill", x, y, d.r)
        love.graphics.setColor(0, 0, 0, 0.4 * alpha)
        love.graphics.circle("line", x, y, d.r)
    elseif d.shape == "rect" then
        love.graphics.setColor(d.color[1], d.color[2], d.color[3], alpha)
        love.graphics.rectangle("fill", x - d.w / 2, y - d.h / 2, d.w, d.h)
        love.graphics.setColor(0, 0, 0, 0.4 * alpha)
        love.graphics.rectangle("line", x - d.w / 2, y - d.h / 2, d.w, d.h)
    end
end

function assets.getDesc(key)
    return descs[key]
end

return assets
