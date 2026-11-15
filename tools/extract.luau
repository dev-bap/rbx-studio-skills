--!strict
-- Write the Assistant skills shipped with the live Roblox Studio release to
-- skills/, one file per document. Run from the repository root:
--
--     lune run tools/extract.luau
--
-- skills/ is rewritten from scratch each time; git shows what changed.

local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")

local unzip = require("./lib/unzip")
local stringValues = require("./lib/stringValues")

local SKILLS = "Assistant/Packages/_Index/AssistantSkills/AssistantSkills/"

local function get(url: string): string
	local response = net.request({ url = url, headers = { ["User-Agent"] = "rbx-studio-skills" } })
	assert(response.ok, `{url}: HTTP {response.statusCode}`)
	return response.body
end

-- 1. Which Studio is live? (clientVersionUpload names its files on the CDN.)
local live = serde.decode("json", get("https://clientsettings.roblox.com/v2/client-version/WindowsStudio64"))

-- 2. Its built-in plugins, and the Assistant plugin inside them.
local zip = get(`https://setup.rbxcdn.com/{live.clientVersionUpload}-BuiltInStandalonePlugins.zip`)
local assistant = unzip(zip, "Optimized_Embedded_Signature/Assistant.rbxm")

-- 3. Every skill document is a StringValue under SKILLS.
if fs.isDir("skills") then
	fs.removeDir("skills")
end
local count = 0
for path, text in stringValues(assistant) do
	if string.sub(path, 1, #SKILLS) == SKILLS then
		local file = "skills/" .. string.sub(path, #SKILLS + 1) .. ".md"
		fs.writeDir(string.match(file, "^(.*)/") :: string)
		fs.writeFile(file, (string.gsub(text, "\r\n", "\n")))
		count += 1
	end
end
assert(count > 0, "no skill found: the Assistant plugin layout changed")
fs.writeFile("skills/STUDIO_VERSION", `{live.version} {live.clientVersionUpload}\n`)
print(`Studio {live.version}: {count} skill documents written to skills/.`)
