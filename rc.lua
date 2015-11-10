-- default rc.lua
--
-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
-- Applications menu
local menubar = require("menubar")
local xdg_menu = require("archmenu")
-- Dynamic tagging library
--local shifty = require("awesome-shifty")
local tyrannical = require("tyrannical")
local tagctl     = require("lib/tagctl")
-- apw - pulseaudio integration
local APW = require("apw/widget")
-- Other widgets and layout library
local vicious = require("vicious")
local blingbling = require("blingbling")
local lain = require("lain")
-- Documentation for keybinding
local keydoc = require("lib/keydoc")
-- Xrandr
local xrandr = require("lib/xrandr")
-- Give information for clients and load modules
local dbg = require("lib/debug")
-- Run programs once
local ro = require("lib/run_once")
-- Shutdown widget
local shutdown = require("lib/shutdown")


-- {{{ Error handling
require("lib/errors")
-- }}}


-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
local home_dir = os.getenv("HOME")
local config_dir = awful.util.getdir("config")
local themes_dir = config_dir .. "/themes"
local theme_dir = themes_dir .. "/default"
beautiful.init(theme_dir .. "/theme.lua")


-- This is used later as the default terminal and editor to run.
terminal = "terminator"
browser = "firefox"
mail = "thunderbird"
system_monitor = "gnome-system-monitor"
editor = os.getenv("EDITOR") or "nano"
visual_editor = "geany"
file_manager = "thunar"
editor_cmd = terminal .. " -e " .. editor

-- Bug for multiple screen, to set separate screens instead of duplicates (clones)
-- Curiously, this does not work perfectly when awesome is started but it is perfect when restarted
-- a better solution is to modify xorg.conf
--awful.util.spawn("xrandr --output eDP1 --auto --primary --output DP1 --auto --left-of eDP1 --output HDMI2 --off --output HDMI1 --off --output DP2 --off --output VIRTUAL1 --off", false)
--awful.screen.focus(screen["eDP1"].index)


-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"
altkey = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    --awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- First, set some settings
tyrannical.settings.default_layout =  awful.layout.suit.max
tyrannical.settings.mwfact = 0.66

-- Setup some tags
tyrannical.tags = {
    {
        name        = "term",                 -- Call the tag "Term"
        init        = true,                   -- Load the tag on startup
        exclusive   = true,                   -- Refuse any other type of clients (by classes)
        screen      = {1,2},                  -- Create this tag on screen 1 and 2
        layout      = awful.layout.suit.tile, -- Use the tile layout
        --exec_once   = {terminal},            -- When the tag is accessed for the first time, execute this command
        selected    = true,
        class       = { --Accept the following classes, refuse everything else (because of "exclusive=true")
            "xterm" , "urxvt" , "aterm","URxvt","XTerm","konsole","terminator","gnome-terminal"
        }
    } ,
    {
        name        = "web",
        init        = false,
        exclusive   = true,
        screen      = 1,                  -- Create this tag on screen 1
      --icon        = "~net.png",                 -- Use this icon for the tag (uncomment with a real path)
        --exec_once   = browser,
        layout      = awful.layout.suit.max,      -- Use the max layout
        class = {
            "Opera"         , "Firefox"        , "Rekonq"    , "Dillo"        , "Arora",
            "Chromium"      , "nightly"        , "minefield" , "Midori"    }
    } ,
    {
        name        = "mail",
        init        = false,
        exclusive   = true,
        screen      = 1,                  -- Create this tag on screen 1
        --exec_once   = mail,
        layout      = awful.layout.suit.max,      -- Use the max layout
        class = {
            "Thunderbird", "davmail"}
    } ,
    {
        name        = "files",
        init        = false,
        exclusive   = true,
        screen      = {1, 2},
        layout      = awful.layout.suit.max,
        --exec_once   = {file_manager}, --When the tag is accessed for the first time, execute this command
        class  = {
            "Thunar", "Konqueror", "Dolphin", "ark", "Nautilus","emelfm", "Spacefm"
        }
    } ,
    {
        name        = "edit",
        init        = false,
        exclusive   = true,
        screen      = screen.count()>1 and 2 or 1,-- Setup on screen 2 if there is more than 1 screen, else on screen 1
        --force_screen = true,
        layout      = awful.layout.suit.max                          ,
        class ={ 
            "Kate", "KDevelop", "Codeblocks", "Code::Blocks" , "DDD", "kate4", "geany"}
    } ,
    {
        name        = "libreoffice",
        init        = false, -- This tag wont be created at startup, but will be when one of the
                             -- client in the "class" section will start. It will be created on
                             -- the client startup screen
        exclusive   = true,
        screen      = screen.count()>1 and 2 or 1,-- Setup on screen 2 if there is more than 1 screen, else on screen 1
        --force_screen = true,
        --clone_on    = 1, -- Create a single instance of this tag on screen 1, but also show it on screen 2
                         ---- The tag can be used on both screen, but only one at once
        no_focus_stealing_out = true,
        layout      = awful.layout.suit.max,
        class       = { "libreoffice" }   
    } ,
    {
        name        = "presentation",
        init        = false, -- This tag wont be created at startup, but will be when one of the
                             -- client in the "class" section will start. It will be created on
                             -- the client startup screen
        screen      = 2,     -- Setup on screen 2 if there is more than 1 screen, else on screen 1
        force_screen = true,
        selected    = true,
        volatile    = true,
        no_focus_stealing_out = true,
        layout      = awful.layout.suit.max,
        class       = {
            "libreoffice-fullscreen"}
    } ,
    {
        name        = "doc",
        init        = false, 
        no_focus_stealing_out = true,
        layout      = awful.layout.suit.max,
        class       = {
            "Assistant"     , "Okular"         , "Evince"    , "EPDFviewer"   , "xpdf",
            "Xpdf"          , "Mupdf"             }
    } ,
    {
        name        = "mpl",
        init        = false, 
        exclusive   = false,
        screen      = screen.count()>1 and 2 or 1,-- Setup on screen 2 if there is more than 1 screen, else on screen 1
        force_screen = true,
        no_focus_stealing_in = true,
        class       = { "mpl"  }
    } ,
    --{
        --name        = "conky",
        --hide        = true,
        --class       = { "conky" }
    --} ,
}

