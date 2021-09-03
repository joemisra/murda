-- murda
-- 
-- proswell
--
-- asl banks 4 crow
-- grid required
-- 
-- e1 sel output 1-4
-- e2 change dyn1
-- e3 change dyn2
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

local m = include('murda/lib/murda')

local show_console = true -- displays messages from crow on-screen
local viewall = true

local total_params = 2

local wavs = 0


local grid_state = {}
local grid_dirty = true
local g = grid.connect()

local P = norns.crow.public

-- experimenting w/ carrying dyn values over even when switching
local dyncache = {
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, -- dyn1
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, -- dyn2
}

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function init()
  norns.crow.loadscript("asl.lua")

  m:init()

  metro[1].event = update_grid
  metro[1].time  = 0.02

  metro[2].event = update_screen
  metro[2].time  = 0.02

  function P.change()
      --redraw()
  end

  function P.discovered()
    print'discovered!'
    if viewall then crow.public.view.all() end -- enable viewing of all CV levels
    metro[1]:start() 
    metro[2]:start() 

    m:shuffle()
    --redraw()
  end

  clock.run(grid_redraw_clock)
  --redraw()
end

function enc(k,d)
  if k==1 then
      m.cur = util.clamp(m.cur + d, 1, 4)
  elseif k==2 then
      --nu = m.rows[m.cur].curr_selected + d
      --m:set_selected(m.cur, util.clamp(nu, 1, 16))
      crow.public.dyn1 = crow.public.dyn1 + (d * 0.01)
  elseif k==3 then
      -- set bank
      crow.public.dyn2 = crow.public.dyn2 + (d * 0.01)
  end
end

-- FIXME: unused
function set_dyn(i, d, v)
    x = m.curr_selected[i]

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
  if m.toggled[x][y] then -- if key is toggled, then...
    m.brightness[x][y] = m.brightness[x][y] == 15 and 8 or 15 -- flip brightness 8->15 or 15->8.
  end
  counter[x][y] = nil -- clear the counter
  grid_dirty = true -- flag for redraw
end

function draw_public_views( vs )
end

-- draw viewable i/o on screen
function draw_public_views_x( vs )

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
  for i=1,4 do
    if vs.output[i] ~= nil then
      vslide(115 + (i-1) * 4, vs.output[i])
    end
  end

end

function update_screen()
  redraw()
end

function update_grid()
    offset = 0 -- for flickering effect on selected pads, brightness offset

    -- bottom left animations
    for i=1,6 do
        -- first 4 are outputs next 2 are inputs
        if (i < 5 and P.viewing.output[i] ~= nil) or (i > 4 and P.viewing.input[i-4] ~= nil) then
            if i < 5 then
                which = P.viewing.output[i]
                m.rows[i]:update_wf(P.viewing.output[i])
            else
                which = P.viewing.input[i - 4]
            end

            if(which < 0) then
                level_is = math.floor((which / 5.0) * 16)
            else
                level_is = math.floor((which / 10.0) * 16)
            end

            offset = math.floor((which / 5.0) * 4)

            if(level_is < 0) then
                y = 8
                level_is = level_is * -1
                m.toggled[i][7] = false
                m.toggled[i][8] = true
                offset = 8 + (offset * -1)
            elseif level_is > 0 then
                y = 7
                m.toggled[i][7] = true
                m.toggled[i][8] = false
            elseif level_is == 0 then
                y = 0
                m.toggled[i][8] = false
                m.toggled[i][7] = false
            end

            if y >= 0 and level_is ~= nil then
                m.brightness[i][y] = level_is -- flip brightness 8->15 or 15->8.
                g:led(i, y, level_is)
            end
        end

        -- flickering effect on selected pads
        -- brightness[curr_selected[i]][i] = 10 + offset
    end

    grid_dirty = true
end

function grid_redraw()
  g:all(0)
  for x = 1,16 do
    for y = 1,8 do
      if m.toggled[x][y] then -- if coordinate is toggled on...
          g:led(x,y,m.brightness[x][y]) -- set LED to coordinate at specified brightness.
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

    clock.sleep(1/15)
  end

  redraw()
end

function redraw()
    screen.clear()

    screen.level(15)

    --screen.move(1,m.rows[m.cur].wf[1])
    --screen.aa(1)
    --screen.line_width(2)
    --for i=1,128 do
        --screen.rect(i,m.rows[m.cur].wf[i],1,1)
        --screen.line(i, m.rows[m.cur].wf[i])
        --screen.stroke()
        --screen.move(i, m.rows[m.cur].wf[i])
        --screen.fill()

        --screen.line(i, m.rows[1].wf[i])
        --screen.stroke()
        --screen.move(i, m.rows[1].wf[i])
    --end
    
    barheight = 4
    barspacing = 8

    for i=1,6 do
        ypos = 0

        if i > 4 then
            extraoffset = 4 -- the inputs
            barheight = 4
        else
            extraoffset = 0
        end
        
        ypos = (i * barspacing)

        if i == m.cur then
            squish = 11
            screen.level(15)
            screen.rect(1 * squish - 2, ypos + 2, 2, barheight)
            screen.rect(128 - (1 * squish), ypos + 2, 2, barheight)
            screen.fill()
        else
            squish = 13
        end

        if i < 5 then
            screen.level(12)
            sm = i
            screen.move(1, ypos + 6)
            screen.text(sm)

            sm = m.rows[i].curr_selected

            screen.level(12)
            screen.move(128-screen.text_extents(sm) - 1, ypos + 6)
            screen.text(sm)
        end

        for j=0,1 do
            screen.level(m.brightness[i][7 + j] - 1)
            ypos = ypos + (j * barheight)
            screen.rect(1 * squish, ypos, 128 - (squish * 2),barheight)
            screen.fill()
        end
    end

    --if P.viewing ~= nil then
    --    draw_public_views(P.viewing)
    --end

    if crow.public.dyn1 ~= nil and crow.public.dyn2 ~= nil then
        sm=string.format("dyn1 %0.2f dyn2 %0.2f", crow.public.dyn1, crow.public.dyn2)

        screen.level(12)
        screen.move(128-screen.text_extents(sm)-1,54)
        screen.text(sm)
    end
    
    screen.update()
end

-- handle grid butt0npress
function g.key(x,y,z)
    print(x .. " " .. y .. " " .. z)

    if z == 1 then
        if y == 8 then
            m.toggled[x][y] = true
            m.brightness[x][y] = 15
            --g:led(x,y,12)
            --g:refresh()
            grid_dirty = true
        end
        short_press(x,y)
    elseif z == 0 then
        if y == 8 then
            m.toggled[x][y] = false
            m.brightness[x][y] = 0 
            grid_dirty = true
            --g:refresh()
        end
    end
end

-- handle grid buttonz
function short_press(x,y) -- define a short press
    -- clear top rows
    --for j=1,4 do
    --    for i=1,16 do
    --        toggled[i][j] = false
    --        brightness[i][j] = 0 -- set brightness to half.
    --    end
    --end

    if y > 0 and y < 5 then
        m:set_selected(y, x)
    elseif y == 8 then
        if x == 15 then
            -- reload script?
            m:init()
        end

        if x == 7 then
            -- restart all ASL
            m:shuffle()
        end

        if x == 8 then
            -- restart all ASL
            m:sync()
        end

        for j=1,4 do
            if x == 9 then
                -- subtract one / wrap
                m:dec_selected(j)
            elseif x == 10 then
                -- add one / wrap
                m:inc_selected(j)
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

