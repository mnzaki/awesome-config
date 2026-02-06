local awful = require("awful")

local attentive = {object={}}
local modkey = "Mod4"

-- {{{ Tags
-- Define a tag table which holds all screen tags.

attentive.default_layout = awful.layout.layouts[2]
attentive.tags = {}
attentive.tagskeys = {}
attentive.tag_last_layout = {}

attentive.create_tags = function(s)
  -- Each screen has its own tag table.
  local alltags = {}
  local idx = s.index
  attentive.tag_last_layout[idx] = {}
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
  attentive.tags[idx] = awful.tag(alltags, s, attentive.default_layout)
  return attentive.tags[idx]
end

attentive.create_tags_keys = function(s)
  function def_tag_keybindings(i, keycode)
    -- Bind all key numbers to tags.
    -- Be careful: we use keycodes to make it works on any keyboard layout.
    -- This should map on the top row of your keyboard, usually 1 to 9.
    attentive.tagskeys = awful.util.table.join(
        attentive.tagskeys,

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

  root.keys(
    awful.util.table.join(
      root.keys(),
      attentive.tagskeys
    )
  )
end

attentive.temp_tag_max_layout = function()
  local last = attentive.tag_last_layout[mouse.screen][awful.tag.getidx()+1]
  if last == nil then
    attentive.tag_last_layout[mouse.screen][awful.tag.getidx()+1] = awful.layout.get()
    awful.layout.set(awful.layout.suit.max)
  else
    awful.layout.set(last)
    attentive.tag_last_layout[mouse.screen][awful.tag.getidx()+1] = nil
  end
end

attentive.init = function()
  awful.screen.connect_for_each_screen(
    function(s)
      attentive.create_tags(s)
    end
  )

  attentive.create_tags_keys(s)
end

return attentive
