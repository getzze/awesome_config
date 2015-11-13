-- Document key bindings

local awful     = require("awful")
local table     = table
local ipairs    = ipairs
local pairs     = pairs
local math      = math
local string    = string
local type      = type
local beautiful = require("beautiful")
local naughty   = require("naughty")

local capi      = {
   root   = root,
   client = client,
   mouse  = mouse
}

local settings = {
    color_keys   = "#E0E0D1",   -- white
    color_mods   = "#E0E0D1",   -- white
    color_doc    = "#77DFD8",   -- cyan
    font = "DejaVu Sans Mono 10",
    width = 72,
    hide_without_description = true,
    default_group = "Misc",
    nil
}

local function get_styles(styles)
	local styles = styles or {}
    local res = {
		color_group = styles.color_group or settings.color_group or beautiful.keydoc_color_group or "#b9214f",   -- red
		color_keys  = styles.color_keys or settings.color_keys or beautiful.keydoc_color_keys or "#E0E0D1",    -- white
		color_mods  = styles.color_mods or settings.color_mods or beautiful.keydoc_color_mods or "#E0E0D1",    -- white
		color_doc   = styles.color_doc or settings.color_doc or beautiful.keydoc_color_doc or "#77DFD8",      -- cyan
		font = styles.font or settings.font or "DejaVu Sans Mono 10",
		width = styles.font or settings.font or 72,
        hide_without_description = styles.hide_without_description or settings.hide_without_description or true,
        default_group = styles.default_group or settings.default_group or "Misc",
        nil
	}
	return res
end


--local doc = { }
local hotkeys = {}
local orig = awful.key.new
local current_group = get_styles().default_group
cached_awful_keys = {}

-- Start a new group
function group(name)
   currentgroup = name
   return {}
end

