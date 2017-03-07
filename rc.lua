-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local xdg_menu = require("archmenu")
local hotkeys_popup = require("awful.hotkeys_popup").widget
-- Dynamic tagging library
local tyrannical = require("tyrannical")
local tagctl     = require("lib/tagctl")
-- apw - pulseaudio integration
local APW = require("apw/widget")
-- Other widgets and layout library
local vicious = require("vicious")
--local blingbling = require("blingbling")
local calendar = require("calendar")
local lain = require("lain")
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
-- Themes define colours, icons, font and wallpapers.
function set_theme(name)
    local themes_dir = awful.util.get_configuration_dir().."themes/"
    local theme_dir = themes_dir .. name
    beautiful.init(theme_dir .. "/theme.lua")
end
set_theme("default")

-- This is used later as the default terminal and editor to run.
--terminal = "sakura"
terminal = "terminator"
browser = "firefox"
mail = "thunderbird"
system_monitor = "gnome-system-monitor"
editor = os.getenv("EDITOR") or "nano"
visual_editor = "geany"
file_manager = "nautilus"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"
altkey = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
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
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Tyrannical
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
            "xterm" , "urxvt" , "aterm","URxvt","XTerm","konsole","terminator","gnome-terminal","Sakura","Urxvt-tabbed"
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
            "Opera"         , "Firefox"        , "Rekonq"    , "Dillo"    , "Arora"  ,  "Min"  , 
            "Chromium"      , "nightly"        , "minefield" , "Midori"                         }
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
-- }}}


-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() return false, hotkeys_popup.show_help end},
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end}
}

