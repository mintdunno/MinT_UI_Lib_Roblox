-- VariableInspector component: inspect and edit variables in realtime
-- Props:
-- Data (table) or Provider (function -> table)
-- OnChanged(path, newValue) callback when user edits a value
-- RefreshInterval (number) seconds to auto-refresh when Provider set
-- Size (UDim2) default (520, 260)
-- Parent (Instance)

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Animator = require(script.Parent.Parent.core.Animator)
local Toggle = require(script.Parent.Toggle)
local Base = require(script.Parent.Parent.core.ComponentBase)

local VariableInspector = Base.extend({})

local function isArray(t)
	local i = 0
	for k, _ in pairs(t) do
		if typeof(k) ~= "number" then return false end
		i = math.max(i, k)
	end
	return i > 0
end

function VariableInspector.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, VariableInspector)
	self.Data = props.Data or {}
	self.Provider = props.Provider
	self.OnChanged = props.OnChanged
	self.RefreshInterval = props.RefreshInterval or 1

	local theme = Theme.current()
	local root = Util.Create("Frame", {
		Name = "MintVariableInspector",
		BackgroundColor3 = theme.colors.surface,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(520, 260),
	})
	self:_own(root)
	Util.Roundify(root, 8, theme.colors.border, 0.9)
	Util.Padding(root, 8)

	local list = Util.Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(0,0,0,0),
		Size = UDim2.new(1, 0, 1, 0),
	})
	list.Parent = root
	local uiList = Util.VList(list, 4, Enum.HorizontalAlignment.Left)
	self:_trackConn(uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.new(0,0,0, uiList.AbsoluteContentSize.Y + 8)
	end))

	local function addRow(path, key, value, depth)
		depth = depth or 0
		local row = Util.Create("Frame", { BackgroundColor3 = theme.colors.inputBg, BorderSizePixel = 0, Size = UDim2.new(1, -6, 0, 28) })
		Util.Roundify(row, 6, theme.colors.border, 0.8)
		row.Parent = list

		local keyLbl = Util.Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 8 + depth*16, 0, 0),
			Size = UDim2.new(0, 200 - depth*16, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Text = tostring(key),
			TextColor3 = theme.colors.text,
			Font = Enum.Font.Gotham,
			TextSize = 13,
		})
		keyLbl.Parent = row

		local valueType = typeof(value)
		if valueType == "boolean" then
			local t = Toggle.new({ Value = value })
			t.Instance.Size = UDim2.fromOffset(60, 24)
			t.Instance.Position = UDim2.new(1, -68, 0.5, -12)
			t.Instance.Parent = row
			t.Instance.BackgroundTransparency = 1
			t.Instance:FindFirstChild("Track").Size = UDim2.fromOffset(42, 22)
			t.Instance:FindFirstChild("Track").Position = UDim2.new(1, -44, 0.5, -11)
			t.Instance:FindFirstChild("Track").AnchorPoint = Vector2.new(0,0)
			t.Instance:FindFirstChild("Track").ZIndex = row.ZIndex + 1
			t.Instance:FindFirstChild("Track"):FindFirstChild("Dot").ZIndex = row.ZIndex + 2
			t.Instance:FindFirstChild("Track"):FindFirstChild("Dot").Size = UDim2.fromOffset(16,16)
			-- rewire change callback
			self:_trackConn(t.Instance.Track.MouseButton1Click:Connect(function()
				local newVal = not value
				if self.OnChanged then pcall(self.OnChanged, path, newVal) end
				value = newVal
			end))
		elseif valueType == "number" or valueType == "string" then
			local box = Util.Create("TextBox", { BackgroundColor3 = theme.colors.surface, BorderSizePixel=0, Size=UDim2.new(0, 160, 0, 22), Position = UDim2.new(1, -168, 0.5, -11), Text = tostring(value), TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Center, TextColor3 = theme.colors.text, Font = Enum.Font.Gotham, TextSize = 13 })
			Util.Roundify(box, 6, theme.colors.border, 0.8); Util.Padding(box, 6)
			box.Parent = row
			self:_trackConn(box.FocusLost:Connect(function()
				local val = box.Text
				if valueType == "number" then val = tonumber(val) or value end
				if self.OnChanged then pcall(self.OnChanged, path, val) end
				value = val
			end))
		elseif valueType == "table" then
			local btn = Util.Create("TextButton", { AutoButtonColor=false, BackgroundTransparency=1, Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 4, 0, 0), TextXAlignment=Enum.TextXAlignment.Left, Text = "▶", TextColor3 = theme.colors.textMuted, Font = Enum.Font.GothamBold, TextSize=13 })
			btn.Parent = row
			local expanded = false
			self:_trackConn(btn.MouseButton1Click:Connect(function()
				expanded = not expanded
				btn.Text = expanded and "▼" or "▶"
				if expanded then
					for k, v in pairs(value) do
						addRow(path .. "." .. tostring(k), k, v, depth + 1)
					end
				else
					-- rebuild entire view to collapse properly
					VariableInspector._render(self)
				end
			end))
		else
			local lbl = Util.Create("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(0, 160, 1, 0), Position=UDim2.new(1,-168,0,0), TextXAlignment=Enum.TextXAlignment.Right, TextYAlignment=Enum.TextYAlignment.Center, Text = tostring(value), TextColor3 = theme.colors.textMuted, Font=Enum.Font.Gotham, TextSize=13 })
			lbl.Parent = row
		end
	end

	function VariableInspector:_render()
		list:ClearAllChildren()
		local data = self.Data
		if self.Provider then
			local ok, res = pcall(self.Provider)
			if ok and type(res) == "table" then data = res end
		end
		for k, v in pairs(data) do
			addRow(tostring(k), k, v, 0)
		end
	end

	self:_render()

	if self.Provider then
		local running = true
		self:_trackCleanup(function() running = false end)
		task.spawn(function()
			while running do
				task.wait(self.RefreshInterval)
				self:_render()
			end
		end)
	end

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		root.BackgroundColor3 = newTheme.colors.surface
		self:_render()
	end))

	self.Instance = root
	if props.Parent then root.Parent = props.Parent end
	return self
end

function VariableInspector:SetData(t)
	self.Data = t or {}
	self:_render()
end

return VariableInspector