-- Replacement for awful.key.new
local function new(_mod, key, press, release, data)
    -- Usually, there is no use of release, let's just use it for doc
    -- if it's a string.
    if press and release and not data and (type(release)=='table' or type(release)=='string') then
        data = release
        release = nil
    end
    if type(data)=='string' then
        data = {description=data, group=currentgroup}
    end

    local k = orig(_mod, key, press, release)

    local hide_empty = get_styles().hide_without_description
    -- Append documentation for this key
    if not hide_empty or (k and #k > 0 and data) then
        data.modifiers = _mod
        data.key = key
        table.insert(hotkeys, data)
    end
    return k
end
awful.key.new = new		-- monkey patch



-- Turn a keysym to a string
local function sym2str(sym)
    local translate = {
        ["#14"] = "#",
        [" "] = "Space",
    }
    sym = translate[sym] or sym
    return sym
end

-- Turn a modifier to a string
local function mod2str(mods)
    local result = ""
    if not mods or #mods == 0 then return result end
    local translate = {
        ['Mod4'] = "⊞",
        ['Mod1'] = "Alt",
        ['Shift']    = "⇧",
        ['Control']  = "Ctrl",
    }
    for _, mod in pairs(mods) do
        mod = translate[mod] or mod
        result = result .. mod .. " + "
    end
    return result
end

-- Turn a key to a string
local function key2str(key)
    local sym = key.key or key.keysym
    sym = sym2str(sym)

    if not key.modifiers or #key.modifiers == 0 then return sym end
    _mod = mod2str(key.modifiers)

    return _mod .. sym
end


-- Unicode "aware" length function (well, UTF8 aware)
-- See: http://lua-users.org/wiki/LuaUnicode
local function unilen(str)
   local _, count = string.gsub(str, "[^\128-\193]", "")
   return count
end

function linewrap(text, width, indent)
    local styles = get_styles()

    text = text or ""
    width = width or styles.width
    indent = indent or 0
 
    local pos = 1
    return text:gsub("(%s+)()(%S+)()",
        function(sp, st, word, fi)
            if fi - pos > width then
                pos = st
                return "\n" .. string.rep(" ", indent) .. word
            end
        end)
end

local markup = {}
function markup.font(font, text)
    return string.format('<span font="%s">', font) .. text .. '</span>'
end

function markup.keys(keys, longest)
    local styles = get_styles()

    local result = ""
    for _, key in ipairs(keys) do
        local string_key, string_mods, desc = key.key, key.mods, key.desc
        local space = string.format("%" .. (longest-unilen(string_key)-unilen(string_mods)) .. "s", "")
        result = result .. 
                string.format('<span font="%s" color="%s">', styles.font, styles.color_mods) .. space .. string_mods .. '</span>' ..
                string.format('<span font="%s" color="%s">', styles.font, styles.color_keys) .. string_key .. '</span>' ..
                string.format('<span color="%s">', styles.color_doc) .. ' ' .. desc .. '</span>\n'
    end
    return result
end


local function add_hotkey(data, target)
    local styles = get_styles()
    if styles.hide_without_description and not data.description then return end

    local group = data.group or styles.default_group
    --group_list[group] = true
    if not target[group] then target[group] = {} end
    table.insert(
        target[group],
        {key=sym2str(data.key), mods=mod2str(data.modifiers), desc=data.description}
    )
end

-- Generate a table sorted by key groups from awful.keys
local function import_awful_keys()
    cached_awful_keys = {}
    for _, data in pairs(hotkeys) do
        add_hotkey(data, cached_awful_keys)
    end
    table.sort(cached_awful_keys)
    --sort_hotkeys(cached_awful_keys)
end

local function awful_keys()
    if #cached_awful_keys > 0 then
        return cached_awful_keys
    end
    import_awful_keys()
    return cached_awful_keys
end

-- Customize version of standard function pairs that sort keys
-- (from Michal Kottman on Stackoverflow)
function spairs(t, order)
	-- collect the keys
	local keys = {}
	for k in pairs(t) do keys[#keys+1] = k end

	-- if order function given, sort by it by passing the table and keys a, b,
	-- otherwise just sort the keys 
	if order then
		table.sort(keys, function(a,b) return order(t, a, b) end)
	else
		table.sort(keys)
	end

	-- return the iterator function
	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end

function get_group_dimension(keys)
    local height = #keys
    -- Compute width, i.e. longest key combination
    local width = 0
    local width_key = 0
    for _, key in ipairs(keys) do
        k = unilen(key.key) + unilen(key.mods)
        l = k + unilen(key.desc or "")
        width_key = math.max(width_key, k)
        width = math.max(width, l)
    end
    return {height=height, width=width, width_key=width_key}
end

function get_dimension(_table)
    local height = 0
    local width = 0
    local width_key = 0
    for group, keys in spairs(_table) do
        dim = get_group_dimension(keys)
        h, w, l = dim.height, dim.width, dim.width_key
        
        if height > 0 then
            height = height + 1  -- space between groups, after first group
        end
        height = height + 1 + h  -- one extra line for group name
        
        width = math.max(width, w)
        width_key = math.max(width_key, l)
    end
    return {height=height, width=width, width_key=width_key}
end


-- Display help in a naughty notification
local nid = nil
function display()
    local s = capi.mouse.screen
    local styles = get_styles()
    table_keys = awful_keys()

    dim = get_dimension(table_keys)
    height, width, longest = dim.height, dim.width, dim.width_key
    -- TO DO
    -- Compute real height and width in pixel to properly cut the hotkeys text in columns and rows

    local text = ""
    for group, keys in spairs(table_keys) do
        if #text > 0 then text = text .. "\n" end   -- insert empty line before new group (except for the first one)
        text = text .. string.format('<span weight="bold" color="%s">' , styles.color_group) .. group .. "</span>\n"
        text = text .. markup.keys(keys, longest)
    end

    nid = naughty.notify({ text = text,
			replaces_id = nid,
			--hover_timeout = 0.1,
			timeout = 30,
            screen = s}).id
end

local keydoc =
{
    settings     = settings,
    display      = display,
    group        = group
}
return keydoc
