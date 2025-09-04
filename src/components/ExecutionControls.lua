-- ExecutionControls: Play/Pause/Stop control strip with visual state
-- Props:
-- State ('stopped'|'running'|'paused') default 'stopped'
-- OnPlay(), OnPause(), OnStop() callbacks optional
-- Actions: { Play='ActionName', Pause='ActionName', Stop='ActionName' } optional for Registry
-- Parent (Instance)

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Animator = require(script.Parent.Parent.core.Animator)
local Registry = require(script.Parent.Parent.core.Registry)
local Base = require(script.Parent.Parent.core.ComponentBase)

local ExecutionControls = Base.extend({})

function ExecutionControls.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, ExecutionControls)
	self.State = props.State or 'stopped'
	self.Actions = props.Actions or {}
	self.OnPlay = props.OnPlay
	self.OnPause = props.OnPause
	self.OnStop = props.OnStop

	local theme = Theme.current()
	local root = Util.Create("Frame", {
		Name = "MintExecutionControls",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(220, 32),
	})
	self:_own(root)

	local layout = Util.HList(root, 8, Enum.VerticalAlignment.Center)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left

	local function makeBtn(txt)
		local b = Util.Create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = theme.colors.inputBg,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(64, 28),
			Text = txt,
			TextColor3 = theme.colors.text,
			Font = Enum.Font.GothamSemibold,
			TextSize = 14,
		})
		Util.Roundify(b, 6, theme.colors.border, 0.8)
		return b
	end

	local play = makeBtn("▶ Run")
	local pause = makeBtn("⏸ Pause")
	local stop = makeBtn("⏹ Stop")
	play.Parent = root; pause.Parent = root; stop.Parent = root

	local function applyState()
		local s = self.State
		local activeColor = theme.colors.primary
		Animator.tween(play, Animator.Durations.Fast, { BackgroundColor3 = (s=='running') and activeColor or theme.colors.inputBg, TextColor3 = (s=='running') and Color3.new(1,1,1) or theme.colors.text })
		Animator.tween(pause, Animator.Durations.Fast, { BackgroundColor3 = (s=='paused') and activeColor or theme.colors.inputBg, TextColor3 = (s=='paused') and Color3.new(1,1,1) or theme.colors.text })
		Animator.tween(stop, Animator.Durations.Fast, { BackgroundColor3 = (s=='stopped') and activeColor or theme.colors.inputBg, TextColor3 = (s=='stopped') and Color3.new(1,1,1) or theme.colors.text })
	end
	applyState()

	local function safeCall(fn) if fn then local ok,e=pcall(fn); if not ok then warn(e) end end end

	self:_trackConn(play.MouseButton1Click:Connect(function()
		self.State = 'running'; applyState()
		safeCall(self.OnPlay)
		if self.Actions.Play then Registry.invoke(self.Actions.Play) end
	end))
	self:_trackConn(pause.MouseButton1Click:Connect(function()
		self.State = 'paused'; applyState()
		safeCall(self.OnPause)
		if self.Actions.Pause then Registry.invoke(self.Actions.Pause) end
	end))
	self:_trackConn(stop.MouseButton1Click:Connect(function()
		self.State = 'stopped'; applyState()
		safeCall(self.OnStop)
		if self.Actions.Stop then Registry.invoke(self.Actions.Stop) end
	end))

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		theme = newTheme
		applyState()
	end))

	self.Instance = root
	if props.Parent then root.Parent = props.Parent end
	return self
end

return ExecutionControls

