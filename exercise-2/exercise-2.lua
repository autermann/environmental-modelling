-- Environmental Modelling Exercise 2
-- Author: Christian Autermann
growth = (function()
    local linearEq = function (p1, p2)
        local m = (p2[2] - p1[2])/(p2[1] - p1[1])
        local n = p1[2] - m * p1[1]
        return function(x) return m * x + n end
    end
    local highest = (5 + 40)/2
    local lower = linearEq({ 5, 0 }, { highest, 1})
    local higher = linearEq({ highest, 1}, { 40, 0 })
    return function(t)
        if t <= 5 or t >= 40 then return 0
        elseif t < highest then return lower(t)
        else return higher(t) end
    end
end)()

local worlds = { "Constant Luminosity",
                 "Luminosity jumps to 1.10 in 2010",
                 "Luminosity drops to 0.95 in 2010",
                 "Luminosity grows 4% each ten years from 2010 until 2040" }

for i = 1, #worlds do
    worlds[i] = Cell{ title = worlds[i], size = 1000,
        white = 400, black = 270, empty = 330,
        local_temp_white = 0, local_temp_black = 0,
        global_temp = 0, albedo = 0, luminosity = 1.0
    }
    Observer{ subject = worlds[i], type = "chart",
              title = worlds[i].title .. ": Ground",
              xLabel = "time", yLabel = "ha",
              attributes = { "white",
                             "black",
                             "empty" },
              curveLabels = { "White Daisies",
                              "Black Daisies",
                              "Empty Ground" } }
    Observer{ subject = worlds[i], type = "chart",
              title = worlds[i].title .. ": Temperature",
              xLabel = "time", yLabel = "C",
              attributes = { "local_temp_white",
                             "local_temp_black",
                             "global_temp" },
              curveLabels = { "Local White Daisies Temperature",
                              "Local Black Daisies Temperature",
                              "Average Temperature" } }
    worlds[i]:notify(0)
end

Timer{
    Event{time = 11, action = function(e)
        worlds[2].luminosity = 1.10
        worlds[3].luminosity = 0.95
        return false
    end},
    Event{time = 1, period = 10, action = function(e)
        worlds[4].luminosity = worlds[4].luminosity * 1.04
        if e:getTime() >= 40 then return false end
    end},
    Event{action = function(e)
        for _, world in ipairs(worlds) do
            world.albedo = (0.75 * world.white +
                            0.50 * world.empty +
                            0.25 * world.black)/world.size
            world.global_temp = 200 * ((1 - world.albedo) * world.luminosity) - 80
            world.local_temp_white = world.global_temp - 20 * (world.albedo - 0.75)
            world.local_temp_black = world.global_temp + 20 * (world.albedo - 0.25)
            local white_decay = 0.3 * world.white
            if world.white < white_decay then white_decay = world.white end

            local black_decay = 0.3 * world.black
            if world.black < black_decay then black_decay = world.black end

            world.empty = world.empty + white_decay + black_decay

            local new_white = world.white * growth(world.local_temp_white)
            if new_white > world.empty then new_white = world.empty end

            local new_black = world.black * growth(world.local_temp_black)
            if new_black > world.empty then new_black = world.empty end

            local new = new_black + new_white
            if new > world.empty then
                new_black = (new_black / new) * world.empty
                new_white = (new_white / new) * world.empty
            end

            world.black = world.black - black_decay + new_black
            world.white = world.white - white_decay + new_white
            world.empty = world.empty -   new_white - new_black
        end
    end},
    Event{action = function(e)
        for _, world in ipairs(worlds) do
            world:notify(e:getTime())
        end
    end}
}:execute(60)
