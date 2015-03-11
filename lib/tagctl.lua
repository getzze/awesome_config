local awful     = require("awful")
local naughty   = require("naughty")
local beautiful = require("beautiful")

local capi = {
    client = client,
    mouse  = mouse,
    tag    = tag
}

-- from https://github.com/pw4ever/awesome-wm-config
-- some of the routines are inspired by Shifty (https://github.com/bioe007/awesome-shifty.git)
-- taglist: table of awful.widget.taglist by screen
-- prompt: table of awful.widget.prompt by screen
local settings = {
    taglist = {},
    prompt  = {}
}

-- Call this function in rc.lua to be able to rename tags inplace, without prompt
function set_taglist(taglist)
    settings.taglist = taglist
end

-- Call this function in rc.lua to be able to rename tags with the prompt
function set_prompt(prompt)
    settings.prompt = prompt
end

--@param tag: tag object to be moved
--@param idx: int; relative or absolute tag number
--@param rel_move: boolean; if true, idx is the relative index, otherwise absolute
function move_tag(tag, idx, rel_idx)
    if tag then 
        local s = awful.tag.getscreen(tag)
        local tag_idx = awful.tag.getidx(tag)
        local tags = awful.tag.gettags(s)
        local ind
        if rel_idx then
            ind = tag_idx + idx
        else
            ind = idx
        end
        local target = awful.util.cycle(#tags, ind)
        awful.tag.move(target, tag)
        awful.tag.viewonly(tag)
    end
end

-- @param prompt: a awful.widget.prompt() object
local function rename_tag_prompt(tag, prompt)
    naughty.notify({ text="Rename tag prologue" , screen = capi.mouse.screen })
    local s = capi.mouse.screen
    local t = tag or awful.tag.selected(s)
    if not t then return end
    naughty.notify({ text="Rename tag. Tag?" , screen = capi.mouse.screen })
    local p = prompt or settings.prompt
    if not p then 
        naughty.notify({ text=print(settings) , screen = capi.mouse.screen })
        return
    end
    naughty.notify({ text="Rename tag. Prompt?" , screen = capi.mouse.screen })

    local textbox = p[s].widget
    awful.prompt.run(
            { prompt = "New tag name: " },
            textbox,
            function(new_name)
                if not new_name or #new_name == 0 then
                    return
                else
                    t.name = new_name
                end
            end)
end

local function rename_tag_inplace(tag, taglist)
    local s = capi.mouse.screen
    local t = tag or awful.tag.selected(s)
    if not t then return end
    local tagl = taglist or settings.taglist
    if not tagl then return end

    local theme = beautiful.get()
    if t == awful.tag.selected(s) then
        local bg = theme.bg_focus or '#535d6c'
    else
        local bg = theme.bg_normal or '#222222'
    end
    local fg = theme.fg_urgent or '#ffffff'

    local textbox = tagl[s].widgets[awful.tag.getidx(t)].widget.widgets[2].widget
    awful.prompt.run({fg_cursor = fg, bg_cursor = bg,
                ul_cursor = "single",
                text = t.name,
                selectall = true},
        -- taglist internals -- found with the debug code above
        textbox,
        function (name)
            t.name = name;
        end)
end

-- @param prompt: 
local function add_tag_prompt(prompt)
    local s = capi.mouse.screen
    local p = prompt or settings.prompt
    if not p then return end

    local props = {selected = true}

    local textbox = p[s].widget
    awful.prompt.run(
            { prompt = "New tag name: " },
            textbox,
            function(new_name)
                if not new_name or #new_name == 0 then
                    return
                else
                    new_t = awful.tag.add(new_name, props)
                    awful.tag.viewonly(new_t)
                end
            end)
end

-- @param prompt: 
local function add_tag_inplace(taglist)
    local s = capi.mouse.screen
    local tagl = taglist or settings.taglist
    if not tagl then return end

    local props = {selected = true}

    new_t = awful.tag.add(" ", props)
    rename_tag_inplace(new_t, tagl)
    if not new_t.name or #(new_t.new_name) == 0 then
        awful.tag.delete(new_t)
    else
        awful.tag.viewonly(new_t)
    end
end

local function list_tags()
    local s = capi.mouse.screen
    local ret = {}
    for i, t in ipairs(awful.tag.gettags(s)) do
        ret[i] = t.name
    end
    return ret
end

-- i is the index of target tag in variable `tags'
local function swap_tags(tag1, tag2)
   local s = capi.mouse.screen
   --local from = capi.client.focus:tags()[1]
   --local to = tags[screen][i]
   if tag1 and tag2 then
        t = tag2:clients()
        for i, c in ipairs(tag1:clients()) do
            awful.client.movetotag(tag2, c)
        end
        for i, c in ipairs(t) do
            awful.client.movetotag(tag1, c)
        end
        --rename
        local name1 = tag1.name
        tag1.name = tag2.name
        tag2.name = name
   end
end


function delete()
    awful.tag.delete()
end

function add(prompt)
    add_tag_prompt(prompt)
end

function rename(prompt)
    rename_tag_prompt(nil, prompt)
end


local tagctl =
{
    settings    = settings,
    delete      = delete,
    add         = add,
    rename      = rename,
    set_taglist = set_taglist,
    set_prompt  = set_prompt
}
return tagctl
