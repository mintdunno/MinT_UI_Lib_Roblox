-- Slider component
-- Props:
-- Label (string)
-- Min (number) default 0
-- Max (number) default 100
-- Step (number) optional; if set, snaps value
-- Value (number) initial value
-- OnChanged (function:number)
-- Action (string) optional; Registry.invoke(Action, value)
-- Size (UDim2) default (200, 40)
-- Parent (Instance) optional

local UserInputService = game:GetService("UserInputService")

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Animator = require(script.Parent.Parent.core.Animator)
local Registry = require(script.Parent.Parent.core.Registry)
local Base = require(script.Parent.Parent.core.ComponentBase)

local Slider = Base.extend({})

local function clamp(v, min, max)
	if v < min then return min end
	if v > max then return max end
	return v
end

local function snap(v, step)
	if not step or step <= 0 then return v end
	return math.floor((v / step) + 0.5) * step
end

function Slider.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, Slider)

	self.Min = type(props.Min) == "number" and props.Min or 0
	self.Max = type(props.Max) == "number" and props.Max or 100
	self.Step = type(props.Step) == "number" and props.Step or nil
	self.Value = type(props.Value) == "number" and props.Value or self.Min
	self.OnChanged = props.OnChanged
	self.Action = props.Action

	local theme = Theme.current()

	local root = Util.Create("Frame", {
		Name = "MintSlider",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.fromOffset(220, 40),
	})
	self:_own(root)

	local vlist = Util.VList(root, 6)
	vlist.HorizontalAlignment = Enum.HorizontalAlignment.Left

	local label = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = tostring(props.Label or "Slider"),
		TextColor3 = theme.colors.text,
		Font = Enum.Font.Gotham,
		TextSize = 13,
	})
	label.Parent = root

	local track = Util.Create("Frame", {
		Name = "Track",
		BackgroundColor3 = theme.colors.border,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 6),
	})
	Util.Roundify(track, 3)
	track.Parent = root

	local fill = Util.Create("Frame", {
		Name = "Fill",
		BackgroundColor3 = theme.colors.primary,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
	})
	Util.Roundify(fill, 3)
	fill.Parent = track

	local knob = Util.Create("Frame", {
		Name = "Knob",
		BackgroundColor3 = theme.colors.surface,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromOffset(0, -4),
	})
	Util.Roundify(knob, 7, theme.colors.primary, 0)
	knob.Parent = fill

	local dragging = false
	local function setValueFromX(x)
		local absPos = track.AbsolutePosition.X
		local width = track.AbsoluteSize.X
		local alpha = clamp((x - absPos) / math.max(1, width), 0, 1)
		local newVal = self.Min + (self.Max - self.Min) * alpha
		newVal = snap(newVal, self.Step)
		newVal = clamp(newVal, self.Min, self.Max)
		self:SetValue(newVal, true)
	end

	local function refresh(animate)
		local alpha = (self.Value - self.Min) / math.max(1e-6, (self.Max - self.Min))
		alpha = clamp(alpha, 0, 1)
		local goalFill = { Size = UDim2.new(alpha, 0, 1, 0) }
		if animate then
			Animator.tween(fill, Animator.Durations.Fast, goalFill)
		else
			fill.Size = goalFill.Size
		end
	end

	function self:SetValue(v, fire)
		v = clamp(v, self.Min, self.Max)
		if self.Step then v = snap(v, self.Step) end
		self.Value = v
		refresh(true)
		if fire then
			if self.OnChanged then
				local ok, err = pcall(self.OnChanged, self.Value)
				if not ok then warn(err) end
			end
			if self.Action then
				Registry.invoke(self.Action, self.Value)
			end
		end
	end

	-- Input handling
	self:_trackConn(track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setValueFromX(UserInputService:GetMouseLocation().X)
		end
	end))
	self:_trackConn(track.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
	self:_trackConn(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setValueFromX(UserInputService:GetMouseLocation().X)
		end
	end))

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		label.TextColor3 = newTheme.colors.text
		track.BackgroundColor3 = newTheme.colors.border
		fill.BackgroundColor3 = newTheme.colors.primary
	end))

	refresh(false)

	self.Instance = root
	if props.Parent then root.Parent = props.Parent end
	return self
end

return Slider

