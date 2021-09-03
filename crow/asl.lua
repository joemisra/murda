-- murda asl bank

local total_params = 2

-- this public stuff is currently not used
public{index1 = 1}:range(0, 16)  -- asl index 1
public{index2 = 2}:range(0, 16)  -- asl index 2
public{index3 = 3}:range(0, 16)  -- asl index 3
public{index4 = 4}:range(0, 16)  -- asl index 4
public{amp = 5}:range(-5, 10)  -- amp
public{output1 = 0}:range(-5, 10)  -- output1
public{dyn3 = 0.01}:range(-5, 5) -- dyn3 

-- used
public{dyn1 = 5}:range(-5, 10) -- dyn1
public{dyn2 = 0.5}:range(0.01, 10)  -- dyn2


-- do we maybe want to have this list on the norns side?
local caw = {}

s = sequins

shapez = s{'over', 'exp', 'log', 'lin', 'sine', 'under'}
midz = s{0,1.25,2.5,3.75,4.5,5}
aslz = s{
    to( dyn{dyn1=public.dyn1}, 0.01*dyn{dyn2=1}, shapez()),
    to( -1 * midz(), 0.005*math.random(1,5)*dyn{dyn2=1}, shapez() ),
    to( midz(), 0.002*math.random(1,5)*dyn{dyn2=1}, shapez() ),
    to( midz(), 0.02*math.random(1,5)*dyn{dyn2=1}, shapez() ),
    to( midz(), 0.2*math.random(1,3)*dyn{dyn2=1}, shapez() ),
    to(-1 * dyn{dyn1=public.dyn1},0.01*dyn{dyn2=public.dyn2}, shapez()),
    to(-1 * dyn{dyn1=public.dyn1},0.1*dyn{dyn2=public.dyn2}, shapez()),
    to( dyn{dyn1=public.dyn1}, 0.02*dyn{dyn2=1}), to( 0, 0.2*dyn{dyn2=1}),
    to( dyn{dyn1=public.dyn1}, 0.05*dyn{dyn2=public.dyn2}, 'sine'),
    to(-1 * dyn{dyn1=public.dyn1},0.05*dyn{dyn2=public.dyn2}, 'sine'),
    to(-1 * dyn{dyn1=public.dyn1},0.05*dyn{dyn2=public.dyn2}, 'exp'),
    to(dyn{dyn1=public.dyn1},0.25*dyn{dyn2=public.dyn2}, 'exp')
}

-- TODO: add method to randomize and reset these
function gen_caw()
    caw = {}

    for i=1,16 do
        aslz:step(math.random(1,5))
        table.insert(caw, loop{
            aslz(),
            aslz()
            }
        )
    end
end

cache = { 0, public.index1, public.index2, public.index3, public.index4 }

function init()
  gen_caw()

  --public.view.framerate(4)

  for i=1,4 do
      output[i](caw[i])
  end

  input[1].change = function(s)
      for i=1,4 do
        output[i]()
    end
  end

  input[1].mode('change',4.5,0.01,'rising')

  --input[1].stream = function(v)
  --    for i=1,4 do
  --      if output[i].dyn.dyn1 ~= nil then
  --        output[i].dyn.dyn1 = v
  --      end
  --  end
  --end

  --input[1].mode('stream', 0.05)

  --input[2].stream = function(v)
  --      output[1].dyn.dyn3 = v
  --end

  --input[2].mode('stream', 0.5)

  metro[1].event = update_index
  metro[1].time = 0.15
  metro[1]:start()
end

function update_index()
    for i=1,4 do
        -- only update if it has changed
        if output[i].dyn.dyn1 ~= nil and output[i].dyn.dyn1 ~= public.dyn1 then
            output[i].dyn.dyn1 = public.dyn1
        end

        -- only update if it has changed
        if output[i].dyn.dyn2 ~= nil and output[i].dyn.dyn2 ~= public.dyn2 then
            output[i].dyn.dyn2 = public.dyn2
        end
    end
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
