--[[
Cellular automaton models of interspecific
competition for space – the effect of pattern
on process -- Silverton et al.

Author: Christian Autermann

Due some error no Observer could be used:
.../CellularSpace.lua:282: bad argument #-2
    to 'notify' (TeCell expected, got nil)

Instead all observing is done manually. This
includes outputting the worlds to console,
images (to do so this script uses lua-gd[1]),
csv and Excel compatible XML format in './out/'.

There are two plattform specific method in util.lua,
which have to be adjusted (mkdir, rmdir).

[1] http://ittner.github.io/lua-gd/
]]--
require("util")
require("excel")
require("world")


local SYMBOLS = { "#", "+", "@", "$", "/", "ß", "€", "¶", "¢"}

local Worlds_ = {

    each = function(self, fun)
        for _,w in ipairs(self) do fun(w) end
    end,

    printWorlds = function(self, time)
        local width = 2 * self.xdim * #self + 3 * #self - 4
        local time = time .. " "
        io.write(time .. string.rep("-", width - string.len(time)) .."\n")
        for y = 1, self.ydim do
            for m = 1, #self do
                for x = 1, self.xdim do
                    local cell = self[m].cells[self.ydim * (x - 1) + y]
                    io.write(SYMBOLS[cell.species])
                    if x ~= self.xdim then io.write(" ") end
                end
                if m ~= #self then io.write(string.rep(" ", 4)) end
            end
            if y ~= self.ydim then io.write("\n") end
        end
        io.write("\n")
        local S = #self.species
        for i, s in pairs(self.species) do
            io.write(s .. " (" .. SYMBOLS[i] .. ")")
            if i == S then io.write("\n") else io.write(" ") end
        end
        io.write(string.rep("-", width) .."\n\n")
    end,

    mergeFiles = function(self)
        local files = {}
        self:each(function(w)
            files[w.filename] =
                w.filename:gsub("out/", ""):gsub("%.csv","")
        end)
        local xls = ExcelXML("out/all.xml")
        xls:writeWorkbook(function()
            for filename, sheetname in pairs(files) do
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

    init = function(self, executions, init)
        rmdir(self.out)
        mkdir(self.out)
        mkdir(self.out .. "/images")
        mkdir(self.out .. "/csv")
        for i, fun in ipairs(init) do
			mkdir(self.out .. "/images/model" .. i)
            for j = 1, executions do
                local imgdir = self.out .. "/images/model" .. i .. "/run" .. j
				mkdir(imgdir)
                table.insert(self, World({
                    init = fun,
                    xdim = self.xdim,
                    ydim = self.ydim,
                    pmatrix = self.pmatrix,
                    species = self.species,
                    filename = self.out .. "/csv/model-".. i .. "-" .. j .. ".csv",
                    imgprefix = imgdir .. "/",
                    imageType = self.imageType,
                    imageCellSize = self.imageCellSize
                }))
            end
        end
    end,

    observe = function(self, time, iterations)
        self:each(function(w)
            w:writeHistogram(time)
        end)
        if self.image and (time == iterations or time % self.image == 0) then
            self:each(function(w)
                w:printImage(time)
            end)
        end
        if self.print and (time == iterations or time % self.print == 0) then
            self:printWorlds(time)
        end
    end,

    run = function(self, iterations)
        self:each(function(w)
            w:openFile()
            w:writeHeader()
        end)
        Timer({
            Event{time = 0, action = function(e)
                self:observe(e:getTime(), iterations)
            end},
            Event{action = function(e)
                self:each(function(w)
                    w:synchronize()
                    w:update()
                end)
            end}
        }):execute(iterations)

        self:each(function(w) w:closeFile() end)
        self:mergeFiles()
    end
}

function Worlds(attr)
    assert(type(attr.species) == "table")
    assert(type(attr.pmatrix) == "table")
    if type(attr.init) == "function" then attr.init = {attr.init} end
    assert(type(attr.init) == "table")
    if type(attr.executions) == "number" then
        attr.executions = attr.executions or 1
    else
        attr.executions = 1
    end
    assert(#attr.species == #attr.pmatrix)
    for _,v in ipairs(attr.pmatrix) do
        assert(#attr.species == #v)
    end
    if attr.image == true then attr.image = 1 end
    if attr.print == true then attr.print = 1 end
    local worlds = {
        out = attr.out or "out",
        xdim = attr.xdim or 40,
        ydim = attr.ydim or 40,
        species = attr.species,
        pmatrix = attr.pmatrix,
        print = attr.print or false,
        image = attr.image or false,
        imageType = attr.imageType or "png",
        imageCellSize = attr.imageCellSize or 40
    }
    setmetatable(worlds, {__index = Worlds_})
    worlds:init(attr.executions, attr.init)
    return worlds
end
