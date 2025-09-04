-- Panel component: a themed container
-- Props:
-- Size (UDim2)
-- Padding (number) optional, default 8
-- Layout ("Vertical"|"Horizontal") optional
-- Parent (Instance) optional

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Base = require(script.Parent.Parent.core.ComponentBase)

local Panel = Base.extend({})

function Panel.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, Panel)
	self.Props = props

	local theme = Theme.current()
	local panel = Util.Create("Frame", {
		Name = "MintPanel",
		BackgroundColor3 = theme.colors.surface,
		BorderSizePixel = 1,
		BorderColor3 = theme.colors.border,
		Size = props.Size or UDim2.fromOffset(300, 400),
	})
	self:_own(panel)

	Util.Roundify(panel, 8, theme.colors.border, 1)
	Util.Padding(panel, props.Padding or 8)

	if props.Layout == "Vertical" then
		Util.VList(panel, props.Padding or 8, Enum.HorizontalAlignment.Left)
	elseif props.Layout == "Horizontal" then
		Util.HList(panel, props.Padding or 8, Enum.VerticalAlignment.Top)
	end

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		panel.BackgroundColor3 = newTheme.colors.surface
		panel.BorderColor3 = newTheme.colors.border
		local stroke = panel:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = newTheme.colors.border
		end
	end))

	self.Instance = panel
	if props.Parent then panel.Parent = props.Parent end
	return self
end

return Panel

