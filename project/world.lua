require "util"

function World(species, pmatrix, filename, init)
	local world = CellularSpace{
		xdim = 40, 
		ydim = 40,
		filename = filename,
		pmatrix = pmatrix,
		species = species
	}
	function world:each(f)
		forEachCell(self, f)
	end

	function world:init()
		world:createNeighborhood({
			strategy = "vonneumann",
			self = false 
		})
		self:each(function(cell, ...) 
			cell.species = init(self, cell, ...) 
			function cell:each(f) 
				forEachNeighbor(cell, f)
			end
		end)
	end

	function world:update()
		self:each(function(cell)
			self:invade(cell)
		end)
	end
	
	function world:close()
		self.file:close()
	end
	
	function world:flush()
		self.file:flush()
	end
	
	function world:open()
		self.file = io.open(self.filename, "w")
	end
	
	function world:writeln(...)
		self.file:write(tabs(...) .. "\n")
	end
	
	function world:invade(cell)
		local weighted = self:weightProbabilities(cell)
		for i = 1, #weighted do
			if math.random() < weighted[i].p then
				cell.species = weighted[i].species
				break
			end
		end	
	end
	
	function world:hist()
		local d = fill(#self.species, 0)
		self:each(function(cell)
			d[cell.species] = d[cell.species] + 1
		end)
		return d
	end
	
	function world:countNeighbors(cell)
		local neighbors, counts = 0, fill(#self.species, 0)
		cell:each(function(cell, neighbor)
			neighbors = neighbors + 1
			counts[neighbor.past.species] 
				= counts[neighbor.past.species] + 1
		end)
		return neighbors, counts
	end

	function world:weightProbabilities(cell)
		local weighted, shuffled = {}, {}
		local neighbors, counts = self:countNeighbors(cell)
		for i,count in ipairs(counts) do
			weighted[i] = (count/neighbors) * self.pmatrix[i][cell.species]
		end
		-- shuffle the species and iterate till invasion
		for i = 1,#weighted do
			shuffled[i] = { rnd = math.random(), species= i, p = weighted[i] } 
		end
		table.sort(shuffled, function(a, b) return a.rnd < b.rnd end)
		return shuffled
	end

	world:init()
	
	return world
end