
---------------------------------------------------------------------------
-- A calendar widget
--
-- This module defines two widgets: a month calendar and a year calendar
--
-- The two widgets have a `date` property, in the form of a string "[%d] [%m] %Y".
--
-- The `year` widget displays the whole specified year, e.g. "2006".
--
-- The `month` widget displays the calendar for the specified month, e.g. "12 2006",
-- highlighting the specified day if the day is provided in the date, e.g. "22 12 2006".
--
-- Cell and container styles can be overridden using the "fn_embed_[cell]" properties.
-- `fn_embed_year`, `fn_embed_month`, `fn_embed_yearheader`, `fn_embed_header`, `fn_embed_weekdays`,
-- can be used to define padding, border, shape, fg and bg colors to the widgets.
--
--@DOC_wibox_widget_defaults_calendar_EXAMPLE@
--
-- @author getzze
-- @copyright 2017 getzze
-- @classmod wibox.widget.calendar
---------------------------------------------------------------------------

local setmetatable = setmetatable
local string = string
local ipairs = ipairs
local util = require("awful.util")
local vertical = require("wibox.layout.fixed").vertical
local grid = require("calendar/grid")
local textbox = require("wibox.widget.textbox")
local base = require("wibox.widget.base")
local beautiful = require("beautiful")

local calendar = { mt = {} }

local properties = { "date", "font", "spacing", "hide_year", "week_numbers", "start_sunday" ,
                     "fn_embed_year", "fn_embed_month", "fn_embed_yearheader", "fn_embed_header",
                     "fn_embed_weekdays", "fn_embed_weeknumber", "fn_embed_normal", "fn_embed_focus",
                     "markup_yearheader", "markup_header", "markup_weekdays", "markup_weeknumber",
                     "markup_normal", "markup_focus"}


--- The calendar font.
-- @beautiful beautiful.calendar_font
-- @tparam string font Font of the calendar

--- The calendar spacing.
-- @beautiful beautiful.calendar_spacing
-- @tparam number spacing Spacing of the grid (twice this value for inter-month spacing)

--- Display the calendar week numbers.
-- @beautiful beautiful.calendar_week_numbers
-- @param boolean Display week numbers

--- Start the week on Sunday.
-- @beautiful beautiful.calendar_start_sunday
-- @param boolean Start the week on Sunday

--- The calendar date.
--
-- Date in space-separated integers format "[%day] [%month] %year".
-- E.g.. "21 02 2005", "02 2005", "2005".
-- @param string Date in space-separated integers format "[%day] [%month] %year".
-- @property date

--- The calendar font.
--
-- Choose a monospace font for a better rendering.
--@DOC_wibox_widget_calendar_font_EXAMPLE@
-- @param[opt="Monospace 10"] string Font of the calendar
-- @property font

--- The calendar spacing.
--
-- The spacing between cells in the month.
-- The spacing between months in a year calendar is twice this value.
-- @param[opt=5] number Spacing of the grid
-- @property spacing

--- Display the calendar week numbers.
--
--@DOC_wibox_widget_calendar_week_numbers_EXAMPLE@
-- @param[opt=false] boolean Display week numbers
-- @property week_numbers

--- Start the week on Sunday.
-- @param[opt=false] boolean Start the week on Sunday
-- @property start_sunday

--- Hide year number in month header.
-- @param boolean Hide year in header (default: false for month calendar, true for year calendar)
-- @property hide_year

--- Year header markup
-- @param[opt=nil] nil|function|string A markup function, pattern
-- (string containing "%s" to use with `string.format`) or nil (does not change the text).
-- @property markup_yearheader

--- Month header markup
-- @param[opt=nil] nil|function|string A markup function, pattern
-- (string containing "%s" to use with `string.format`) or nil (does not change the text).
-- @property markup_header

--- Week days markup
-- @param[opt=nil] nil|function|string A markup function, pattern
-- (string containing "%s" to use with `string.format`) or nil (does not change the text).
-- @property markup_weekdays

