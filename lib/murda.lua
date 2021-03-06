local Murda={}

local MurdaRow={}

function MurdaRow:new(args)
    local l=setmetatable({},{__index=MurdaRow})
    local args=args==nil and {} or args

    l.index = args.index

    return l
end

function MurdaRow:init()
    self.curr_bank = 1
    self.curr_selected = 1

    -- setup osc
    self.wf={}
    for i=1,128 do
        self.wf[i]=0
    end
end

function MurdaRow:update_wf(volts)
    if volts ~= nil then
        volts = util.clamp(volts, -5, 10) -- params:get(i.."clampmin"),params:get(i.."clampmax")
        nuevolts = math.floor(util.linlin(-5,10,64,1,volts))

        --if self.wf[128] ~= nuevolts then
            -- copy everything right to left
            for i=1,127 do
                self.wf[i]=self.wf[i+1]
            end

            -- add new value to end
            self.wf[128]=nuevolts
        --end
    end
end

-- increase selected index by one (wrap if over 16)
function Murda:inc_selected(y)
    n = self.rows[y].curr_selected + 1
    if n > 16 then
        n = 1
    end
    self:set_selected(n, y)
end

-- decrease selected index by one (wrap if under 0)
function Murda:dec_selected(y)
    n = self.rows[y].curr_selected - 1
    if n < 1 then
        n = 16
    end
    self:set_selected(n, y)
end

function Murda:inc_bank(y)
    n = self.rows[y].curr_bank + 1
    if n > 16 then
        n = 1
    end
end

function Murda:dec_bank(y)
    n = self.rows[y].curr_bank - 1
    if n < 1 then
        n = 16
    end
end

-- randomize selections
function Murda:shuffle()
    for i=1,4 do
    self:set_selected(i, math.random(1,16))
    end
end

-- change selected asl
function MurdaRow:set_selected(x)
    self.curr_selected = x
end

function Murda:new(args)
    local l=setmetatable({},{__index=Murda})
    local args=args==nil and {} or args
    l.use_grid=args.use_grid or false

    return l
end

function Murda:init()
    self.toggled = {} -- meta-table to track the state of the grid keys
    self.brightness = {} -- meta-table to track the brightness of each grid key
    self.counter = {} -- meta-table to hold counters to distinguish between long and short press
    self.show = {x = 1, y = 1}
    self.cur = 1

    self.rows = {}

    for y = 1,4 do
        self.rows[y] = MurdaRow.new({index = y})
        self.rows[y]:init()
    end

    for x = 1,16 do -- for each x-column (16 on a 128-sized grid)...
        self.toggled[x] = {} -- create an x state tracker,
        self.brightness[x] = {} -- create an x brightness,

        self.counter[x] = {} -- long press counter (unused)

        for y = 1,8 do
            self.toggled[x][y] = false
            self.brightness[x][y] = 0
        end
    end

    for y = 1,4 do
        self.toggled[self.rows[y].curr_selected][y] = true
        self.brightness[self.rows[y].curr_selected][y] = 15
    end
end

function Murda:set_selected(y, x)
    prev_selected = self.rows[y].curr_selected

    self.toggled[prev_selected][y] = false -- toggle it on,

    self.toggled[x][y] = true -- toggle it on,
    self.brightness[x][y] = 15 -- set brightness to half.

    self.rows[y]:set_selected(x)

    crow.send('update_output(' .. x .. ',' .. y .. ')')
end

-- retrigger current selections
function Murda:sync()
    for i=1,4 do
        crow.output[i]()
    end
end

return Murda
