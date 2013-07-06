require("worlds")
require("util")

local species = {
    "Lolium",
    "Agrostis",
    "Holcus",
    "Poa",
    "Cynosurus"
}

local function banded(order)
    local idx = {}
    for i,s in ipairs(order) do
        idx[i] = table.indexOf(species, s)
    end
    return function(world, cell)
        return idx[math.floor(cell.x/(world.xdim/#order)) + 1]
    end
end

math.randomseed(os.time())

local worlds = Worlds{
    executions = 5,
    xdim = 40,
    ydim = 40,
    species = species,
    print = false,
    image = true,
    imageCellSize = 40,
    imageType = "gif",
    pmatrix = {
        { 0, 0.02, 0.06, 0.05, 0.03 },
        { 0.23, 0, 0.09, 0.32, 0.37 },
        { 0.06, 0.08, 0, 0.16, 0.09 },
        { 0.44, 0.06, 0.06, 0, 0.11 },
        { 0.03, 0.02, 0.03, 0.05, 0 }
    },
    init = {
        function(world) return math.random(#world.species) end,
        banded({ "Agrostis", "Holcus", "Lolium", "Cynosurus", "Poa" }),
        banded({ "Agrostis", "Lolium", "Cynosurus", "Holcus", "Poa" }),
        banded({ "Agrostis", "Holcus", "Poa", "Cynosurus", "Lolium" })
    }
}


worlds:run(600)
