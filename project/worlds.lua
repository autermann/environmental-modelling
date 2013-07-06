require("util")
require("excel")
require("gd")

local colors = {
    {255,   0,   0},
    {255, 255,   0},
    {255, 127,   0},
    {128,  64,  64},
    {  0, 255,   0},
    {  0, 255, 255},
    {  0,   0, 255},
    {160, 160, 160},
    {255,   0, 255}
}
local symbols = { "#", "+", "@", "$", "/", "ß", "€", "¶", "¢"}

local Worlds_ = {

    each = function(self, f)
        for _,w in ipairs(self) do f(w) end
    end,

    notify = function(self, t)
        self:each(function(w)
            w:notify(t)
        end)
    end,

    synchronize = function(self)
        self:each(function(w) w:synchronize() end)
    end,

    update = function(self)
        self:each(function(w)
            forEachCell(w, function(cell)
                local p = fill(#w.species, 0)
                forEachNeighbor(cell, function(cell, neighbor, weight)
                    local this, that = cell.species, neighbor.past.species
                    p[that] = p[that] + (1/4) * w.pmatrix[that][this]
                end)
                p = table.shuffle(p, "species", "p")
                for i = 1, #p do
                    if math.random() < p[i].p then
                        cell.species = p[i].species
                        break
                    end
                end
            end)
        end)
    end,

    openFiles = function(self)
        rmdir("out")
        mkdir("out")
        mkdir("out/images")
        self:each(function(w) w.file = io.open(w.filename, "w") end)
    end,

    closeFiles = function(self)
        self:each(function(w) w.file:close() end)
    end,

    printWorlds = function(self, time, last)
        if self.print then
            if (type(self.print) ~= "number" or (last or time % self.print == 0)) then
                local width = 2 * self.xdim * #self + 3 * #self - 4
                local time = time .. " "
                io.write(time .. string.rep("-", width - string.len(time)) .."\n")
                for y = 1, self.ydim do
                    for m = 1, #self do
                        for x = 1, self.xdim do
                            local cell = self[m].cells[self.ydim * (x - 1) + y]
                            io.write(symbols[cell.species])
                            if x ~= self.xdim then io.write(" ") end
                        end
                        if m ~= #self then io.write(string.rep(" ", 4)) end
                    end
                    if y ~= self.ydim then io.write("\n") end
                end
                io.write("\n")
                local S = #self.species
                for i, s in pairs(self.species) do
                    io.write(s .. " (" .. symbols[i] .. ")")
                    if i == S then
                        io.write("\n")
                    else
                        io.write(" ")
                    end
                end
                io.write(string.rep("-", width) .."\n\n")
            end
        end
    end,

    printImages = function(self, time, last)
        if self.image then
            if (type(self.image) ~= "number" or (last or time % self.image == 0)) then
                self:each(function(w)
                    local image = gd.createTrueColor(w.xdim * self.imageCellSize,
                                                     w.ydim * self.imageCellSize)
                    local c = {}
                    for i = 1, #self.species do
                        c[i] = image:colorResolve(colors[i][1],
                                                  colors[i][2],
                                                  colors[i][3])
                    end
                    forEachCell(w, function(cell)
                        image:filledRectangle(
                            cell.x * self.imageCellSize,
                            (cell.y + 1) * self.imageCellSize - 1,
                            (cell.x + 1) * self.imageCellSize - 1,
                            cell.y * self.imageCellSize,
                            c[cell.species])
                    end)
                    image:png(w.imgprefix .. "-" .. time .. ".png")
                end)
            end
        end
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

    writeHeader = function(self)
        self:each(function(w)
            w.file:write(tabs("Time", w.species) .. "\n")
        end)
    end,

    writeHistogram = function(self, time)
        self:each(function(w)
            local hist = fill(#self.species, 0)
            forEachCell(w, function(cell)
                hist[cell.species] = hist[cell.species] + 1
            end)
            w.file:write(tabs(time, hist) .. "\n")
        end)
    end,

    init = function(self, executions, init)
        for i, fun in ipairs(init) do
            for j = 1, executions do
                local world = CellularSpace{
                    xdim = self.xdim,
                    ydim = self.ydim,
                    pmatrix = self.pmatrix,
                    species = self.species,
                    filename = "out/model-".. i .. "-" .. j .. ".csv",
                    imgprefix = "out/images/model-".. i .. "-" .. j
                }
                forEachCell(world, function(cell, ...)
                    cell.species = fun(world, cell, ...)
                end)
                world:createNeighborhood({
                    strategy = "vonneumann",
                    self = false
                })
                table.insert(self, world)
            end
        end
    end,

    run = function(self, iterations)
        self:openFiles()
        self:writeHeader()
        Timer{
            Event{time = 0, action = function(e)
                self:writeHistogram(e:getTime())
                self:printWorlds(e:getTime(), e:getTime() == iterations)
                self:printImages(e:getTime(), e:getTime() == iterations)
            end},
            Event{action = function(e)
                self:synchronize()
                self:update()
            end}
        }:execute(iterations)
        self:closeFiles()
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
    local worlds = {
        xdim = attr.xdim or 40,
        ydim = attr.ydim or 40,
        species = attr.species,
        pmatrix = attr.pmatrix,
        print = attr.print or false,
        image = attr.image or false,
        imageCellSize = attr.imageCellSize or 40
    }
    setmetatable(worlds, {__index = Worlds_})
    worlds:init(attr.executions, attr.init)
    return worlds
end
