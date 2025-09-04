-- StatusBar component: bottom bar showing status text and indicators
-- Props:
-- Text (string)
-- Sandbox ("Sandboxed"|"Unsafe"|"Offline"|"Online")
-- Size (UDim2) default (520, 24)
-- Parent (Instance)

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Base = require(script.Parent.Parent.core.ComponentBase)

local StatusBar = Base.extend({})

local function indicatorColor(state, theme)
	local t = theme.colors
	if state == "Sandboxed" then return t.success end
	if state == "Online" then return t.primary end
	if state == "Unsafe" then return t.error end
	return t.warning -- Offline or unknown
end

function StatusBar.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, StatusBar)

	local theme = Theme.current()
	local root = Util.Create("Frame", {
		Name = "MintStatusBar",
		BackgroundColor3 = theme.colors.surface,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(520, 24),
	})
	self:_own(root)
	Util.Roundify(root, 6, theme.colors.border, 0.9)
	Util.Padding(root, 6)

	local text = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -80, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = tostring(props.Text or "Ready"),
		TextColor3 = theme.colors.text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
	})
	text.Parent = root

	local right = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(1, -80, 0, 0) })
	right.Parent = root

	local dot = Util.Create("Frame", { BackgroundColor3 = indicatorColor(props.Sandbox or "Offline", theme), BorderSizePixel = 0, Size = UDim2.fromOffset(10,10), Position = UDim2.new(0,0,0.5,-5) })
	Util.Roundify(dot, 5)
	dot.Parent = right

	local label = Util.Create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 16, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Text = tostring(props.Sandbox or "Offline"), Font=Enum.Font.Gotham, TextSize=12, TextColor3 = theme.colors.textMuted })
	label.Parent = right

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		root.BackgroundColor3 = newTheme.colors.surface
		text.TextColor3 = newTheme.colors.text
		dot.BackgroundColor3 = indicatorColor(label.Text, newTheme)
		label.TextColor3 = newTheme.colors.textMuted
	end))

	function self:SetText(t)
		text.Text = tostring(t)
	end
	function self:SetSandbox(state)
		label.Text = tostring(state)
		dot.BackgroundColor3 = indicatorColor(state, Theme.current())
	end

	self.Instance = root
	if props.Parent then root.Parent = props.Parent end
	return self
end

return StatusBar

