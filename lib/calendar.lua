---------------------------------------------------------------------------
-- A calendar widget
--
-- This module defines two widgets: a month calendar and a year calendar
--
-- The two widgets have a `date` property, in the form of a string "[%d] [%m] %Y".
--
-- The `calendar.widget.year` widget date property is a string, e.g. "2006". It displays the whole specified year.
--
-- The `calendar.widget.month` widget date property is a string, e.g. "22 12 2006" or "12 2006".
-- It displays the calendar for the specified month, highlighting the specified day if the day is provided in the date.
--
--
-- In addition to the widgets, wiboxes containing the widgets can be directly called to display the calendars.
--
-- They are called using `calendar.month` and `calendar.year`.
-- The wibox takes the same options as the widget, except for the `date` that is automatically generated.
-- It accepts the extra arguments `opacity`, `bg`, `screen` and `position`.
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
local color = require("gears.color")
local wibox = require("wibox")
local base = require("wibox.widget.base")
local beautiful = require("beautiful")

wibox.layout.grid = wibox.layout.grid or require("lib/grid")

local calendar = { offset = 0, mt = {} }
calendar.widget = { mt = {} }

local special_properties = { "date", "font" }
local properties = { "spacing", "padding", "border_width", "border_color", "fg_color", "bg_color", "shape", "opacity" }
local month_properties = { "week_numbers" , "start_sunday", "hide_year" }
local year_properties = { }

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

--- The calendar fallback font.
-- @param[opt="Monospace 10"] string Font of the calendar (can be overridden individually for each cell).
-- @property widget.font

--- The calendar date.
--
-- Date in space-separated integers format "[%day] [%month] %year".
-- E.g.. "21 02 2005", "02 2005", "2005".
-- @param string Date in space-separated integers format "[%day] [%month] %year".
-- @property widget.date

--- The month calendar style.
--
-- Each individual property is also directly defined `[set|get]_month_[property]`.
-- See `month_properties`.
-- @tparam month_properties table Table of month calendar properties
-- @property widget.style_month

--- The year calendar style.
--
-- Each individual property is also directly defined `[set|get]_year_[property]`.
-- See `year_properties`.
-- @tparam year_properties table Table of year calendar properties
-- @property widget.style_year

--- The month calendar header style.
--
-- Each individual property is also directly defined `[set|get]_header_[property]`.
-- See `cell_properties`.
-- @tparam cell_properties table Table of cell calendar properties
-- @property widget.style_header

--- The month calendar week days cell style.
--
-- Each individual property is also directly defined `[set|get]_weekdays_[property]`.
-- See `cell_properties`.
-- @tparam cell_properties table Table of cell calendar properties
-- @property widget.style_weekdays

--- The month calendar week number cells style.
--
-- Each individual property is also directly defined `[set|get]_weeknumber_[property]`.
-- See `cell_properties`.
-- @tparam cell_properties table Table of cell calendar properties
-- @property widget.style_weeknumber

--- The month calendar normal day style.
--
-- Each individual property is also directly defined `[set|get]_normal_[property]`.
-- See `cell_properties`.
-- @tparam cell_properties table Table of cell calendar properties
-- @property widget.style_normal

--- The month calendar current day style.
--
-- Each individual property is also directly defined `[set|get]_focus_[property]`.
-- See `cell_properties`.
-- @tparam cell_properties table Table of cell calendar properties
-- @property widget.style_focus

--- The year calendar header style.
--
-- Each individual property is also directly defined `[set|get]_yearheader_[property]`.
-- See `cell_properties`.
-- @tparam cell_properties table Table of cell calendar properties
-- @property widget.style_yearheader


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

--- Month properties.
-- @field spacing Calendar grid spacing
-- @field padding Calendar grid padding
-- @field border_width Calendar border width
-- @field border_color Calendar border color
-- @field fg_color Calendar foreground color
-- @field bg_color Calendar background color
-- @field shape Calendar border shape
-- @field opacity Calendar opacity
-- @field week_numbers Show week numbers
-- @field start_sunday Start week on Sunday
-- @table month_properties