-- Ignore the tag "exclusive" property for the following clients (matched by classes)
tyrannical.properties.intrusive = {
    "synapse"       , "albert"         ,
    "ksnapshot"     , "pinentry"       , "gtksu"     , "kcalc"        , "xcalc"               ,
    "feh"           , "Gradient editor", "About KDE" , "Paste Special", "Background color"    ,
    "kcolorchooser" , "plasmoidviewer" , "Xephyr"    , "kruler"       , "plasmaengineexplorer",  "Conky",
}

-- Ignore the tiled layout for the matching clients
tyrannical.properties.floating = {
    "MPlayer"      , "pinentry"        , "ksnapshot"  , "pinentry"     , "gtksu"          ,
    "xine"         , "feh"             , "kmix"       , "kcalc"        , "xcalc"          ,
    "yakuake"      , "Select Color$"   , "kruler"     , "kcolorchooser", "Paste Special"  ,
    "New Form"     , "Insert Picture"  , "kcharselect", "mythfrontend" , "plasmoidviewer" ,
    "Conky"        , 
}

-- Make the matching clients (by classes) on top of the default layout
tyrannical.properties.ontop = {
    "synapse"      , "albert"       , "Xephyr"       , "ksnapshot"    , "kruler"       , "libreoffice-fullscreen"
}

-- Make the matching clients (by classes) fullscreen
tyrannical.properties.fullscreen = {
    "libreoffice-fullscreen"
}

-- Force the matching clients (by classes) to be centered on the screen on init
tyrannical.properties.centered = {
    "kcalc", "libreoffice-fullscreen"
}

-- Allow focus on the matching clients (by classes)
tyrannical.properties.focusable = {
    "Kate",     "KDevelop",     "Codeblocks",   "Code::Blocks" ,    "DDD",  "kate4",    "geany",
    "skype",    "deadbeef"
}
tyrannical.properties.sticky = {
    "conky",
}
-- Do not honor size hints request for those classes
tyrannical.properties.size_hints_honor = { xterm = false, URxvt = false, aterm = false, sauer_client = false, mythfrontend  = false}

--tyrannical.settings.block_children_focus_stealing = true --Block popups ()
--tyrannical.settings.group_children = true --Force popups/dialogs to have the same tags as the parent client


-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "logout", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome"         , myawesomemenu     , beautiful.menu_awesome },
                                    { "applications"    , xdgmenu           , beautiful.menu_apps },
                                    { "show keys"       , keydoc.display    , beautiful.menu_info },
                                    { "open terminal"   , terminal          , beautiful.menu_terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.menu_awesome,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Logout Menu
logoutmenu = blingbling.system.mainmenu(beautiful.menu_shutdown, 
                beautiful.menu_shutdown,
                beautiful.menu_reboot,
                beautiful.menu_logout,
                beautiful.menu_lock) 
-- }}}

