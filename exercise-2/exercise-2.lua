-- Environmental Modelling Exercise 2
-- Author: Christian Autermann
constants = {
  decay = 0.3,
  temp = { min = 5, max = 40},
  albedo = { white = 0.75, black = 0.25, empty = 0.5}
}
printf = function(s, ...)
  return print(s:format(...))
end

growth = (function()
    local linearEq = function (p1, p2)
        local m = (p2[2] - p1[2])/(p2[1] - p1[1])
        local n = p1[2] - m * p1[1]
        return function(x) return m * x + n end
    end
    local highest = (constants.temp.min + constants.temp.max)/2
    local lower = linearEq({ constants.temp.min, 0 }, { highest, 1})
    local higher = linearEq({ highest, 1}, { constants.temp.max, 0 })
    return function(t)
        if t <= constants.temp.min 
          or t >= constants.temp.max then return 0
        elseif t < highest then return lower(t)
        else return higher(t) end
    end
end)()

function new(e, p, t)
  local n = p * growth(t)
  if n > e then return e else return n end
end

function decay(p)
  local d = constants.decay * p
  if p < d then return p else return d end
end

function calculate(w)
  w.albedo = (1/w.size) * (constants.albedo.white * w.white 
                         + constants.albedo.empty * w.empty 
                         + constants.albedo.black * w.black)
  w.global_temp = 200 * ((1 - w.albedo) * w.luminosity) - 80
  w.local_temp_white = w.global_temp - 20 * math.abs(w.albedo - constants.albedo.white)
  w.local_temp_black = w.global_temp + 20 * math.abs(w.albedo - constants.albedo.black)
end

local worlds = {}
for i = 1, 4 do
    worlds[i] = Cell{ 
      size = 1000,
      white = 400, 
      black = 270, 
      empty = 330,
      local_temp_white = 0, 
      local_temp_black = 0,
      global_temp = 0,
      albedo = 0, 
      luminosity = 1.0,
      print = function(self)
        printf("Temperatures:\n\tGlobal: %g\n\tWhite: %g\n\tBlack: %g\n\t", 
               self.global_temp, self.local_temp_white, self.local_temp_black)
        printf("Populations:\n\tEmpty: %g\n\tWhite: %g\n\tBlack: %g\n\t", 
               self.empty, self.white, self.black)
      end 
    }
    Observer{ subject = worlds[i], type = "chart",
              title = i .. ": Ground",
              xLabel = "time", yLabel = "ha",
              attributes = { "white",
                             "black",
                             "empty" },
              curveLabels = { "White Daisies",
                              "Black Daisies",
                              "Empty Ground" } }
    Observer{ subject = worlds[i], type = "chart",
              title = i .. ": Temperature",
              xLabel = "time", yLabel = "C",
              attributes = { "local_temp_white",
                             "local_temp_black",
                             "global_temp" },
              curveLabels = { "Local White Daisies Temperature",
                              "Local Black Daisies Temperature",
                              "Average Temperature" } }
    calculate(worlds[i])
    worlds[i]:notify(0)
end

function normalize(empty, black, white)
  local new = black + white
  if new > empty then
    return (black / new) * empty, 
           (white / new) * empty
  else return black, white end
end

Timer{
    Event{time = 11, action = function(e)
        worlds[2].luminosity = 1.10
        worlds[3].luminosity = 0.95
        return false
    end},
    Event{time = 11, period = 10, action = function(e)
        worlds[4].luminosity = worlds[4].luminosity * 1.04
        if e:getTime() >= constants.temp.max then return false end
    end},
    Event{action = function(e)
        for _, w in ipairs(worlds) do
            calculate(w)

            local white_decay = decay(w.white)
            local black_decay = decay(w.black)
            
            w.empty = w.empty + white_decay + black_decay

            local new_white = new(w.empty, w.white, w.local_temp_white)
            local new_black = new(w.empty, w.black, w.local_temp_black)
            new_black, new_white = normalize(w.empty, new_black, new_white)

            
            w.black = w.black - black_decay + new_black
            w.white = w.white - white_decay + new_white
            w.empty = w.empty -   new_white - new_black
        end
    end},
    Event{period=1, action = function(e)
        for _, w in ipairs(worlds) do
          w:notify(e:getTime())
        end
    end}
}:execute(50)

for _, w in ipairs(worlds) do w:print() end