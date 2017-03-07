local awful         = require("awful")


local capi = { screen = screen }


-- Launch program if tag not already opened
local function raise_or_new_tag(name, cmd, all_screens)
    local all_screens = all_screens
    local function fun()
        local t = nil
        if not all_screens then
            t = awful.tag.find_by_name(awful.screen.focused(), name)
        else
            for s in capi.screen do
                t = awful.tag.find_by_name(s, name)
                if t then break end
            end
        end
        
        if t then
            awful.screen.focus(t.screen)
            t:view_only()
        else
            awful.spawn(cmd)
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
    -- Move to screen
    screen = screen or awful.screen.focused()
    awful.screen.focus(screen)
    local cmd = prg
    if arg_string then
        cmd = cmd .. " " .. arg_string
    end
    --awful.spawn.with_shell("pgrep -u $USER -f '" .. pname .. "' || (" .. prg .. ")")
    awful.spawn.with_shell("pgrep -u $USER -x '" .. pname .. "' >/dev/null || (" .. cmd .. ")")
end

-- Synchronous call of `cmd`
local function pread(cmd)
    -- Very bad, synchronous, but nothing better was found
    if cmd and cmd ~= "" then
        local f, err = io.popen(cmd, 'r')
        if f then
            local s = f:read("*all")
            f:close()
            return s
        else
            return err
        end
    end
end

require("lfs") 
-- Check runing processes
local function processwalker()
   local function yieldprocess()
      for dir in lfs.dir("/proc") do
        -- All directories in /proc containing a number, represent a process
        if tonumber(dir) ~= nil then
          local f, err = io.open("/proc/"..dir.."/cmdline")
          if f then
            local cmdline = f:read("*all")
            f:close()
            if cmdline ~= "" then
              coroutine.yield(cmdline)
            end
          end
        end
      end
    end
    return coroutine.wrap(yieldprocess)
end

-- Run once using lua-filesystem
function run_once_lua(process, cmd)
   assert(type(process) == "string")
   local regex_killer = {
      ["+"]  = "%+", ["-"] = "%-",
      ["*"]  = "%*", ["?"]  = "%?" }

   for p in processwalker() do
      if p:find(process:gsub("[-+?*]", regex_killer)) then
	 return
      end
   end
   return awful.spawn(cmd or process)
end

-- Run DesktopEntry 
function xrun()
    awful.spawn.easy_async("xrdb -query", 
        function(stdout, stderr, reason, exit_code) 
            local xresources_name = "awesome.started"
            if not stdout:match(xresources_name) then
                -- Execute once for X server
                awful.spawn("dex -a -e Awesome")
            end
            awful.spawn.with_shell("xrdb -merge <<< " .. "'" .. xresources_name .. ": true'")
        end
    )
end

return {
    pread = pread,
    xrun = xrun,
    run_once = run_once,
    run_once_lua = run_once_lua,
    raise_or_new_tag = raise_or_new_tag
}
