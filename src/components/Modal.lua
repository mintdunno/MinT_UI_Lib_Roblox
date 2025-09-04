-- Modal dialog component: overlay with a centered panel
-- Props:
-- Title (string)
-- Content (Instance | string)
-- Buttons: array of { text=string, style='Primary'|'Secondary', action=function() } (order left->right)
-- Size (UDim2) panel size, default (360, 180)
-- Parent (Instance)
-- Returns { Instance, Open(), Close(), SetContent(inst|string) }

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Animator = require(script.Parent.Parent.core.Animator)
local Base = require(script.Parent.Parent.core.ComponentBase)

local Modal = Base.extend({})

function Modal.new(props)
	props = props or {}
	local self = Base.init({})
	setmetatable(self, Modal)

	local theme = Theme.current()

	local overlay = Util.Create("Frame", {
		Name = "MintModalOverlay",
		BackgroundColor3 = Color3.fromRGB(0,0,0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1,1),
		Visible = false,
		ZIndex = 10000,
	})
	self:_own(overlay)

	local panel = Util.Create("Frame", {
		Name = "Panel",
		BackgroundColor3 = theme.colors.surface,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5,0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = props.Size or UDim2.fromOffset(360, 180),
		ZIndex = overlay.ZIndex + 1,
	})
	Util.Roundify(panel, 10, theme.colors.border, 0.9)
	Util.Padding(panel, 10)
	panel.Parent = overlay
	self:_own(panel)

	local title = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Text = tostring(props.Title or ""),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextColor3 = theme.colors.text,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
	})
	title.Parent = panel

	local contentArea = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -60),
		Position = UDim2.new(0, 0, 0, 26),
		ClipsDescendants = true,
	})
	contentArea.Parent = panel

	local footer = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.new(0, 0, 1, -28),
	})
	footer.Parent = panel
	local btnLayout = Util.HList(footer, 8, Enum.VerticalAlignment.Center)
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

	local function setContent(value)
		for _, ch in ipairs(contentArea:GetChildren()) do
			ch:Destroy()
		end
		if typeof(value) == "Instance" then
			value.Parent = contentArea
		elseif type(value) == "string" then
			local lbl = Util.Create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Text = value,
				TextColor3 = theme.colors.text,
				Font = Enum.Font.Gotham,
				TextSize = 14,
			})
			lbl.Parent = contentArea
		end
	end
	setContent(props.Content)
	self.SetContent = setContent

	local function addButtons(buttons)
		for _, b in ipairs(buttons or {}) do
			local btn = Util.Create("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = (b.style == "Secondary") and theme.colors.inputBg or theme.colors.primary,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(88, 28),
				Text = tostring(b.text or "OK"),
				TextColor3 = (b.style == "Secondary") and theme.colors.text or Color3.new(1,1,1),
				Font = Enum.Font.GothamSemibold,
				TextSize = 14,
			})
			Util.Roundify(btn, 6, theme.colors.border, 0.8)
			btn.Parent = footer
			self:_trackConn(btn.MouseButton1Click:Connect(function()
				if type(b.action) == "function" then b.action() end
				self:Close()
			end))
		end
	end
	addButtons(props.Buttons)

	function self:Open()
		overlay.Visible = true
		overlay.BackgroundTransparency = 1
		Animator.tween(overlay, Animator.Durations.Normal, { BackgroundTransparency = 0.35 })
		panel.Size = UDim2.fromOffset((props.Size or UDim2.fromOffset(360,180)).X.Offset * 0.95, (props.Size or UDim2.fromOffset(360,180)).Y.Offset * 0.95)
		Animator.tween(panel, Animator.Durations.Normal, { Size = props.Size or UDim2.fromOffset(360,180) })
	end

	function self:Close()
		Animator.tween(overlay, Animator.Durations.Fast, { BackgroundTransparency = 1 })
		task.delay(Animator.Durations.Fast + 0.05, function()
			overlay.Visible = false
		end)
	end

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		panel.BackgroundColor3 = newTheme.colors.surface
		title.TextColor3 = newTheme.colors.text
	end))

	self.Instance = overlay
	self.Panel = panel
	if props.Parent then overlay.Parent = props.Parent end
	return self
end

return Modal

