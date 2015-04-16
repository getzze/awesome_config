local awful         = require("awful")


local capi = {
    screen = screen,
    client = client,
    mouse  = mouse
}


-- {{{ Find tags (from https://github.com/pw4ever/awesome-wm-config/)
--name2tags: matches string 'name' to tag objects
--@param name: tag name to find
--@param scr: screen to look for tags on
--@return table of tag objects or nil
local function name2tags(name, scr)
    local ret = {}
    local a, b = scr or 1, scr or capi.screen.count()
    for s = a, b do
        for _, t in ipairs(awful.tag.gettags(s)) do
            if name == t.name then
                table.insert(ret, t)
            end
        end
    end
    if #ret > 0 then return ret end
end

local function find_tag(name, scr)
    local ts = name2tags(name, scr)
    if ts then return ts[idx or 1] end
end

-- Launch program if tag not already opened
local function raise_or_new_tag(name, cmd, all_screens)
    local all_screens = all_screens
    local function fun()
        local scr = nil
        if not all_screens then
            scr = capi.mouse.screen
        end
        local tag = find_tag(name, scr)
        if tag then
            awful.tag.viewonly(tag)
            awful.screen.focus(awful.tag.getscreen(tag))
        else
            awful.util.spawn(cmd)
        end
    end
    return fun
end

-- Start program if not running already from pgrep command
function run_once(prg, arg_string, pname, screen)
    if not prg then
        do return nil end
    end

    if not pname then
       pname = prg
    end

    if not arg_string then 
        --awful.util.spawn_with_shell("pgrep -u $USER -f '" .. pname .. "' || (" .. prg .. ")", screen)
        awful.util.spawn_with_shell("pgrep -u $USER -x '" .. pname .. "' || (" .. prg .. ")", screen)
    else
        awful.util.spawn_with_shell("pgrep -u $USER -x '" .. pname .. "' || (" .. prg .. " " .. arg_string .. ")", screen)
    end
end


return {
    run_once = run_once,
    raise_or_new_tag = raise_or_new_tag
}
