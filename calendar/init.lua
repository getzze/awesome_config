---------------------------------------------------------------------------
-- A calendar popup wibox
--
-- Display a month or year calendar popup using `calendar.month` or `calendar.year`.
-- The calendar style can be tweaked by providing tables of style properties at creation:
-- `style_year` and `style_month` (see `container_properties`); `style_yearheader`, `style_header`,
-- `style_weekdays`, `style_weeknumber`, `style_normal`, `style_focus` (see `cell_properties`).
--
-- The wibox accepts arguments for the calendar widget: "font", "spacing", "week_numbers", "start_sunday".
-- It also accepts the extra arguments `opacity`, `bg`, `screen` and `position`.
-- `opacity` and `bg` apply to the wibox itself, they are mainly useful to manage opacity
-- by setting `opacity` for the false opacity or setting `bg="#00000000"` for compositor opacity.
-- The `screen` argument forces the display of the wibox to this screen (instead of the focused screen by default).
-- The `position` argument is a two-characters string describing the screen alignment "[vertical][horizontal]", e.g. "cc", "tr", "bl", ...
--
-- The wibox visibility can be changed calling the `toggle` method.
-- The `attach` method adds mouse bindings to an existing widget in order to toggle the display of the wibox.
--
--@DOC_wibox_awidget_defaults_calendar_EXAMPLE@
--
-- @author getzze
-- @copyright 2017 getzze
-- @classmod awful.widget.calendar
---------------------------------------------------------------------------

local setmetatable = setmetatable
local string = string
local ipairs = ipairs
local util = require("awful.util")
local ascreen = require("awful.screen")
local abutton = require("awful.button")
local gears = require("gears")
local wibox = require("wibox")
local base = require("wibox.widget.base")
local beautiful = require("beautiful")

wibox.layout.grid = wibox.layout.grid or require("calendar/grid")
wibox.widget.calendar = wibox.widget.calendar or require("calendar/calendar")

local calendar_popup = { offset = 0, mt = {} }

local properties = { "padding", "border_width", "border_color", "fg_color", "bg_color", "shape", "opacity" }

local month_styles = { "header", "weekdays", "weeknumber", "normal", "focus" }
local year_styles  = { "yearheader" }
local style_properties = { "font", "fg_color", "bg_color", "shape", "markup", "align", "valign", "padding", "opacity" }


--- The year calendar style table.
--
-- Each table property can also be defined by `beautiful.calendar_year_[property]=val`.
-- @beautiful beautiful.calendar_style_year
-- @tparam year_properties table Table with year properties

--- The month calendar style table.
--
-- Each table property can also be defined by `beautiful.calendar_month_[property]=val`.
-- @beautiful beautiful.calendar_style_month
-- @tparam month_properties table Table with month properties

--- The cell calendar style table.
--
-- Individual table property for a particular cell (from `year_styles` or `month_styles` values)
-- can be defined by `beautiful.calendar_[cell]_[property]=val` .
-- @beautiful beautiful.calendar_style_cell
-- @tparam cell_properties table Table with default cell properties (apply to all cells)

--- The calendar fallback font.
-- @beautiful beautiful.calendar_font
-- @tparam string font Font of the calendar (can be overridden by individual cells)


--- The month calendar style.
--
-- See `container_properties`.
-- @tparam month_properties table Table of month calendar properties
-- @property style_month

--- The year calendar container style.
--
-- See `container_properties`.
-- @tparam year_properties table Table of year calendar properties
-- @property style_year

--- The month calendar header style.
--
-- See `cell_properties`.
-- @tparam cell_properties table Table of cell calendar properties
-- @property style_header

--- The month calendar week days cell style.
--
-- See `cell_properties`.
-- @tparam cell_properties table Table of cell calendar properties
-- @property style_weekdays

--- The month calendar week number cells style.
--
-- See `cell_properties`.
-- @tparam cell_properties table Table of cell calendar properties
-- @property style_weeknumber

