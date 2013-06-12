
cb = CellularSpace{
	dbType = "mysql",
	host = "localhost",
	database = "cabeca",
	user = "root",
	password = "",
	theme = "cells90x90",
	select = {"height_ as height", "soilWater"}
}

soilWaterLeg = Legend{
	grouping = "equalsteps",
	slices = 20,
	colorBar = {
		{color = "white", value = 0},
		{color = "blue", value = 5000}
	}
}

obs1 = Observer{
	subject = cb,
	type = "map",
	attributes = {"soilWater"},
	legends= {soilWaterLeg}
}

cb:notify()

forEachCell(cb, function(cell)
	cell.soilWater = 0
end)

t = Timer{
	Event{action = function(e)
		forEachCell(cb,function(cell)
			if cell.height > 200 then
				cell.soilWater = cell.soilWater + 1000
			end
		end)
		return false
	end},
	Event{priority = 5, action = function()
		cb:notify()
	end}
}

t:execute(10)

