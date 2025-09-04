-- Notification (Toast) Manager
-- Attaches to a ScreenGui and listens to ErrorHandler to show animated toasts
-- API:
-- local Notification = require(...components.Notification)
-- Notification.Attach(screenGui, opts?)
-- Notification.Notify(level, message, opts?)
-- Notification.Detach()
--
-- opts: { Duration: number (default 3), MaxToasts: number (default 4), Position: "TopRight"|"BottomRight"|"TopLeft"|"BottomLeft" }

local Util = require(script.Parent.Parent.core.Util)
local Animator = require(script.Parent.Parent.core.Animator)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local ErrorHandler = require(script.Parent.Parent.core.ErrorHandler)

local Notification = {}

local state = {
	attachedGui = nil,
	container = nil,
	conns = {},
	settings = {
		Duration = 3,
		MaxToasts = 4,
		Position = "TopRight",
	},
}

local function cornerAnchor(position)
	if position == "TopRight" then
		return Vector2.new(1,0), UDim2.new(1, -12, 0, 12)
	elseif position == "BottomRight" then
		return Vector2.new(1,1), UDim2.new(1, -12, 1, -12)
	elseif position == "TopLeft" then
		return Vector2.new(0,0), UDim2.new(0, 12, 0, 12)
	else
		return Vector2.new(0,1), UDim2.new(0, 12, 1, -12)
	end
end

local function colorFor(level, theme)
	local t = theme.colors
	if level == "success" then return t.success end
	if level == "warning" then return t.warning end
	if level == "error" then return t.error end
	return t.primary -- info/default
end

local function rebuildLayout()
	local c = state.container
	if not c then return end
	for i, toast in ipairs(c:GetChildren()) do
		if toast:IsA("Frame") then
			toast.LayoutOrder = i
		end
	end
end

local function mountContainer(screenGui)
	local theme = Theme.current()
	local anchorPoint, position = cornerAnchor(state.settings.Position)
	local container = Util.Create("Frame", {
		Name = "Mint_ToastContainer",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = anchorPoint,
		Position = position,
		Size = UDim2.fromOffset(320, 10),
		ZIndex = 1000,
	})
	container.Parent = screenGui

	local list = Util.VList(container, 8, Enum.HorizontalAlignment.Right)
	list.FillDirection = (anchorPoint.Y == 1) and Enum.FillDirection.Vertical or Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder

	state.container = container
end

local function ensureSpaceLimit()
	if not state.container then return end
	local frames = {}
	for _, child in ipairs(state.container:GetChildren()) do
		if child:IsA("Frame") then
			frames[#frames+1] = child
		end
	end
	if #frames > state.settings.MaxToasts then
		-- remove the oldest (first)
		local oldest = frames[1]
		oldest:Destroy()
		rebuildLayout()
	end
end

local function createToast(level, message, opts)
	opts = opts or {}
	local theme = Theme.current()
	local color = colorFor(level, theme)
	local bg = theme.colors.surface
	local txt = theme.colors.text

	local toast = Util.Create("Frame", {
		Name = "Toast",
		BackgroundColor3 = bg,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 320, 0, 44),
		ClipsDescendants = true,
		ZIndex = 1001,
	})
	Util.Roundify(toast, 8, theme.colors.border, 0.9)
	Util.Padding(toast, 8)

	-- Accent bar
	local accent = Util.Create("Frame", {
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 4, 1, 0),
	})
	accent.Parent = toast

	local label = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -20, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true,
		Text = tostring(message),
		TextColor3 = txt,
		Font = Enum.Font.Gotham,
		TextSize = 14,
	})
	label.Parent = toast

	toast.Parent = state.container
	rebuildLayout()
	ensureSpaceLimit()

	-- Animate in from side
	toast.AnchorPoint = Vector2.new(1,0)
	toast.Position = UDim2.new(1, 340, 0, 0)
	Animator.tween(toast, Animator.Durations.Normal, { Position = UDim2.new(1, 0, 0, 0) })

	-- Auto-remove after duration
	local duration = opts.Duration or state.settings.Duration
	task.delay(duration, function()
		if toast and toast.Parent then
			Animator.tween(toast, Animator.Durations.Fast, { Position = UDim2.new(1, 340, 0, 0), BackgroundTransparency = 1 })
			task.delay(Animator.Durations.Fast + 0.05, function()
				if toast then toast:Destroy() end
				rebuildLayout()
			end)
		end
	end)

	-- Click to dismiss
	local button = Instance.new("TextButton")
	button.Name = "HitArea"
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Size = UDim2.fromScale(1,1)
	button.Parent = toast
	button.MouseButton1Click:Connect(function()
		if toast then toast:Destroy() end
		rebuildLayout()
	end)

	-- Theme changes
	Theme.changed:Connect(function(newTheme)
		local c = colorFor(level, newTheme)
		accent.BackgroundColor3 = c
		toast.BackgroundColor3 = newTheme.colors.surface
		label.TextColor3 = newTheme.colors.text
		local s = toast:FindFirstChildOfClass("UIStroke"); if s then s.Color = newTheme.colors.border end
	end)
end

function Notification.Attach(screenGui, opts)
	if state.attachedGui == screenGui then return end
	Notification.Detach()
	state.attachedGui = screenGui
	state.settings = setmetatable(opts or {}, { __index = state.settings })
	mountContainer(screenGui)
	-- Listen to ErrorHandler
	state.conns[#state.conns+1] = ErrorHandler.event:Connect(function(level, msg)
		Notification.Notify(level, msg)
	end)
end

function Notification.Detach()
	for _, c in ipairs(state.conns) do if c.Connected then c:Disconnect() end end
	state.conns = {}
	if state.container then state.container:Destroy() end
	state.container = nil
	state.attachedGui = nil
end

function Notification.Notify(level, message, opts)
	if not state.container then return end
	createToast(level or "info", message or "", opts)
end

return Notification