--- The month calendar normal day style.
--
-- See `cell_properties`.
-- @tparam cell_properties table Table of cell calendar properties
-- @property style_normal

--- The month calendar current day style.
--
-- See `cell_properties`.
-- @tparam cell_properties table Table of cell calendar properties
-- @property style_focus

--- The year calendar header style.
--
-- See `cell_properties`.
-- @tparam cell_properties table Table of cell calendar properties
-- @property style_yearheader


--- Cell properties.
-- @field font Text font
-- @field fg_color Text foreground color
-- @field bg_color Text background color
-- @field align Text horizontal alignment
-- @field valign Text vertical alignment
-- @field markup Text markup
-- @field shape Cell shape
-- @field padding Cell padding
-- @field opacity Cell opacity
-- @table cell_properties

--- Container properties.
-- @field padding Calendar grid padding
-- @field border_width Calendar border width
-- @field border_color Calendar border color
-- @field fg_color Calendar foreground color
-- @field bg_color Calendar background color
-- @field shape Calendar border shape
-- @field opacity Calendar opacity
-- @field week_numbers Show week numbers
-- @field start_sunday Start week on Sunday
-- @table container_properties

--- Month cell types.
-- @field header Month header cell properties table
-- @field weekdays Weekdays cell properties table
-- @field weeknumber Week number cell properties table
-- @field normal Normal day cell properties table
-- @field focus Current day cell properties table
-- @table month_cells

--- Year cell styles.
-- @field yearheader Year number header cell properties table
-- @table year_cells


--- Create a container for the grid layout
-- @tparam table props Table of calendar container properties.
-- @tparam widget widget The grid layout to set in the container
-- @treturn widget Container widget
local function embed(props)
    local function fn (widget)
        local out = base.make_widget_declarative {
            {
                widget,
                margins = props.padding + props.border_width,
                widget  = wibox.container.margin
            },
            shape              = props.shape or gears.shape.rectangle,
            shape_border_color = props.border_color,
            shape_border_width = props.border_width,
            fg                 = props.fg_color,
            bg                 = props.bg_color,
            opacity            = props.opacity,
            widget             = wibox.container.background
        }
        return out
    end
    return fn
end


--- Parse the properties of the cell type and set default values
-- @tparam string cell The cell type
-- @tparam table vargs Table of properties to enforce
-- @treturn table The properties table
local function parse_markup(cell, vargs)
    local args = (vargs or {})["style_" .. cell] or {}
    local function do_nothing(t) return t end
    local function do_focus(t) return "<b>" .. t .. "</b>" end
    return args.markup or beautiful["calendar_" .. cell .. "_markup"]
                                    or (beautiful.calendar_style_cell or {}).markup
                                    or (cell == "focus" and do_focus or do_nothing)
end

--- Parse the properties of the cell type and set default values
-- @tparam string cell The cell type
-- @tparam table args Table of properties to enforce
-- @treturn table The properties table
local function parse_cell_options(cell, args)
    args = args or {}
    local props = {}
    local bl_style = beautiful.calendar_style_cell or {}

    -- style default values
    props.fg_color  = args.fg_color or beautiful["calendar_" .. cell .. "_fg_color"]
                                    or bl_style.fg_color
                                    or (cell == "focus" and beautiful["fg_focus"] or beautiful["fg_normal"])
    props.bg_color  = args.bg_color or beautiful["calendar_" .. cell .. "_bg_color"]
                                    or bl_style.bg_color
                                    or (cell == "focus" and beautiful["bg_focus"] or beautiful["bg_normal"])
    props.shape     = args.shape    or beautiful["calendar_" .. cell .. "_shape"]
                                    or bl_style.shape
                                    or nil
    props.padding   = args.padding  or beautiful["calendar_" .. cell .. "_padding"]
                                    or bl_style.padding
                                    or 2
    props.opacity   = args.opacity  or beautiful["calendar_" .. cell .. "_opacity"]
                                    or bl_style.opacity
                                    or 1
    props.border_width = args.border_width  or beautiful["calendar_" .. cell .. "_border_width"]
                                            or bl_style.border_width
                                            or beautiful.border_width
                                            or 0
    props.border_color = args.border_color  or beautiful["calendar_" .. cell .. "_border_color"]
                                            or bl_style.border_color
                                            or beautiful.border_normal
                                            or beautiful.fg_normal
    return props
