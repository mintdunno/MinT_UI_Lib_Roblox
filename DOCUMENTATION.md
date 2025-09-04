MinT UI Library for Roblox — Comprehensive Documentation

Introduction
MinT is a modern, responsive, themeable GUI library that bridges backend script functionality with elegant, interactive UI components. It is designed to build full script-execution experiences in Roblox (editors, consoles, toolbars, execution controls) while remaining fast, modular, and easy to integrate.

Highlights
- Theme system with Dark/Light and live toggling
- Responsive scaling across devices
- Rich component set (editor, console, file browser, toolbar, queue manager, etc.)
- Registry pattern: wire UI to your backend functions with simple Action names
- Smooth animations; centralized errors, logs, and notifications
- Production lifecycle: all components expose Destroy() to prevent memory leaks

Installation & Setup
1) Import the library
- Place the src folder into your project as a ModuleScript hierarchy. A common approach is a Folder named Mint with child ModuleScripts and Folders that mirror src.
- Ensure src/init.lua is the ModuleScript you require (the root entry).

2) Require and mount

local Players = game:GetService("Players")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local Mint = require(path.to.Mint) -- points to src/init.lua

local app = Mint.newApp(playerGui, {
    Name = "MintUI",
    Notifications = { Position = "TopRight", Duration = 3 },
})
app:mount()

Core Concepts
App factory and mounting
- Mint.newApp(parent, config?) -> app table
- app:mount(): Creates and parents a ScreenGui, attaches UIScale for responsiveness, hooks theme background, and attaches toast notifications.
- app:unmount(): Destroys the ScreenGui.
- app:toggleTheme(), app:setTheme(name): Convenience helpers.

Registry pattern
- Register backend actions by name, then reference them from any component via the Action prop.

Mint.Registry.register("RunScript", function()
    print("Running...")
end)

local btn = Mint.components.Button.new({ Text = "Run", Action = "RunScript", Parent = app.Root })

Theming system
- Mint.ThemeManager.current(): returns active theme (colors table)
- Mint.ThemeManager.set("Light") / toggle(): switch themes
- Mint.ThemeManager.register("MyTheme", { colors = { ... } }): add custom themes
- Components react to ThemeManager.changed

Component lifecycle
- All components return a table with .Instance and Destroy().
- Always call comp:Destroy() when removing dynamically to clean up signal connections and UI instances.

Complete API Reference (Overview)
Core modules
- Util: helpers for Instance creation, tweening, layout
  - Create(className, props?, children?) -> Instance
  - Tween(inst, TweenInfo, goal) -> Tween?; Roundify(inst, radius?, strokeColor?, strokeTransparency?)
  - Padding(frame, px?) -> UIPadding; VList/HList(parent, spacing, align)
- Event: simple signal wrapper
  - Event.new(); :Connect(fn); :Once(fn); :Fire(...); :Destroy()
- Animator: centralized timings and interactions
  - tween(inst, duration, properties, easingStyle?, easingDirection?)
  - bindHover(buttonLikeInst, lightenColor?) -> cleanupFn
  - pressScale(buttonLikeInst) -> cleanupFn
- Responsive: UIScale with viewport-based scale
  - Attach(ScreenGui, opts?) -> UIScale, cleanupFn
- ThemeManager: theme registry with live updates
  - current(); set(name); toggle(); changed (Event); register(name, themeTable)
- Registry: action name to function mapping
  - register(name, fn, meta?); unregister(name); has(name); list(); invoke(name, ...) -> ok, result
- ErrorHandler: central notify bus (info/success/warning/error)
  - notify(level, message); event (Event); helpers: info/success/warn/error
- Hotkeys: keyboard shortcuts
  - bind("Ctrl+R", fn|{Action=string}); unbind(combo); clear(); enabled(bool)
  - Ignores shortcuts while a TextBox is focused
- LogManager: structured logging
  - append(level, message) -> entry; clear(); list(filter?) -> entries; added (Event); cleared (Event)
- Storage: pluggable persistence
  - setBackend({ save=function(key,t), load=function(key)->t|nil }); save(key,t); load(key); enableAuto(key, getterFn, interval?)
