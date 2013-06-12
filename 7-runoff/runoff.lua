
cb = CellularSpace{
	database = "/home/auti/Source/environmental-modelling/7-runoff/cabecaDeBoi_4_2_0.mdb",
	theme = "cells90x90",
	select = {"height_ as height", "soilWater"}
}

cb:createNeighborhood{
	strategy = "3x3",
	filter = function(cell, neighbor)
		return cell ~= neighbor and cell.height >= neighbor.height
	end
}

heightLeg = Legend{
	grouping = "equalsteps",
	slices = 20,
	colorBar = {
		{color = "black", value = 0},
		{color = "white", value = 300}
	}
}

soilWaterLeg = Legend{
	grouping = "equalsteps",
	slices = 20,
	colorBar = {
		{color = "white", value = 0},
		{color = "blue", value = 10000}
	}
}

obs1 = Observer{
	subject = cb,
	type = "map",
	attributes = {"soilWater", "height"},
	legends= {soilWaterLeg, heightLeg}
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
	Event{action = function(e)
		cb:synchronize()
		forEachCell(cb, function(cell)
			cell.soilWater = 0
		end)
		
		forEachCell(cb, function(cell)
			if cell:getNeighborhood():size() > 0 then
				flow = cell.past.soilWater / cell:getNeighborhood():size()
				forEachNeighbor(cell, function(cell, neigh)
					neigh.soilWater = neigh.soilWater + flow
				end)
			else
				cell.soilWater = cell.soilWater + cell.past.soilWater
			end
		end)
	end},
	Event{priority = 5, action = function()
		cb:notify()
	end}
}

t:execute(100)

