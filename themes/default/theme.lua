---------------------------
-- Default awesome theme --
---------------------------
local util = require('awful.util')

function script_path()
    local debug = require("debug")
    --local str = debug.getinfo(2, "S").source:sub(2)
    local str = debug.getinfo(1).source:match("@(.*)$")
    return str:match("(.*/)")
end

local dark_grey         = "#121212"
local grey              = "#444444ff"
local light_grey        = "#555555"
local white             = "#ffffff"
local light_white       = "#999999"
local light_black       = "#232323"
local red               = "#b9214f"
local bright_red        = "#ff5c8d"
local yellow            = "#ff9800"
local bright_yellow     = "#ffff00"
local black             = "#000000"
local bright_black      = "#5D5D5D"
local green             = "#A6E22E"
local bright_green      = "#CDEE69"
local blue              = "#3399ff"
local bright_blue       = "#9CD9F0"
local magenta           = "#8e33ff"
local bright_magenta    = "#FBB1F9"
local cyan              = "#06a2dc"
local bright_cyan       = "#77DFD8"
local widget_background = "#303030"
--local white = "#B0B0B0"
local bright_white      = "#F7F7F7"
local transparent       = "#00000000"

----------
local theme = {}

--theme.dir           = os.getenv("HOME") .. "/.config/awesome/themes/default"
theme.dir           = script_path()
theme.font          = "Droid sans 8"

theme.bg_normal     = light_black 
theme.bg_focus      = red
theme.bg_urgent     = bright_red
theme.bg_minimize   = light_black
theme.bg_systray    = theme.bg_normal 

theme.fg_normal     = light_white
theme.fg_focus      = white
theme.fg_urgent     = black
theme.fg_minimize   = blue

theme.useless_gap   = 0
theme.border_width  = 0 
theme.border_normal = light_black
theme.border_focus  = light_white
theme.border_marked = theme.bg_normal


-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- taglist_[bg|fg]_[focus|urgent|occupied|empty]
-- tasklist_[bg|fg]_[focus|urgent]
-- titlebar_[bg|fg]_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- mouse_finder_[color|timeout|animate_timeout|radius|factor]
-- Example:
--theme.taglist_bg_focus = "#ff0000"
theme.tasklist_bg_focus    = light_grey
theme.tasklist_fg_focus    = yellow 
theme.tasklist_bg_minimize = bright_blue
theme.tasklist_fg_minimize = black
theme.titlebar_bg_normal   = light_black
theme.titlebar_bg_focus    = light_black 

-- Display the taglist squares
--theme.taglist_squares_sel   = theme.dir.."/taglist/bar_sel.png"
--theme.taglist_squares_unsel = theme.dir.."/taglist/bar_unsel.png"
theme.taglist_squares_sel   = theme.dir.."/taglist/squarefw.png"
theme.taglist_squares_unsel = theme.dir.."/taglist/squarew.png"

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_submenu_icon = theme.dir.."/menu/submenu_grey.png"
theme.menu_border_width = 3
theme.menu_border_color = theme.bg_normal
theme.menu_height = 15
theme.menu_width  = 100
theme.menu_awesome = theme.dir.."/menu/awesome.png"
theme.menu_apps = theme.dir.."/menu/apps.png"
theme.menu_info = theme.dir.."/menu/info.png"
theme.menu_terminal = theme.dir.."/menu/terminal.png"
theme.menu_reboot = theme.dir.."/menu/reboot.png"
theme.menu_shutdown = theme.dir.."/menu/shutdown.png"
theme.menu_logout = theme.dir.."/menu/logout.png"
theme.menu_accept = theme.dir.."/menu/accept.png"
theme.menu_cancel = theme.dir.."/menu/cancel.png"
theme.menu_lock = theme.dir.."/menu/lock.png"

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.bg_widget = "#cc0000"

-- Define the image to load
theme.titlebar_close_button_normal = theme.dir.."/titlebar/close_normal.png"
theme.titlebar_close_button_focus  = theme.dir.."/titlebar/close_focus.png"

theme.titlebar_minimize_button_normal = theme.dir.."/titlebar/minimize_normal.png"
theme.titlebar_minimize_button_focus  = theme.dir.."/titlebar/minimize_focus.png"

theme.titlebar_ontop_button_normal_inactive = theme.dir.."/titlebar/ontop_normal_inactive.png"
theme.titlebar_ontop_button_focus_inactive  = theme.dir.."/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_active = theme.dir.."/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_active  = theme.dir.."/titlebar/ontop_focus_active.png"

theme.titlebar_sticky_button_normal_inactive = theme.dir.."/titlebar/sticky_normal_inactive.png"
theme.titlebar_sticky_button_focus_inactive  = theme.dir.."/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_active = theme.dir.."/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_active  = theme.dir.."/titlebar/sticky_focus_active.png"

theme.titlebar_floating_button_normal_inactive = theme.dir.."/titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive  = theme.dir.."/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active = theme.dir.."/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active  = theme.dir.."/titlebar/floating_focus_active.png"

theme.titlebar_maximized_button_normal_inactive = theme.dir.."/titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive  = theme.dir.."/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active = theme.dir.."/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active  = theme.dir.."/titlebar/maximized_focus_active.png"

theme.wallpaper = theme.dir.."/background.png"

-- You can use your own layout icons like this:
theme.layout_fairh = theme.dir.."/layouts/fairhw.png"
theme.layout_fairv = theme.dir.."/layouts/fairvw.png"
theme.layout_floating  = theme.dir.."/layouts/floatingw.png"
theme.layout_magnifier = theme.dir.."/layouts/magnifierw.png"
theme.layout_max = theme.dir.."/layouts/maxw.png"
theme.layout_fullscreen = theme.dir.."/layouts/fullscreenw.png"
theme.layout_tilebottom = theme.dir.."/layouts/tilebottomw.png"
theme.layout_tileleft   = theme.dir.."/layouts/tileleftw.png"
theme.layout_tile = theme.dir.."/layouts/tilew.png"
theme.layout_tiletop = theme.dir.."/layouts/tiletopw.png"
theme.layout_spiral  = theme.dir.."/layouts/spiralw.png"
theme.layout_dwindle = theme.dir.."/layouts/dwindlew.png"
theme.layout_cornernw = theme.dir.."/layouts/cornernww.png"
theme.layout_cornerne = theme.dir.."/layouts/cornernew.png"
theme.layout_cornersw = theme.dir.."/layouts/cornersww.png"
theme.layout_cornerse = theme.dir.."/layouts/cornersew.png"

theme.awesome_icon = theme.dir.."/menu/awesome.png"

-- Define the icon theme for application icons. If not set then the icons
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
theme.icon_theme = nil

-- Calendar widget
local cell_style = {
    h_margin = 0, 
    v_margin = 0, 
    rounded_size = 0.3, 
    background_color = widget_background, 
    text_background_color = transparent,
    text_color = white, 
}

theme.calendar_style = calendar_style
theme.calendar_days_of_week_text_color       = light_grey
theme.calendar_weeks_number_text_color       = light_grey
theme.calendar_corner_widget_text_color      = light_grey

theme.calendar_current_day_background_color  = green
theme.calendar_current_day_text_color        = dark_grey
theme.calendar_current_day_rounded_size      = {0.5,0,0.5,0}

theme.calendar_focus_widget_background_color = yellow
theme.calendar_focus_widget_rounded_size     = {0,0.5,0,0.5}
theme.calendar_info_cell_background_color    = transparent
theme.calendar_info_cell_text_color          = bright_white


return theme

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
