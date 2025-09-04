-- Toolbar component: horizontal button group for common actions
-- Props:
-- Items: array of { id=string, text=string, icon=string?, style='Primary'|'Secondary'|'Ghost', Action=string?, OnClick=function? }
-- Spacing (number) default 6
-- Parent (Instance)

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Animator = require(script.Parent.Parent.core.Animator)
local Registry = require(script.Parent.Parent.core.Registry)
local Base = require(script.Parent.Parent.core.ComponentBase)

local Toolbar = Base.extend({})

function Toolbar.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, Toolbar)
	self.Items = props.Items or {}

	local theme = Theme.current()
	local root = Util.Create("Frame", {
		Name = "MintToolbar",
		BackgroundColor3 = theme.colors.surface,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(10, 36),
	})
	self:_own(root)
	Util.Roundify(root, 8, theme.colors.border, 0.9)
	Util.Padding(root, 6)
	local layout = Util.HList(root, props.Spacing or 6, Enum.VerticalAlignment.Center)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left

	local function addItem(it)
		local btn = Util.Create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = (it.style == 'Ghost') and Color3.new(0,0,0) or (it.style == 'Secondary' and theme.colors.inputBg or theme.colors.primary),
			BackgroundTransparency = (it.style == 'Ghost') and 1 or 0,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(88, 28),
			Text = tostring(it.text or it.id or "Button"),
			TextColor3 = (it.style == 'Primary') and Color3.new(1,1,1) or theme.colors.text,
			Font = Enum.Font.GothamSemibold,
			TextSize = 14,
		})
		Util.Roundify(btn, 6, theme.colors.border, 0.8)
		btn.Parent = root
		self:_trackConn(btn.MouseButton1Click:Connect(function()
			if it.OnClick then pcall(it.OnClick) end
			if it.Action then Registry.invoke(it.Action) end
		end))
		return btn
	end

	for _, it in ipairs(self.Items) do addItem(it) end

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		root.BackgroundColor3 = newTheme.colors.surface
		for _, child in ipairs(root:GetChildren()) do
			if child:IsA("TextButton") then
				local st = child:FindFirstChildOfClass("UIStroke"); if st then st.Color = newTheme.colors.border end
			end
		end
	end))

	self.Instance = root
	if props.Parent then root.Parent = props.Parent end
	return self
end

return Toolbar

