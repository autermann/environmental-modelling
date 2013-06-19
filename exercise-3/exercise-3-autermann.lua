math.randomseed(os.time())

SIMULATIONS = 5
EMPTY = 0
FOREST = 1
BURNING = 2
BURNED = 3

local levels = { 0.2, 0.4, 0.6, 0.8, 1.0 }
local params = {
	{ xdim =  50, ydim =  50, ntype = "vonneumann", iterations = 1, pBurn = 1.0 },
	{ xdim =  50, ydim =  50, ntype = "moore",      iterations = 1, pBurn = 1.0 },
	{ xdim =  50, ydim =  50, ntype = "vonneumann", iterations = 2, pBurn = 1.0 },
	{ xdim = 100, ydim = 100, ntype = "vonneumann", iterations = 1, pBurn = 1.0 },
	{ xdim =  50, ydim =  50, ntype = "vonneumann", iterations = 1, pBurn = 0.9 }
}

function distribution(world)
	local d = {}
	forEachCell(world, function(c)
		if d[c.cover] then 
			d[c.cover] = d[c.cover] + 1
		else d[c.cover] = 1 end
	end)
	local size = world.xdim * world.ydim
	for k,v in pairs(d) do d[k] = v/size end
	return d
end

function update(world)
	local burning = false
	forEachCell(world, function(cell)
		if cell.past.cover == FOREST then
			if math.random() <= world.pBurn then
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
			if cell.iteration >= world.iterations then 
				cell.cover = BURNED
			else burning = true end
		end
	end)
	return burning
end

function sim(worlds)
	local events = {}
	for i, world in ipairs(worlds) do
		events[i] = Event{action = function(e)
			world:synchronize()
			if not update(world) then
				world.finished = e:getTime()
				return false
			end
		end}
	end
	Timer(events):execute(1000)
end


function createWorld(name, initialCover, xdim, ydim, ntype, iterations, pBurn)
	local world = CellularSpace{ 
		name = name,
		xdim = xdim, 
		ydim = ydim,
		iterations = iterations,
		pBurn = pBurn
	}
	world:createNeighborhood{ 
		strategy = ntype,
		self = false
	}
	forEachCell(world, function(cell)
		cell.iteration = 0
		if math.random() > initialCover then
			cell.cover = EMPTY
		else 
			cell.cover = FOREST 
		end
	end)
	world:sample().cover = BURNING
	return world
end

-- world creation (seperated by initial forest level)
local worlds = {}
for j, level in ipairs(levels) do
	worlds[level] = {}
	for i, param in ipairs(params) do
		for k = 1,SIMULATIONS do
			table.insert(worlds[level], createWorld(
				i .. "." .. k .. " (".. level .. ")", level,
				param.xdim, param.ydim, param.ntype,
				param.iterations, param.pBurn))
		end
	end
end

-- execution
for l, w in pairs(worlds) do sim(w) end

-- obtaining results
local lines = {}
for l,w in pairs(worlds) do
	for _,world in ipairs(w) do
		local hist = distribution(world)
		table.insert(lines, { 
			world.name, 
			hist[EMPTY] or 0, 
			hist[FOREST] or 0,
			hist[BURNED] or 0,
			world.finished or -1,
			hist[BURNING] or 0 
		})
	end
	
end
table.insert(lines, 1, { "Run", "Empty", "Forest", 
						 "Burned", "Runtime", "Burning" })
for _,line in ipairs(lines) do
	print(table.concat(line, "\t"))
end