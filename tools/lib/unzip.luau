--!strict
-- Read one file out of a zip archive.
--
-- A zip entry is a raw deflate stream whose CRC32 and size the archive's
-- directory already holds. Wrapped in a gzip header and trailer, serde can
-- inflate it, and checks the CRC on the way.

local serde = require("@lune/serde")

return function(zip: string, wanted: string): string
	local b = buffer.fromstring(zip)

	-- The directory's position is in the "end of central directory" record,
	-- the last 22 bytes of the file (more when the archive has a comment).
	local eocd = buffer.len(b) - 22
	while buffer.readu32(b, eocd) ~= 0x06054b50 do
		eocd -= 1
		assert(eocd >= 0, "not a zip archive")
	end

	local p = buffer.readu32(b, eocd + 16)
	for _ = 1, buffer.readu16(b, eocd + 10) do
		local nameLen = buffer.readu16(b, p + 28)
		local name = buffer.readstring(b, p + 46, nameLen)
		if string.gsub(name, "\\", "/") == wanted then
			local method = buffer.readu16(b, p + 10)
			local size = buffer.readu32(b, p + 20)
			local header = buffer.readu32(b, p + 42)
			local start = header + 30 + buffer.readu16(b, header + 26) + buffer.readu16(b, header + 28)
			local raw = buffer.readstring(b, start, size)
			if method == 0 then
				return raw
			end
			assert(method == 8, "unsupported zip compression")
			local trailer = buffer.create(8)
			buffer.writeu32(trailer, 0, buffer.readu32(b, p + 16)) -- CRC32
			buffer.writeu32(trailer, 4, buffer.readu32(b, p + 24)) -- uncompressed size
			return serde.decompress("gzip", "\x1f\x8b\x08\0\0\0\0\0\0\xff" .. raw .. buffer.tostring(trailer))
		end
		p += 46 + nameLen + buffer.readu16(b, p + 30) + buffer.readu16(b, p + 32)
	end
	error(`{wanted} is not in the archive`)
end
