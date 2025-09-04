-- Responsive: attaches a UIScale to a ScreenGui that updates with viewport size
-- Default strategy: scale relative to 1080p height with clamping
local Responsive = {}

local DEFAULTS = {
	BaseHeight = 1080,
	MinScale = 0.75,
	MaxScale = 1.25,
}

local function getViewportSize()
	local camera = workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end
	return Vector2.new(1920, 1080)
end

local function computeScale(opts)
	local vp = getViewportSize()
	local scale = vp.Y / (opts.BaseHeight or DEFAULTS.BaseHeight)
	if opts.MinScale then scale = math.max(scale, opts.MinScale) end
	if opts.MaxScale then scale = math.min(scale, opts.MaxScale) end
	return scale
end

function Responsive.Attach(screenGui, opts)
	assert(screenGui and screenGui:IsA("ScreenGui"), "Responsive.Attach requires a ScreenGui")
	opts = setmetatable(opts or {}, { __index = DEFAULTS })
	local scaleInst = Instance.new("UIScale")
	scaleInst.Name = "Mint_UIScale"
	scaleInst.Parent = screenGui

	local function update()
		local s = computeScale(opts)
		scaleInst.Scale = s
	end

	update()

	local conns = {}
	local camera = workspace.CurrentCamera
	if camera then
		conns[#conns+1] = camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	end
	conns[#conns+1] = screenGui.AncestryChanged:Connect(function()
		if not screenGui.Parent then
			for _, c in ipairs(conns) do if c.Connected then c:Disconnect() end end
		end
	end)

	return scaleInst, function()
		for _, c in ipairs(conns) do if c.Connected then c:Disconnect() end end
		if scaleInst then scaleInst:Destroy() end
	end
end

return Responsive

