-- Dropdown component
-- Props:
-- Items (array) - either array of strings or array of { text=string, value=any }
-- Placeholder (string)
-- SelectedValue (any)
-- OnChanged (function:value, item)
-- Action (string) optional; Registry.invoke(Action, value)
-- Size (UDim2) default (220, 32)
-- MaxMenuHeight (number) default 160
-- Parent (Instance) optional

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Animator = require(script.Parent.Parent.core.Animator)
local Registry = require(script.Parent.Parent.core.Registry)
local Base = require(script.Parent.Parent.core.ComponentBase)

local Dropdown = Base.extend({})

local function normalizeItems(items)
	local out = {}
	for i, it in ipairs(items or {}) do
		if type(it) == "string" then
			out[#out+1] = { text = it, value = it }
		elseif type(it) == "table" then
			out[#out+1] = { text = tostring(it.text or it.value or ("Item "..i)), value = it.value ~= nil and it.value or it.text }
		end
	end
	return out
end

function Dropdown.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, Dropdown)
	self.Items = normalizeItems(props.Items or {})
	self.SelectedValue = props.SelectedValue
	self.OnChanged = props.OnChanged
	self.Action = props.Action
	self._overlay = nil

	local theme = Theme.current()

	local root = Util.Create("Frame", {
		Name = "MintDropdown",
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		Size = props.Size or UDim2.fromOffset(220, 32),
	})
	self:_own(root)

	local button = Util.Create("TextButton", {
		Name = "Button",
		AutoButtonColor = false,
		BackgroundColor3 = theme.colors.inputBg,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
	})
	Util.Roundify(button, 6, theme.colors.border, 0.7)
	Util.Padding(button, 8)
	button.Parent = root

	local label = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = props.Placeholder or "Select...",
		TextColor3 = theme.colors.textMuted,
		Font = Enum.Font.Gotham,
		TextSize = 14,
	})
	label.Parent = button

	local chevron = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(1, -16, 0.5, -8),
		Text = "▼",
		TextColor3 = theme.colors.textMuted,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
	})
	chevron.Parent = button

	local menu = Util.Create("Frame", {
		Name = "Menu",
		BackgroundColor3 = theme.colors.surface,
		BorderSizePixel = 0,
		Visible = false,
		Position = UDim2.new(0, 0, 1, 4),
		Size = UDim2.new(1, 0, 0, math.min(props.MaxMenuHeight or 160, 160)),
		ClipsDescendants = true,
		ZIndex = 100,
	})
	Util.Roundify(menu, 6, theme.colors.border, 0.7)
	Util.Padding(menu, 4)
	menu.Parent = root
	self:_own(menu)

	local list = Util.Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageTransparency = 0.5,
		CanvasSize = UDim2.new(0,0,0,0),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 101,
	})
	local uiList = Util.VList(list, 4, Enum.HorizontalAlignment.Left)
	self:_trackConn(uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.new(0,0,0, uiList.AbsoluteContentSize.Y + 8)
	end))
	list.Parent = menu

	local function rebuildMenu()
		list:ClearAllChildren()
		for _, item in ipairs(self.Items) do
			local opt = Util.Create("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = theme.colors.surface,
				BorderSizePixel = 0,
				Size = UDim2.new(1, -4, 0, 28),
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = "  " .. tostring(item.text),
				TextColor3 = theme.colors.text,
				Font = Enum.Font.Gotham,
				TextSize = 14,
				ZIndex = 102,
			})
			Util.Roundify(opt, 4, theme.colors.border, 1)
			opt.Parent = list
			self:_trackConn(opt.MouseEnter:Connect(function()
				Animator.tween(opt, Animator.Durations.Fast, { BackgroundColor3 = theme.colors.inputBg })
			end))
			self:_trackConn(opt.MouseLeave:Connect(function()
				Animator.tween(opt, Animator.Durations.Fast, { BackgroundColor3 = theme.colors.surface })
			end))
			self:_trackConn(opt.MouseButton1Click:Connect(function()
				self:SetSelected(item.value, true)
			end))
		end
	end

	local open = false

	local function destroyOverlay()
		if self._overlay then
			self._overlay:Destroy()
			self._overlay = nil
		end
	end

	local function setOpen(v)
		if v == open then return end
		open = v
		menu.Visible = v
		if v then
			-- overlay to capture outside clicks
			local screenGui = root:FindFirstAncestorWhichIsA("ScreenGui")
			if screenGui then
				local overlay = Instance.new("TextButton")
				overlay.Name = "Mint_Dropdown_Overlay"
				overlay.AutoButtonColor = false
				overlay.BackgroundTransparency = 1
				overlay.Text = ""
				overlay.ZIndex = menu.ZIndex - 1
				overlay.Size = UDim2.fromScale(1,1)
				overlay.Parent = screenGui
				self:_trackConn(overlay.MouseButton1Click:Connect(function()
					setOpen(false)
				end))
				self._overlay = overlay
				self:_own(overlay)
			end
			menu.Size = UDim2.new(1, 0, 0, 0)
			Animator.tween(menu, Animator.Durations.Normal, { Size = UDim2.new(1, 0, 0, math.min(props.MaxMenuHeight or 160, 160)) })
		else
			Animator.tween(menu, Animator.Durations.Fast, { Size = UDim2.new(1, 0, 0, 0) })
			destroyOverlay()
		end
	end

	self:_trackConn(button.MouseButton1Click:Connect(function()
		setOpen(not open)
	end))

	function self:SetItems(items)
		self.Items = normalizeItems(items)
		rebuildMenu()
	end

	function self:SetSelected(value, fire)
		self.SelectedValue = value
		local found
		for _, item in ipairs(self.Items) do
			if item.value == value then found = item break end
		end
		if found then
			label.Text = tostring(found.text)
			label.TextColor3 = theme.colors.text
			chevron.TextColor3 = theme.colors.textMuted
		else
			label.Text = props.Placeholder or "Select..."
			label.TextColor3 = theme.colors.textMuted
		end
		setOpen(false)
		if fire then
			if self.OnChanged then
				local ok, err = pcall(self.OnChanged, self.SelectedValue, found)
				if not ok then warn(err) end
			end
			if self.Action then
				Registry.invoke(self.Action, self.SelectedValue)
			end
		end
	end

	rebuildMenu()
	if self.SelectedValue ~= nil then
		self:SetSelected(self.SelectedValue, false)
	end

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		button.BackgroundColor3 = newTheme.colors.inputBg
		local stroke = button:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Color = newTheme.colors.border end
		label.TextColor3 = (self.SelectedValue ~= nil) and newTheme.colors.text or newTheme.colors.textMuted
		chevron.TextColor3 = newTheme.colors.textMuted
		menu.BackgroundColor3 = newTheme.colors.surface
		local s = menu:FindFirstChildOfClass("UIStroke"); if s then s.Color = newTheme.colors.border end
		rebuildMenu()
		if self.SelectedValue ~= nil then
			self:SetSelected(self.SelectedValue, false)
		end
	end))

	self.Instance = root
	if props.Parent then root.Parent = props.Parent end
	return self
end

return Dropdown