--- Month cell styles.
-- @field header Month header cell properties table
-- @field weekdays Weekdays cell properties table
-- @field weeknumber Week number cell properties table
-- @field normal Normal day cell properties table
-- @field focus Current day cell properties table
-- @table month_styles

--- Year properties.
-- @field spacing Calendar grid spacing
-- @field padding Calendar grid padding
-- @field border_width Calendar border width
-- @field border_color Calendar border color
-- @field fg_color Calendar foreground color
-- @field bg_color Calendar background color
-- @field shape Calendar border shape
-- @field opacity Calendar opacity
-- @table year_properties

--- Year cell styles.
-- @field yearheader Year number header cell properties table
-- @table year_styles


-- Parse a date for the day, month and year
-- @tparam string date Date in the "%d %m %Y" format
-- @treturn {number,number,number} List of day, month, year (nil if undefined)
local function parse_date(date)
    -- Split a string by a given `separator`
    local function split(str, sep)
        local sep, fields = sep or ":", {}
        local pattern = string.format("([^%s]+)", sep)
        str:gsub(pattern, function(c) fields[#fields+1] = c end)
        return fields
    end

    local dfield = split(date, " ")
    if #dfield == 3 then
        return tonumber(dfield[1]), tonumber(dfield[2]), tonumber(dfield[3])
    elseif #dfield == 2 then
        return nil, tonumber(dfield[1]), tonumber(dfield[2])
    elseif #dfield == 1 then
        return nil, nil, tonumber(dfield[1])
    end
    return nil, nil, nil
end

--- Create and format a cell widget
-- @tparam table props Table of calendar cell properties
-- @tparam string text Text of the widget
-- @tparam string fb_font Fallback font
-- @treturn widget
local function create_cell(props, text, fb_font)
    local align  = props.align  or 'right'
    local valign = props.valign or 'center'
    local markup = type(props.markup) == "function" and props.markup or function(t) return t end
    local font   = props.font or fb_font

    w = wibox.widget {
        {
            {
                markup = markup(text),
                align  = align,
                valign = valign,
                font   = font,
                widget = wibox.widget.textbox
            },
            margins = props.padding,
            widget  = wibox.container.margin
        },
        fg      = props.fg_color,
        bg      = props.bg_color,
        shape   = props.shape,
        opacity = props.opacity,
        widget  = wibox.container.background
    }
    return w
end

--- Create a container for the grid layout
-- @tparam table props Table of calendar container properties.
-- @tparam widget widget The grid layout to set in the container
-- @treturn widget Container widget
local function create_container(props, widget)
    local ret = base.make_widget_declarative {
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
    return ret
end


--- Create a grid layout with the month calendar
-- @tparam table props Table of calendar properties
-- @tparam string date Date in the "%d %m %Y" format
-- @treturn widget Grid layout
local function create_month(props, date)
    local day, month, year = parse_date(date)
    local num_rows    = 8
    local num_columns = props.style_month.week_numbers and 8 or 7

    -- Create grid layout
    local layout = base.make_widget_declarative{
        layout      = wibox.layout.grid,
        expand      = true,
        homogeneous = true,
        spacing     = props.style_month.spacing,
        forced_num_rows = num_rows,
        forced_num_cols = num_columns,
    }

    local start_row    = 3
    local start_column = num_columns - 6
    local week_start   = props.style_month.start_sunday and 1 or 2
    local d            = os.date("*t", os.time{year=year, month=month+1, day=0})
    local month_days   = d.day
    local column_day   = (d.wday - d.day + 1 - week_start ) % 7

    --local flags = {"header", "weekdays", "weeknumber", "normal", "focus"}
    local t, i, j, w, flag, text

    -- Header
    flag = "header"
    t = os.time{year=year, month=month, day=1}
    text = os.date(props.style_month.hide_year and "%B" or "%B %Y", t)
    w = create_cell(props["style_" .. flag], text, props.font)
    layout:add_widget_at(w, 1, 1, 1, num_columns)

    -- Week days
    i = 2
    for j = start_column, num_columns do  -- columns
        flag = "weekdays"
        t = os.time{year=2006, month=1, day=j-start_column+week_start}
        text = string.sub(os.date("%a", t), 1, 2)
        w = create_cell(props["style_" .. flag], text, props.font)
        layout:add_widget_at(w, i, j, 1, 1)
    end

    -- Days
    i = start_row
    j = column_day + start_column
    local current_week = nil
    for d=1, month_days do
        if props.style_month.week_numbers then -- Week number
            t = os.time{year=year, month=month, day=d}
            text = os.date("%V", t)
            if tonumber(text) ~= current_week then
                flag = "weeknumber"
                w = create_cell(props["style_" .. flag], text, props.font)
                layout:add_widget_at(w, i, 1, 1, 1)
                current_week = tonumber(text)
                if j < start_column then j = start_column end
            end
        end
        -- Normal day
        flag = "normal"
        -- Focus day
        if day and day == d then flag = "focus" end
        text = string.format("%2d", d)
        w = create_cell(props["style_" .. flag], text, props.font)
        layout:add_widget_at(w, i, j, 1, 1)

        -- find next cell
        i,j = layout:get_next_empty(i,j)
    end
    return create_container(props.style_month, layout)
end


--- Create a grid layout for the year calendar
-- @tparam table props Table of year calendar properties
-- @param date Year to display (number or string)
-- @treturn widget Grid layout
local function create_year(props, date)
    local _, _, year = parse_date(date)

    -- Create a grid widget with the 12 months
    local in_layout = base.make_widget_declarative{
        layout      = wibox.layout.grid,
        expand      = true,
        homogeneous = true,
        spacing     = props.style_year.spacing,
        forced_num_cols = 4,
        forced_num_rows = 3,
    }

    local month_date = ""
    local current_day, current_month, current_year = parse_date(os.date("%d %m %Y"))

    for month=1,12 do
        if year == current_year and month == current_month then
            month_date = string.format("%s %s %s", current_day, current_month, current_year)
        else
            month_date = string.format("%s %s", month, year)
        end
        in_layout:add(create_month(props, month_date))
    end

    -- Create a vertical layout
    local year_header = create_cell(props.style_yearheader, string.format("%s", year), props.font)
    local out_layout = base.make_widget_declarative{
        year_header,
        in_layout,
        spacing = props.style_year.spacing, -- separate header from calendar grid
        layout  = wibox.layout.fixed.vertical
    }
    return create_container(props.style_year, out_layout)
end


--- Set the container to the current date
-- @param self Widget to update
-- @tparam boolean disablecache Force to recreate the widget in cache
local function fill_container(self, disablecache)
    disablecache = disablecache and false or true
    local date = self._private.date
    if date and (not self._private.container or disablecache) then
        -- Create calendar grid
        if disablecache or not self._private.calendar_cache[date] then
            if self.type == "month" then
                self._private.calendar_cache[date] = create_month(self._private, date)
            elseif self.type == "year" then
                self._private.calendar_cache[date] = create_year(self._private, date)
            end
        end
        -- Create calendar box
        self._private.container = self._private.calendar_cache[date]
    end
end

--- Parse the font
-- @tparam string font The font name
-- @treturn string The font
local function parse_font(font)
    return font or beautiful["calendar_font"] or "Monospace 10"
end


--- Parse the properties of the cell type and set default values
-- @tparam string cell The cell type
-- @tparam table args Table of properties to enforce
-- @treturn table The properties table
local function parse_cell_options(cell, args)
    args = args or {}
    local props = {}
    local function do_nothing(t) return t end
    local function do_focus(t) return "<b>" .. t .. "</b>" end

    -- style default values
    props.font      = args.font     or beautiful["calendar_" .. cell .. "_font"]  -- no default, to allow fallback
    props.fg_color  = args.fg_color or beautiful["calendar_" .. cell .. "_fg_color"]
                                    or (beautiful.calendar_style_cell or {})["fg_color"]
                                    or (cell == "focus" and beautiful["fg_focus"] or beautiful["fg_normal"])
    props.bg_color  = args.bg_color or beautiful["calendar_" .. cell .. "_bg_color"]
                                    or (beautiful.calendar_style_cell or {})["bg_color"]
                                    or (cell == "focus" and beautiful["bg_focus"] or beautiful["bg_normal"])
    props.shape     = args.shape    or beautiful["calendar_" .. cell .. "_shape"]
                                    or (beautiful.calendar_style_cell or {})["shape"]
                                    or nil
    props.markup    = args.markup   or beautiful["calendar_" .. cell .. "_markup"]
                                    or (beautiful.calendar_style_cell or {})["markup"]
                                    or (cell == "focus" and do_focus or do_nothing)
    props.align     = args.align    or beautiful["calendar_" .. cell .. "_align"]
                                    or (beautiful.calendar_style_cell or {})["align"]
                                    or ((cell == "header" or cell == "yearheader") and "center" or "right")
    props.valign    = args.valign   or beautiful["calendar_" .. cell .. "_valign"]
                                    or (beautiful.calendar_style_cell or {})["valign"]
                                    or "center"
    props.padding   = args.padding  or beautiful["calendar_" .. cell .. "_padding"]
                                    or (beautiful.calendar_style_cell or {})["padding"]
                                    or 2
    props.opacity   = args.opacity  or beautiful["calendar_" .. cell .. "_opacity"]
                                    or (beautiful.calendar_style_cell or {})["opacity"]
                                    or 1
    return props
end

--- Parse the common properties of the month and year and set default values
-- @tparam string caltype Type of the calendar, `year` or `month`.
-- @tparam table args Table of properties to enforce
-- @treturn table The properties table
local function parse_common_options(caltype, args)
    local props = {}
    props.spacing      = args.spacing       or beautiful["calendar_" .. caltype .. "_spacing"]
                                            or (beautiful["calendar_style_" .. caltype] or {})["spacing"]
                                            or 5
    props.padding      = args.padding       or beautiful["calendar_" .. caltype .. "_padding"]
                                            or (beautiful["calendar_style_" .. caltype] or {})["padding"]
                                            or 5
    props.border_width = args.border_width  or beautiful["calendar_" .. caltype .. "_border_width"]
                                            or (beautiful["calendar_style_" .. caltype] or {})["border_width"]
                                            or beautiful.border_width
                                            or 0
    props.border_color = args.border_color  or beautiful["calendar_" .. caltype .. "_border_color"]
                                            or (beautiful["calendar_style_" .. caltype] or {})["border_color"]
                                            or beautiful.border_normal
                                            or beautiful.fg_normal
    props.fg_color     = args.fg_color      or beautiful["calendar_" .. caltype .. "_fg_color"]
                                            or (beautiful["calendar_style_" .. caltype] or {})["fg_color"]
                                            or beautiful.fg_normal
    props.bg_color     = args.bg_color      or beautiful["calendar_" .. caltype .. "_bg_color"]
                                            or (beautiful["calendar_style_" .. caltype] or {})["bg_color"]
                                            or beautiful.bg_normal
    props.shape        = args.shape         or beautiful["calendar_" .. caltype .. "_shape"]
                                            or (beautiful["calendar_style_" .. caltype] or {})["shape"]
                                            or nil
    props.opacity      = args.opacity       or beautiful["calendar_" .. caltype .. "_opacity"]
                                            or (beautiful["calendar_style_" .. caltype] or {})["opacity"]
                                            or 1
    return props
end

--- Parse the properties of the month calendar and set default values
-- @tparam table args Table of properties to enforce
-- @treturn table The properties table
local function parse_month_options(args)
    args = args or {}
    local props = {}
    props.hide_year    = args.hide_year or false
    props.week_numbers = args.week_numbers  or beautiful["calendar_month_week_numbers"]
                                            or (beautiful.calendar_style_month or {})["week_numbers"]
                                            or false
    props.start_sunday = args.start_sunday  or beautiful["calendar_month_start_sunday"]
                                            or (beautiful.calendar_style_month or {})["start_sunday"]
                                            or false
    -- Add options common to year and month calendar
    util.table.crush(props, parse_common_options("month", args), false)

    return props
end

--- Parse the properties of the year calendar and set default values
-- @tparam table args Table of properties to enforce
-- @treturn table The properties table
local function parse_year_options(args)
    args = args or {}
    local props = parse_common_options("year", args)

    return props
end

-- Set the calendar date
function calendar.widget:set_date(date)
    if date and date ~= self._private.date then
        self._private.date = date
        self:emit_signal("widget::layout_changed")
    end
end

-- Get the calendar date
function calendar.widget:get_date()
    return self._private.date
end

-- Set the calendar font
function calendar.widget:set_font(font)
    if self._private.font ~= font then
        self._private.font = font
        -- empty cache
        self._private.calendar_cache = {}
        self:emit_signal("widget::layout_changed")
    end
end

-- Get the calendar font
function calendar.widget:get_font()
    return self._private.font
end

-- Set the container opacity (overwrite base.widget.opacity property)
function calendar.widget:set_opacity(value)
    if self._private.opacity ~= value then
        self._private["style_" .. self.type].opacity = value
        -- empty cache
        self._private.calendar_cache = {}
        self:emit_signal("widget::layout_changed")
    end
end

-- Get the container opacity
function calendar.widget:get_opacity()
    return self._private["style_" .. self.type].opacity
end


-- Override container functions
function calendar.widget:get_children()
    fill_container(self, false)
    return self._private.container or {}
end

function calendar.widget:set_children(...)
end

-- Layout widget
function calendar.widget:layout(context, width, height)
    fill_container(self, true)
    if self._private.container then
        return { base.place_widget_at(self._private.container, 0, 0, width, height) }
    end
    return {}
end

-- Fit widget
function calendar.widget:fit(context, width, height)
    fill_container(self, false)
    if self._private.container then
        return base.fit_widget(self, context, self._private.container, width, height)
    end
    return 0,0
end


--- Add properties to the calendar widget.
-- @tparam table ret The widget
-- @tparam table properties_table Properties of the calendar (see `year_properties` and `month_properties`)
-- @tparam string caltype The type of properties, `year` or `month`. If nil, it defines the default properties, depending on the widget type.
local function add_properties(ret, properties_table, caltype)
    -- Build properties function
    for _, prop in ipairs(properties_table) do
        local full_prop = prop
        local default = "style_" .. (caltype or ret.type)
        if caltype then
            full_prop = caltype .. "_" .. prop
        end
        -- setter
        if not ret["set_" .. full_prop] then
            ret["set_" .. full_prop] = function(self, value)
                if self._private[default][prop] ~= value then
                    self._private[default][prop] = value
                    -- empty cache
                    self._private.calendar_cache = {}
                    self:emit_signal("widget::layout_changed")
                end
            end
        end
        -- getter
        if not ret["get_" .. full_prop] then
            ret["get_" .. full_prop] = function(self)
                return self._private[default][prop]
            end
        end
    end

end

--- Add style properties to the calendar widget.
-- @tparam table ret The widget
-- @tparam table styles_table Style properties of the cell (see `cell_properties`)
local function add_style_properties(ret, styles_table)
    -- Build style properties function
    for _, style in ipairs(styles_table) do
        for _,style_prop in ipairs(style_properties) do
            local prop = style .. "_" .. style_prop
            local table_style = "style_" .. style
            -- table setter
            if not ret["set_" .. table_style] then
                ret["set_" .. table_style] = function(self, value)
                    if type(value) == "table" then
                        self._private[table_style] = parse_cell_options(style, value)
                        -- empty cache
                        self._private.calendar_cache = {}
                        self:emit_signal("widget::layout_changed")
                    end
                end
            end
            -- getter
            if not ret["get_" .. table_style] then
                ret["get_" .. table_style] = function(self)
                    return self._private[table_style]
                end
            end
            -- individual value setter
            if not ret["set_" .. prop] then
                ret["set_" .. prop] = function(self, value)
                    if self._private[table_style][style_prop] ~= value then
                        self._private[table_style][style_prop] = value
                        -- empty cache
                        self._private.calendar_cache = {}
                        self:emit_signal("widget::layout_changed")
                    end
                end
            end
            -- individual value getter
            if not ret["get_" .. prop] then
                ret["get_" .. prop] = function(self)
                    return self._private[table_style][style_prop]
                end
            end
        end
    end
end


--- Return a new calendar widget by type.
--
-- @tparam string t Type of the calendar, `year` or `month`
-- @tparam table args Properties of the calendar
-- @treturn widget The calendar widget
local function get_calendar(t, args)
    args = args or {}
    if t ~= "month" and t ~= "year" then return end
    local ret = base.make_widget(nil, "calendar_"..t)
    util.table.crush(ret, calendar.widget, true)

    ret.type = t
    ret._private.calendar_cache = {}

    -- default values
    ret._private.date = args.date
    ret._private.font = parse_font(args.font)
    ret._private.style_month = parse_month_options(args.style_month)
    for _,style in ipairs(month_styles) do
        ret._private["style_" .. style] = parse_cell_options(style, args["style_" .. style])
    end
    if t == "year" then
        ret._private.style_month.hide_year = true
        ret._private.style_year = parse_year_options(args.style_year)
        for _,style in ipairs(year_styles) do
            ret._private["style_" .. style] = parse_cell_options(style, args["style_" .. style])
        end
    end

    -- add default properties
    add_properties(ret, properties, nil)
    -- add month properties
    add_properties(ret, util.table.join(properties, month_properties), "month")
    -- add month styles properties
    add_style_properties(ret, month_styles )

    if ret.type == "year" then
        -- add year properties
        add_properties(ret, util.table.join(properties, year_properties), "year")
        -- add year styles properties
        add_style_properties(ret, year_styles )
    end

    return ret
end


--- A month calendar widget.
--
-- A calendar widget is a grid containing the calendar for one month
--
--@DOC_wibox_awidget_calendar_month_EXAMPLE@
-- @tparam table args Properties of the calendar
-- @treturn widget The month calendar widget
-- @function calendar.widget.month
function calendar.widget.month(args)
    return get_calendar("month", args)
end


--- A year calendar widget.
--
-- A calendar widget is a grid containing the calendar for one year
--
--@DOC_wibox_awidget_calendar_year_EXAMPLE@
-- @tparam table args Properties of the calendar
-- @treturn widget The year calendar widget
-- @function calendar.widget.year
function calendar.widget.year(args)
    return get_calendar("year", args)
end


-- {{{ Calendar wibox


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
function calendar:call_calendar(inc_offset, props)
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
function calendar:toggle()
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
function calendar:attach(widget, position)
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
    ret.call_calendar = calendar.call_calendar
    ret.toggle = calendar.toggle
    ret.attach = calendar.attach

    ret.offset   = 0
    ret.position = args.position  or "cc"
    ret.screen   = args.screen

    if caltype == "month" then
        ret:set_widget(calendar.widget.month(args))
    else
        ret:set_widget(calendar.widget.year(args))
    end

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
function calendar.month(args)
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
function calendar.year(args)
    return get_cal_wibox("year", args)
end


function calendar.mt:__call(caltype, ...)
    return get_cal_wibox(caltype, ...)
end
-- }}}


return setmetatable(calendar, calendar.mt)