--- Week number markup
-- @param[opt=nil] nil|function|string A markup function, pattern
-- (string containing "%s" to use with `string.format`) or nil (does not change the text).
-- @property markup_weeknumber

--- Normal day markup
-- @param[opt=nil] nil|function|string A markup function, pattern
-- (string containing "%s" to use with `string.format`) or nil (does not change the text).
-- @property markup_normal

--- Current day markup
-- @param[opt='<span foreground="'..beautiful.fg_focus..'" background="'..
--beautiful.bg_focus..'"><b>%s</b></span>'] nil|function|string A markup function, pattern
-- (string containing "%s" to use with `string.format`) or nil (does not change the text).
-- @property markup_focus

--- The month calendar encapsulating function.
--
-- Function that takes a widget as argument and returns another widget.
--
-- Default value: function (widget) return widget end
--
--@DOC_wibox_widget_calendar_fn_embed_month_EXAMPLE@
-- @param function Function to embed the month widget
-- @property fn_embed_month

--- The year calendar encapsulating function.
--
-- Function that takes a widget as argument and returns another widget.
--
-- Default value: function (widget) return widget end
--
-- see `fn_embed_month`.
-- @param function Function to embed the year widget
-- @property fn_embed_year

--- The year header cell encapsulating function.
--
-- Function that takes a widget as argument and returns another widget.
--
-- Default value: function (widget) return widget end
--
-- see `fn_embed_header`.
-- @param function Function to embed the year header cell
-- @property fn_embed_yearheader

--- The month header cell encapsulating function.
--
-- Function that takes a widget as argument and returns another widget.
--
-- Default value: function (widget) return widget end
--
--@DOC_wibox_widget_calendar_fn_embed_header_EXAMPLE@
-- @param function Function to embed the month header cell
-- @property fn_embed_header

--- The week days cell encapsulating function.
--
-- Function that takes a widget as argument and returns another widget.
--
-- Default value: function (widget) return widget end
--
-- see `fn_embed_header`.
-- @param function Function to embed the week days cells
-- @property fn_embed_weekdays

--- The week number cell encapsulating function.
--
-- Function that takes a widget as argument and returns another widget.
--
-- Default value: function (widget) return widget end
--
-- see `fn_embed_header`.
-- @param function Function to embed the week number cells
-- @property fn_embed_weeknumber

--- The normal day cell encapsulating function.
--
-- Function that takes a widget as argument and returns another widget.
--
-- Default value: function (widget) return widget end
--
-- see `fn_embed_header`.
-- @param function Function to embed the normal day cells
-- @property fn_embed_normal

--- The current day cell encapsulating function.
--
-- Function that takes a widget as argument and returns another widget.
--
-- Default value: function (widget) return widget end
--
-- see `fn_embed_header`.
-- @param function Function to embed the current day cells
-- @property fn_embed_focus


--- The current day calendar cell.
--
-- Function that takes a text and font as arguments and returns a widget.
--
-- Default value:
--
--    fn_yearheader_cell = function (text, font)
--        local markup = string.format(
--                      '<span foreground="%s" background="%s"><b>%s</b></span>',
--                      beautiful.fg_focus, beautiful.bg_focus, text)
--        local w = wibox.widget {
--            text = markup,
--            font = font,
--            align = 'right',
--            valign = 'center',
--            widget = wibox.widget.textbox
--        }
--        return w
--    end
--
-- see `fn_header_cell`.
-- @param function Function to create the current day cell widget
-- @property fn_focus_cell



