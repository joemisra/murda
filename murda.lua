-- murda
-- 
-- proswell
--
-- asl banks for crow
--
-- lfo / envelope
--
local show_console = true -- displays messages from crow on-screen
local viewall = true

local total_params = 2
local grid_state = {}
local grid_dirty = true

local toggled = {} -- meta-table to track the state of the grid keys
local brightness = {} -- meta-table to track the brightness of each grid key
local counter = {} -- meta-table to hold counters to distinguish between long and short press

local scope = {0,0}

--local crowii  = crow.ii.crow
local P = norns.crow.public

--local P2 = crowii.public -- does this even work?

local g = grid.connect()

function init()
  norns.crow.loadscript("asl.lua")

  show = {x = 1, y = 1} -- table tracking x,y position

  for x = 1,16 do -- for each x-column (16 on a 128-sized grid)...
    toggled[x] = {} -- create an x state tracker,
    brightness[x] = {} -- create an x brightness,
    counter[x] = {} -- create an x brightness,

    for y = 1,8 do
        toggled[x][y] = false
        brightness[x][y] = 0
    end
  end

  for y = 1,4 do
    toggled[1][y] = true
    brightness[1][y] = 15
  end

  metro[1].event = update_grid
  metro[1].time  = 0.1
  metro[1]:start() 

  function P.change() redraw() end

  function P.discovered()
    print'discovered!'
    if viewall then crow.public.view.all() end -- enable viewing of all CV levels
    redraw()
  end

  clock.run(grid_redraw_clock)
  redraw()
end

function update_grid()
    for i=1,4 do
        level_is = math.floor((P.viewing.output[i] / 5) * 16)
        if(level_is < 0) then
            y = 8
            level_is = level_is * -1
            toggled[i][7] = false
        else
            y = 7
            toggled[i][8] = false
        end

        g:led(i, y, level_is)
        toggled[i][y] = true
        brightness[i][y] = level_is -- flip brightness 8->15 or 15->8.
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
        short_press(x,y)
    end
end

function short_press(x,y) -- define a short press
    if y > 0 and y < 5 then
        -- clear this row
        for i=1,16 do
            toggled[i][y] = false
            brightness[i][y] = 0 -- set brightness to half.
        end

        toggled[x][y] = true -- toggle it on,
        brightness[x][y] = 8 -- set brightness to half.

        --cmd = 'public.update("index' .. y .. '",' .. x .. ')'
        --print(cmd)
        --norns.crow.send(cmd)
        crow.send('update_output(' .. x .. ',' .. y .. ')')
    end

    -- i dunno who this is 626 696 9226

    grid_dirty = true -- flag for redraw
end

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

function out(i,v)
  scope[i] = v
end

-- draw viewable i/o
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
