local awful = require("awful")

local attentive = {object={}}
local modkey = "Mod4"

-- {{{ Tags
-- Define a tag table which holds all screen tags.

attentive.default_layout = awful.layout.layouts[2]
attentive.tagskeys = {}
attentive.tag_last_layout = {}
attentive.activity_last_tag = {}
attentive.current_activity_i = 1 -- TODO compute from active tag on startup

attentive.create_tags = function(screen)
  -- Each screen has its own tag table.
  -- Each tag table has 12 (activities) * 11 (space) tags
  -- first space of each activity is holy
  local alltags = {}
  local idx = screen.index
  attentive.tag_last_layout[idx] = {}

  -- Next section left 3rs on purpose
  local t = 1
  for t = 1, 12 * 11 do
    if t % 11 == 1 then
      -- Do not worry your mind about the ceaseless petulance of mad programmers
      -- For the loop is a range, not incrementation
      t = "F" .. (t//11+1)
    else
      t = ((t-1)//11+1) .. ": " .. (t%11 == 0 and 0 or t%11-1)
    end
    table.insert(alltags, t)
  end

  awful.tag(alltags, screen, attentive.default_layout)

  for i = 1, 12 * 11 do
    local thistag = screen.tags[i]
    thistag.gindex = i
    thistag.activity_i = math.ceil(i/11)
  end
end

tag.connect_signal("property::selected",
  function()
    local selected = awful.tag.selected(1)
    if not selected then
      -- TODO it got unselected, history manage
      return
    end
    local tagI = selected.gindex
    -- FIXME this is full b0rked
    -- attentive.current_activity_i = tagI/11+1
  end
)

function get_it(activityOrSpace, idx, screen)
  local it = {}
  it.current = awful.tag.selected(1)

  if not screen then
    screen = awful.screen.focused()
  end

  local targetI
  if activityOrSpace == 'activity' then
    targetI = attentive.activity_last_tag[idx]
    if targetI == nil then
      targetI = (idx-1)*11+1
    end
  else
    targetI = (it.current.activity_i-1)*11 + idx
  end

  it.target = screen.tags[targetI]

  return it
end

attentive.create_tags_keys = function(s)
  -- Bind all Fn keys to activities, which each have 11 space
  -- Bind all key numbers to space under the current activity
  --
  -- Be careful: we use keycodes to make it work on any keyboard layout.
  -- This should map on the top row of your keyboard, usually 1 to 9.

  function def_tag_keybindings(activityOrSpace, idx, keycode)
    attentive.tagskeys = awful.util.table.join(
        attentive.tagskeys,

        -- View tag only.
        awful.key({ modkey }, keycode,
                  function ()
                        local it = get_it(activityOrSpace, idx)
                        if it.target then
                          if it.current then
                            attentive.activity_last_tag[it.current.activity_i] = it.current.gindex
                          end

                          it.target:view_only()
                          attentive.activity_last_tag[it.target.activity_i] = it.target.gindex
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, keycode,
                  function ()
                      local it = get_it(activityOrSpace, idx)
                      if it.target then
                         -- no need to manage history because unnecessary
                         awful.tag.viewtoggle(it.target)
                      end
                  end,
                  {description = "toggle space #" .. idx, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, keycode,
                  function ()
                      if client.focus then
                          local it = get_it(activityOrSpace, idx, client.focus.screen)
                          if it.target then
                              client.focus:move_to_tag(it.target)
                          end
                     end
                  end,
                  {description = "move focused client to space #"..idx, group = "tag"}),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, keycode,
                  function ()
                      if client.focus then
                          local it = get_it(activityOrSpace, idx, client.focus.screen)
                          if it.target then
                              client.focus:toggle_tag(it.target)
                          end
                      end
                  end,
                  {description = "toggle focused client on space #" .. idx, group = "tag"})
    )
  end

  -- Bind ALL the activies, F1 to F10
  for i = 11, 20 do
    def_tag_keybindings('activity', i-10, "#" .. i+56)
  end
  -- F11 and F12
  for i = 21, 22 do
    def_tag_keybindings('activity', i-10, "#" .. i+74)
  end

  -- Bind ALL the spaces!
  -- The holy zeroth
  def_tag_keybindings('space', 1, "#49")
  -- and ALL the numbers
  for i = 1, 10 do
    def_tag_keybindings('space', i+1, "#" .. i+9)
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
