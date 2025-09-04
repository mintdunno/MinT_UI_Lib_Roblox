-- ProgressBar component
-- Props:
-- Value (number 0..1)
-- Label (string) optional
-- Size (UDim2) default (220, 12)
-- Parent (Instance) optional

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Animator = require(script.Parent.Parent.core.Animator)
local Base = require(script.Parent.Parent.core.ComponentBase)

local ProgressBar = Base.extend({})

function ProgressBar.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, ProgressBar)
	self.Value = math.clamp(tonumber(props.Value) or 0, 0, 1)

	local theme = Theme.current()

	local root = Util.Create("Frame", {
		Name = "MintProgressBar",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.fromOffset(220, 16),
	})
	self:_own(root)

	local track = Util.Create("Frame", {
		BackgroundColor3 = theme.colors.border,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 8),
		Position = UDim2.new(0, 0, 0.5, -4),
	})
	Util.Roundify(track, 4)
	track.Parent = root

	local fill = Util.Create("Frame", {
		BackgroundColor3 = theme.colors.primary,
		BorderSizePixel = 0,
		Size = UDim2.new(self.Value, 0, 1, 0),
	})
	Util.Roundify(fill, 4)
	fill.Parent = track

	local label
	if props.Label then
		label = Util.Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 0, -16),
			Text = tostring(props.Label),
			TextColor3 = theme.colors.text,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		label.Parent = root
	end

	function self:SetValue(v)
		self.Value = math.clamp(tonumber(v) or 0, 0, 1)
		Animator.tween(fill, Animator.Durations.Fast, { Size = UDim2.new(self.Value, 0, 1, 0) })
	end

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		track.BackgroundColor3 = newTheme.colors.border
		fill.BackgroundColor3 = newTheme.colors.primary
		if label then label.TextColor3 = newTheme.colors.text end
	end))

	self.Instance = root
	if props.Parent then root.Parent = props.Parent end
	return self
end

return ProgressBar