-- {{{ Wibox
spacer = wibox.widget.textbox()
separator = wibox.widget.textbox()
spacer:set_text(" ")
separator:set_text(" | ")


-- RAM usage widget
memwidget = awful.widget.progressbar()
memwidget:set_width(15)
memwidget:set_height(30)
memwidget:set_vertical(true)
memwidget:set_background_color('#494B4F')
memwidget:set_color('#AECF96')
--memwidget:set_gradient_colors({ '#AECF96', '#88A175', '#FF5656' })
memwidget:set_color({ type = "linear", from = { 0, 0 }, to = { 0, 20 }, stops = { { 0, "#AECF96" }, { 0.5, "#88A175" }, { 1, "#FF5656" } }})

-- RAM usage tooltip
memwidget_t = awful.tooltip({ objects = { memwidget },})

vicious.cache(vicious.widgets.mem)
vicious.register(memwidget, vicious.widgets.mem, 
                function (widget, args)
                    memwidget_t:set_text(" RAM: " .. args[2] .. "MB / " .. args[3] .. "MB ")
                    return args[1]
                 end, 13)

-- CPU usage widget
cpuwidget = awful.widget.graph()
cpuwidget:set_width(50)
cpuwidget:set_height(30)
cpuwidget:set_background_color("#494B4F")
cpuwidget:set_color("#FF5656")
--cpuwidget:set_gradient_colors({ "#FF5656", "#88A175", "#AECF96" })
cpuwidget:set_color({ type = "linear", from = { 0, 0 }, to = { 0, 20 }, stops = { { 0, "#FF5656" }, { 0.5, "#88A175" }, { 1, "#AECF96" } }})
function cpuwidget.LaunchSytemMonitor()
	awful.util.spawn_with_shell( system_monitor )
end
cpuwidget:buttons(awful.util.table.join(
		awful.button({ }, 1, cpuwidget.LaunchSytemMonitor)
	)
)

cpuwidget_t = awful.tooltip({ objects = { cpuwidget },})

-- Register CPU widget
vicious.register(cpuwidget, vicious.widgets.cpu, 
                    function (widget, args)
                        cpuwidget_t:set_text("CPU Usage: " .. args[1] .. "%")
                        return args[1]
                    end)


-- {{{ Clock widget

markup      = lain.util.markup
-- Textclock
clockicon = wibox.widget.imagebox(beautiful.widget_clock)
laintextclock = awful.widget.textclock(markup("#de5e1e", "%A %d %B ") .. markup("#343639", ">") .. markup("#7788af", " %H:%M "))

-- Calendar
--lain.widgets.calendar:attach(laintextclock, { font_size = 10 })
calendar = blingbling.calendar({ widget = laintextclock})
calendar:set_prev_next_widget_style(beautiful.blingbling.calendar.prev_next_widget_style)
calendar:set_current_date_widget_style(beautiful.blingbling.calendar.current_date_widget_style)
calendar:set_days_of_week_widget_style(beautiful.blingbling.calendar.days_of_week_widget_style)
calendar:set_days_of_month_widget_style(beautiful.blingbling.calendar.days_of_month_widget_style)
calendar:set_weeks_number_widget_style(beautiful.blingbling.calendar.weeks_number_widget_style)
calendar:set_corner_widget_style(beautiful.blingbling.calendar.corner_widget_style)
calendar:set_current_day_widget_style(beautiful.blingbling.calendar.current_day_widget_style)
calendar:set_focus_widget_style(beautiful.blingbling.calendar.focus_widget_style)
calendar:set_info_cell_style(beautiful.blingbling.calendar.info_cell_style)
-- }}}

-- Update APW widget periodically, in case the volume is changed from somewhere else. 
APWTimer = timer({ timeout = 0.5 }) -- set update interval in s
APWTimer:connect_signal("timeout", APW.Update)
APWTimer:start()

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
        awful.button({ }, 1, awful.tag.viewonly),
        awful.button({ modkey }, 1, awful.client.movetotag),
        awful.button({ }, 3, awful.tag.viewtoggle),
        awful.button({ modkey }, 3, awful.client.toggletag),
        awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
        awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
        )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
        awful.button({ }, 1, 
                function (c)
                    if c == client.focus then
                        c.minimized = true
                    else
                        -- Without this, the following
                        -- :isvisible() makes no sense
                        c.minimized = false
                        if not c:isvisible() then
                            awful.tag.viewonly(c:tags()[1])
                        end
                        -- This will also un-minimize
                        -- the client, if needed
                        client.focus = c
                        c:raise()
                    end
                end),
        awful.button({ }, 3, 
                function ()
                    if instance then
                        instance:hide()
                        instance = nil
                    else
                        instance = awful.menu.clients({ width=250 })
                    end
                end),
        awful.button({ }, 4,
                function ()
                    awful.client.focus.byidx(1)
                    if client.focus then client.focus:raise() end
                end),
        awful.button({ }, 5,
                function ()
                    awful.client.focus.byidx(-1)
                    if client.focus then client.focus:raise() end
                end)
        )

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(separator)
    left_layout:add(mypromptbox[s])
    left_layout:add(separator)


    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(separator)
    right_layout:add(cpuwidget)
    right_layout:add(separator)
    right_layout:add(memwidget)
    right_layout:add(separator)
    right_layout:add(APW)
    right_layout:add(separator)
    right_layout:add(laintextclock)
    right_layout:add(separator)
    right_layout:add(mylayoutbox[s])
    right_layout:add(separator)
    right_layout:add(logoutmenu)

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- Set prompt and taglist for the tag control
tagctl.set_prompt(myprompbox)
tagctl.set_taglist(mytaglist)
tagctl.settings.prompt = myprompbox

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
-- Global keys
keydoc.settings.font = "DejaVu Sans Mono 8"

globalkeys = awful.util.table.join(
    -- Standard program
    keydoc.group("Awesome options"),
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end,  "Spawn terminal"),
    awful.key({ modkey, "Control" }, "r", awesome.restart,  "Awesome restart"   ),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,     "Awesome quit"      ),
    awful.key({ modkey, "Control" }, "q", shutdown.logout_dialog_menu,     "Shutdown window"      ),
    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end, "Prompt"),
    -- Lua prompt
    --awful.key({ modkey }, "l", dbg.lua_prompt(mypromptbox[mouse.screen]), "Lua prompt"),
    --awful.key({ modkey }, "x", 
            --function ()
                --awful.prompt.run({ prompt = "Run Lua code: " },
                    --mypromptbox[mouse.screen].widget,
                    --awful.util.eval, nil,
                    --awful.util.getdir("cache") .. "/history_eval")
            --end, "Lua prompt"),

    -- Menubar
    awful.key({ modkey }, "p", function () menubar.show() end         , "Show app menu"     ),
    awful.key({ modkey }, "w", function () mymainmenu:toggle() end    , "Show main menu"    ),


    -- Tag view
    keydoc.group("Tag manipulation"),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev  , "Previous tag"    ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext  , "Next tag"        ),
    awful.key({ modkey,           }, "z", awful.tag.history.restore, "Last opened tag" ),

    -- Tag control
    awful.key({ modkey, "Control" }, "d",      function () awful.tag.delete() end           , "Delete tag" ),
    awful.key({ modkey, "Control" }, "a",      function () tagctl.add(mypromptbox) end      , "Add tag"    ),
    awful.key({ modkey, "Control" }, "w",      function () tagctl.rename(mypromptbox) end   , "Rename tag" ),

    -- Layout manipulation
    keydoc.group("Layout manipulation"),
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,   "Swap with next window"     ),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,   "Swap with previous window" ),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,   "Jump to next screen"       ),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,   "Jump to previous screen"   ),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end, "Increase master factor"      ),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end, "Decrease master factor"      ),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end, "Increase number of masters"  ),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end, "Decrease number of masters"  ),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end, "Increase number of columns"  ),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end, "Decrease number of columns"  ),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end, "Next layout"        ),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end, "Previous layout"    ),

    --awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Client manipulation
    keydoc.group("Window manipulation"),
    -- Implement Alt-Tab
    awful.key({ altkey            }, "Tab",
            function ()
                awful.client.focus.byidx( 1)
                if client.focus then client.focus:raise() end
            end,
            "Next client"  ),
    awful.key({ altkey, "Shift"   }, "Tab",
            function ()
                awful.client.focus.byidx(-1)
                if client.focus then client.focus:raise() end
            end,
            "Previous client"  ),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        "Last opened client"
        ),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),

    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,   "Focus on urgent client"  ),
    
    -- Volume and display
    keydoc.group("Volume and display"),
	-- Fn keys with APW
    awful.key({ },          "XF86AudioRaiseVolume",    APW.Up  ),
    awful.key({ },          "XF86AudioLowerVolume",    APW.Down),
    awful.key({ },          "XF86AudioMute",           APW.ToggleMute),
		-- Mute/Unmute microphone (source index 2 in pulseaudio). See `man pactl`
	awful.key({ modkey },   "F8",                      function () awful.util.spawn("pactl set-source-mute 2 toggle") end, "Mute micro"),
		-- Brightness
    awful.key({ },          "XF86MonBrightnessDown",   function () awful.util.spawn("xbacklight -dec 15") end),
    awful.key({ },          "XF86MonBrightnessUp",     function () awful.util.spawn("xbacklight -inc 15") end),
    --awful.key({ },        "XF86Sleep", nil),
    --awful.key({ },        "XF86Display", nil),

    -- Display
    awful.key({ },          "XF86Display",             xrandr.change_display,  "Change display"),
    awful.key({"Control" }, "XF86Display",             xrandr.force_vga_output,  "Force VGA output"),

    -- bind PrintScrn to capture a screen
    awful.key({},           "Print",                   function () awful.util.spawn("scrot -e 'mv $f ~/screenshots/ 2>/dev/null'") end, "Print screen"),

    -- Show Conky when Pause is pressed and held
    --awful.key({},           "Scroll_Lock",                   raise_conky, lower_conky),

    
    keydoc.group("Programs"),
	-- Add keybinding to tag opening, attached to a program 
    awful.key({ altkey },  "b",      ro.raise_or_new_tag('web', browser, true),                "Browser" ),        -- open firefox 
    awful.key({ altkey },  "m",      ro.raise_or_new_tag('mail', mail, true),                  "Mail" ),           -- open thunderbird
    awful.key({ altkey },  "f",      ro.raise_or_new_tag('files', file_manager),               "Files" ),          -- open file manager
    awful.key({ altkey },  "e",      ro.raise_or_new_tag('edit', visual_edit, true),           "Editor" ),         -- open geany
    awful.key({ altkey },  "x",      ro.raise_or_new_tag('term', terminal),                    "Terminal" ),       -- go to terminal tag
	awful.key({ altkey },  "Escape", function () awful.util.spawn(system_monitor) end,         "System monitor" ), -- open system-monitor
    
    awful.key({ modkey, },  "F1",  keydoc.display),     -- display keybinding
	nil
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
            function ()
                local screen = mouse.screen
                local tag = awful.tag.gettags(screen)[i]
                if tag then
                    awful.tag.viewonly(tag)
                end
            end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
            function ()
                local screen = mouse.screen
                local tag = awful.tag.gettags(screen)[i]
                if tag then
                    awful.tag.viewtoggle(tag)
                end
            end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
            function ()
                if client.focus then
                    local tag = awful.tag.gettags(client.focus.screen)[i]
                    if tag then
                        awful.client.movetotag(tag)
                    end
                end
            end),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
            function ()
                if client.focus then
                    local tag = awful.tag.gettags(client.focus.screen)[i]
                    if tag then
                        awful.client.toggletag(tag)
                    end
                end
        end))
