math.randomseed(os.time())

EMPTY = 0
FOREST = 1
BURNING = 2
BURNED = 3

function distribution(cs)
	local d = {}
	forEachCell(cs, function(c)
		if d[c.cover] then 
			d[c.cover] = d[c.cover] + 1
		else d[c.cover] = 1 end
	end)
	local size = cs.xdim * cs.ydim
	for k,v in pairs(d) do d[k] = v/size end
	return d
end

function simulate(simulations, xdim, ydim, ntype, burningIterations, pBurn)
	function sim(initialCover)
		local world = CellularSpace{ xdim = xdim, ydim = ydim }
		world:createNeighborhood{ strategy = ntype, self = false }

		forEachCell(world, function(cell)
			cell.iteration = 0
			if math.random() > initialCover then
				cell.cover = EMPTY
			else
				cell.cover = FOREST
			end
		end)

		update = function(cs)
			local burning = false
			forEachCell(cs, function(cell)
				if cell.past.cover == FOREST then
					if math.random() <= pBurn then
						forEachNeighbor(cell, function(cell, neighbor)
							if neighbor.past.cover == BURNING then
								burning = true
								cell.cover = BURNING
								cell.iteration = 1
							end
						end)
					end
				elseif cell.past.cover == BURNING then
					cell.iteration = cell.past.iteration + 1
					if cell.iteration >= burningIterations then
						cell.cover = BURNED
					else
						burning = true
					end
				end
			end)
			return burning
		end
		world:sample().cover = BURNING
		Timer{Event{action = function(e)
			world:synchronize()
			local burning = update(world);
			if not burning then
				world.finished = e:getTime()
			end
			return burning
		end}}:execute(1000)

		return {
			runtime = world.finished,
			hist = distribution(world)
		}
	end
	local sims = {}
	for i = 1, simulations do
		table.insert(sims, sim(math.random())) 
	end
	return sims
end


-- execution
local worlds = {
	simulate(5,  50,  50, "vonneumann", 1, 1.0),
	simulate(5,  50,  50, "moore",      1, 1.0),
	simulate(5,  50,  50, "vonneumann", 2, 1.0),
	simulate(5, 100, 100, "vonneumann", 1, 1.0),
	simulate(5,  50,  50, "vonneumann", 1, 0.9)	
}
print("Run\t\tEmpty\t\tForest\t\tBurned\t\tRuntime\t\tBurning")
for i,runs in ipairs(worlds) do
	local avg = { i, 0, 0, 0, 0, 0}
	for j,run in ipairs(runs) do
		local runtime = run.runtime or -1
		local empty = run.hist[EMPTY] or 0
		local forest = run.hist[FOREST] or 0
		local burning = run.hist[BURNING] or 0
		local burned = run.hist[BURNED] or 0
		local l = { i .. "." .. j, empty, forest,
					burned, runtime, burning }
		avg[2] = avg[2] + empty
		avg[3] = avg[3] + forest
		avg[4] = avg[4] + burned
		avg[5] = avg[5] + runtime
		avg[6] = avg[6] + burning
		print(table.concat(l,"\t\t"))
	end
	for k = 2,6 do avg[k] = avg[k]/#runs end
	print(table.concat(avg,"\t\t"))
end