-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget

local extra = {object={}}
local modkey = "Mod4"

local deficient = require("deficient")
-- revelation: expose
local revelation = require("revelation")

local attention = require("./attentive")

extra.init = function(taglist_buttons)
  revelation.init()
  attention.init()
end

local filter_noempty = awful.widget.taglist.filter.noempty
function filter_tags_for_taglist(t)
  local in_activity = awful.tag.selected(1).activity_i == t.activity_i
  local is_head = t.gindex % 11 == 1
  local is_renamed_head = (t.name ~= ("F" .. t.activity_i)) and is_head
  local is_notempty = filter_noempty(t)
  return is_renamed_head or (is_head or in_activity) and is_notempty
  --local is_first_of_non_empty_activity = false
  -- FIXME too slow and borken
  --if t.gindex % 11 == 1 then
  --  for i = 1, 10 do
  --    local thistag = t.screen.tags[t.gindex+i]
  --    if awful.widget.taglist.filter.noempty(thistag) then
  --      is_first_of_non_empty_activity = true
  --      break
  --    end
  --  end
  --end
  -- return (notempty and in_activity) or is_first_of_non_empty_activity
end

extra.create_taglist = function(s, taglist_buttons)
  s.mytaglist = awful.widget.taglist(s, filter_tags_for_taglist, taglist_buttons)
end

extra.create_wibox = function(s)
  s.mywibox = awful.wibar({ position = "top", screen = s, height = 16 })
end

-- {{{ Miscellaneous helpers for keybindings
extra.spawn = function(cmd, sn)
  return function ()
    awful.spawn(cmd, sn)
  end
end

extra.spawn_once = function(cmd)
  return function ()
    awful.util.spawn("run_once " .. cmd)
  end
end

extra.shellcmd = function(cmd, sn)
  return function ()
    awful.util.spawn_with_shell(cmd, sn)
  end
end

volnotify = {}
volnotify.id = nil
function volnotify:notify (msg)
    self.id = naughty.notify({ text = msg, timeout = 1, replaces_id = self.id}).id
end

extra.increaseVolume = function()
  awful.util.spawn("pamixer --allow-boost -i 1")
  extra.showVolume()
end

extra.decreaseVolume = function()
  awful.util.spawn("pamixer --allow-boost -d 1")
  extra.showVolume()
end

extra.increaseBrightness = function()
  awful.util.spawn("brightnessctl s +5%")
end

extra.decreaseBrightness = function()
  awful.util.spawn("brightnessctl s 5%-")
end

extra.setupExternalDisplay = function()
  awful.util.spawn("external-setup")
end

extra.showVolume = function()
  handle = io.popen("pamixer --get-volume")
  curvol = handle:read("*a")
  handle:close()
  volnotify:notify('Volume: ' .. curvol)
end

extra.toggleMute = function()
  awful.util.spawn("pamixer -t")
end

extra.toggleMicMute = function()
  extra.shellcmd("pamixer --default-source default -t")()
end
-- }}}

extra.globalkeys = awful.util.table.join(
    -- Rename a tag
    awful.key({ modkey }, "r",    function ()
              awful.prompt.run({ prompt = "Rename tag: ", text = awful.tag.selected().name, },
                  mouse.screen.mypromptbox.widget,
                  function (s)
                      awful.tag.selected().name = s
                  end)
              end),

    -- Standard programs
    awful.key({ modkey, "Shift"   }, "Return", extra.spawn("st -e tmux attach"),
              { description = "new terminal with tmux attach" }),

    awful.key({                   }, "XF86Launch8", extra.spawn("nemo"),
              { description = "nemo file manager" }),

    -- My dmenu utils
    awful.key({ modkey,           }, "i",  extra.spawn("2ktbli")),
    awful.key({ modkey,           }, "p",  extra.spawn("dmenu-recent 'activity run'")),
    awful.key({ modkey,           }, "\\", extra.spawn("dmenu-supergenpass")),
    awful.key({ modkey,           }, "-",  extra.spawn("dmenu-dict")),
    awful.key({ modkey, "Shift"   }, "-",  extra.spawn("dmenu-dict.cc")),
    awful.key({ modkey,           }, "=",  extra.spawn("dmenu-calc")),

    -- Media Keys
    awful.key({                   }, "XF86AudioRaiseVolume", extra.increaseVolume),
    awful.key({                   }, "XF86AudioLowerVolume", extra.decreaseVolume),
    awful.key({                   }, "XF86AudioMute", extra.toggleMute),
    awful.key({                   }, "XF86AudioMicMute", extra.toggleMicMute),
    awful.key({                   }, "XF86MonBrightnessUp", extra.increaseBrightness),
    awful.key({                   }, "XF86MonBrightnessDown", extra.decreaseBrightness),
    awful.key({                   }, "XF86Display", extra.setupExternalDisplay),

    -- Print Screen
    awful.key({                   }, "Print",
      extra.spawn("scrotme")),
    awful.key({         "Shift"   }, "Print",
      extra.spawn("scrotme -p")),
    awful.key({         "Control" }, "Print",
      extra.spawn("import /home/mnzaki/Images/screenshots/$(date +%Y-%m-%d-%H%M%S).png")),

    -- Screen sleep and lock
    awful.key({                   }, "0x1008ff2d", nil, extra.spawn("xset dpms force off")),
    awful.key({ modkey            }, "q", extra.shellcmd("slock & sleep 1 && xset dpms force off")),

    -- MPD
    awful.key({                   }, "0x1008ff14", extra.spawn("mpc -h boopity@localhost toggle")),
    awful.key({                   }, "0x1008ff15", extra.spawn("mpc -h boopity@localhost stop")),
    awful.key({                   }, "0x1008ff17", extra.spawn("mpc -h boopity@localhost next")),
    awful.key({                   }, "0x1008ff16", extra.spawn("mpc -h boopity@localhost prev")),

    -- Stop, Suspend
    awful.key({ modkey, "Shift"   }, "x", extra.spawn("xkill", false)),
    awful.key({ modkey, "Shift"   }, "s", extra.shellcmd("xsuspend $(xdotool getwindowfocus)")),

    -- revelation
    awful.key({ modkey,           }, "e",      revelation),

    -- gotta go fast some times
    awful.key({ modkey,          }, ".", extra.shellcmd("switchspeed slow")),
    awful.key({ modkey,          }, ",", extra.shellcmd("switchspeed fast")),

    -- clipster
    awful.key({ modkey,          }, "c", extra.shellcmd("clipster -s")),

    -- opacity
    awful.key({ modkey           }, "[", function ()
          local c = client.focus
          local current_opacity = c.opacity or 1
          c.opacity = math.max(0, math.min(1, current_opacity - 0.05))
    end),

    awful.key({ modkey           }, "]", function ()
          local c = client.focus
          local current_opacity = c.opacity or 1
          c.opacity = math.max(0, math.min(1, current_opacity + 0.05))
    end)
)

extra.signals = function()
  -- No borders on maximized windows
  client.connect_signal("property::maximized", function(c)
      c.border_width = c.maximized and 0 or beautiful.border_width
  end)
end

return extra