-- Parse a date for the day, month and year
-- @tparam string date Date in the "%d %m %Y" format
-- @treturn {number,number,number} List of day, month, year (nil if undefined)
local function parse_date(date)
    -- Split a string by a given `separator`
    local function split(str, sep)
        local sep, fields = sep or ":", {}
        local pattern = string.format("([^%s]+)", sep)
        string.gsub(str, pattern, function(c) fields[#fields+1] = c end)
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


--- Make a textbox
-- @tparam string text Text of the textbox
-- @tparam string font Font of the text
-- @tparam boolean center Center the text horizontally
-- @treturn wibox.widget.textbox
local function make_cell(text, font, center)
    return base.make_widget_declarative {
        markup = text,
        align  = center and "center" or "right",
        valign = 'center',
        font   = font,
        widget = textbox
    }
end

--- Get default cell creation function
-- @tparam table props Widget properties
-- @tparam string flag Type of cell
-- @tparam string text Text to display in the cell
-- @treturn function
local function default_cell(props, flag, text)
    local markup = text
    local m = props["markup_"..flag]
    if type(m) == "function" then
        markup = m(text)
    elseif type(m) == "string" and string.find(m, "%s", 1, true) then
        markup = string.format(m, text)
    end
    local w = make_cell(markup, props.font, flag=="yearheader" or flag=="header")
    return props["fn_embed_"..flag](w)
end



--- Create a grid layout with the month calendar
-- @tparam table props Table of calendar properties
-- @tparam string date Date in the "%d %m %Y" format
-- @treturn widget Grid layout
local function create_month(props, date)
    local day, month, year = parse_date(date)
    local num_rows    = 8
    local num_columns = props.week_numbers and 8 or 7

    -- Create grid layout
    local layout = base.make_widget_declarative{
        layout      = grid,
        expand      = true,
        homogeneous = true,
        spacing     = props.spacing,
        forced_num_rows = num_rows,
        forced_num_cols = num_columns,
    }

    local start_row    = 3
    local start_column = num_columns - 6
    local week_start   = props.start_sunday and 1 or 2
    local d            = os.date("*t", os.time{year=year, month=month+1, day=0})
    local month_days   = d.day
    local column_day   = (d.wday - d.day + 1 - week_start ) % 7

    --local flags = {"header", "weekdays", "weeknumber", "normal", "focus"}
    local t, i, j, w, flag, text, markup

    -- Header
    flag = "header"
    t = os.time{year=year, month=month, day=1}
    text = os.date(props.hide_year and "%B" or "%B %Y", t)
    w = default_cell(props, flag, text)
    layout:add_widget_at(w, 1, 1, 1, num_columns)

    -- Week days
    i = 2
    for j = start_column, num_columns do  -- columns
        flag = "weekdays"
        t = os.time{year=2006, month=1, day=j-start_column+week_start}
        text = string.sub(os.date("%a", t), 1, 2)
        w = default_cell(props, flag, text)
        layout:add_widget_at(w, i, j, 1, 1)
    end

    -- Days
    i = start_row
    j = column_day + start_column
    local current_week = nil
    for d=1, month_days do
        if props.week_numbers then -- Week number
            t = os.time{year=year, month=month, day=d}
            text = os.date("%V", t)
            if tonumber(text) ~= current_week then
                flag = "weeknumber"
                w = default_cell(props, flag, text)
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
        w = default_cell(props, flag, text)
        layout:add_widget_at(w, i, j, 1, 1)

        -- find next cell
        i,j = layout:get_next_empty(i,j)
    end
    return props.fn_embed_month(layout)
end


--- Create a grid layout for the year calendar
-- @tparam table props Table of year calendar properties
-- @param date Year to display (number or string)
-- @treturn widget Grid layout
local function create_year(props, date)
    local _, _, year = parse_date(date)

    -- Create a grid widget with the 12 months
    local in_layout = base.make_widget_declarative{
        layout      = grid,
        expand      = true,
        homogeneous = true,
        spacing     = 2*props.spacing,
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
    local flag, text = "yearheader", string.format("%s", year)
    local year_header = default_cell(props, flag, text)
    local out_layout = base.make_widget_declarative{
        year_header,
        in_layout,
        spacing = 2*props.spacing, -- separate header from calendar grid
        layout  = vertical
    }
    return props.fn_embed_year(out_layout)
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


-- Set the calendar date
function calendar:set_date(date)
    if date and date ~= self._private.date then
        self._private.date = date
        self:emit_signal("widget::layout_changed")
    end
end


-- Build properties function
for _, prop in ipairs(properties) do
    -- setter
    if not calendar["set_" .. prop] then
        calendar["set_" .. prop] = function(self, value)
            if (string.sub(prop,1,3)=="fn_" and type(value) == "function") or self._private[prop] ~= value then
                self._private[prop] = value
                -- empty cache
                self._private.calendar_cache = {}
                self:emit_signal("widget::layout_changed")
            end
        end
    end
    -- getter
    if not calendar["get_" .. prop] then
        calendar["get_" .. prop] = function(self)
            return self._private[prop]
        end
    end
end

-- Override container functions
function calendar:get_children()
    fill_container(self, false)
    return self._private.container or {}
end

function calendar:set_children(...)
end

-- Layout widget
function calendar:layout(context, width, height)
    fill_container(self, true)
    if self._private.container then
        return { base.place_widget_at(self._private.container, 0, 0, width, height) }
    end
    return {}
end

-- Fit widget
function calendar:fit(context, width, height)
    fill_container(self, false)
    if self._private.container then
        return base.fit_widget(self, context, self._private.container, width, height)
    end
    return 0,0
end


--- Return a new calendar widget by type.
--
-- @tparam string t Type of the calendar, `year` or `month`
-- @tparam string date Date of the calendar
-- @tparam[opt="Monospace 10"] string font Font of the calendar
-- @treturn widget The calendar widget
local function get_calendar(t, date, font)
    args = args or {}
    if t ~= "month" and t ~= "year" then return end
    local ret = base.make_widget(nil, "calendar_"..t, {enable_properties = true})
    util.table.crush(ret, calendar, true)

    ret.type = t
    ret._private.calendar_cache = {}

    -- default values
    ret._private.date = date
    ret._private.font = font or beautiful.calendar_font or "Monospace 10"

    ret._private.spacing      = beautiful.calendar_spacing or 5
    ret._private.week_numbers = beautiful.calendar_week_numbers or false
    ret._private.start_sunday = beautiful.calendar_start_sunday or false
    ret._private.hide_year    = t == "year" and true or false

    local containers = { "year", "month", "yearheader", "header", "weekdays", "weeknumber", "normal", "focus" }
    for _, flag in pairs(containers) do
        ret._private["fn_embed_" .. flag] = function (w) return w end
    end
    ret._private.markup_focus = string.format('<span foreground="%s" background="%s"><b>%s</b></span>', 
                                    beautiful.fg_focus, beautiful.bg_focus, "%s")

    return ret
end

--- A month calendar widget.
--
-- A calendar widget is a grid containing the calendar for one month.
-- If the day is specified in the date, its cell is highlighted.
--
--@DOC_wibox_widget_calendar_month_EXAMPLE@
-- @tparam string date Date of the calendar
-- @tparam[opt="Monospace 10"] string font Font of the calendar
-- @treturn widget The month calendar widget
-- @function wibox.widget.calendar.month
function calendar.month(date, font)
    return get_calendar("month", date, font)
end

--- A year calendar widget.
--
-- A calendar widget is a grid containing the calendar for one year.
--
--@DOC_wibox_widget_calendar_year_EXAMPLE@
-- @tparam string date Date of the calendar
-- @tparam[opt="Monospace 10"] string font Font of the calendar
-- @treturn widget The year calendar widget
-- @function wibox.widget.calendar.year
function calendar.year(date, font)
    return get_calendar("year", date, font)
end


function calendar.mt:__call(caltype, ...)
    return get_calendar(caltype, ...)
end

return setmetatable(calendar, calendar.mt)
