-- TextInput component
-- Props:
-- Placeholder (string)
-- Text (string) initial
-- ClearTextOnFocus (boolean)
-- OnChanged (function:string)
-- OnSubmitted (function:string)
-- Validate (function:string -> boolean, string|nil) returns ok, errMsg
-- Action (string) optional; Registry.invoke(Action, text) on submit
-- Size (UDim2) default (220, 32)
-- Parent (Instance) optional

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Animator = require(script.Parent.Parent.core.Animator)
local Registry = require(script.Parent.Parent.core.Registry)
local Base = require(script.Parent.Parent.core.ComponentBase)

local TextInput = Base.extend({})

function TextInput.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, TextInput)
	self.Props = props
	self.Text = props.Text or ""

	local theme = Theme.current()

	local root = Util.Create("Frame", {
		Name = "MintTextInput",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.fromOffset(220, 32),
	})
	self:_own(root)

	local box = Util.Create("TextBox", {
		Name = "Box",
		BackgroundColor3 = theme.colors.inputBg,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ClearTextOnFocus = props.ClearTextOnFocus == true,
		Text = self.Text,
		PlaceholderText = props.Placeholder or "Type here...",
		TextColor3 = theme.colors.text,
		PlaceholderColor3 = theme.colors.textMuted,
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	Util.Roundify(box, 6, theme.colors.border, 0.7)
	Util.Padding(box, 8)
	box.Parent = root

	local errorLabel = Util.Create("TextLabel", {
		Name = "Error",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 1, 2),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "",
		TextColor3 = theme.colors.error,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextTransparency = 1,
	})
	errorLabel.Parent = root

	local function setError(msg)
		if msg and msg ~= "" then
			errorLabel.Text = tostring(msg)
			Animator.tween(errorLabel, Animator.Durations.Fast, { TextTransparency = 0 })
			Animator.tween(box, Animator.Durations.Fast, { BackgroundColor3 = Color3.fromRGB(255, 240, 240) })
		else
			Animator.tween(errorLabel, Animator.Durations.Fast, { TextTransparency = 1 })
			Animator.tween(box, Animator.Durations.Fast, { BackgroundColor3 = theme.colors.inputBg })
		end
	end

	self:_trackConn(box:GetPropertyChangedSignal("Text"):Connect(function()
		self.Text = box.Text
		if props.OnChanged then
			local ok, err = pcall(props.OnChanged, self.Text)
			if not ok then warn(err) end
		end
		if props.Validate then
			local ok, errMsg = props.Validate(self.Text)
			setError(ok and nil or errMsg or "Invalid input")
		end
	end))

	self:_trackConn(box.FocusLost:Connect(function(enterPressed)
		local valid = true
		if props.Validate then
			local ok, errMsg = props.Validate(self.Text)
			valid = ok
			setError(ok and nil or errMsg or "Invalid input")
		end
		if enterPressed and valid then
			if props.OnSubmitted then
				local ok, err = pcall(props.OnSubmitted, self.Text)
				if not ok then warn(err) end
			end
			if props.Action then
				Registry.invoke(props.Action, self.Text)
			end
		end
	end))

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		box.BackgroundColor3 = newTheme.colors.inputBg
		box.TextColor3 = newTheme.colors.text
		box.PlaceholderColor3 = newTheme.colors.textMuted
		errorLabel.TextColor3 = newTheme.colors.error
	end))

	self.Instance = root
	self.Box = box
	if props.Parent then root.Parent = props.Parent end
	return self
end

function TextInput:SetText(text)
	self.Text = tostring(text or "")
	if self.Box then self.Box.Text = self.Text end
end

return TextInput

