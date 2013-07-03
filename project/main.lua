require "worlds"

local pmatrix = {
	{ 0, 0.02, 0.06, 0.05, 0.03 },
	{ 0.23, 0, 0.09, 0.32, 0.37 },
	{ 0.06, 0.08, 0, 0.16, 0.09 },
	{ 0.44, 0.06, 0.06, 0, 0.11 },
	{ 0.03, 0.02, 0.03, 0.05, 0 }
}

local species = { 
	"Lolium",
	"Agrostis",
	"Holcus",
	"Poa",
	"Cynosurus"
}

function random()
	return function(world) 
		return math.random(#world.species)
	end
end

function banded(order)
	return function(world, cell)
		local width = world.xdim/#order
		-- cells coordinates are zero based, arrays one based ...
		local band = math.floor(cell.x/width) + 1
		return order[band]
	end
end

math.randomseed(os.time())

local init = {
	-- random
	random(),
	-- Agrostis, Holcus, Lolium, Cynosurus, Poa
	banded({ 2, 3, 1, 5, 4 }),
	-- Agrostis, Lolium, Cynosurus, Holcus, Poa
	banded({ 2, 1, 5, 3, 4 }),
	-- Agrostis, Holcus, Poa, Cynosurus, Lolium
	banded({ 2, 3, 4, 5, 1 })
}

-- create the worlds
local worlds = Worlds(1, species, pmatrix, init)

-- runs for around 20 minutes...
worlds:run(2)

-- merge the csv files to a single excel file
