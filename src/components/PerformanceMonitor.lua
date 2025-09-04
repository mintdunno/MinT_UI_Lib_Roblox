-- PerformanceMonitor component: displays memory usage and a run timer
-- Props:
-- Size (UDim2) default (260, 60)
-- Parent (Instance)
-- Provide external controls: Start(), Pause(), Stop() to manage timer

local RunService = game:GetService("RunService")

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Base = require(script.Parent.Parent.core.ComponentBase)

local PerformanceMonitor = Base.extend({})

local function formatMemMB(kb)
	local mb = (kb or 0) / 1024
	return string.format("%.1f MB", mb)
end

local function formatTime(sec)
	sec = math.max(0, math.floor(sec))
	local h = math.floor(sec / 3600); sec = sec % 3600
	local m = math.floor(sec / 60); local s = sec % 60
	if h > 0 then return string.format("%02d:%02d:%02d", h, m, s) end
	return string.format("%02d:%02d", m, s)
end

function PerformanceMonitor.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, PerformanceMonitor)
	self._running = false
	self._startTime = 0
	self._accumPaused = 0
	self._pauseStarted = 0

	local theme = Theme.current()
	local root = Util.Create("Frame", {
		Name = "MintPerformanceMonitor",
		BackgroundColor3 = theme.colors.surface,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(260, 60),
	})
	self:_own(root)
	Util.Roundify(root, 8, theme.colors.border, 0.9)
	Util.Padding(root, 8)

	local vlist = Util.VList(root, 4, Enum.HorizontalAlignment.Left)

	local memLabel = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "Memory: ...",
		TextColor3 = theme.colors.text,
		Font = Enum.Font.Gotham,
		TextSize = 13,
	})
	memLabel.Parent = root

	local timeLabel = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "Time: 00:00",
		TextColor3 = theme.colors.text,
		Font = Enum.Font.Gotham,
		TextSize = 13,
	})
	timeLabel.Parent = root

	local hbConn
	local function update()
		-- Memory via collectgarbage("count") in KB
		local kb = collectgarbage("count")
		memLabel.Text = "Memory: " .. formatMemMB(kb)
		if self._running then
			local t = os.clock() - self._startTime - self._accumPaused
			timeLabel.Text = "Time: " .. formatTime(t)
		end
	end

	local function start()
		if self._running then return end
		self._running = true
		if self._startTime == 0 then self._startTime = os.clock() end
		if self._pauseStarted > 0 then
			self._accumPaused += (os.clock() - self._pauseStarted)
			self._pauseStarted = 0
		end
		if not hbConn then hbConn = RunService.Heartbeat:Connect(update); self:_trackConn(hbConn) end
	end

	local function pause()
		if not self._running then return end
		self._running = false
		self._pauseStarted = os.clock()
	end

	local function stop()
		self._running = false
		self._startTime = 0
		self._accumPaused = 0
		self._pauseStarted = 0
		timeLabel.Text = "Time: 00:00"
	end

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		root.BackgroundColor3 = newTheme.colors.surface
		memLabel.TextColor3 = newTheme.colors.text
		timeLabel.TextColor3 = newTheme.colors.text
	end))

	self.Instance = root
	self.Start = start
	self.Pause = pause
	self.Stop = stop
	if props.Parent then root.Parent = props.Parent end
	update()
	return self
end

return PerformanceMonitor

