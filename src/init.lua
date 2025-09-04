-- MinT_UI_Lib_Roblox
-- Entry point for the library. Provides factory methods and exports core utilities and components.
--
-- How to use (see README for full guide):
-- local Mint = require(path.to.Mint)
-- local app = Mint.newApp(player:WaitForChild("PlayerGui"))
-- app:mount() -- creates a ScreenGui and responsive scaling
--
-- local btn = Mint.components.Button.new({
--     Text = "Run",
--     Action = "RunScript", -- optional: name in the Registry
--     OnClick = function()
--         print("Clicked Run")
--     end,
-- })
-- btn.Instance.Parent = app.Root -- attach to your layout container
--
-- Mint.Registry.register("RunScript", function()
--     -- do work
-- end)

local Mint = {}

Mint._version = "0.1.0"

-- Core
Mint.Util = require(script.core.Util)
Mint.Event = require(script.core.Event)
Mint.Animator = require(script.core.Animator)
Mint.Responsive = require(script.core.Responsive)
Mint.Registry = require(script.core.Registry)
Mint.ThemeManager = require(script.core.ThemeManager)
Mint.ErrorHandler = require(script.core.ErrorHandler)
Mint.Hotkeys = require(script.core.Hotkeys)
Mint.LogManager = require(script.core.LogManager)
Mint.Storage = require(script.core.Storage)
Mint.Validator = require(script.core.Validator)
Mint.Queue = require(script.core.Queue)

-- Components
Mint.components = {
	Button = require(script.components.Button),
	Toggle = require(script.components.Toggle),
	Slider = require(script.components.Slider),
	TextInput = require(script.components.TextInput),
	Dropdown = require(script.components.Dropdown),
	Label = require(script.components.Label),
	Panel = require(script.components.Panel),
	Notification = require(script.components.Notification),
	ProgressBar = require(script.components.ProgressBar),
	CodeEditor = require(script.components.CodeEditor),
	Console = require(script.components.Console),
	Tabs = require(script.components.Tabs),
	Modal = require(script.components.Modal),
	StatusBar = require(script.components.StatusBar),
	Toolbar = require(script.components.Toolbar),
	ExecutionControls = require(script.components.ExecutionControls),
	QueueManager = require(script.components.QueueManager),
	VariableInspector = require(script.components.VariableInspector),
	PerformanceMonitor = require(script.components.PerformanceMonitor),
}

-- App factory: creates a ScreenGui + responsive scaling + theme hookup
function Mint.newApp(parent, config)
	config = config or {}
	local Util = Mint.Util
	local ThemeManager = Mint.ThemeManager
	local Responsive = Mint.Responsive
	local Notification = require(script.components.Notification)

	local app = {}

	app.Parent = parent
	app.Config = {
		Name = config.Name or "MintUI",
		ZIndexBehavior = config.ZIndexBehavior or Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = config.IgnoreGuiInset ~= false,
		DisplayOrder = config.DisplayOrder or 0,
	}

	function app:mount()
		if self.Root then return self.Root end
		local gui = Util.Create("ScreenGui", {
			Name = self.Config.Name,
			ZIndexBehavior = self.Config.ZIndexBehavior,
			IgnoreGuiInset = self.Config.IgnoreGuiInset,
			DisplayOrder = self.Config.DisplayOrder,
			ResetOnSpawn = false,
		}, {
			Util.Create("Folder", { Name = "Layers" }),
		})
		gui.Parent = self.Parent

		self.Root = gui
		self.Scale = Responsive.Attach(gui)

		-- Attach Notification system for user feedback
		Notification.Attach(gui, config.Notifications)

		-- Apply current theme background to the root by adding a full-size Frame layer
		local bg = Util.Create("Frame", {
			Name = "AppBackground",
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
		})
		bg.Parent = gui

		local function applyTheme(theme)
			bg.BackgroundColor3 = theme.colors.background
		end
		applyTheme(ThemeManager.current())
		ThemeManager.changed:Connect(applyTheme)

		return gui
	end

	function app:unmount()
		if self.Root then
			self.Root:Destroy()
			self.Root = nil
			self.Scale = nil
		end
	end

	-- Theme helpers for convenience
	function app:setTheme(name)
		return ThemeManager.set(name)
	end
	function app:toggleTheme()
		ThemeManager.toggle()
	end

	-- Forward notify helper
	function app:notify(level, message, opts)
		local gui = self.Root
		if gui then
			require(script.components.Notification).Notify(level, message, opts)
		end
	end

	return app
end

return Mint