end

-- Client related keys
clientkeys = awful.util.table.join(
    keydoc.group("Client specific"),
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end   , "Fullscreen"),
    --awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ altkey,           }, "F4",     function (c) c:kill() end      , "Kill"),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle   , "Toggle floating"),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,  "Switch with master"),
    awful.key({ modkey,           }, "o",      function (c) awful.client.movetoscreen(c) tyrannical.match_client(c) end,  "Move to next screen"),
    awful.key({ modkey,           }, "F5",     function (c) awful.client.movetoscreen(c) tyrannical.match_client(c) c.fullscreen=true end,  "Move to next screen and fullscreen"),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop  end, "Raise window"),
    awful.key({ modkey, "Shift"   }, "t",      awful.titlebar.toggle, "Toggle titlebar"),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end,
        "Minimize"  ),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end,
        "Maximize"  ),
    awful.key({ modkey, }, "s", function (c) c.sticky = not c.sticky end,  "Stick window"),
    awful.key({ modkey, }, "i", dbg.client_info,  "Get client-related information"),
    nil
)

clientbuttons = awful.util.table.join(
    awful.button({ },           1,   function (c) mymainmenu:hide(); client.focus = c; c:raise() end),
    awful.button({ modkey },    1,   awful.mouse.client.move),
    awful.button({ modkey },    3,   awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- Handle LibreOffice fullscreen windows
local function get_libreoffice_fullscreen_name()
    local string = require("string")
    local name = awful.util.pread("libreoffice --version")
    name = string.match(name, "LibreOffice [0-9]*.[0-9]*")
    return name
end

local function create_titlebar(c)
    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(awful.titlebar.widget.iconwidget(c))

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(awful.titlebar.widget.floatingbutton(c))
    right_layout:add(awful.titlebar.widget.maximizedbutton(c))
    right_layout:add(awful.titlebar.widget.stickybutton(c))
    right_layout:add(awful.titlebar.widget.ontopbutton(c))
    right_layout:add(awful.titlebar.widget.closebutton(c))

    -- The title goes in the middle
    local title = awful.titlebar.widget.titlewidget(c)
    title:buttons(awful.util.table.join(
            awful.button({ }, 1, function()
                client.focus = c
                c:raise()
                awful.mouse.client.move(c)
            end),
            awful.button({ }, 3, function()
                client.focus = c
                c:raise()
                awful.mouse.client.resize(c)
            end)
            ))

    -- Now bring it all together
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_right(right_layout)
    layout:set_middle(title)

    awful.titlebar(c):set_widget(layout)
    
end

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    {   rule = { },
        callback = create_titlebar,
        properties = { border_width = beautiful.border_width,
                    border_color = beautiful.border_normal,
                    focus = awful.client.focus.filter,
                    keys = clientkeys,
                    buttons = clientbuttons }
    },
    -- Hide titlebar on some window types
    {   rule_any = { type = {"normal", "dialog", "utility", "splash", "desktop", "toolbar"} },
        callback = function(c) create_titlebar(c); awful.titlebar.hide(c) end
    },
    -- Tyrannical: match matplotlib figures using the `overwrite_class` feature
    {   rule = { class = "", name = "Figure %d"  },
        callback = function(c)
                awful.client.property.set(c, "overwrite_class", "mpl")
            end
    },
    -- Tyrannical: match libreoffice different windows
    {   rule_any = { class = { "openoffice",    "soffice", "Soffice", "LibreOffice",
                "libreoffice-writer",  "libreoffice-base",  "libreoffice-impress", "libreoffice-calc", "libreoffice-draw", "libreoffice-math", "libreoffice-startcenter"  }},
        callback = function(c)
                awful.client.property.set(c, "overwrite_class", "libreoffice")
            end
    },
    {   rule = { name = get_libreoffice_fullscreen_name(), class = "Soffice", type = "normal"},
    --{   rule = { name = "LibreOffice 4.4", class = "Soffice", type = "normal"},
        callback = function(c)
                awful.client.property.set(c, "overwrite_class", "libreoffice-fullscreen")
                c.fullscreen = true
                --naughty.notify({ text="Rename tag prologue" , screen = mouse.screen })
            end,
        properties = { 
            --fullscreen = true,  -- does not seem to work
            skip_taskbar = true,
            maximized = true,
            focusable = true}
    },
    nil  -- stopper
}
-- }}}

