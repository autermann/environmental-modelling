require "util"
require "excel"
require "world"

function Worlds(executions, species, pmatrix, init)

	assert(#species == #pmatrix)
	for _,v in ipairs(pmatrix) do
		assert(#species == #v)
	end

	local worlds = {}
	for i, f in ipairs(init) do
		for j = 1,executions do
			worlds[(i - 1) * executions + j] 
				= World(species, pmatrix, "out/model-".. i .. "-" .. j .. ".csv", f)
		end
	end
	function worlds:each(f)
		for _,w in ipairs(self) do f(w) end
	end
	function worlds:run(iterations)
		rmdir("out")
		mkdir("out")
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
		self:convertToExcel("out/all.xml", worlds:files())
	end

	function worlds:files()
		local files = {}
		self:each(function(w)
			files[w.filename] = w.filename:gsub("out/", ""):gsub("%.csv","")
		end)
		return pairs(files)
	end

	function worlds:convertToExcel(filename)
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
	end
	return worlds
end