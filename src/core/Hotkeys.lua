-- Hotkeys: register keyboard shortcuts mapped to Registry actions or callbacks
-- API:
-- Hotkeys.bind("Ctrl+R", function() ... end) or Hotkeys.bind("Ctrl+R", { Action = "RunScript" })
-- Hotkeys.unbind("Ctrl+R")
-- Hotkeys.clear()
-- Hotkeys.enabled(true/false)

local UserInputService = game:GetService("UserInputService")

local Registry = require(script.Parent.Registry)

local Hotkeys = {}

local _enabled = true
local _bindings = {} -- comboId -> { callback=function, actionName=string }
local _conn

local function normalizeKey(key)
	key = string.upper(key)
	key = key:gsub("CTRL", "LeftControl"):gsub("CMD", "LeftMeta"):gsub("ALT", "LeftAlt")
	return key
end

local function parseCombo(combo)
	-- Supports: Ctrl+Shift+K, Alt+R, F5
	local parts = {}
	for token in string.gmatch(combo, "[^+]+") do
		parts[#parts+1] = normalizeKey(token)
	end
	return parts
end

local function comboId(parts)
	table.sort(parts)
	return table.concat(parts, "+")
end

local function currentModifiers()
	local parts = {}
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then parts[#parts+1] = "LeftControl" end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then parts[#parts+1] = "LeftShift" end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) then parts[#parts+1] = "LeftAlt" end
	return parts
end

local function ensureListener()
	if _conn then return end
	_conn = UserInputService.InputBegan:Connect(function(input, processed)
		if not _enabled or processed then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		-- Ignore when typing in a TextBox
		if UserInputService:GetFocusedTextBox() ~= nil then return end
		local parts = currentModifiers()
		local key = input.KeyCode.Name
		if key ~= "Unknown" then parts[#parts+1] = key end
		local id = comboId(parts)
		local binding = _bindings[id]
		if binding then
			if binding.callback then
				binding.callback()
			elseif binding.actionName then
				Registry.invoke(binding.actionName)
			end
		end
	end)
end

function Hotkeys.bind(combo, target)
	local parts = parseCombo(combo)
	local id = comboId(parts)
	if type(target) == "function" then
		_bindings[id] = { callback = target }
	elseif type(target) == "table" and type(target.Action) == "string" then
		_bindings[id] = { actionName = target.Action }
	else
		error("Hotkeys.bind requires a function or { Action = name }")
	end
	ensureListener()
end

function Hotkeys.unbind(combo)
	local id = comboId(parseCombo(combo))
	_bindings[id] = nil
end

function Hotkeys.clear()
	_bindings = {}
end

function Hotkeys.enabled(v)
	_enabled = v and true or false
end

return Hotkeys

