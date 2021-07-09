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

-- revelation: expose
local revelation = require("revelation")

extra.init = function()
  revelation.init()
end

-- {{{ Tags
-- Define a tag table which holds all screen tags.
extra.tags = {}
extra.tag_last_layout = {}
extra.default_layout = awful.layout.layouts[2]

extra.create_tags = function(s)
  -- Each screen has its own tag table.
  local alltags = {}
  local idx = s.index
  extra.tag_last_layout[idx] = {}
  local t = 1
  for t = 1, 22 do
    if t == 10 then
      t = 0
    end
    if t > 10 then
      t = "F" .. (t-10)
    end
    table.insert(alltags, t)
  end
  extra.tags[idx] = awful.tag(alltags, s, extra.default_layout)
  return extra.tags[idx]
end

extra.create_taglist = function(s, taglist_buttons)
  s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.noempty, taglist_buttons)
end

extra.create_wibox = function(s)
  s.mywibox = awful.wibar({ position = "top", screen = s, height = 16 })
end

extra.temp_tag_max_layout = function()
  local last = extra.tag_last_layout[mouse.screen][awful.tag.getidx()+1]
  if last == nil then
    extra.tag_last_layout[mouse.screen][awful.tag.getidx()+1] = awful.layout.get()
    awful.layout.set(awful.layout.suit.max)
  else
    awful.layout.set(last)
    extra.tag_last_layout[mouse.screen][awful.tag.getidx()+1] = nil
  end
end
-- }}}


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
  awful.util.spawn("pamixer --sink 0 --allow-boost -i 1")
  extra.showVolume()
end

extra.decreaseVolume = function()
  awful.util.spawn("pamixer --sink 0 --allow-boost -d 1")
  extra.showVolume()
end

extra.showVolume = function()
  handle = io.popen("pamixer --sink 0 --get-volume")
  curvol = handle:read("*a")
  handle:close()
  volnotify:notify('Volume: ' .. curvol)
end

extra.toggleMute = function()
  awful.util.spawn("pamixer --sink 0 -t")
end

extra.toggleMicMute = function()
  extra.shellcmd("pactl -- set-source-mute alsa_input.pci-0000_00_1b.0.analog-stereo toggle")()
end
-- }}}

extra.globalkeys = awful.util.table.join(
    -- Rename a tag
---     awful.key({ modkey, }, "r",    function ()
---               awful.prompt.run({ prompt = "Rename tag: ", text = awful.tag.selected().name, },
---                   mypromptbox[mouse.screen].widget,
---                   function (s)
---                       awful.tag.selected().name = s
---                   end)
---               end),
---
    -- Standard programs
    awful.key({ modkey, "Shift"   }, "Return", extra.spawn("st -e tmux attach"),
              { description = "new terminal with tmux attach" }),
    awful.key({ modkey, "Shift", "Control"   }, "Return", extra.spawn("dmenu-tmuxstart"),
              { description = "tmuxstart from dmenu list" }),

    awful.key({                   }, "0x1008ff41", extra.spawn("nemo"),
              { description = "nemo file manager" }),

    -- My dmenu utils
    awful.key({ modkey,           }, "p",  extra.spawn("dmenu-recent")),
    awful.key({ modkey,           }, "\\", extra.spawn("dmenu-supergenpass")),
    awful.key({ modkey,           }, "-",  extra.spawn("dmenu-dict")),
    awful.key({ modkey, "Shift"   }, "-",  extra.spawn("dmenu-dict.cc")),
    awful.key({ modkey,           }, "=",  extra.spawn("dmenu-calc")),

    -- Media Keys
    awful.key({                   }, "XF86AudioRaiseVolume", extra.increaseVolume),
    awful.key({                   }, "XF86AudioLowerVolume", extra.decreaseVolume),
    awful.key({                   }, "XF86AudioMute", extra.toggleMute),
    awful.key({                   }, "XF86AudioMicMute", extra.toggleMicMute),

    -- Print Screen
    awful.key({                   }, "Print",
      extra.spawn("scrotme")),
    awful.key({         "Shift"   }, "Print",
      extra.spawn("scrotme -p")),
    awful.key({         "Control" }, "Print",
      extra.spawn("import /home/mnzaki/Images/screenshots/$(date +%Y-%m-%d-%H%M%S).png")),

    -- Screen sleep and lock
    awful.key({                   }, "0x1008ff2d", nil, extra.spawn("xset dpms force off")),
    awful.key({                   }, "0x1008ff93", extra.shellcmd("slock & sleep 1 && xset dpms force off")),

    -- MPD
    awful.key({                   }, "0x1008ff14", extra.spawn("mpc -h boopity@localhost toggle")),
    awful.key({                   }, "0x1008ff15", extra.spawn("mpc -h boopity@localhost stop")),
    awful.key({                   }, "0x1008ff17", extra.spawn("mpc -h boopity@localhost next")),
    awful.key({                   }, "0x1008ff16", extra.spawn("mpc -h boopity@localhost prev")),

    -- Kill, Suspend
    awful.key({ modkey, "Shift"   }, "x", extra.spawn("xkill", false)),
    awful.key({ modkey, "Shift"   }, "s", extra.shellcmd("xsuspend $(xdotool getwindowfocus)")),

    -- revelation
    awful.key({ modkey,           }, "e",      revelation),

    -- gotta go fast some times
    awful.key({ modkey,          }, ".", extra.shellcmd("switchspeed slow")),
    awful.key({ modkey,          }, ",", extra.shellcmd("switchspeed fast"))

)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
extra.tagskeys = {}
function def_tag_keybindings(i, keycode)
    extra.tagskeys = awful.util.table.join(
        extra.tagskeys,

        -- View tag only.
        awful.key({ modkey }, keycode,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                          tag:view_only()
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, keycode,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, keycode,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, keycode,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
  )
end

-- bind ALL the tags!
-- ALL the numbers
for i = 1, 10 do
  def_tag_keybindings(i, "#" .. i+9)
end
-- F1 to F10
for i = 11, 20 do
  def_tag_keybindings(i, "#" .. i+56)
end
-- F11 and F12
for i = 21, 22 do
  def_tag_keybindings(i, "#" .. i+74)
end

extra.signals = function()
  -- No borders on maximized windows
  client.connect_signal("property::maximized", function(c)
      c.border_width = c.maximized and 0 or beautiful.border_width
  end)
end

return extra
