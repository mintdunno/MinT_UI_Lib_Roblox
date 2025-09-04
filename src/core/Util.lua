-- Utility helpers for MinT UI
local TweenService = game:GetService("TweenService")

local Util = {}

-- Shallow assign/merge: later tables override earlier ones
function Util.Assign(...)
	local result = {}
	for i = 1, select('#', ...) do
		local src = select(i, ...)
		if type(src) == "table" then
			for k, v in pairs(src) do
				result[k] = v
			end
		end
	end
	return result
end

-- Create Instance helper
-- Usage: Util.Create("Frame", propsTable, childrenArray)
function Util.Create(className, props, children)
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			pcall(function()
				inst[k] = v
			end)
		end
	end
	if children then
		for _, child in ipairs(children) do
			if typeof(child) == "Instance" then
				child.Parent = inst
			end
		end
	end
	return inst
end

-- Tween a single instance property safely
function Util.Tween(inst, tweenInfo, goal)
	local ok, tween = pcall(function()
		return TweenService:Create(inst, tweenInfo, goal)
	end)
	if ok and tween then
		tween:Play()
		return tween
	end
	return nil
end

-- Apply UICorner and UIStroke to an Instance
function Util.Roundify(inst, radius, strokeColor, strokeTransparency)
	radius = radius or 8
	strokeTransparency = strokeTransparency or 0.5
	local corner = Util.Create("UICorner", { CornerRadius = UDim.new(0, radius) })
	corner.Parent = inst
	local stroke = Util.Create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = strokeColor or Color3.fromRGB(255, 255, 255),
		Transparency = strokeTransparency,
		Thickness = 1,
	})
	stroke.Parent = inst
	return corner, stroke
end

-- Apply padding to Frames
function Util.Padding(parent, padding)
	padding = padding or 8
	local pad = Util.Create("UIPadding", {
		PaddingTop = UDim.new(0, padding),
		PaddingBottom = UDim.new(0, padding),
		PaddingLeft = UDim.new(0, padding),
		PaddingRight = UDim.new(0, padding),
	})
	pad.Parent = parent
	return pad
end

-- Safe connect helper that returns a disconnect function
function Util.Connect(signal, fn)
	local conn = signal:Connect(fn)
	return function()
		if conn and conn.Connected then conn:Disconnect() end
	end
end

-- Clamp helper
function Util.Clamp(n, min, max)
	if n < min then return min end
	if n > max then return max end
	return n
end

-- Lerp
function Util.Lerp(a, b, t)
	return a + (b - a) * t
end

-- UI list layout helper
function Util.VList(parent, padding, align)
	local layout = Util.Create("UIListLayout", {
		Padding = UDim.new(0, padding or 8),
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	layout.Parent = parent
	return layout
end

function Util.HList(parent, padding, align)
	local layout = Util.Create("UIListLayout", {
		Padding = UDim.new(0, padding or 8),
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = align or Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	layout.Parent = parent
	return layout
end

return Util

