-- QueueManager component: visual manager for a Queue of scripts/tasks
-- Props:
-- Queue (Queue instance) required
-- OnSelect(item)
-- Actions map optional: { Start='ActionName', Pause='ActionName', Stop='ActionName', Remove='ActionName' }
-- Size (UDim2)
-- Parent (Instance)

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Animator = require(script.Parent.Parent.core.Animator)
local ProgressBar = require(script.Parent.ProgressBar)
local Registry = require(script.Parent.Parent.core.Registry)
local Base = require(script.Parent.Parent.core.ComponentBase)

local QueueManager = Base.extend({})

function QueueManager.new(props)
	props = props or {}
	assert(props.Queue, "QueueManager requires props.Queue (Queue instance)")
	local self = Base.init({})
	setmetatable(self, QueueManager)
	self.Queue = props.Queue
	self.Actions = props.Actions or {}
	self.OnSelect = props.OnSelect

	local theme = Theme.current()
	local root = Util.Create("Frame", {
		Name = "MintQueueManager",
		BackgroundColor3 = theme.colors.surface,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(520, 240),
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
	local uiList = Util.VList(list, 6, Enum.HorizontalAlignment.Left)
	self:_trackConn(uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.new(0,0,0, uiList.AbsoluteContentSize.Y + 8)
	end))

	local function statusColor(st)
		local c = Theme.current().colors
		if st == 'running' then return c.primary
		elseif st == 'paused' then return c.warning
		elseif st == 'done' then return c.success
		elseif st == 'failed' then return c.error
		elseif st == 'stopped' then return c.textMuted
		else return c.border end
	end

	local rows = {}

	local function render()
		list:ClearAllChildren()
		rows = {}
		for _, item in ipairs(self.Queue:list()) do
			local row = Util.Create("Frame", { BackgroundColor3 = theme.colors.inputBg, BorderSizePixel = 0, Size = UDim2.new(1, -6, 0, 56) })
			Util.Roundify(row, 6, theme.colors.border, 0.8)
			row.Parent = list
			local title = Util.Create("TextLabel", { BackgroundTransparency=1, Size = UDim2.new(1, -200, 0, 20), TextXAlignment=Enum.TextXAlignment.Left, Text = tostring(item.name), Font=Enum.Font.GothamBold, TextSize=14, TextColor3 = theme.colors.text })
			title.Parent = row
			local status = Util.Create("TextLabel", { BackgroundTransparency=1, Size = UDim2.new(0, 100, 0, 20), Position = UDim2.new(1,-100,0,0), TextXAlignment=Enum.TextXAlignment.Right, Text = string.upper(item.status), Font=Enum.Font.Gotham, TextSize=12, TextColor3 = statusColor(item.status) })
			status.Parent = row

			local pb = ProgressBar.new({ Value = item.progress or 0 })
			pb.Instance.Size = UDim2.new(1, -6, 0, 8)
			pb.Instance.Position = UDim2.new(0, 3, 0, 26)
			pb.Instance.Parent = row

			local controls = Util.Create("Frame", { BackgroundTransparency=1, Position = UDim2.new(1, -190, 0, 0), Size = UDim2.fromOffset(180, 24) })
			controls.Parent = row
			local h = Util.HList(controls, 6, Enum.VerticalAlignment.Center)
			h.HorizontalAlignment = Enum.HorizontalAlignment.Right
			local function makeBtn(txt)
				local b = Util.Create("TextButton", { AutoButtonColor=false, BackgroundColor3=theme.colors.surface, BorderSizePixel=0, Size=UDim2.fromOffset(40, 22), Text=txt, Font=Enum.Font.Gotham, TextSize=12, TextColor3=theme.colors.text })
				Util.Roundify(b, 4, theme.colors.border, 0.8)
				b.Parent = controls
				return b
			end
			local bPlay = makeBtn("Run")
			local bPause = makeBtn("Pause")
			local bStop = makeBtn("Stop")
			local bDel = makeBtn("X")

			self:_trackConn(bPlay.MouseButton1Click:Connect(function()
				self.Queue:start(item.id)
				if self.Actions.Start then Registry.invoke(self.Actions.Start, item) end
			end))
			self:_trackConn(bPause.MouseButton1Click:Connect(function()
				self.Queue:pause(item.id)
				if self.Actions.Pause then Registry.invoke(self.Actions.Pause, item) end
			end))
			self:_trackConn(bStop.MouseButton1Click:Connect(function()
				self.Queue:stop(item.id)
				if self.Actions.Stop then Registry.invoke(self.Actions.Stop, item) end
			end))
			self:_trackConn(bDel.MouseButton1Click:Connect(function()
				self.Queue:remove(item.id)
				if self.Actions.Remove then Registry.invoke(self.Actions.Remove, item) end
			end))

			self:_trackConn(row.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if self.OnSelect then pcall(self.OnSelect, item) end
				end
			end))

			rows[#rows+1] = row
		end
	end

	render()

	self:_trackConn(props.Queue.changed:Connect(function(op, item)
		render()
	end))

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		root.BackgroundColor3 = newTheme.colors.surface
		render()
	end))

	self.Instance = root
	if props.Parent then root.Parent = props.Parent end
	return self
end

return QueueManager