- Validator: lightweight validation
  - basicSyntax(text) -> ok, { line, col, msg } | true
- Queue: queue of tasks with events
  - new(); enqueue(meta)->id,item; update(id,patch); start/pause/stop/complete/remove/clear; list(); changed (Event)
- ComponentBase: internal base for lifecycle
  - extend({}), init({}); instance: _trackConn(conn), _trackCleanup(fn), _own(instance), Destroy()

Components
All components: new(props) -> component; component.Instance is an Instance; component:Destroy() tears down.
- Button: Props { Text, Icon?, Action?, OnClick?, Style? (Primary|Secondary|Ghost), Size?, Parent? }
- Toggle: Props { Label, Value?, OnChanged?, Action?, Parent? }; Methods: SetValue(bool), GetValue()
- Slider: Props { Label, Min?, Max?, Step?, Value?, OnChanged?, Action?, Size?, Parent? }; Methods: SetValue(number)
- TextInput: Props { Placeholder?, Text?, ClearTextOnFocus?, OnChanged?, OnSubmitted?, Validate?, Action?, Size?, Parent? }; Methods: SetText(string)
- Dropdown: Props { Items, Placeholder?, SelectedValue?, OnChanged?, Action?, Size?, MaxMenuHeight?, Parent? }; Methods: SetItems(array), SetSelected(value, fire?)
- Label: Props { Text, Size?, TextSize?, Bold?, Parent? }
- Panel: Props { Size, Padding?, Layout? (Vertical|Horizontal), Parent? }
- ProgressBar: Props { Value[0..1], Label?, Size?, Parent? }; Methods: SetValue(number)
- CodeEditor: Props { Text?, AutoSaveKey?, OnChanged?, OnValidate?, Size?, Parent? }; Methods: SetText(string)
- Console: Props { Size?, Levels? (set), MaxEntries? (default 500), Parent? }
  - UI toggles for levels; search; Clear button; listens to ErrorHandler + LogManager
- Tabs: Props { Tabs?: array<{ id, title, content }>, OnChanged?, Size?, Parent? }; Methods: AddTab(tab)
- Modal: Props { Title?, Content (Instance|string)?, Buttons?, Size?, Parent? }; Methods: Open(), Close(), SetContent(value)
- StatusBar: Props { Text?, Sandbox? (Sandboxed|Unsafe|Offline|Online), Size?, Parent? }; Methods: SetText, SetSandbox
- Toolbar: Props { Items, Spacing?, Parent? }
- ExecutionControls: Props { State?, OnPlay?, OnPause?, OnStop?, Actions?, Parent? }
- FileBrowser: Props { Items (tree), OnSelect?, OnOpen?, OnAction?, Size?, Parent? }
- QueueManager: Props { Queue (Queue instance), Actions?, OnSelect?, Size?, Parent? }
- VariableInspector: Props { Data? or Provider?, OnChanged?, RefreshInterval?, Size?, Parent? }; Methods: SetData(table)
- PerformanceMonitor: Props { Size?, Parent? }; Methods: Start(), Pause(), Stop()
- Notification (manager): Notification.Attach(screenGui, opts?), Notification.Notify(level, message, opts?)

Full IDE Example

local Players = game:GetService("Players")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local Mint = require(path.to.Mint)

local app = Mint.newApp(playerGui, { Name = "Mint Studio", Notifications = { Position = "TopRight" } })
app:mount()

-- Toolbar
local toolbar = Mint.components.Toolbar.new({
    Items = {
        { id = "run", text = "Run", style = "Primary", Action = "RunScript" },
        { id = "stop", text = "Stop", style = "Secondary", Action = "StopScript" },
        { id = "clear", text = "Clear", style = "Ghost", Action = "ClearConsole" },
    },
    Parent = app.Root,
})

-- Tabs and panes
local tabs = Mint.components.Tabs.new({ Size = UDim2.new(1, 0, 1, -120), Parent = app.Root })