mymainmenu = awful.menu({ items = { { "awesome"         , myawesomemenu     , beautiful.menu_awesome },
                                    { "applications"    , xdgmenu           , beautiful.menu_apps },
                                    { "open terminal"   , terminal          , beautiful.menu_terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it

-- Keyboard map indicator and switcher
--mykeyboardlayout = awful.widget.keyboardlayout()

-- Logout Menu
logoutmenu = awful.widget.launcher(
        {image = beautiful.menu_shutdown,
         menu = awful.menu({items = {
                    {"Shutdown", 'systemctl poweroff', beautiful.menu_shutdown }, 
                    {"Reboot"  , 'systemctl reboot', beautiful.menu_reboot }, 
                    {"Logout"  , function() awesome.quit() end, beautiful.menu_logout },
                    --{"Lock"    , 'xscreensaver-command -lock', beautiful.menu_lock },
                    nil                       
         }})
})
-- }}}


-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Spacers
spacer = wibox.widget.textbox(" ")
separator = wibox.widget.textbox(" | ")

-- Vicious widgets
-- RAM usage widget
memwidget = wibox.widget {
    widget    = wibox.container.rotate,
    direction = "east",
    {
        widget           = wibox.widget.progressbar,
        id               = "pbar",
        background_color = '#494B4F',
        color            = { type = "linear", from = { 0, 0 }, to = { 20, 0 }, stops = { { 0, "#AECF96" }, { 0.5, "#88A175" }, { 1, "#FF5656" } }},
        forced_height    = 15,
        forced_width     = 30,
        max_value        = 1,
    }
}
memwidget_t = awful.tooltip({ objects = { memwidget },})
function memwidget_t_update(widget, args)
    memwidget_t:set_text(" RAM: " .. args[2] .. "MB / " .. args[3] .. "MB ")
    return args[1]
end
-- Register RAM usage
vicious.cache(vicious.widgets.mem)
vicious.register(memwidget.pbar, vicious.widgets.mem, memwidget_t_update, 17)

-- CPU usage widget
cpuwidget = wibox.widget {
    widget           = wibox.widget.graph(),
    background_color = '#494B4F',
    color            = { type = "linear", from = { 0, 0 }, to = { 0, 20 }, stops = { { 0, "#FF5656" }, { 0.5, "#88A175" }, { 1, "#AECF96" } }},
    forced_height    = 30,
    forced_width     = 50,
    --vicious          = {vicious.widgets.cpu, cpuwidget_t_update},
}
function cpuwidget.LaunchSytemMonitor()
	awful.spawn.with_shell( system_monitor )
end
cpuwidget:buttons(awful.util.table.join(
		awful.button({ }, 1, cpuwidget.LaunchSytemMonitor)
))
cpuwidget_t = awful.tooltip({ objects = { cpuwidget },})
function cpuwidget_t_update(widget, args)
    cpuwidget_t:set_text("CPU Usage: " .. args[1] .. "%")
    return args[1]
end
-- Register CPU widget
vicious.cache(vicious.widgets.cpu)
vicious.register(cpuwidget, vicious.widgets.cpu, cpuwidget_t_update)


-- { Clock widget

markup      = lain.util.markup
-- Textclock
--clockicon = wibox.widget.imagebox(beautiful.widget_clock)
laintextclock = wibox.widget.textclock(markup("#de5e1e", "%A %d %B ") .. markup("#F7F7F7", ">") .. markup("#7788af", " %H:%M "))

-- Calendar
--lain.widgets.calendar.attach(laintextclock)
--lain.widgets.calendar.attach(widget, args)
cal = calendar.year {
    font             = "Monospace 12",
    --bg               = "#00000000",
    bg               = "#ffffff",
    week_numbers     = false,
    style_year       = { spacing      = 10,
                         padding      = 10,
                         bg_color     = "#00000000",
                         border_width = 0,
                         border_color = "#de5e1e"
    },
    style_yearheader = { shape    = function(cr, width, height) gears.shape.rounded_rect(cr, width, height, 10) end,
                         markup   = function(t) return '<span font="Monospace 32"><b>' .. t .. '</b></span>' end,
                         padding  = 10,
                         fg_color = "#F7F7F7",
                         bg_color =  "#7788af"
    },
    style_month      = { padding      = 5,
                         bg_color     = "#555555",
                         shape        = function(cr, width, height) gears.shape.rounded_rect(cr, width, height, 10) end
    },
    style_normal     = { shape  = function(cr, width, height) gears.shape.rounded_rect(cr, width, height, 5) end },
    style_focus      = { shape  = function(cr, width, height) gears.shape.partially_rounded_rect(cr, width, height, false, true, false, true, 5) end },
    style_header     = { markup = function(t) return markup.bold(markup("#F7F7F7", t)) end,
                         shape  = function(cr, width, height) gears.shape.rounded_rect(cr, width, height, 10) end
    },
    style_weekdays   = { markup = function(t) return markup.bold(markup("#7788af", t)) end,
                         shape  = function(cr, width, height) gears.shape.rounded_rect(cr, width, height, 5) end
    },
    style_weeknumber = { markup   = function(t) return markup("#ff9800", t) end,
                         bg_color = "#555555"
    },
    nil  -- stopper
}
tooltip_cal = calendar.month {
    font             = "Monospace 10",
    bg               = "#00000000",
    week_numbers     = false,
    style_month      = { border_width = 5,
                         border_color = "#de5e1e"
    },
    style_focus      = { shape  = function(cr, width, height) gears.shape.partially_rounded_rect(cr, width, height, false, true, false, true, 5) end },
    style_header     = { markup = function(t) return markup.bold(markup("#de5e1e", t)) end },
    style_weekdays   = { markup = function(t) return markup.bold(markup("#7788af", t)) end },
    style_weeknumber = { markup   = function(t) return markup("#ff9800", t) end },
    nil  -- stopper
}
tooltip_cal:attach(laintextclock)

-- }

-- Pacman Widget
pacwidget = wibox.widget.textbox()
pacwidget_t = awful.tooltip({ objects = { pacwidget},})
function pacwidget_t_update(widget, args)
    pacwidget_t:set_text(args[2])
    return "UPDATES: " .. args[1]
end
pacwidget:buttons(awful.util.table.join(
		awful.button({ }, 3, 
            function ()
                naughty.notify({ text="Update pacman widget..." , 
                                 screen=awful.screen.focused()
                })
                vicious.force({pacwidget})
            end)
))

--vicious.cache(vicious.widgets.pkg)
--vicious.register(pacwidget, vicious.widgets.pkg, pacwidget_t_update, 600, "Arch C")
-- Update APW widget periodically, in case the volume is changed from somewhere else. 
APWTimer = gears.timer({ timeout = 0.5 }) -- set update interval in s
APWTimer:connect_signal("timeout", APW.Update)
APWTimer:start()
-- }}}

-- {{{ Connect Wibar
-- Create a wibox for each screen and add it
local taglist_buttons = awful.util.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}
local tasklist_buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    local tag_table = { }
    awful.tag(tag_table, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    left_widgets_list = {
        mylauncher,
        s.mytaglist,
        s.mypromptbox
    }

    left_widgets = {layout = wibox.layout.fixed.horizontal}
    for _, wid in ipairs(left_widgets_list) do
        table.insert(left_widgets, wid)
        if wid ~= mylauncher then
            table.insert(left_widgets, separator)
        end
    end

    right_widgets_list = {
        s.index == 1 and wibox.widget.systray(),
        --mykeyboardlayout,
        pacwidget,
        cpuwidget,
        memwidget,
        APW,
        laintextclock,
        s.mylayoutbox,
        logoutmenu,
    }

    right_widgets = {layout = wibox.layout.fixed.horizontal}
    for _, wid in ipairs(right_widgets_list) do
        if wid ~= nil then
            table.insert(right_widgets, separator)
            table.insert(right_widgets, wid)
        end
    end

    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        left_widgets, -- Left widgets
        s.mytasklist, -- Middle widget
        right_widgets,-- Right widgets
    }
end)
-- }}}

