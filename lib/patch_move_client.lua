-- Patch for several functions to change screen to make them recompute the maximized and fullscreen values
-- List of patched functons:
--   * awful.client.movetoscreen
--   * awful.client.movetotag
--   * tyrannical.focus_client
-- Load this patch after loading awful and tyrannical in your configuration file
local awful     = require("awful")

local capi      = {
   client = client
}

local orig_movetotag    = awful.client.movetotag
local orig_movetoscreen = awful.client.movetoscreen
local orig_focus_client = tyrannical.focus_client

local function reload_max (c)
    if c.maximized then
        c.maximized = false
        c.maximized = true
    else
        if c.maximized_horizontal then
            c.maximized_horizontal = false
            c.maximized_horizontal = true
        end
        if c.maximized_vertical then
            c.maximized_vertical = false
            c.maximized_vertical = true
        end
    end
    if c.fullscreen then
        c.fullscreen = false
        c.fullscreen = true
    end
end

-- Replacement for awful.client.movetotag
local function movetotag(target, c)
    local sel = c or capi.client.focus
    local s = awful.tag.getscreen(target)

    if s == sel.screen then
        orig_movetotag(target, c)
    else
        orig_movetotag(target, sel)
        reload_max(sel)
    end
end

-- Replacement for awful.client.movetoscreen
local function movetoscreen(c, s)
    local sel = c or capi.client.focus
    orig_movetoscreen(sel, s)
    reload_max(sel)
end

-- Replacement for tyrannical.focus_client
function focus_client(c,properties)
    local success = orig_focus_client(c, properties)
    if success then
        reload_max(c)
    end
    return success
end

-- Monkey patch
awful.client.movetotag    = movetotag
awful.client.movetoscreen = movetoscreen
tyrannical.focus_client = focus_client
