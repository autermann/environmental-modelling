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
require("gd")

local COLORS = {
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

local World_ = {

    init = function(self, fun)
        self:each(function(cell, ...)
            cell.species = fun(self, cell, ...)
        end)
        self:createNeighborhood({
            strategy = "vonneumann",
            self = false
        })
    end,

    each = function(self, fun)
        return forEachCell(self, fun)
    end,

    update = function(self)
        self:each(function(cell)
            local p = table.fill(#self.species, 0)
            forEachNeighbor(cell, function(cell, neighbor, weight)
                local this, that = cell.species, neighbor.past.species
                p[that] = p[that] + (1/4) * self.pmatrix[that][this]
            end)
            p = table.shuffle(p, "species", "p")
            for i = 1, #p do
                if math.random() < p[i].p then
                    cell.species = p[i].species
                    break
                end
            end
        end)
    end,

    openFile = function(self)
        self.file = io.open(self.filename, "w")
    end,

    closeFile = function(self)
        self.file:close()
    end,

    writeHeader = function(self)
        self.file:write(tabs("Time", self.species) .. "\n")
    end,

    writeHistogram = function(self, time)
        local hist = table.fill(#self.species, 0)
        self:each(function(cell)
            hist[cell.species] = hist[cell.species] + 1
        end)
        self.file:write(tabs(time, hist) .. "\n")
    end,

    printImage = function(self, time)
        local image = gd.createTrueColor(self.xdim * self.imageCellSize,
                                         self.ydim * self.imageCellSize)
        local colors = {}
        for i = 1, #self.species do
            colors[i] = image:colorResolve(COLORS[i][1],
                                           COLORS[i][2],
                                           COLORS[i][3])
        end
        self:each(function(cell)
            image:filledRectangle(
                cell.x * self.imageCellSize,
                (cell.y + 1) * self.imageCellSize - 1,
                (cell.x + 1) * self.imageCellSize - 1,
                cell.y * self.imageCellSize,
                colors[cell.species])
        end)
        if self.imageType == "gif" then
            image:gif(self.imgprefix .. time .. ".gif")
        elseif self.imageType == "png" then
            image:png(self.imgprefix .. time .. ".png")
        elseif self.imageType == "jpeg" then
            image:jpeg(self.imgprefix .. time .. ".jpg", 80)
        end
    end
}
setmetatable(World_, {__index = CellularSpace_})

local worldmt = {__index = World_}

function World(attr)
    local world = CellularSpace{
        xdim = attr.xdim,
        ydim = attr.ydim,
        pmatrix = attr.pmatrix,
        species = attr.species,
        filename = attr.filename,
        imgprefix = attr.imgprefix,
        imageType = attr.imageType,
        imageCellSize = attr.imageCellSize
    }
    setmetatable(world, worldmt)
    world:init(attr.init)
    return world
end

