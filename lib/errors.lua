local naughty = require("naughty")

local capi = { awesome = awesome }

--- If the plugin does not work, copy its content(after this comment and without the last line) in your rc.lua


-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if capi.awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = capi.awesome.startup_errors })
end
-- Handle runtime errors after startup
do
    local in_error = false
    capi.awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end

return {}