-- Set prompt and taglist for the tag control
tagctl.get_prompt = function() return awful.screen.focused().mypromptbox end
dbg.get_prompt = function() return awful.screen.focused().mypromptbox end

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    -- Awesome
    awful.key({ modkey,           }, "w"      , function () mymainmenu:toggle() end   , {description = "show main menu", group = "awesome"}),
    awful.key({ modkey,           }, "s"      , hotkeys_popup.show_help               , {description="show help", group="awesome"}),
    awful.key({ modkey, "Control" }, "r"      , awesome.restart                       , {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q"      , awesome.quit                          , {description = "quit awesome", group = "awesome"}),
    awful.key({ modkey, "Control" }, "q"      , shutdown.logout_dialog_menu           , {description = "open shutdown dialog", group = "awesome"}),
    -- Menubar
    awful.key({ modkey,           }, "Return" , function () awful.spawn(terminal) end , {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "m"      , function() menubar.show() end         , {description = "show the menubar", group = "launcher"}),
    -- Prompt
    awful.key({ modkey,           }, "r"      , function () awful.screen.focused().mypromptbox:run() end, {description = "run prompt", group = "launcher"}),
    awful.key({ modkey,           }, "p"      , dbg.lua_prompt()                      , {description = "lua debug prompt", group = "launcher"}),

    -- Tags
    awful.key({ modkey,           }, "Left"  , awful.tag.viewprev                          , {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right" , awful.tag.viewnext                          , {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore                   , {description = "go back", group = "tag"}),
    awful.key({ modkey, "Control" }, "d"     , function () tagctl.delete() end             , {description = "delete tag", group = "tag"}),
    awful.key({ modkey, "Control" }, "a"     , function () tagctl.add() end                , {description = "add tag", group = "tag"}),
    awful.key({ modkey, "Control" }, "p"     , function () tagctl.permute() end            , {description = "permute selected tags", group = "tag"}),
    awful.key({ modkey, "Control" }, "w"     , function () tagctl.rename() end             , {description = "rename tag", group = "tag"}),

    -- Clients
    awful.key({ modkey,           }, "j"     , function () awful.client.focus.byidx( 1) end, {description = "focus next by index", group = "client"}),
    awful.key({ modkey,           }, "k"     , function () awful.client.focus.byidx(-1) end, {description = "focus previous by index", group = "client"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),
    -- Implement Alt-Tab
    awful.key({ altkey            }, "Tab",
            function ()
                awful.client.focus.byidx( 1)
                if client.focus then client.focus:raise() end
            end,
            {description = "next client", group = "client"}),
    awful.key({ altkey, "Shift"   }, "Tab",
            function ()
                awful.client.focus.byidx(-1)
                if client.focus then client.focus:raise() end
            end,
            {description = "previous client", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Volume and display
        -- Fn keys with APW
    awful.key({ },          "XF86AudioRaiseVolume",    APW.Up        , {description = "volume up", group = "volume and display"}),
    awful.key({ },          "XF86AudioLowerVolume",    APW.Down      , {description = "volume down", group = "volume and display"}),
    awful.key({ },          "XF86AudioMute",           APW.ToggleMute, {description = "volume mute", group = "volume and display"}),
		-- Mute/Unmute microphone (source index 2 in pulseaudio). See `man pactl`
	awful.key({ modkey },   "F8",                      function () awful.util.spawn("pactl set-source-mute 2 toggle") end,
              {description = "mute mic", group = "volume and display"}),
		-- Brightness
    awful.key({ },          "XF86MonBrightnessDown",   function () awful.util.spawn("xbacklight -dec 15") end,
              {description = "decrease brightness", group = "volume and display"}),
    awful.key({ },          "XF86MonBrightnessUp",     function () awful.util.spawn("xbacklight -inc 15") end,
              {description = "increase brightness", group = "volume and display"}),
        -- Display
    awful.key({ },          "XF86Display",             xrandr.change_display  , {description = "change display", group = "volume and display"}),
    awful.key({"Control" }, "XF86Display",             xrandr.force_vga_output, {description = "force VGA output", group = "volume and display"}),

    -- bind PrintScrn to capture a screen
    awful.key({}, "Print", function () awful.spawn("scrot -e 'mv $f ~/screenshots/ 2>/dev/null'") end, {description = "print screen", group = "volume and display"}),

    -- Show Conky when Pause is pressed and held
    --awful.key({},           "Scroll_Lock",                   raise_conky, lower_conky),
    
    -- Test calendar
    awful.key({ modkey, "Control" }, "c",  function () cal:toggle() end),

    
	-- Programs
    awful.key({ altkey },  "b",      ro.raise_or_new_tag('web', browser, true)          , {description = "Browser", group = "programs"}),        -- open firefox 
    awful.key({ altkey },  "m",      ro.raise_or_new_tag('mail', mail, true)            , {description = "Mail", group = "programs"}),           -- open thunderbird
    awful.key({ altkey },  "f",      ro.raise_or_new_tag('files', file_manager)         , {description = "Files", group = "programs"}),          -- open file manager
    awful.key({ altkey },  "e",      ro.raise_or_new_tag('edit', visual_edit, true)     , {description = "Editor", group = "programs"}),         -- open geany
    awful.key({ altkey },  "x",      ro.raise_or_new_tag('term', terminal)              , {description = "Terminal", group = "programs"}),       -- go to terminal tag
	awful.key({ altkey },  "Escape", function () awful.spawn(system_monitor) end   , {description = "System monitor", group = "programs"}), -- open system-monitor
    nil
)

-- Additional custom hotkeys
hotkeys_popup.add_hotkeys({
    ["programs"] = {{modifiers = {altkey}, keys = {["space"]="synapse"}}},
    ["tag"]      = {{modifiers = {modkey,                   }, keys = {["#"]="view tag #(1-9)"}},
                    {modifiers = {modkey, "Control"         }, keys = {["#"]="toggle tag #(1-9)"}},
                    {modifiers = {modkey, "Shift"           }, keys = {["#"]="move client to tag #(1-9)"}},
                    {modifiers = {modkey, "Control", "Shift"}, keys = {["#"]="toggle client on tag #(1-9)"}},
    },
    nil
})


clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = true               end,
              {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "maximize", group = "client"}),
    awful.key({ modkey, }, "s", function (c) c.sticky = not c.sticky end, {description = "stick window", group = "client"}),
    awful.key({ modkey, }, "i", dbg.client_info, {description = "get information about client", group = "client"}),
    awful.key({ modkey, }, "d", awful.titlebar.toggle, {description = "toggle decoration", group = "client"}),
    --awful.key({ modkey, }, "o" , function (c) awful.client.movetoscreen(c) tyrannical.match_client(c) end, {description = "move to next screen", group = "client"}),
    --awful.key({ modkey, }, "F5", function (c) awful.client.movetoscreen(c) tyrannical.match_client(c) c.fullscreen=true end, {description = "move to next screen and fullscreen", group = "client"}),
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
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end),
                  --end,
                  --{description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
                  --end,
                  --{description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end),
                  --end,
                  --{description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end),
                  --end,
                  --{description = "toggle focused client on tag #" .. i, group = "tag"}),
        nil -- stopper
    )
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}


-- {{{ Helper functions
-- Handle LibreOffice fullscreen windows
local function add_libreoffice_rule()
    local string = require("string")
    local table = require("table")
    local function add_rule(stdout, stderr)
        name = string.match(stdout, "LibreOffice [0-9]*.[0-9]*")
        table.insert(awful.rules.rules, {
            rule       = { name = name, class = "Soffice", type = "normal"},
            callback   = function(c)
                             awful.client.property.set(c, "overwrite_class", "libreoffice-fullscreen")
                             c.fullscreen = true
                         end,
            properties = { 
                fullscreen   = true,  -- does not seem to work
                skip_taskbar = true,
                maximized    = true,
                focusable    = true}
        })
    end
    
    awful.spawn.easy_async("libreoffice --version", add_rule)
end


-- Create titlebar
local function create_titlebar(c)
    -- buttons for the titlebar
    local buttons = awful.util.table.join(
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
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      callback = create_titlebar,
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Hide titlebar on some window types
    { rule_any = { type = {"normal", "dialog", "utility", "splash", "desktop", "toolbar"} },
      callback = function(c) create_titlebar(c); awful.titlebar.hide(c) end,
      properties = { placement = awful.placement.no_overlap+awful.placement.no_offscreen+awful.placement.centered }
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
    nil  -- stopper
}
add_libreoffice_rule()
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

awesome.connect_signal("exit", function() awful.spawn("systemctl --user stop compton") end)

local do_test = false
if do_test then
    test = require("calendar/test").start()
end

-- {{{ Startup
awful.spawn("setxkbmap int")
awful.spawn("numlockx on")
-- Startup programs in ~/.config/autostart
ro.xrun()
ro.run_once(terminal)
--ro.run_once("systemctl --user start compton")
--ro.run_once("nm-applet","--sm-disable")
--ro.run_once("synapse","--startup")
--ro.run_once("cbatticon","-u 30 -i symbolic -x gnome-power-statistics")
--ro.run_once("caffeine")
--ro.run_once_lua("davmail", nil, "java")
--ro.run_once_lua("redshift-gtk")
-- }}}
