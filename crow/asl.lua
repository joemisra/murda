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
public{cock = 1}:range(0, 16)  -- asl index 4

-- TODO refine ranges & apply 'expo' where appropriate
public{dyn1 = 0.75}:range(0, 1) -- dyn1
public{dyn2 = 0.5}:range(0, 1)  -- dyn2

caw = { 
  loop{ to( 5, 0.1 ), to(0,0.01) },
  loop{ to( 5, 0.05 ), to(0,0.2)  },
  loop{ to( 5, 0.02 ), to(0,0.4)  },
  loop{ to( 5, 0.02 ), to(0,0.8)  },
  loop{ to( 5, 0.02 ), to(0,1)  },
  loop{ to( 0, 0.05 ), to(5,0.2)  },
  loop{ to( 0, 0.02 ), to(5,0.4)  },
  loop{ to( 0, 0.02 ), to(5,0.6)  },
  loop{ to( 0, 0.02 ), to(5,0.8)  },
  lfo(0.5),
  lfo(0.25),
  lfo(0.1),
  lfo(0.05),
  lfo(0.025),
  lfo(0.01),
  lfo(0.005),
  lfo(0.001),
}

cache = { 0, public.index1, public.index2, public.index3, public.index4 }

function init()
    print("loaded")
  for i=1,4 do
      
      output[i](caw[i])
  end

  metro[1].event = update_index
  metro[1].time = 1
  metro[1]:start()
end

function update_index()
    print(public.index1 .. " " .. public.index2 .. " " .. public.index3 .. " " .. public.index4)
    print(public.cock)
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
