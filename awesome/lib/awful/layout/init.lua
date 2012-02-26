---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008 Julien Danjou
-- @release v3.4.11
---------------------------------------------------------------------------

-- Grab environment we need
local ipairs = ipairs
local type = type
local capi = { screen = screen, client = client }
local tag = require("awful.tag")
local util = require("awful.util")
local suit = require("awful.layout.suit")
local ascreen = require("awful.screen")
local capi = {
    screen = screen,
    awesome = awesome,
    client = client
}
local client = require("awful.client")

--- Layout module for awful
module("awful.layout")

-- This is a special lock used by the arrange function.
-- This avoids recurring call by emitted signals.
local arrange_lock = false

--- Get the current layout.
-- @param screen The screen number.
-- @return The layout function.
function get(screen)
    local t = tag.selected(screen)
    return tag.getproperty(t, "layout") or suit.floating
end

--- Change the layout of the current tag.
-- @param layouts A table of layouts.
-- @param i Relative index.
function inc(layouts, i)
    local t = tag.selected()
    if t then
        local curlayout = get()
        local curindex
        local rev_layouts = {}
        for k, v in ipairs(layouts) do
            if v == curlayout then
                curindex = k
                break
            end
        end
        if curindex then
            local newindex = util.cycle(#layouts, curindex + i)
            set(layouts[newindex])
        end
    end
end

--- Set the layout function of the current tag.
-- @param layout Layout name.
function set(layout, t)
    t = t or tag.selected()
    tag.setproperty(t, "layout", layout)
end

--- Arrange a screen using its current layout.
-- @param screen The screen to arrange.
function arrange(screen)
    if arrange_lock then return end
    arrange_lock = true
    local p = {}
    p.workarea = capi.screen[screen].workarea
    -- Handle padding
    local padding = ascreen.padding(capi.screen[screen])
    if padding then
        p.workarea.x = p.workarea.x + (padding.left or 0)
        p.workarea.y = p.workarea.y + (padding.top or 0)
        p.workarea.width = p.workarea.width - ((padding.left or 0 ) + (padding.right or 0))
        p.workarea.height = p.workarea.height - ((padding.top or 0) + (padding.bottom or 0))
    end
    p.geometry = capi.screen[screen].geometry
    p.clients = client.tiled(screen)
    p.screen = screen
    get(screen).arrange(p)
    capi.screen[screen]:emit_signal("arrange")
    arrange_lock = false
end

--- Get the current layout name.
-- @param layout The layout.
-- @return The layout name.
function getname(layout)
    local layout = layout or get()
    return layout.name
end

local function arrange_prop(obj) arrange(obj.screen) end

capi.client.add_signal("new", function(c)
    c:add_signal("property::size_hints_honor", arrange_prop)
    c:add_signal("property::struts", arrange_prop)
    c:add_signal("property::minimized", arrange_prop)
    c:add_signal("property::sticky", arrange_prop)
    c:add_signal("property::fullscreen", arrange_prop)
    c:add_signal("property::maximized_horizontal", arrange_prop)
    c:add_signal("property::maximized_vertical", arrange_prop)
    c:add_signal("property::border_width", arrange_prop)
    c:add_signal("property::hidden", arrange_prop)
    c:add_signal("property::titlebar", arrange_prop)
    c:add_signal("property::floating", arrange_prop)
    c:add_signal("property::geometry", arrange_prop)
    -- If prop is screen, we do not know what was the previous screen, so
    -- let's arrange all screens :-(
    c:add_signal("property::screen", function(c)
        for screen = 1, capi.screen.count() do arrange(screen) end end)
end)

local function arrange_on_tagged(c, tag)
    if not tag.screen then return end
    arrange(tag.screen)
    if not capi.client.focus or not capi.client.focus:isvisible() then
        local c = client.focus.history.get(tag.screen, 0)
        if c then capi.client.focus = c end
    end
end

for s = 1, capi.screen.count() do
    tag.attached_add_signal(s, "property::mwfact", arrange_prop)
    tag.attached_add_signal(s, "property::nmaster", arrange_prop)
    tag.attached_add_signal(s, "property::ncol", arrange_prop)
    tag.attached_add_signal(s, "property::layout", arrange_prop)
    tag.attached_add_signal(s, "property::windowfact", arrange_prop)
    tag.attached_add_signal(s, "property::selected", arrange_prop)
    tag.attached_add_signal(s, "tagged", arrange_prop)
    capi.screen[s]:add_signal("property::workarea", function(screen)
        arrange(screen.index)
    end)
    capi.screen[s]:add_signal("tag::attach", function (screen, tag)
        arrange(screen.index)
    end)
    capi.screen[s]:add_signal("tag::detach", function (screen, tag)
        arrange(screen.index)
    end)
    capi.screen[s]:add_signal("padding", function (screen)
        arrange(screen.index)
    end)
end

capi.client.add_signal("focus", function(c) arrange(c.screen) end)
capi.client.add_signal("list", function()
                                   for screen = 1, capi.screen.count() do
                                       arrange(screen)
                                   end
                               end)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