-- Left/Right frame for editor + browser
local editorPane = Instance.new("Frame"); editorPane.BackgroundTransparency = 1; editorPane.Size = UDim2.fromScale(1,1)
Mint.Util.HList(editorPane, 10, Enum.VerticalAlignment.Top)

local fileBrowser = Mint.components.FileBrowser.new({
    Items = { { id = "Scripts", name = "Scripts", isFolder = true, _expanded = true, children = {
        { id = "hello", name = "hello.lua" },
    } } },
    OnOpen = function(node) Mint.Registry.invoke("OpenScript", node) end,
    Parent = editorPane,
})
fileBrowser.Instance.Size = UDim2.new(0, 260, 1, 0)

local editor = Mint.components.CodeEditor.new({
    Text = "print('Hello')",
    AutoSaveKey = "mint_autosave",
    Size = UDim2.new(1, -270, 1, 0),
    Parent = editorPane,
})

tabs:AddTab({ id = "editor", title = "Editor", content = editorPane })

local console = Mint.components.Console.new({ Size = UDim2.fromScale(1,1) })
tabs:AddTab({ id = "output", title = "Output", content = console.Instance })

local status = Mint.components.StatusBar.new({ Text = "Ready", Sandbox = "Sandboxed", Parent = app.Root })

-- Hotkeys
Mint.Hotkeys.bind("Ctrl+R", { Action = "RunScript" })
Mint.Hotkeys.bind("Ctrl+.", { Action = "StopScript" })

-- Registry actions
Mint.Registry.register("OpenScript", function(node)
    if node and not node.isFolder then
        editor:SetText("-- Loaded: " .. tostring(node.name) .. "\nprint('Loaded script')")
        Mint.ErrorHandler.info("Opened " .. tostring(node.name))
    end
end)

Mint.Registry.register("ClearConsole", function()
    Mint.LogManager.clear()
end)

Mint.Registry.register("RunScript", function()
    local ok, err = Mint.Validator.basicSyntax(editor.Text)
    if not ok then
        Mint.ErrorHandler.error(("Syntax error at line %d col %d: %s"):format(err.line, err.col, err.msg))
        return
    end
    Mint.ErrorHandler.success("Executed!")
    Mint.LogManager.append("output", "Execution finished")
end)

Mint.Registry.register("StopScript", function()
    Mint.ErrorHandler.warn("Stopped")
end)

Dynamic Loading with loadstring
Why bundling is needed
- Roblox ModuleScripts are resolved by the DataModel and cannot be directly loaded via loadstring.
- The library spans multiple modules with internal require calls (e.g., require(script.core.Util)). To load it dynamically from a single string, those requires must be inlined and resolved at runtime.

Build script (Lua, requires LuaFileSystem)
- We provide tools/build_mint.lua which bundles all files under src into Mint.min.lua.
- Prerequisites: Install Lua 5.1+ and LuaFileSystem (lfs) on your machine.
- Usage (from repo root):

lua tools/build_mint.lua

- Output: Mint.min.lua at repo root. The file returns a function; calling it returns the Mint table.

Loading via loadstring (client example)

local HttpService = game:GetService("HttpService")
local MINT_URL = "URL_TO_YOUR_RAW_MINT_MIN_LUA_FILE" -- e.g., from GitHub raw

local ok, res = pcall(function()
    return HttpService:GetAsync(MINT_URL)
end)

if ok and res then
    local ok2, factory = pcall(loadstring(res))
    if ok2 and typeof(factory) == "function" then
        local Mint = factory()
        print("MinT UI Library loaded successfully via loadstring!")
        -- Use Mint as usual:
        -- local app = Mint.newApp(Players.LocalPlayer.PlayerGui)
    else
        warn("Failed to execute loaded library string:", factory)
    end
else
    warn("Failed to fetch MinT UI Library:", res)
end

Notes
- The single-file bundle emulates require(script.Parent...) chains and injects a per-module script object shim, so internal requires work.
- The bundle assumes Lua 5.1 semantics (loadstring, setfenv), available in Roblox environments.
- If you modify the src files, re-run the builder to regenerate Mint.min.lua.

