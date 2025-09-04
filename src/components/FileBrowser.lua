-- FileBrowser/ScriptManager component: simple tree/list with selection and actions
-- Props:
-- Items: array of nodes { id=string, name=string, isFolder=bool, children=array }
-- OnSelect(node)
-- OnOpen(node)
-- OnAction(actionName, node) optional; or set Action map on items for Registry use
-- Size (UDim2) default (260, 300)
-- Parent (Instance)

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Animator = require(script.Parent.Parent.core.Animator)
local Base = require(script.Parent.Parent.core.ComponentBase)

local FileBrowser = Base.extend({})

local function flatten(nodes, depth, out)
	out = out or {}
	depth = depth or 0
	for _, n in ipairs(nodes or {}) do
		out[#out+1] = { node = n, depth = depth }
		if n._expanded and n.children then
			flatten(n.children, depth+1, out)
		end
	end
	return out
end

function FileBrowser.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, FileBrowser)
	self.Items = props.Items or {}
	self.OnSelect = props.OnSelect
	self.OnOpen = props.OnOpen
	self.OnAction = props.OnAction
	self._selectedId = nil

	local theme = Theme.current()

	local root = Util.Create("Frame", {
		Name = "MintFileBrowser",
		BackgroundColor3 = theme.colors.surface,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(260, 300),
	})
	self:_own(root)
	Util.Roundify(root, 8, theme.colors.border, 0.9)
	Util.Padding(root, 6)

	local list = Util.Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(0,0,0,0),
		Size = UDim2.new(1, 0, 1, 0),
	})
	list.Parent = root
	local uiList = Util.VList(list, 2, Enum.HorizontalAlignment.Left)
	self:_trackConn(uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.new(0,0,0, uiList.AbsoluteContentSize.Y + 8)
	end))

	local rows = {}

	local function render()
		list:ClearAllChildren()
		rows = {}
		local flat = flatten(self.Items)
		for _, rec in ipairs(flat) do
			local n = rec.node
			local depth = rec.depth
			local row = Util.Create("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = theme.colors.inputBg,
				BorderSizePixel = 0,
				Size = UDim2.new(1, -6, 0, 24),
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = "",
			})
			Util.Roundify(row, 6, theme.colors.border, 1)
			row.Parent = list

			local label = Util.Create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8 + depth*16, 0, 0),
				Size = UDim2.new(1, -8 - depth*16, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				Text = (n.isFolder and "📁 " or "📄 ") .. tostring(n.name or n.id or "node"),
				TextColor3 = theme.colors.text,
				Font = Enum.Font.Gotham,
				TextSize = 14,
			})
			label.Parent = row

			-- Expand/collapse arrow for folders
			if n.isFolder then
				local arrow = Util.Create("TextButton", {
					AutoButtonColor = false,
					BackgroundTransparency = 1,
					Text = n._expanded and "▼" or "▶",
					TextColor3 = theme.colors.textMuted,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					Size = UDim2.fromOffset(16, 16),
					Position = UDim2.new(0, depth*16, 0.5, -8),
				})
				arrow.Parent = row
				self:_trackConn(arrow.MouseButton1Click:Connect(function()
					n._expanded = not n._expanded
					render()
				end))
			end

			self:_trackConn(row.MouseEnter:Connect(function()
				Animator.tween(row, Animator.Durations.Fast, { BackgroundColor3 = theme.colors.inputBg:lerp(theme.colors.surface, 0.2) })
			end))
			self:_trackConn(row.MouseLeave:Connect(function()
				Animator.tween(row, Animator.Durations.Fast, { BackgroundColor3 = theme.colors.inputBg })
			end))

			self:_trackConn(row.MouseButton1Click:Connect(function()
				self._selectedId = n.id or n.name
				if self.OnSelect then pcall(self.OnSelect, n) end
				if not n.isFolder and self.OnOpen then pcall(self.OnOpen, n) end
			end))

			rows[#rows+1] = row
		end
	end

	render()

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		root.BackgroundColor3 = newTheme.colors.surface
		render()
	end))

	self.Instance = root
	if props.Parent then root.Parent = props.Parent end
	return self
end

return FileBrowser

