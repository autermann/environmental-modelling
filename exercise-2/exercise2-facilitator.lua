-- Environmental Modelling Exercise 2
-- Script to describe the functions "growth" and "average_temperature".
-- This script is only an example of using and plotting the functions,
-- it should not be used as a starting point for implementing the model.
-- Author: Pedro Andrade
-- Version: 0.1
-- Date: 07/May/13

c1 = Cell{
	growth = 0
}

c2 = Cell{
	average_temperature = -40
}

o = Observer{
	subject = c1,
	type = "chart",
	attributes = {"growth"},
	title = "Growth",
	xLabel = "temperature",
	yLabel = "growth"
}

o = Observer{
	subject = c2,
	type = "chart",
	attributes = {"average_temperature"},
	title = "Average temperature based on the albedo",
	xLabel = "albedo",
	yLabel = "oC"
}

function growth(temperature)
	if temperature < 5 then
		return 0
	elseif temperature < 22.5 then
		return 0.0571 * temperature - 0.2857
	elseif temperature < 40 then
		return -0.0571 * temperature + 2.284
	else
		return 0
	end
end

function average_temperature(absorbed_luminosity)
	return 200 * absorbed_luminosity - 80
end

t = Timer{
	Event{time = 0, period = 0.1, action = function(e)
		time = e:getTime()
		c1.growth = growth(time)
		c1:notify(time)
		if time > 50 then return false end
	end},
	Event{time = 0.2, period = 0.02, action = function(e)
		time = e:getTime()
		c2.average_temperature = average_temperature(e:getTime())
		c2:notify(time)
		if time > 1 then return false end
	end}
}

t:execute(50)

