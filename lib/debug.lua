local awful         = require("awful")
local naughty       = require("naughty")
local getmetatable  = getmetatable
local beautiful     = require("beautiful")

local capi = {
    client = client,
    mouse  = mouse
}

local colors = {
    name   = beautiful.keydoc_color_keys or "#77DFD8",    -- cyan
    doc    = beautiful.keydoc_color_doc or "#E0E0D1",      -- white
    header = beautiful.keydoc_color_group or "#b9214f",   -- red
    count  = beautiful.fg_widget_label or "#E0E0D1",   -- white
    index  = beautiful.fg_widget_label or "#A6E22E"   -- green
}

local settings = {
    left_align = false,  -- true for a left alignment, false for a right alignement
    font = "DejaVu Sans Mono 8"
}

local function client_info(c)
    local v = ""

    -- object
    local c = c or capi.client.focus
    v = v .. tostring(c)

    -- geometry
    local cc = c:geometry()
    local signx = (cc.x > 0 and "+") or ""
    local signy = (cc.y > 0 and "+") or ""
    v = string.format('<span color="%s">', colors.header) .. v .. " @ " .. cc.width .. 'x' .. cc.height .. signx .. cc.x .. signy .. cc.y .. "</span>\n\n"

    local aw_inf = {
        "overwrite_class"
    }
    local inf = {
        "name", "icon_name", "type", "class", "role", "instance", "pid",
        "skip_taskbar", "id", "group_window", "leader_id", "machine",
        "screen", "hidden", "minimized", "size_hints_honor", "titlebar", "urgent",
        "focus", "opacity", "ontop", "above", "below", "fullscreen", "transient_for",
        "maximixed_horizontal", "maximixed_vertical", "sticky", "modal", "focusable"
    }
    
    local longest = 0
    for _, key in ipairs(inf) do
        longest = math.max(longest, string.len(key))
    end
    for _, key in ipairs(aw_inf) do
        longest = math.max(longest, string.len(key))
    end
    ---- Make table with client informations
    
    local alignement = ''
    if settings.left_align then
        alignement = '-'
    else
        alignement = '+'
    end
    
    awful.client.property.get(c, "overwrite_class")

    for i = 1, #aw_inf do
        local prop = awful.client.property.get(c, aw_inf[i])
        v = v .. '<span color="' .. colors.name .. '">' .. string.format('%' .. alignement .. longest .. 's', aw_inf[i]) .. 
                string.format('</span> = <span color="%s">%s</span>\n', colors.doc, prop)
    end
    for i = 1, #inf do
        local prop = tostring(c[inf[i]])
        v = v .. '<span color="' .. colors.name .. '">' .. string.format('%' .. alignement .. longest .. 's', inf[i]) .. 
                string.format('</span> = <span color="%s">%s</span>\n', colors.doc, prop)
    end
    text = string.format('<span font="%s">%s</span>', settings.font, v:sub(1, #v-1))

    naughty.notify{ text = text, timeout = 0, margin = 10, screen = c.screen }
end

local function dbg_get(var, depth, indent)
    local a = ""
    local text = ""
    local name = ""
    local vtype = type(var)
    local vstring = tostring(var)
    
    if vtype == "table" or vtype == "userdata" then
        if vtype == "userdata" then var = getmetatable(var) end
        -- element count and longest key
        local count = 0
        local longest_key = 3
        for k,v in pairs(var) do
            count = count + 1
            longest_key = math.max(#tostring(k), longest_key)
        end
        text = text .. vstring .. " <span color='"..colors.count.."'>#" .. count .. "</span>"
        -- descend a table
        if depth > 0 then
            -- sort keys FIXME: messes up sorting number
            local sorted = {}
            for k, v in pairs(var) do table.insert(sorted, { k, v }) end
            table.sort(sorted, function(a, b) return tostring(a[1]) < tostring(b[1]) end)
            -- go through elements
            for _, p in ipairs(sorted) do
                local key = p[1]; local value = p[2]
                -- don't descend _M
                local d; if key ~= "_M" then d = depth - 1 else d = 0 end
                -- get content and add to output
                local content = dbg_get(value, d, indent + longest_key + 1)
                text = text .. '\n' .. string.rep(" ", indent) ..
                    string.format("<span color='"..colors.index.."'>%-"..longest_key.."s</span> %s",
                                    tostring(key), content)
            end
        end
    else
        if vtype == "tag" or vtype == "client" then
            name = " [<span color='"..colors.name.."'>" .. var.name:sub(1,10) .. "</span>]"
        end
        text = text .. vstring .. name or ""
    end
    
    return text
end

local function info(...)
    local num = table.maxn(arg)
    local text = "<span color='"..colors.header.."'>dbg</span> <span color='"..colors.count.."'>#"..num.."</span>"
    local depth = 2
    local clients = 0
   
    for i = 1, num do
        local desc = dbg_get(arg[i], depth, 3)
        text = text .. string.format("\n<span color='"..colors.index.."'>%2d</span> %s", i, desc)
        if type(arg[i]) == "client" then
            client_info(arg[i])
            clients = clients + 1
        end
    end
    -- Display only if we don't have only clients to be displayed
    if clients ~= num then
        naughty.notify{ text = text, timeout = 0, hover_timeout = 2, screen = screen.count() }
    end
end

-- Simple function to load additional LUA files from rc/.
-- from https://raw.githubusercontent.com/vincentbernat/awesome-configuration
function loadrc(name, mod)
    local success
    local result
   
    -- Which file? In rc/ or in lib/?
    local path = awful.util.getdir("config") .. "/" ..
            (mod and "lib" or "rc") .. "/" .. name .. ".lua"
    
    -- If the module is already loaded, don't load it again
    if mod and package.loaded[mod] then return package.loaded[mod] end
   
    -- Execute the RC/module file
    success, result = pcall(function() return dofile(path) end)
    if not success then
        naughty.notify({ title = "Error while loading an RC file",
	  	        text = "When loading `" .. name ..
                        "`, got the following error:\n" .. result,
	  	        preset = naughty.config.presets.critical })
        return print("E: error loading RC file '" .. name .. "': " .. result)
    end
   
    -- Is it a module?
    if mod then
        return package.loaded[mod]
    end
   
    return result
end

-- Compatibility layer to load Lua code from prompt
local function load_code(code, environment)
    if setfenv and loadstring then
        local f, err = loadstring("return "..code)
        if not f then
            f, err = loadstring(s);
        end
        setfenv(f, environment)
        return f, err
    else    -- Lua > 5.2
        local f, err = load("return "..code, nil, "t", environment)
        if not f then
            f, err = load(code, nil, "t", environment)
        end
        return f, err
    end
end

function lua_eval(s)
    local context = {}        -- create new environment
    setmetatable(context, {__index = _G})
    local f, err = load_code(s, context)

	if f then
		local ret = { pcall(f) };
		if ret[1] then
			-- Ok
			table.remove(ret, 1)
			local highest_index = #ret;
			for k, v in pairs(ret) do
				if type(k) == "number" and k > highest_index then
					highest_index = k;
				end
				ret[k] = select(2, pcall(tostring, ret[k])) or "<no value>";
			end
			-- Fill in the gaps
			for i = 1, highest_index do
				if not ret[i] then
					ret[i] = "nil"
				end
			end
			if highest_index > 0 then
				naughty.notify({ title=">>> "..s, text = awful.util.escape(">: "..tostring(table.concat(ret, ", "))) , screen = capi.mouse.screen });
                --mypromptbox[capi.mouse.screen].text = awful.util.escape("Result"..(highest_index > 1 and "s" or "")..": "..tostring(table.concat(ret, ", ")));
			else
                naughty.notify({ title=">>> "..s, text=">: " , screen = capi.mouse.screen });
				--mypromptbox[capi.mouse.screen].text = "Result: Nothing";
			end
		else
			err = ret[2];
		end
	end
	if err then
        naughty.notify({ title=">>> "..s, text=awful.util.escape(">: [Error] "..tostring(err)) , screen = capi.mouse.screen })
		--mypromptbox[capi.mouse.screen].text = awful.util.escape("Error: "..tostring(err));
	end
end

function lua_completion (line, cur_pos, ncomp)
    -- Only complete at the end of the line, for now
    if cur_pos ~= #line + 1 then
        return line, cur_pos
    end
    
    -- We're really interested in the part following the last (, [, comma or space
    local lastsep = #line - (line:reverse():find('[[(, ]') or #line)
    local lastidentifier
    if lastsep ~= 0 then
        lastidentifier = line:sub(lastsep + 2)
    else
        lastidentifier = line
    end
    
    local environment = _G
    
    -- String up to last dot is our current environment
    local lastdot = #lastidentifier - (lastidentifier:reverse():find('.', 1, true) or #lastidentifier)
    if lastdot ~= 0 then
        -- We have an environment; for each component in it, descend into it
        for env in lastidentifier:sub(1, lastdot):gmatch('([^.]+)') do
            if not environment[env] then
                -- Oops, no such subenvironment, bail out
                return line, cur_pos
            end
            environment = environment[env]
        end
    end
    
    local tocomplete = lastidentifier:sub(lastdot + 1)
    if tocomplete:sub(1, 1) == '.' then
        tocomplete = tocomplete:sub(2)
    end
    
    local completions = {}
    for k, v in pairs(environment) do
        if type(k) == "string" and k:sub(1, #tocomplete) == tocomplete then
            table.insert(completions, k)
        end
    end
    
    if #completions == 0 then
        return line, cur_pos
    end
    
    while ncomp > #completions do
        ncomp = ncomp - #completions
    end
    
    local str = ""
    if lastdot + lastsep ~= 0 then
        str = line:sub(1, lastsep + lastdot + 1)
    end
    str = str .. completions[ncomp]
    cur_pos = #str + 1
    return str, cur_pos
end

-- @param prompt: a awful.widget.prompt() object
function lua_prompt(prompt)
    local textbox = prompt.widget
    local function f ()
        awful.prompt.run({ prompt = "Run Lua code: " },
            textbox,
            lua_eval,
            lua_completion,
            awful.util.getdir("cache") .. "/history_eval")
    end
    return f
end

local dbg =
{
    settings    = settings,
    colors      = colors,
    loadrc      = loadrc,
    --info        = info,
    lua_prompt  = lua_prompt,
    client_info = client_info
}
return dbg
