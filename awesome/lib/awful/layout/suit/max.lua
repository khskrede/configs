---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008 Julien Danjou
-- @release v3.4.11
---------------------------------------------------------------------------

-- Grab environment we need
local pairs = pairs
local client = require("awful.client")

--- Maximized and fullscreen layouts module for awful
module("awful.layout.suit.max")

local function fmax(p, fs)
    -- Fullscreen?
    local area
    if fs then
        area = p.geometry
    else
        area = p.workarea
    end

    for k, c in pairs(p.clients) do
        c:geometry(area)
    end
end

--- Maximized layout.
-- @param screen The screen to arrange.
name = "max"
function arrange(p)
    return fmax(p, false)
end

--- Fullscreen layout.
-- @param screen The screen to arrange.
fullscreen = {}
fullscreen.name = "fullscreen"
function fullscreen.arrange(p)
    return fmax(p, true)
end
