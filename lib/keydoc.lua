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
    color_group  = "#b9214f",   -- red
    color_keys   = "#77DFD8",   -- cyan
    color_doc    = "#E0E0D1",   -- white
    font = "DejaVu Sans Mono 10"
}

local function get_styles(styles)
	local styles = styles or settings or {}
    local res = {
		color_group = styles.color_group or settings.color_group or beautiful.keydoc_color_group or "#b9214f",   -- red
		color_keys  = styles.color_keys or settings.color_keys or beautiful.keydoc_color_keys or "#77DFD8",    -- cyan
		color_doc   = styles.color_doc or settings.color_doc or beautiful.keydoc_color_doc or "#E0E0D1",      -- white
		font = styles.font or settings.font or "DejaVu Sans Mono 10"
	}
	return res
end


local doc = { }
local currentgroup = "Misc"
local orig = awful.key.new

-- Replacement for awful.key.new
local function new(mod, key, press, release, docstring)
   -- Usually, there is no use of release, let's just use it for doc
   -- if it's a string.
   if press and release and not docstring and type(release) == "string" then
      docstring = release
      release = nil
   end
   local k = orig(mod, key, press, release)
   -- Remember documentation for this key (we take the first one)
   if k and #k > 0 and docstring then
      doc[k[1]] = { help = docstring,
		    group = currentgroup }
   end

   return k
end
awful.key.new = new		-- monkey patch

-- Turn a key to a string
local function key2str(key)
    local sym = key.key or key.keysym
    local translate = {
        ["#14"] = "#",
        [" "] = "Space",
    }
    sym = translate[sym] or sym
    if not key.modifiers or #key.modifiers == 0 then return sym end
    local result = ""
    local translate = {
        ['Mod4'] = "⊞",
        ['Mod1'] = "Alt",
        ['Shift']    = "⇧",
        ['Control']  = "Ctrl",
    }
    for _, mod in pairs(key.modifiers) do
        mod = translate[mod] or mod
        result = result .. mod .. " + "
    end
    return result .. sym
end

-- Unicode "aware" length function (well, UTF8 aware)
-- See: http://lua-users.org/wiki/LuaUnicode
local function unilen(str)
   local _, count = string.gsub(str, "[^\128-\193]", "")
   return count
end

-- Start a new group
function group(name)
   currentgroup = name
   return {}
end

local function markup(keys)
    local styles = get_styles()
    local result = {}
    
    -- Compute longest key combination
    local longest = 0
    for _, key in ipairs(keys) do
        if doc[key] then
            longest = math.max(longest, unilen(key2str(key)))
        end
    end
    
    local curgroup = nil
    for _, key in ipairs(keys) do
        if doc[key] then
            local help, group = doc[key].help, doc[key].group
            local skey = key2str(key)
            result[group] = (result[group] or "") ..
                        string.format('<span font="%s"', styles.font) .. string.format(' color="%s"> ', styles.color_doc) ..
                        string.format("%" .. (longest - unilen(skey)) .. "s  ", "") .. skey ..
                        '</span>  <span color="' .. styles.color_keys .. '">' .. 
                        help .. '</span>\n'
        end
    end
    return result
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

-- Display help in a naughty notification
local nid = nil
function display()
    local s = capi.mouse.screen
    local styles = get_styles()
    local strings = markup(awful.util.table.join(
        capi.root.keys(),
        capi.client.focus and capi.client.focus:keys() or {}))

    local result = ""
    for group, res in spairs(strings) do
        if #result > 0 then result = result .. "\n" end
        result = result ..
            '<span weight="bold" color="' .. styles.color_group .. '">' ..
            group .. "</span>\n" .. res
    end

    nid = naughty.notify({ text = result,
			replaces_id = nid,
			hover_timeout = 0.1,
			timeout = 30,
            screen = s}).id
end

local keydoc =
{
    settings = settings,
    display  = display,
    group    = group
}
return keydoc
