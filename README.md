MinT UI Library for Roblox

A modern, themeable, responsive UI library that bridges backend script functionality to elegant, interactive GUI controls. Designed for performance, modularity, and developer ergonomics.

Features
- Light and Dark themes with instant toggling
- Fully responsive via UIScale with sensible clamping
- Modern components: Button, Toggle, Slider, TextInput, Dropdown, Label, Panel, Notification (toasts)
- Script IDE components: CodeEditor, Console, FileBrowser, ProgressBar, Modal, Tabs, StatusBar, Toolbar, ExecutionControls, QueueManager, VariableInspector, PerformanceMonitor
- Hotkeys, LogManager, Storage (auto-save), Validator, Queue
- Modular registry for connecting backend functions to UI via simple Action names
- Smooth, optimized animations and micro-interactions
- Cross-platform (PC, mobile, console) friendly
- Centralized error and feedback handling with on-screen toasts and Console

Getting Started
1) Place the src folder (or its contents) into a Folder/ModuleScript hierarchy in Roblox Studio so that:
   - Mint (ModuleScript) is the root (src/init.lua)
   - core (Folder) contains core modules (Util, Event, Animator, Responsive, ThemeManager, Registry, ErrorHandler)
   - components (Folder) contains components (Button, Toggle, Slider, TextInput, Dropdown, Label, Panel, Notification)

2) Require Mint and create an app:

local Players = game:GetService("Players")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local Mint = require(path.to.Mint) -- ModuleScript at src/init.lua

local app = Mint.newApp(playerGui, {
    Name = "MintUI",
    Notifications = { Position = "TopRight", Duration = 3 },
})
app:mount() -- creates ScreenGui and attaches responsive scaling + notifications

-- Optional: attach toasts to ErrorHandler
Mint.ErrorHandler.success("Welcome to Mint UI!")

Theming
- Default themes: "Dark" and "Light"
- Toggle quickly:

app:toggleTheme()

- Or set explicitly:

Mint.ThemeManager.set("Light")

- Register a custom theme:

Mint.ThemeManager.register("HighContrast", {
    colors = {
        background = Color3.fromRGB(0,0,0),
        surface = Color3.fromRGB(20,20,20),
        primary = Color3.fromRGB(0,255,0),
        primaryVariant = Color3.fromRGB(0,200,0),
        accent = Color3.fromRGB(255,255,0),
        text = Color3.fromRGB(255,255,255),
        textMuted = Color3.fromRGB(200,200,200),
        border = Color3.fromRGB(90,90,90),
        inputBg = Color3.fromRGB(30,30,30),
        success = Color3.fromRGB(48, 209, 88),
        warning = Color3.fromRGB(255, 214, 10),
        error = Color3.fromRGB(255, 69, 58),
    }
})
Mint.ThemeManager.set("HighContrast")

Connecting Backend Functions
Use the Registry to expose actions callable by UI components via the Action property. This keeps code decoupled and makes wiring trivial.

-- Register actions once
Mint.Registry.register("RunScript", function()
    print("Running your script...")
end)

Mint.Registry.register("SetVolume", function(value)
    print("Volume:", value)
end)

-- Any component with Action will invoke it when the user interacts
local btn = Mint.components.Button.new({ Text = "Run", Action = "RunScript" })
btn.Instance.Parent = app.Root

local slider = Mint.components.Slider.new({ Label = "Volume", Min = 0, Max = 100, Value = 30, Action = "SetVolume" })
slider.Instance.Parent = app.Root

UI Components
All components return a table with Instance (the Roblox Instance to parent), a Destroy() lifecycle method, and component-specific methods.

Lifecycle
- Each component now supports component:Destroy() to disconnect signals and destroy owned instances, preventing memory leaks.
- If you dynamically create/remove components, always call Destroy() when done.

- Button.new({ Text, Icon, Action, OnClick, Style, Size, Parent })
  Styles: "Primary" (default), "Secondary", "Ghost"

- Toggle.new({ Label, Value, OnChanged, Action, Parent })
  Methods: SetValue(bool), GetValue()

- Slider.new({ Label, Min, Max, Step, Value, OnChanged, Action, Size, Parent })
  Methods: SetValue(number)

- TextInput.new({ Placeholder, Text, ClearTextOnFocus, OnChanged, OnSubmitted, Validate, Action, Size, Parent })
  Methods: SetText(string)

- Dropdown.new({ Items, Placeholder, SelectedValue, OnChanged, Action, Size, MaxMenuHeight, Parent })
  Methods: SetItems(array), SetSelected(value, fire)

- Label.new({ Text, Size, TextSize, Bold, Parent })

- Panel.new({ Size, Padding, Layout, Parent })
  Layout: "Vertical" | "Horizontal"

- Console.new({ Size, Levels, MaxEntries, Parent })
  - UI controls to toggle levels (info, success, warning, error, debug, output)
  - Search box and Clear button
  - MaxEntries cap (default 500) to keep UI performant

- Notification.Attach(screenGui, opts), Notification.Notify(level, message, opts)
  Levels: info | success | warning | error

Error Handling and User Feedback
Use the centralized ErrorHandler to surface messages. The Notification system is attached automatically by app:mount() if available. Console also listens and shows messages.

Mint.ErrorHandler.info("Fetching data...")
Mint.ErrorHandler.success("Done!")
Mint.ErrorHandler.warn("Be careful")
Mint.ErrorHandler.error("Something went wrong")

Responsive Design
Mint.Responsive.Attach(ScreenGui) adds a UIScale that adapts to viewport height (relative to 1080p) with clamping. You can customize BaseHeight, MinScale, MaxScale if needed.

Accessibility and UX
- High contrast between text and backgrounds in both themes
- Consistent focus and hover states for interactive elements
- Animations are short and unobtrusive

Example: Small Tool Panel

local panel = Mint.components.Panel.new({ Size = UDim2.fromOffset(320, 200), Padding = 10, Layout = "Vertical", Parent = app.Root })

local runBtn = Mint.components.Button.new({ Text = "Run", Action = "RunScript" })
runBtn.Instance.Parent = panel.Instance

local toggle = Mint.components.Toggle.new({ Label = "Enable Fast Mode", Value = false, Action = "ToggleFast" })
toggle.Instance.Parent = panel.Instance

local dd = Mint.components.Dropdown.new({ Items = {"Low","Medium","High"}, Placeholder = "Quality", Action = "SetQuality" })
dd.Instance.Parent = panel.Instance

Mint.Registry.register("ToggleFast", function(v)
    print("Fast mode:", v)
end)

Mint.Registry.register("SetQuality", function(v)
    print("Quality:", v)
end)

Notes
- This library is pure ModuleScript-based; no external dependencies. 
- Ensure you parent component.Instance to your desired container (e.g., app.Root or a Panel.Instance).
- For production, consider structuring ScreenGui into panels/layouts to organize your UI.

License
MIT or your preferred license.

