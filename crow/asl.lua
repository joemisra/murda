-- murda asl bank

local total_params = 2

-- this public stuff is currently not used
public{index1 = 1}:range(0, 16)  -- asl index 1
public{index2 = 2}:range(0, 16)  -- asl index 2
public{index3 = 3}:range(0, 16)  -- asl index 3
public{index4 = 4}:range(0, 16)  -- asl index 4

public{dyn1 = 0.75}:range(0, 1) -- dyn1
public{dyn2 = 0.5}:range(0, 1)  -- dyn2

-- do we maybe want to have this list on the norns side?
local caw = {}

-- TODO: add method to randomize and reset these
function gen_caw()
    caw = {}

    for i=0,4 do
        table.insert(caw, loop{
            to( 5*dyn{dyn1=1}, 0.01*dyn{dyn2=1}),
            to( -2.5*dyn{dyn1=1}, 0.005*math.random(1,5)*i*dyn{dyn2=1} ),
            to( 2.5*dyn{dyn1=1}, 0.002*math.random(1,5)*i*dyn{dyn2=1} ),
            to(-5*dyn{dyn2=1},0.01*i)
          }
        )
    end

    for i=5,8 do
        table.insert(caw,loop{ to( 5, 0.02*dyn{dyn1=1}), to( 0, 0.1*i*dyn{dyn2=1})})
    end

    -- slow lfos
    for i=9,16 do
        table.insert(caw, lfo(0.15*dyn{dyn2=1}*i, dyn{dyn1=5}))
    end
end

cache = { 0, public.index1, public.index2, public.index3, public.index4 }

function init()
  gen_caw()

  --public.view.framerate(4)

  for i=1,4 do
      output[i](caw[i])
  end

  --input[1].change = function(s)
  --    for i=1,4 do
  --      output[i]()
  --  end
  --end

  --input[1].mode('change',4.5,0.01,'rising')

  input[1].stream = function(v)
      for i=1,4 do
        if output[i].dyn.dyn1 ~= nil then
          output[i].dyn.dyn1 = v
        end
    end
  end

  input[1].mode('stream', 0.05)

  input[2].stream = function(v)
      for i=1,4 do
          if output[i].dyn.dyn2 ~= nil then
            output[i].dyn.dyn2 = v
      end
    end
  end

  input[2].mode('stream', 0.05)

  metro[1].event = update_index
  metro[1].time = 1
  metro[1]:start()
end

function update_index()
    --print(public.index1 .. " " .. public.index2 .. " " .. public.index3 .. " " .. public.index4)
end

function update_output(x, y)
  --print("caw is: " .. #caw)
  if y > 0 and y < 5 then
    if x < #caw then
        --print("setting " .. y .. " -> " .. x)
        output[y](caw[x])
    end
  end
end
