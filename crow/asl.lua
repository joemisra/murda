-- 0murda
-- proswell
--
-- asl banks for crow
--
-- lfo / envelope
--
local total_params = 2


public{index1 = 1}:range(0, 16)  -- asl index 1
public{index2 = 2}:range(0, 16)  -- asl index 2
public{index3 = 3}:range(0, 16)  -- asl index 3
public{index4 = 4}:range(0, 16)  -- asl index 4

public{dyn1 = 0.75}:range(0, 1) -- dyn1
public{dyn2 = 0.5}:range(0, 1)  -- dyn2

-- do we maybe want to have this list on the norns side?

caw = { 
  loop{ to( 5, 0.1 ), to(-5,0.01) },
  loop{ to( 5, 0.05 ), to(-5,0.2)  },
  loop{ to( 5, 0.02 ), to(-5,0.4)  },
  loop{ to( 5, 0.02 ), to(-5,0.1), to( 5, 0.02 ), to(-5,0.2), to( 5, 0.02 ), to(-5,0.3)  },
  loop{ to( 5, 0.02 ), to(-5,0.4), to( 5, 0.22 ), to(-5,0.5), to( 5, 0.76 ), to(-5,1)  },
  loop{ to( -5, 0.05 ), to(5,0.2)  },
  loop{ to( -5, 0.02 ), to(5,0.4)  },
  loop{ to( -5, 0.02 ), to(5,0.6)  },
  loop{ to( -5, 0.02 ), to(5,0.8)  },
  lfo(1.5*dyn{dyn1=1}),
  lfo(1.25),
  lfo(1.1),
  lfo(1.05),
  lfo(1.025),
  lfo(1.01),
  lfo(1.005),
  lfo(1.001),
}

cache = { 0, public.index1, public.index2, public.index3, public.index4 }

function init()
  for i=1,4 do
      
      output[i](caw[i])
  end

  metro[1].event = update_index
  metro[1].time = 1
  metro[1]:start()
end

function update_index()
    --print(public.index1 .. " " .. public.index2 .. " " .. public.index3 .. " " .. public.index4)
end

function update_output(x, y)
  print("caw is: " .. #caw)
  if y > 0 and y < 5 then
    if x < #caw then
        print("setting " .. y .. " -> " .. x)
        output[y](caw[x])
    end
  end
end
