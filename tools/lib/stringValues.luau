--!strict
-- List every StringValue of a binary Roblox model (.rbxm) as path -> Value.
--
-- Lune's roblox.deserializeModel would do this, but it refuses Assistant.rbxm
-- (it expects BoolValue.Tags as a SharedString). This reads only the three
-- chunks needed: INST (instances of each class), PROP (their properties, of
-- which only strings are kept) and PRNT (who is whose parent).

local serde = require("@lune/serde")

-- Referent lists are int32 stored byte-interleaved, big-endian, zigzag encoded
-- and as differences from the previous one.
local function referents(b: buffer, at: number, count: number): ({ number }, number)
	local out, sum = {}, 0
	for k = 0, count - 1 do
		local v = 0
		for byte = 0, 3 do
			v = v * 256 + buffer.readu8(b, at + k + byte * count)
		end
		sum += if v % 2 == 0 then v // 2 else -(v + 1) // 2
		out[k + 1] = sum
	end
	return out, at + 4 * count
end

local function decompress(raw: string, size: number): string
	if string.sub(raw, 1, 4) == "\x28\xb5\x2f\xfd" then
		return serde.decompress("zstd", raw)
	end
	-- serde's lz4 wants the block prefixed with its decoded size.
	local prefix = buffer.create(4)
	buffer.writeu32(prefix, 0, size)
	return serde.decompress("lz4", buffer.tostring(prefix) .. raw)
end

return function(model: string): { [string]: string }
	local file = buffer.fromstring(model)
	assert(buffer.readstring(file, 0, 8) == "<roblox!", "not a binary Roblox model")

	local class: { [number]: string } = {} -- referent -> class name
	local members: { [number]: { number } } = {} -- class id -> referents
	local name: { [number]: string } = {}
	local value: { [number]: string } = {}
	local parent: { [number]: number } = {}

	local pos = 32
	while true do
		local kind = buffer.readstring(file, pos, 4)
		local packed, size = buffer.readu32(file, pos + 4), buffer.readu32(file, pos + 8)
		pos += 16
		if kind == "END\0" then
			break
		end
		local body = buffer.fromstring(if packed == 0
			then buffer.readstring(file, pos, size)
			else decompress(buffer.readstring(file, pos, packed), size))
		pos += if packed == 0 then size else packed

		if kind == "INST" then
			local id, len = buffer.readi32(body, 0), buffer.readu32(body, 4)
			local refs = referents(body, 8 + len + 5, buffer.readu32(body, 8 + len + 1))
			members[id] = refs
			for _, ref in refs do
				class[ref] = buffer.readstring(body, 8, len)
			end
		elseif kind == "PROP" then
			local id, len = buffer.readi32(body, 0), buffer.readu32(body, 4)
			local prop = buffer.readstring(body, 8, len)
			local at = 8 + len + 1
			local into = if prop == "Name" then name elseif prop == "Value" then value else nil
			if into and buffer.readu8(body, at - 1) == 0x01 then -- 0x01: string
				for _, ref in members[id] do
					local n = buffer.readu32(body, at)
					into[ref] = buffer.readstring(body, at + 4, n)
					at += 4 + n
				end
			end
		elseif kind == "PRNT" then
			local count = buffer.readu32(body, 1)
			local children, at = referents(body, 5, count)
			local parents = referents(body, at, count)
			for i, child in children do
				parent[child] = parents[i]
			end
		end
	end

	local result = {}
	for ref, text in value do
		if class[ref] == "StringValue" then
			local path, node = name[ref], parent[ref]
			while node and class[node] do
				path = `{name[node]}/{path}`
				node = parent[node]
			end
			result[path] = text
		end
	end
	return result
end
