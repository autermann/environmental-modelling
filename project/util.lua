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

function mkdir(dir)
    os.execute("mkdir -p " .. dir)
end

function rmdir(dir)
    os.execute("rm -rf " .. dir)
end


function table.shuffle(t, key, value)
    local s = {}
    for k, v in pairs(t) do
        table.insert(s, { r = math.random(), [key] = k, [value] = v })
    end
    table.sort(s, function(a, b) return a.r < b.r end)
    for i = 1,#s do s[i].r = nil end
    return s
end

function table.indexOf(t, e)
    local idx
    if type(t) == "table" then
        for i = 1,#t do
            if t[i] == e then
                idx = i
                break
            end
        end
    end
    return idx
end

function table.fill(count, value)
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
