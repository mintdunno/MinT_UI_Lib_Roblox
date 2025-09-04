-- Toggle (switch) component
-- Props:
-- Label (string)
-- Value (boolean) default false
-- OnChanged (function:boolean)
-- Action (string) optional; invokes Registry.invoke(Action, value)
-- Parent (Instance) optional

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Animator = require(script.Parent.Parent.core.Animator)
local Registry = require(script.Parent.Parent.core.Registry)
local Base = require(script.Parent.Parent.core.ComponentBase)

local Toggle = Base.extend({})

function Toggle.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, Toggle)
	self.Props = props
	self._value = props.Value == true

	local theme = Theme.current()

	local root = Util.Create("Frame", {
		Name = "MintToggle",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(200, 28),
	})
	self:_own(root)

	local layout = Util.HList(root, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left

	local knobW, knobH = 40, 22
	local track = Util.Create("TextButton", {
		Name = "Track",
		Size = UDim2.fromOffset(knobW, knobH),
		AutoButtonColor = false,
		BackgroundColor3 = theme.colors.border,
		BorderSizePixel = 0,
		Text = "",
	})
	Util.Roundify(track, knobH/2, theme.colors.border, 0.4)
	track.Parent = root

	local dot = Util.Create("Frame", {
		Name = "Dot",
		BackgroundColor3 = theme.colors.surface,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(knobH-6, knobH-6),
		Position = UDim2.fromOffset(3,3),
	})
	Util.Roundify(dot, (knobH-6)/2)
	dot.Parent = track

	local text = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -knobW-8, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = tostring(props.Label or "Toggle"),
		TextColor3 = theme.colors.text,
		Font = Enum.Font.Gotham,
		TextSize = 14,
	})
	text.Parent = root

	local function apply(v, animate)
		self._value = v
		local goalTrack = { BackgroundColor3 = v and theme.colors.primary or theme.colors.border }
		local goalDot = { Position = v and UDim2.fromOffset(knobW - (knobH-6) - 3, 3) or UDim2.fromOffset(3,3) }
		if animate then
			Animator.tween(track, Animator.Durations.Fast, goalTrack)
			Animator.tween(dot, Animator.Durations.Fast, goalDot)
		else
			track.BackgroundColor3 = goalTrack.BackgroundColor3
			dot.Position = goalDot.Position
		end
	end

	apply(self._value, false)

	self:_trackConn(track.MouseButton1Click:Connect(function()
		apply(not self._value, true)
		if props.OnChanged then
			local ok, err = pcall(props.OnChanged, self._value)
			if not ok then warn(err) end
		end
		if props.Action then
			Registry.invoke(props.Action, self._value)
		end
	end))

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		text.TextColor3 = newTheme.colors.text
		apply(self._value, false)
	end))

	self.Instance = root
	if props.Parent then root.Parent = props.Parent end
	return self
end

function Toggle:SetValue(v)
	if type(v) == "boolean" then
		self._value = v
	end
end

function Toggle:GetValue()
	return self._value
end

return Toggle

