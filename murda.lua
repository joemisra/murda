-- murda
-- 
-- proswell
--
-- asl banks 4 crow
-- grid required
--
-- row 1-4
--   select asl 1-16
--
-- row 8
--   7  = shuffle
--   8  = sync
--   9  = all--
--   10 = all++
--   15 = reload

local show_console = true -- displays messages from crow on-screen
local viewall = true

local total_params = 2
local grid_state = {}
local grid_dirty = true

local toggled = {} -- meta-table to track the state of the grid keys
local brightness = {} -- meta-table to track the brightness of each grid key
local counter = {} -- meta-table to hold counters to distinguish between long and short press

local curr_selected = {1, 1, 1, 1}

local P = norns.crow.public

local g = grid.connect()

-- experimenting w/ carrying dyn values over even when switching
local dyncache = {
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, -- dyn1
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, -- dyn2
}

function init()
  norns.crow.loadscript("asl.lua")
  curr_selected = {1, 1, 1, 1}

  show = {x = 1, y = 1} -- table tracking x,y position

  for x = 1,16 do -- for each x-column (16 on a 128-sized grid)...
    toggled[x] = {} -- create an x state tracker,
    brightness[x] = {} -- create an x brightness,

    -- counter[x] = {} -- press counter (unused)

    for y = 1,8 do
        toggled[x][y] = false
        brightness[x][y] = 0
    end
  end

  for y = 1,4 do
    toggled[curr_selected[y]][y] = true
    brightness[curr_selected[y]][y] = 15
  end

  metro[1].event = update_grid
  metro[1].time  = 0.05

  function P.change() redraw() end

  function P.discovered()
    print'discovered!'
    if viewall then crow.public.view.all() end -- enable viewing of all CV levels
    metro[1]:start() 
    redraw()
  end

  clock.run(grid_redraw_clock)
  redraw()
end

function update_grid()
    offset = 0 -- for flickering effect on selected pads

    -- bottom left animations
    for i=1,4 do
        if P.viewing.output[i] ~= nil then
            level_is = math.floor((P.viewing.output[i] / 10) * 16)
            offset = math.floor((P.viewing.output[i] / 5) * 4)

            if(level_is < 0) then
                y = 8
                level_is = level_is * -1
                toggled[i][7] = false
                toggled[i][8] = true
                offset = 8 + (offset * -1)
            elseif level_is > 0 then
                y = 7
                toggled[i][7] = true
                toggled[i][8] = false
            elseif level_is == 0 then
                y = 0
                toggled[i][8] = false
                toggled[i][7] = false
            end

            if y >= 0 and level_is ~= nil then
                brightness[i][y] = level_is -- flip brightness 8->15 or 15->8.
                g:led(i, y, level_is)
            end
        end

        -- flickering effect on selected pads
        -- brightness[curr_selected[i]][i] = 10 + offset
    end

    grid_dirty = true
end

function redraw()
    screen.clear()

    if P.viewing ~= nil then
        draw_public_views(P.viewing)
    end

    screen.update()
end

function g.key(x,y,z)
    print(x .. " " .. y .. " " .. z)

    if z == 1 then
        if y == 8 then
            toggled[x][y] = true
            brightness[x][y] = 15
            --g:led(x,y,12)
            --g:refresh()
            grid_dirty = true
        end
        short_press(x,y)
    elseif z == 0 then
        if y == 8 then
            toggled[x][y] = false
            brightness[x][y] = 0 
            grid_dirty = true
            --g:refresh()
        end
    end
end

function shuffle()
    for i=1,4 do
        set_selected(i,math.random(1,16))
    end
end

function sync()
    for i=1,4 do
        crow.output[i]()
    end
end

function inc_selected(y)
    n = curr_selected[y] + 1
    if n > 16 then
        n = 1
    end
    set_selected(y, n)
end

function dec_selected(y)
    n = curr_selected[y] - 1
    if n < 1 then
        n = 16
    end
    set_selected(y, n)
end

function set_selected(y, x)
    prev_selected = curr_selected[y]
    toggled[prev_selected][y] = false -- toggle it on,

    toggled[x][y] = true -- toggle it on,
    brightness[x][y] = 15 -- set brightness to half.

    curr_selected[y] = x

    crow.send('update_output(' .. x .. ',' .. y .. ')')

    --set_dyn(y, 1, dyncache[1][y])
    --set_dyn(y, 2, dyncache[2][y])
end

function short_press(x,y) -- define a short press
    -- clear top rows
    --for j=1,4 do
    --    for i=1,16 do
    --        toggled[i][j] = false
    --        brightness[i][j] = 0 -- set brightness to half.
    --    end
    --end

    if y > 0 and y < 5 then
        set_selected(y, x)
    elseif y == 8 then
        if x == 15 then
            -- reload script?
            init()
        end

        if x == 7 then
            -- restart all ASL
            shuffle()
        end

        if x == 8 then
            -- restart all ASL
            sync()
        end

        for j=1,4 do
            if x == 9 then
                -- subtract one / wrap
                dec_selected(j)
            elseif x == 10 then
                -- add one / wrap
                inc_selected(j)
            end
        end

        if x == 11 then
            -- move up / wrap
        elseif x == 12 then
            -- move down / wrap
        end
    end

    grid_dirty = true -- flag for redraw
end

function set_dyn(i, d, v)
    x = curr_selected[i]

    dyncache[d][i] = v

    if d == 1 then
        crow.output[i].dyn.dyn1 = dyncache[1][i]
    elseif d == 2 then
        crow.output[i].dyn.dyn2 = dyncache[2][i]
    end
end

-- unused but probably in future
function long_press(x,y) -- define a long press
  clock.sleep(0.5) -- a long press waits for a half-second...
  -- then all this stuff happens:
  if toggled[x][y] then -- if key is toggled, then...
    brightness[x][y] = brightness[x][y] == 15 and 8 or 15 -- flip brightness 8->15 or 15->8.
  end
  counter[x][y] = nil -- clear the counter
  grid_dirty = true -- flag for redraw
end

function grid_redraw()
  g:all(0)
  for x = 1,16 do
    for y = 1,8 do
      if toggled[x][y] then -- if coordinate is toggled on...
          g:led(x,y,brightness[x][y]) -- set LED to coordinate at specified brightness.
      end
    end
  end
  g:refresh()
end

function grid_redraw_clock()
  while true do
    if grid_dirty then
      grid_redraw()
      grid_dirty = false
    end

    clock.sleep(1/30)
  end
end

-- draw viewable i/o on screen
function draw_public_views( vs )
  local function vslide(x, val)
    val = -val*3.6
    if math.floor(val+0.5) == 0 then
      screen.level(1)
      screen.pixel(x-1, 43) -- pixel prints 1px to the right of line_rel
      screen.fill()
    else
      screen.level(5)
      screen.move(x, 44)
      screen.line_rel(0, val)
      screen.stroke()
    end
  end
  screen.line_width(1)
  for i=1,2 do if vs.input[i] ~= nil then vslide(1 + (i-1) * 4, vs.input[i]) end end
  for i=1,4 do if vs.output[i] ~= nil then vslide(115 + (i-1) * 4, vs.output[i]) end end
end