end


--- Make the geometry of a wibox
-- @tparam widget widget Calendar widget
-- @tparam object screen Screen where to display the calendar (default to focused)
-- @tparam string position Two characters position of the calendar (default "cc")
-- @treturn number,number,number,number Geometry of the calendar, list of x, y, width, height
local function get_geometry(widget, screen, position)
    local pos, s = position or "cc", screen or ascreen.focused()
    local wa = s.workarea
    local hint_width, hint_height = widget:fit({screen=s, dpi=beautiful.xresources.get_dpi(s)}, wa.width, wa.height)

    local height = hint_height < wa.height and hint_height or wa.height
    local width  = hint_width  < wa.width  and hint_width  or wa.width

    -- Set to position: pos = tl, tc, tr
    --                        cl, cc, cr
    --                        bl, bc, br
    local x,y
    if pos:sub(1,1) == "t" then
        y = wa.y
    elseif pos:sub(1,1) == "b" then
        y = wa.y + wa.height - height
    else  --if pos:sub(1,1) == "c" then
        y = wa.y + math.floor((wa.height - height) / 2)
    end
    if pos:sub(2,2) == "l" then
        x = wa.x
    elseif pos:sub(2,2) == "r" then
        x = wa.x + wa.width - width
    else  --if pos:sub(2,2) == "c" then
        x = wa.x + math.floor((wa.width - width) / 2)
    end

    return {x=x, y=y, width=width, height=height}
end

--- Call the calendar with offset
-- @tparam number inc_offset Offset with respect to current date
-- @tparam table props Properties of the calendar (screen, position, ...)
-- @treturn wibox The wibox calendar
function calendar_popup:call_calendar(inc_offset, props)
    local props = props or {}
    local offset, position, s = inc_offset or 0, props.position or self.position, props.screen or self.screen or ascreen.focused()
    self.position = position  -- remember last position when changing offset

    self.offset = self.offset + offset
    local is_current = (offset == 0 or self.offset == 0)
    if is_current then
        self.offset = 0
    end

    local widget = self:get_widget()
    local date, hint_width, hint_height
    if widget.type == "month" then
        if is_current then
            date = os.date("%d %m %Y")
        else
            -- calculate the offset date
            local month = tonumber(os.date("%m"))
            local year  = tonumber(os.date("%Y"))

            month = month + self.offset

            while month > 12 do
                month = month - 12
                year = year + 1
            end

            while month < 1 do
                month = month + 12
                year = year - 1
            end

            date = string.format("%s %s", month, year)
        end
    elseif widget.type == "year" then
        date = string.format("%s", tonumber(os.date("%Y")) + self.offset)
    end

    -- set date and screen before updating geometry
    widget:set_date(date)
    self:set_screen(s)
    -- update geometry (depends on date and screen)
    self:geometry(get_geometry(widget, s, position))
    return self
end


--- Toggle calendar visibility
function calendar_popup:toggle()
    self:call_calendar(0)
    self.visible = not self.visible
end


--- Attach the calendar to a widget to display at a specific position.
--
--    local mytextclock = wibox.widget.textclock()
--    local month_calendar = calendar.month()
--    month_calendar:attach(mytextclock, 'tr')
--
-- @param widget Widget to attach the calendar
-- @tparam[opt="tr"] string position Two characters string defining the position on the screen
-- @treturn wibox The wibox calendar
function calendar_popup:attach(widget, position)
    local position = position or "tr"
    widget:buttons(util.table.join(abutton({ }, 1, function ()
                                                              self:call_calendar(0, {position=position})
                                                              self.visible = not self.visible
                                                        end),
                                   abutton({ }, 4, function () self:call_calendar(-1) end),
                                   abutton({ }, 5, function () self:call_calendar( 1) end)))
    return self
