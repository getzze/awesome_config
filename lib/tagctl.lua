local awful     = require("awful")

local tagctl = { prompt = nil , mt = {} }

function tagctl.get_prompt()
    return tagctl.prompt or awful.screen.focused().mypromptbox
end

-- @param tag: a awful.tag object
function tagctl.rename(tag)
    awful.prompt.run {
        prompt       = "New tag name: ",
        textbox      = tagctl.get_prompt().widget,
        exe_callback = function(new_name)
            if not new_name or #new_name == 0 then return end

            local t = tag or awful.screen.focused().selected_tag
            if t then t.name = new_name end
        end
    }
end

-- @param prompt: 
function tagctl.add()
    local s = awful.screen.focused()

    local props = {selected = true, volatile=true, screen=s}

    awful.prompt.run {
        prompt       = "New tag name: ",
        textbox      = tagctl.get_prompt().widget,
        exe_callback = function(new_name)
            if not new_name or #new_name == 0 then return end
            awful.tag.add(new_name, props):view_only()
        end
    }
end

-- @param tag: a awful.tag object
function tagctl.delete(tag)
    local t = tag or awful.screen.focused().selected_tag
    if not t then return end
    t:delete()
end


--@param ... table of tags to permute
function tagctl.permute(...)
    local args = { n=select('#', ...), ... }
    if args.n == 0 then
        args = awful.screen.focused().selected_tags
        args.n = #args
    end
    if args.n < 2 then return end -- need at least two tags to permute
    for i=2, args.n do
       args[i]:swap(args[i-1])
    end
end

return tagctl
