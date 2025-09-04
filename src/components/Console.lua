-- Console/Output Panel
-- Shows logs with color-coded levels, search and clear. Listens to LogManager and ErrorHandler.
-- Props:
-- Size (UDim2) default (520, 200)
-- Levels (table set) to show initially, default { info=true, success=true, warning=true, error=true, debug=true, output=true }
-- MaxEntries (number) default 500 (display cap)
-- Parent (Instance)

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Animator = require(script.Parent.Parent.core.Animator)
local LogManager = require(script.Parent.Parent.core.LogManager)
local ErrorHandler = require(script.Parent.Parent.core.ErrorHandler)
local Base = require(script.Parent.Parent.core.ComponentBase)

local Console = Base.extend({})

local LEVELS = { "info", "success", "warning", "error", "debug", "output" }

local function levelColor(level, theme)
	local t = theme.colors
	if level == "success" then return t.success end
	if level == "warning" then return t.warning end
	if level == "error" then return t.error end
	if level == "debug" then return t.accent end
	if level == "output" then return t.primaryVariant end
	return t.text
end

function Console.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, Console)
	self.Levels = props.Levels or { info=true, success=true, warning=true, error=true, debug=true, output=true }
	self.Search = ""
	self.MaxEntries = tonumber(props.MaxEntries) or 500

	local theme = Theme.current()
	local root = Util.Create("Frame", {
		Name = "MintConsole",
		BackgroundColor3 = theme.colors.surface,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(520, 240),
	})
	self:_own(root)
	Util.Roundify(root, 8, theme.colors.border, 0.9)
	Util.Padding(root, 8)

	local header = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24) })
	header.Parent = root
	-- Filters row (level toggles)
	local filters = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -60, 1, 0) })
	filters.Parent = header
	local fl = Util.HList(filters, 6, Enum.VerticalAlignment.Center)
	fl.HorizontalAlignment = Enum.HorizontalAlignment.Left

	local function refreshFilterButton(btn, level)
		local active = self.Levels[level] == true
		btn.BackgroundColor3 = active and theme.colors.primary or theme.colors.inputBg
		btn.TextColor3 = active and Color3.new(1,1,1) or theme.colors.text
		local stroke = btn:FindFirstChildOfClass("UIStroke"); if stroke then stroke.Color = theme.colors.border end
	end

	local function addFilter(level)
		local btn = Util.Create("TextButton", { AutoButtonColor=false, BackgroundColor3 = self.Levels[level] and theme.colors.primary or theme.colors.inputBg, BorderSizePixel=0, Size=UDim2.fromOffset(64, 22), Text = level:sub(1,1):upper()..level:sub(2,2), TextColor3 = self.Levels[level] and Color3.new(1,1,1) or theme.colors.text, Font=Enum.Font.Gotham, TextSize=12 })
		Util.Roundify(btn, 6, theme.colors.border, 0.8)
		btn.Parent = filters
		self:_trackConn(btn.MouseButton1Click:Connect(function()
			self.Levels[level] = not self.Levels[level]
			refreshFilterButton(btn, level)
			rebuild()
		end))
		refreshFilterButton(btn, level)
	end
	for _, lv in ipairs(LEVELS) do addFilter(lv) end

	local search = Util.Create("TextBox", {
		BackgroundColor3 = theme.colors.inputBg, BorderSizePixel = 0,
		Size = UDim2.new(0, 160, 1, 0), Position = UDim2.new(1, -212, 0, 0), TextSize = 13, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
		PlaceholderText = "Search...", Text = "", TextColor3 = theme.colors.text, PlaceholderColor3 = theme.colors.textMuted,
	})
	Util.Roundify(search, 6, theme.colors.border, 0.8); Util.Padding(search, 6)
	search.Parent = header
	local clearBtn = Util.Create("TextButton", { Text = "Clear", AutoButtonColor=false, BackgroundColor3=theme.colors.inputBg, BorderSizePixel=0, Size = UDim2.new(0, 52, 1, 0), Position = UDim2.new(1, -52, 0, 0) })
	Util.Roundify(clearBtn, 6, theme.colors.border, 0.8)
	clearBtn.Parent = header

	local list = Util.Create("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -28), Position = UDim2.new(0, 0, 0, 28),
		ScrollBarThickness = 6, CanvasSize = UDim2.new(0,0,0,0), ScrollBarImageTransparency = 0.5,
	})
	list.Parent = root
	local uiList = Util.VList(list, 4, Enum.HorizontalAlignment.Left)
	self:_trackConn(uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.new(0,0,0, uiList.AbsoluteContentSize.Y + 8)
		list.CanvasPosition = Vector2.new(0, math.max(0, uiList.AbsoluteContentSize.Y - list.AbsoluteWindowSize.Y))
	end))

	local entries = {}

	local function enforceCap()
		while #entries > self.MaxEntries do
			local oldest = table.remove(entries, 1)
			if oldest and oldest.Parent then oldest:Destroy() end
		end
	end

	function rebuild()
		list:ClearAllChildren()
		entries = {}
		for _, e in ipairs(LogManager.list({ search = self.Search })) do
			local msg = e.message or ""
			if self.Search ~= "" and not string.find(string.lower(msg), string.lower(self.Search), 1, true) then
				-- skip
			else
				if self.Levels[e.level] then
					local row = Util.Create("TextLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -6, 0, 18),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
						TextSize = 13,
						Font = Enum.Font.Code,
						Text = string.format("[%s] %s", string.upper(e.level), msg),
						TextColor3 = levelColor(e.level, Theme.current()),
					})
					row.Parent = list
					entries[#entries+1] = row
					Animator.tween(row, Animator.Durations.Fast, { TextTransparency = 0 })
					enforceCap()
				end
			end
		end
	end

	self:_trackConn(search:GetPropertyChangedSignal("Text"):Connect(function()
		self.Search = search.Text or ""
		rebuild()
	end))

	self:_trackConn(clearBtn.MouseButton1Click:Connect(function()
		LogManager.clear()
	end))

	self:_trackConn(LogManager.added:Connect(function(e)
		-- Add new entries only if pass filters and search
		local msg = e.message or ""
		if self.Search ~= "" and not string.find(string.lower(msg), string.lower(self.Search), 1, true) then return end
		if not self.Levels[e.level] then return end
		local row = Util.Create("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
			TextSize = 13, Font = Enum.Font.Code, Text = string.format("[%s] %s", string.upper(e.level), msg), TextColor3 = levelColor(e.level, Theme.current()),
		})
		row.Parent = list
		entries[#entries+1] = row
		Animator.tween(row, Animator.Durations.Fast, { TextTransparency = 0 })
		enforceCap()
	end))
	self:_trackConn(LogManager.cleared:Connect(function()
		rebuild()
	end))

	self:_trackConn(ErrorHandler.event:Connect(function(level, msg)
		LogManager.append(level, msg)
	end))

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		root.BackgroundColor3 = newTheme.colors.surface
		local s = root:FindFirstChildOfClass("UIStroke"); if s then s.Color = newTheme.colors.border end
		search.BackgroundColor3 = newTheme.colors.inputBg
		search.TextColor3 = newTheme.colors.text
		search.PlaceholderColor3 = newTheme.colors.textMuted
		-- Rebuild to recolor level text
		rebuild()
	end))

	rebuild()

	self.Instance = root
	if props.Parent then root.Parent = props.Parent end
	return self
end

return Console