-- {{{ Signals
-- Patch change screen for fullscreen
local function client_reload_max(c)
    local c = c or client.focus
    if not c then return end
    if c.maximized then
        --naughty.notify({text="Maximized ! " .. c.name, screen=c.screen})
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
        --naughty.notify({text="Fullscreen ! " .. c.name, screen=c.screen})
        c.fullscreen = false
        c.fullscreen = true
    end
end


-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    -- Create titlebar
    --create_titlebar(c)
end)

-- Connect change screen signal to a resize function
client.connect_signal("property::screen", client_reload_max)

-- Connect urgent signal from client
--client.connect_signal("property::urgent", function(c)
    --local c = c or client.urgent
    --if not c then return end
    --naughty.notify({text="Urgent : " .. c.name, screen=c.screen})
    --c.urgent = true
--end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}


-- {{{ Startup
-- Startup programs in ~/.config/autostart
awful.util.spawn("setxkbmap int")
ro.xrun()
ro.run_once(terminal, nil, nil, 1)
--ro.run_once("nm-applet","--sm-disable")
--ro.run_once("synapse","--startup")
--ro.run_once("cbatticon","-u 30 -i symbolic -x gnome-power-statistics")
--ro.run_once("caffeine")
--ro.run_once_lua("davmail", nil, "java")
--ro.run_once_lua("redshift-gtk")
-- }}}
