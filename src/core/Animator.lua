-- Animator: centralizes tween timings and micro-interactions
local TweenService = game:GetService("TweenService")

local Animator = {}

Animator.Durations = {
	Fast = 0.12,
	Normal = 0.2,
	Slow = 0.35,
}

Animator.Easings = {
	Enter = Enum.EasingStyle.Quad,
	Exit = Enum.EasingStyle.Quad,
	Hover = Enum.EasingStyle.Sine,
}

function Animator.tween(inst, duration, properties, easingStyle, easingDirection)
	local info = TweenInfo.new(duration or Animator.Durations.Normal, easingStyle or Animator.Easings.Enter, easingDirection or Enum.EasingDirection.Out)
	local tween = TweenService:Create(inst, info, properties)
	tween:Play()
	return tween
end

-- Hover effect: returns connections and a cleanup function
function Animator.bindHover(buttonLikeInst, lightenColor3)
	local original
	local enterConn = buttonLikeInst.MouseEnter:Connect(function()
		if buttonLikeInst:IsA("TextButton") or buttonLikeInst:IsA("ImageButton") or buttonLikeInst:IsA("Frame") then
			original = buttonLikeInst.BackgroundColor3
			local c = original
			if lightenColor3 then c = lightenColor3 end
			Animator.tween(buttonLikeInst, Animator.Durations.Fast, { BackgroundColor3 = c })
		end
	end)
	local leaveConn = buttonLikeInst.MouseLeave:Connect(function()
		if original then
			Animator.tween(buttonLikeInst, Animator.Durations.Fast, { BackgroundColor3 = original })
		end
	end)
	return function()
		if enterConn.Connected then enterConn:Disconnect() end
		if leaveConn.Connected then leaveConn:Disconnect() end
	end
end

function Animator.pressScale(inst)
	local down = inst.MouseButton1Down:Connect(function()
		Animator.tween(inst, Animator.Durations.Fast, { Size = inst.Size - UDim2.fromOffset(2, 2) })
	end)
	local up = inst.MouseButton1Up:Connect(function()
		Animator.tween(inst, Animator.Durations.Fast, { Size = inst.Size + UDim2.fromOffset(2, 2) })
	end)
	return function()
		if down.Connected then down:Disconnect() end
		if up.Connected then up:Disconnect() end
	end
end

return Animator

