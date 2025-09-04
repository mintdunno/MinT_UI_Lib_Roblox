-- Button component
-- Props:
-- Text (string)
-- Icon (string asset id) optional
-- Action (string) optional; if set, click invokes Registry.invoke(Action)
-- OnClick (function) optional
-- Style ("Primary"|"Secondary"|"Ghost") default Primary
-- Size (UDim2) optional; default {0,160},{0,36}
-- Parent (Instance) optional
-- Return: component table with Instance (TextButton)

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Animator = require(script.Parent.Parent.core.Animator)
local Registry = require(script.Parent.Parent.core.Registry)
local Base = require(script.Parent.Parent.core.ComponentBase)

local Button = Base.extend({})

local function styleColors(theme, style)
	if style == "Secondary" then
		return theme.colors.surface, theme.colors.text
	elseif style == "Ghost" then
		return Color3.fromRGB(0,0,0), theme.colors.text -- true transparent background via AutoButtonColor off
	else
		return theme.colors.primary, Color3.fromRGB(255,255,255)
	end
end

function Button.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, Button)
	self.Props = props

	local theme = Theme.current()
	local bgColor, textColor = styleColors(theme, props.Style)

	local btn = Util.Create("TextButton", {
		Name = "MintButton",
		Size = props.Size or UDim2.fromOffset(160, 36),
		AutoButtonColor = false,
		BackgroundTransparency = (props.Style == "Ghost") and 1 or 0,
		BackgroundColor3 = bgColor,
		BorderSizePixel = 0,
		Text = tostring(props.Text or "Button"),
		TextColor3 = textColor,
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
	})
	Util.Roundify(btn, 8, theme.colors.border, 0.6)
	Util.Padding(btn, 6)
	self:_own(btn)

	-- Hover/press micro-interactions
	if props.Style ~= "Ghost" then
		local unhover = Animator.bindHover(btn, theme.colors.primaryVariant)
		self:_trackCleanup(unhover)
	end
	local unpress = Animator.pressScale(btn)
	self:_trackCleanup(unpress)

	-- Icon optional (left)
	if props.Icon then
		local image = Util.Create("ImageLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(16, 16),
			Image = props.Icon,
			ImageColor3 = textColor,
			ZIndex = btn.ZIndex + 1,
		})
		image.Parent = btn
		-- shift text with a UIListLayout
		local container = Util.Create("Frame", {
			Name = "Inner",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1,1),
		})
		container.Parent = btn
		local layout = Util.HList(container, 6, Enum.VerticalAlignment.Center)
		image.Parent = container
		local textLabel = Util.Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -24, 1, 0),
			Text = btn.Text,
			TextColor3 = textColor,
			Font = btn.Font,
			TextSize = btn.TextSize,
		})
		textLabel.Parent = container
		btn.TextTransparency = 1
	end

	-- Theme reaction
	self:_trackConn(Theme.changed:Connect(function(newTheme)
		local bg, txt = styleColors(newTheme, props.Style)
		btn.BackgroundColor3 = (props.Style == "Ghost") and btn.BackgroundColor3 or bg
		btn.TextColor3 = txt
		local icon = btn:FindFirstChild("Icon", true)
		if icon and icon:IsA("ImageLabel") then
			icon.ImageColor3 = txt
		end
	end))

	self:_trackConn(btn.MouseButton1Click:Connect(function()
		if props.OnClick then
			local ok, err = pcall(props.OnClick)
			if not ok then warn("Mint Button OnClick error: " .. tostring(err)) end
		end
		if props.Action then
			Registry.invoke(props.Action)
		end
	end))

	self.Instance = btn
	if props.Parent then btn.Parent = props.Parent end
	return self
end

return Button

