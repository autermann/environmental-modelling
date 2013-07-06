-- platform specific
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
