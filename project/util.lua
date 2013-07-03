-- platform specific
function mkdir(dir) os.execute("mkdir -p " .. dir) end
function rmdir(dir) os.execute("rm -rf " .. dir) end

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
