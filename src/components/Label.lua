-- Label component: theme-aware text display
-- Props:
-- Text (string)
-- Size (UDim2) optional
-- TextSize (number) optional
-- Bold (boolean) optional
-- Parent (Instance) optional

local Theme = require(script.Parent.Parent.core.ThemeManager)
local Util = require(script.Parent.Parent.core.Util)
local Base = require(script.Parent.Parent.core.ComponentBase)

local Label = Base.extend({})

function Label.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, Label)
	self.Props = props

	local theme = Theme.current()
	local label = Util.Create("TextLabel", {
		Name = "MintLabel",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.fromOffset(160, 24),
		Text = tostring(props.Text or "Label"),
		TextColor3 = theme.colors.text,
		Font = props.Bold and Enum.Font.GothamBold or Enum.Font.Gotham,
		TextSize = props.TextSize or 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	self:_own(label)

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		label.TextColor3 = newTheme.colors.text
	end))

	self.Instance = label
	if props.Parent then label.Parent = props.Parent end
	return self
end

return Label

