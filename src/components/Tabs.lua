-- Tabs component: top tab bar with content container
-- Props:
-- Tabs: array of { id=string, title=string, content=Instance | function(parent) -> Instance }
-- OnChanged(id)
-- Size (UDim2)
-- Parent (Instance)

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Animator = require(script.Parent.Parent.core.Animator)
local Base = require(script.Parent.Parent.core.ComponentBase)

local Tabs = Base.extend({})

function Tabs.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, Tabs)
	self.OnChanged = props.OnChanged
	self._tabs = {}
	self._selected = nil

	local theme = Theme.current()

	local root = Util.Create("Frame", {
		Name = "MintTabs",
		BackgroundColor3 = theme.colors.surface,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(520, 300),
		ClipsDescendants = true,
	})
	self:_own(root)
	Util.Roundify(root, 8, theme.colors.border, 0.9)
	Util.Padding(root, 8)

	local header = Util.Create("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
	})
	header.Parent = root
	local tabList = Util.HList(header, 6, Enum.VerticalAlignment.Center)
	local content = Util.Create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -32),
		Position = UDim2.new(0, 0, 0, 32),
	})
	content.Parent = root

	local function makeTabButton(tab)
		local btn = Util.Create("TextButton", {
			Name = "Tab_"..tab.id,
			AutoButtonColor = false,
			BackgroundColor3 = theme.colors.inputBg,
			BorderSizePixel = 0,
			Text = tab.title or tab.id,
			TextColor3 = theme.colors.text,
			Font = Enum.Font.Gotham,
			TextSize = 14,
			Size = UDim2.fromOffset(100, 28),
		})
		Util.Roundify(btn, 6, theme.colors.border, 0.8)
		btn.Parent = header
		return btn
	end

	local function selectTab(id)
		if self._selected == id then return end
		self._selected = id
		-- update buttons
		for _, t in pairs(self._tabs) do
			local active = (t.id == id)
			local target = active and theme.colors.primary or theme.colors.inputBg
			local textColor = active and Color3.new(1,1,1) or theme.colors.text
			Animator.tween(t.button, Animator.Durations.Fast, { BackgroundColor3 = target, TextColor3 = textColor })
			if t.view then t.view.Visible = active end
		end
		if self.OnChanged then
			local ok, err = pcall(self.OnChanged, id)
			if not ok then warn(err) end
		end
	end

	function self:AddTab(tab)
		-- tab: { id, title, content }
		assert(tab and tab.id, "Tab requires id")
		local button = makeTabButton(tab)
		local view
		if typeof(tab.content) == "Instance" then
			view = tab.content
		elseif type(tab.content) == "function" then
			view = tab.content(content)
		else
			view = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1,1) })
		end
		view.Visible = false
		view.Size = UDim2.fromScale(1,1)
		view.Parent = content

		local rec = { id = tab.id, button = button, view = view }
		self._tabs[tab.id] = rec

		self:_trackConn(button.MouseButton1Click:Connect(function()
			selectTab(tab.id)
		end))

		if not self._selected then
			selectTab(tab.id)
		end
		return rec
	end

	-- Seed tabs
	for _, t in ipairs(props.Tabs or {}) do self:AddTab(t) end

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		root.BackgroundColor3 = newTheme.colors.surface
		local s = root:FindFirstChildOfClass("UIStroke"); if s then s.Color = newTheme.colors.border end
		for _, t in pairs(self._tabs) do
			local active = (t.id == self._selected)
			t.button.TextColor3 = active and Color3.new(1,1,1) or newTheme.colors.text
			t.button.BackgroundColor3 = active and newTheme.colors.primary or newTheme.colors.inputBg
			local st = t.button:FindFirstChildOfClass("UIStroke"); if st then st.Color = newTheme.colors.border end
		end
	end))

	self.Instance = root
	if props.Parent then root.Parent = props.Parent end
	return self
end

return Tabs