end


--- Return a new calendar wibox by type.
--
-- A calendar widget displaying a `month` or a `year`
-- @tparam string caltype Type of calendar `month` or `year`
-- @tparam table args Properties of the widget
-- @treturn wibox A wibox containing the calendar
local function get_cal_wibox(caltype, args)
    if caltype ~= "month" and caltype ~= "year" then return end
    local args = args or {}

    local ret = wibox{ ontop   = true,
                       opacity = args.opacity or 1,
                       bg      = args.bg
    }
    util.table.crush(ret, calendar_popup, false)

    ret.offset   = 0
    ret.position = args.position  or "cc"
    ret.screen   = args.screen

    local widget = wibox.widget {
        font         = args.font,
        spacing      = args.spacing,
        week_numbers = args.week_numbers,
        start_sunday = args.start_sunday,
        markup_header     = parse_markup("header", args),
        markup_yearheader = parse_markup("yearheader", args),
        markup_weekdays   = parse_markup("weekdays", args),
        markup_weeknumber = parse_markup("weeknumber", args),
        markup_normal     = parse_markup("normal", args),
        markup_focus      = parse_markup("focus", args),
        fn_embed_month      = embed(parse_cell_options("month", args.style_month)),
        fn_embed_year       = embed(parse_cell_options("year", args.style_year)),
        fn_embed_header     = embed(parse_cell_options("header", args.style_header)),
        fn_embed_yearheader = embed(parse_cell_options("yearheader", args.style_yearheader)),
        fn_embed_weekdays   = embed(parse_cell_options("weekdays", args.style_weekdays)),
        fn_embed_weeknumber = embed(parse_cell_options("weeknumber", args.style_weeknumber)),
        fn_embed_normal     = embed(parse_cell_options("normal", args.style_normal)),
        fn_embed_focus      = embed(parse_cell_options("focus", args.style_focus)),
        widget = wibox.widget.calendar(caltype)
    }
    ret:set_widget(widget)

    ret:buttons(util.table.join(
            abutton({ }, 1, function () ret.visible=false end),
            abutton({ }, 3, function () ret.visible=false end),
            abutton({ }, 4, function () ret:call_calendar(-1) end),
            abutton({ }, 5, function () ret:call_calendar( 1) end)
    ))
    return ret
end

--- A month calendar wibox.
--
-- It is highly customizable using the same options as for the widgets.
-- The options are set once and for all at creation, though.
--
--@DOC_wibox_awidget_calendar_month_wibox_EXAMPLE@
--
--    local mytextclock = wibox.widget.textclock()
--    month_calendar:attach( mytextclock, "tr" )
--
-- @tparam table args Properties of the widget
-- @treturn wibox A wibox containing the calendar
-- @function awful.calendar.month
function calendar_popup.month(args)
    return get_cal_wibox("month", args)
end


--- A year calendar wibox.
--
-- It is highly customizable using the same options as for the widgets.
-- The options are set once and for all at creation, though.
--
--@DOC_wibox_awidget_calendar_year_wibox_EXAMPLE@
--
--    globalkeys = awful.util.table.join(globalkeys, awful.key({ modkey, "Control" }, "c",  function () year_calendar:toggle() end))
--
-- @tparam table args Properties of the widget
-- @treturn wibox A wibox containing the calendar
-- @function awful.calendar.year
function calendar_popup.year(args)
    return get_cal_wibox("year", args)
end


function calendar_popup.mt:__call(caltype, ...)
    return get_cal_wibox(caltype, ...)
end

return setmetatable(calendar_popup, calendar_popup.mt)
