-- ThemeManager: handles light/dark themes and reactive updates
local Event = require(script.Parent.Event)

local ThemeManager = {}

local themes = {
	Dark = {
		name = "Dark",
		colors = {
			background = Color3.fromRGB(18, 18, 20),
			surface = Color3.fromRGB(29, 29, 33),
			primary = Color3.fromRGB(93, 169, 255),
			primaryVariant = Color3.fromRGB(65, 135, 217),
			accent = Color3.fromRGB(255, 128, 64),
			text = Color3.fromRGB(236, 236, 236),
			textMuted = Color3.fromRGB(180, 180, 185),
			border = Color3.fromRGB(50, 50, 55),
			inputBg = Color3.fromRGB(24, 24, 27),
			success = Color3.fromRGB(72, 199, 116),
			warning = Color3.fromRGB(255, 204, 0),
			error = Color3.fromRGB(255, 99, 95),
		},
	},
	Light = {
		name = "Light",
		colors = {
			background = Color3.fromRGB(245, 246, 248),
			surface = Color3.fromRGB(255, 255, 255),
			primary = Color3.fromRGB(0, 122, 255),
			primaryVariant = Color3.fromRGB(0, 96, 204),
			accent = Color3.fromRGB(255, 149, 0),
			text = Color3.fromRGB(28, 28, 30),
			textMuted = Color3.fromRGB(99, 99, 102),
			border = Color3.fromRGB(226, 226, 229),
			inputBg = Color3.fromRGB(248, 249, 251),
			success = Color3.fromRGB(48, 209, 88),
			warning = Color3.fromRGB(255, 214, 10),
			error = Color3.fromRGB(255, 69, 58),
		},
	},
}

ThemeManager._current = themes.Dark
ThemeManager.changed = Event.new()

function ThemeManager.current()
	return ThemeManager._current
end

function ThemeManager.get(name)
	return themes[name]
end

function ThemeManager.set(name)
	local t = themes[name]
	if not t then return false end
	ThemeManager._current = t
	ThemeManager.changed:Fire(t)
	return true
end

function ThemeManager.toggle()
	if ThemeManager._current == themes.Dark then
		ThemeManager.set("Light")
	else
		ThemeManager.set("Dark")
	end
end

-- Allow custom theme registration
function ThemeManager.register(name, themeTable)
	assert(type(themeTable) == "table" and themeTable.colors, "Theme must be a table with colors field")
	themeTable.name = name
	themes[name] = themeTable
	return themeTable
end

return ThemeManager

