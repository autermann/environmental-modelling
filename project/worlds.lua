require "util"
require "excel"
require "world"

local colors = {
	"red",
	"yellow",
	"orange",
	"brown",
	"green",
	"cyan",
	"blue",
	"gray",
	"magenta"
}

local Worlds_ = {
	getExecutions = function(self)
		return self.executions
	end,
	getSpecies = function(self)
		return self.species
	end,
	getProbabilities = function(self)
		return self.pmatrix
	end,
	each = function(self, f)
		for _,w in ipairs(self) do f(w) end
	end,
	init = function(self, init)
		-- verify pmatrix
		assert(#self:getSpecies() == #self:getProbabilities())
		for _,v in ipairs(self:getProbabilities()) do
			assert(#self:getSpecies() == #v)
		end
		for i, f in ipairs(init) do
			for j = 1,self:getExecutions() do
				local w = World(self:getSpecies(), self:getProbabilities(),
					"out/model-".. i .. "-" .. j .. ".csv", f)
				-- only observe one run per init function
				w.observe = false--i == 1
				self[(i - 1) * self:getExecutions() + j] = w
			end
		end
		local colorBar = {}
		for i,s in ipairs(self.species) do
			colorBar[i] = { color = colors[i], value = s }
		end
		self.legend = Legend{
			grouping = "uniquevalue",
			colorBar = colorBar
		}
	end,
	files = function(self)
		local files = {}
		self:each(function(w)
			files[w:getFilename()] =
				w:getFilename():gsub("out/", ""):gsub("%.csv","")
		end)
		return pairs(files)
	end,
	convertToExcel = function(self, filename)
		local xls = ExcelXML(filename)
		xls:writeWorkbook(function()
			for filename, sheetname in self:files() do
				xls:writeWorksheet(sheetname, function()
					local l, file = 0, io.open(filename, "r")
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
	end,
	run = function(self, iterations)
		rmdir("out")
		mkdir("out")

		-- open the log files
		self:each(function(w) w:open() end)

		-- create the observers
		self:each(function(w)
			if w.observe then
				w.observer = Observer{
					subject = w,
					type = "chart",
					attributes = { "species" },
					--legends= { self.legend }
				}
			end
		end)

		self:each(function(w) w:notify(0) end)

		local timer = Timer{
			-- write the file header
			Event{time = 0, action = function(e)
				self:each(function(w)
					w:writeln("Time", w:getSpecies())
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
					if w.observe then w:notify(e:getTime()) end
				end)
			end}
		}
		-- execution
		timer:execute(iterations)
		-- close the log files ...
		self:each(function(w) w:close() end)
		-- ... and merge them
		self:convertToExcel("out/all.xml", self:files())
	end
}


function Worlds(executions, species, pmatrix, init)
	local worlds = {
		executions = executions,
		species = species,
		pmatrix = pmatrix
	}
	setmetatable(worlds, {__index = Worlds_})
	worlds:init(init)
	return worlds
end