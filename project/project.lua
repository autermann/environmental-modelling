PMATRIX = {
	{ 0, 0.02, 0.06, 0.05, 0.03 },
	{ 0.23, 0, 0.09, 0.32, 0.37 },
	{ 0.06, 0.08, 0, 0.16, 0.09 },
	{ 0.44, 0.06, 0.06, 0, 0.11 },
	{ 0.03, 0.02, 0.03, 0.05, 0 }
}

SPECIES = { 
	"Lolium",
	"Agrostis",
	"Holcus",
	"Poa",
	"Cynosurus"
}

function fill(count, value)
	local table = {}
	for i = 1,count do table[i] = value end
	return table
end

function tabs(...)
	local vals = {}
	for i, v in ipairs(arg) do
		if type(v) == "table" then
			for j, vv in ipairs(v) do
				table.insert(vals, vv)
			end
		else
			table.insert(vals, v)
		end
	end
	return table.concat(vals, "\t")
end

function XML(file)
	local xml = {}
	xml.indent = 0
	function xml:writeln(s)
		self.file:write(string.rep("\t", self.indent) .. s .. "\n")
	end
	function xml:incIndent()
		self.indent = self.indent + 1
	end
	function xml:decIndent()
		self.indent = self.indent - 1
	end
	function xml:startTag(s)
		self:writeln(s)
		self:incIndent()
	end
	function xml:endTag(s)
		self:decIndent()
		self:writeln(s)
	end
	function xml:open()
		self.file = io.open(file, "w")
		self:writeln('<?xml version="1.0"?>')
	end
	function xml:close()
		self.file:close()
	end
	return xml
end

function ExcelXML(file)
	local xls = XML(file)
	function xls:writeWorkbook(inner)
		self:open()
		self:startTag('<ss:Workbook xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">')
		inner()
		self:endTag("</ss:Workbook>")
		self:close()
	end
	function xls:writeWorksheet(name, inner)
		self:startTag('<ss:Worksheet ss:Name="' .. name .. '">')
		self:startTag('<ss:Table>')
		inner()
		self:endTag('</ss:Table>')
		self:endTag('</ss:Worksheet>')
	end
	function xls:writeRow(inner)
		self:startTag('<ss:Row>')
		inner()
		self:endTag('</ss:Row>')
	end
	function xls:writeCell(inner)
		self:startTag('<ss:Cell>')
		inner()
		self:endTag('</ss:Cell>')
	end
	function xls:writeData(type, value)
		self:writeln('<ss:Data ss:Type="' .. type .. '">' .. value .. '</ss:Data>')
	end
	return xls
end

function convertToExcel(filename, files)
	local xls = ExcelXML(filename)
	xls:writeWorkbook(function()
		for filename, sheetname in files do
			xls:writeWorksheet(sheetname, function()
				local file = io.open(filename, "r")
				local l = 0
				for line in file:lines() do
					l = l + 1
					xls:writeRow(function()
						for column in line:gmatch("([^\t]+)") do
							xls:writeCell(function()
								if l == 1 then
									xls:writeData("String", column)
								else
									xls:writeData("Number", column)
								end
							end)
						end
					end)
				end
			end)
		end
	end)
end

function Worlds(executions, init)
	local worlds = {}
	for i, f in ipairs(init) do
		for j = 1,executions do
			worlds[(i - 1) * executions + j] 
				= World("model-".. i .. "-" .. j .. ".csv", f)
		end
	end
	function worlds:each(f)
		for _,w in ipairs(self) do f(w) end
	end
	function worlds:run(iterations)
		self:each(function(w) w:open() end)
		local timer = Timer{
			-- write the file header
			Event{time = 0, action = function(e)
				self:each(function(w)
					w:writeln("Time", w.species)
				end)
				return false
			end},
			-- print out the histogramm
			Event{time = 0, --[[period = 10,]] action = function(e)
				self:each(function(w)
					w:writeln(e:getTime(), w:hist())
				end)
			end},
			-- update the world
			Event{action = function(e)
				self:each(function(w)
					w:synchronize()
					w:update()
				end)
			end}
		}
		timer:execute(iterations)
		self:each(function(w) w:close() end)
	end

	function worlds:files()
		local files = {}
		self:each(function(w)
			files[w.filename] = w.filename:gsub("%.csv","")
		end)
		return files
	end
	return worlds
end

function World(filename, init)
	local world = CellularSpace{
		xdim = 40, 
		ydim = 40,
		filename = filename,
		pmatrix = PMATRIX,
		species = SPECIES
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
local worlds = Worlds(5, init)

-- runs for around 20 minutes...
worlds:run(600)

-- merge the csv files to a single excel file
convertToExcel("all.xml", worlds:files())