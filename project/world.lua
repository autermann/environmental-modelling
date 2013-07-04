require "util"

local SpeciesCell_ = {
	each = function(self, f)
		forEachNeighbor(self, f)
	end,
	getSpecies = function(self)
		return self.species
	end,
	setSpecies = function(self, species)
		self.species = species
	end,
	getWorld = function(self)
		return self.parent
	end,
	getPropabilities = function(self)
		local p = fill(#self:getWorld():getSpecies(), 0)
		self:each(function(cell, neighbor, weight)
			local this, that = cell:getSpecies(), neighbor:getPast().species
			p[that] = p[that] + (1/weight) * self:getWorld():getPropability(that, this)
		end)
		return table.shuffle(p, "species", "p")
	end,
	update = function(self)
		local p = self:getPropabilities()
		for i = 1, #p do
			if math.random() < p[i].p then
				self:setSpecies(p[i].species)
				break
			end
		end
	end
}

local World_ = {
	each = function(self, f)
		forEachCell(self, f)
	end,
	init = function(self, init)
		self:each(function(cell, ...)
			setmetatable(cell, {__index = SpeciesCell_})
			cell:setSpecies(init(self, cell, ...))
		end)
		self:createNeighborhood({
			strategy = "vonneumann",
			self = false 
		})
	end,
	update = function(self)
		self:each(function(cell) cell:update() end)
	end,
	close = function(self)
		self.file:close()
	end,
	flush = function(self)
		self.file:flush()
	end,
	open = function(self)
		self.file = io.open(self.filename, "w")
	end,
	writeln = function(self, ...)
		self.file:write(tabs(...) .. "\n")
	end,
	getFilename = function(self)
		return self.filename
	end,
	getSpecies = function(self)
		return self.species
	end,
	getPropabilities = function(self)
		return self.pmatrix
	end,
	getPropability = function(self, s1, s2)
		return self:getPropabilities()[s1][s2]
	end,
	hist = function(self)
		local d = fill(#self:getSpecies(), 0)
		self:each(function(c)
			d[c:getSpecies()] = d[c:getSpecies()] + 1
		end)
		return d
	end
}

setmetatable(SpeciesCell_, {__index = Cell_})
setmetatable(World_, {__index = CellularSpace_})
function World(species, pmatrix, filename, init)
	local world = CellularSpace{
		xdim = 40, ydim = 40,
		filename = filename,
		pmatrix = pmatrix,
		species = species
	}
	setmetatable(world, {__index = World_})
	world:init(init)
	return world
end