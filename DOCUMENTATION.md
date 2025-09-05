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




---

# Complete API Reference

This section lists every public Core Module and UI Component. For each item:
- Purpose: one-line summary
- Props: constructor properties to .new(props) with name, type, optional, description
- Methods: public instance methods (or module functions)
- Events: public events and their arguments
- Code Example: common usage

## Core Modules

### Animator
- Purpose: Centralized, smooth tweening and micro-interactions (hover/press).
- Methods:
  - tween(instance, duration[, properties][, easingStyle][, easingDirection]) → Tween: Play a tween.
  - bindHover(buttonLikeInst[, lightenColor3]) → cleanupFn: Animate background on hover.
  - pressScale(buttonLikeInst) → cleanupFn: Subtle press feedback.
- Events: None.
- Code Example:
```
local t = Mint.Animator.tween(frame, 0.2, { BackgroundTransparency = 0.1 })
```

### ComponentBase
- Purpose: Internal base for lifecycle; used by all components.
- Methods (instance):
  - Destroy(): Disconnects signals, runs cleanups, destroys owned instances.
- Events: None.
- Code Example: used implicitly by components; call comp:Destroy().

### ErrorHandler
- Purpose: Centralized user feedback and logging bridge.
- Methods:
  - notify(level, message)
  - info(msg), success(msg), warn(msg), error(msg)
- Events:
  - event:Connect(function(level, message) ... end)
- Code Example:
```
Mint.ErrorHandler.success("Done!")
Mint.ErrorHandler.event:Connect(function(level, msg) print(level, msg) end)
```

### Event
- Purpose: Lightweight signal wrapper.
- Methods:
  - Event.new() → event
  - :Connect(fn) → RBXScriptConnection
  - :Once(fn) → RBXScriptConnection
  - :Fire(...)
  - :Destroy()
- Events: n/a (it is the event).
- Code Example:
```
local ev = Mint.Event.new(); ev:Connect(function(a) print(a) end); ev:Fire(123)
```

### Hotkeys
- Purpose: Register global keyboard shortcuts mapped to callbacks or Registry actions.
- Methods:
  - bind("Ctrl+R", function|{Action=string})
  - unbind(combo)
  - clear()
  - enabled(boolean)
- Notes: Ignores shortcuts when a TextBox is focused.
- Events: None.
- Code Example:
```
Mint.Hotkeys.bind("Ctrl+R", { Action = "RunScript" })
```

### LogManager
- Purpose: Central log store with levels, filtering, and events.
- Methods:
  - append(level, message) → entry
  - clear()
  - list({ level?, search? }) → { entries }
- Events:
  - added:Connect(function(entry) ... end)
  - cleared:Connect(function() ... end)
- Code Example:
```
Mint.LogManager.append("info", "Hello")
```

### Queue
- Purpose: Manage a queue of tasks/scripts with statuses and progress.
- Methods (instance):
  - new() → queue
  - enqueue({ name?, payload? }) → id, item
  - get(id) → item
  - list() → { items }
  - update(id, patch)
  - start(id), pause(id), stop(id), complete(id, ok, result), remove(id), clear()
- Events:
  - changed:Connect(function(op, item) ... end)
- Code Example:
```
local q = Mint.Queue.new(); local id = q:enqueue({ name = "Task" }); q:start(id)
```

### Registry
- Purpose: Map string action names to functions for UI wiring.
- Methods:
  - register(name, fn[, meta])
  - unregister(name)
  - has(name) → bool
  - list() → { { name, meta } }
  - invoke(name, ...) → ok, resultOrErr
- Events:
  - changed:Connect(function(op, name) ... end)
- Code Example:
```
Mint.Registry.register("Run", function() print("Go") end)
Mint.Registry.invoke("Run")
```

### Responsive
- Purpose: UIScale that adapts to viewport size with clamped scaling.
- Methods:
  - Attach(screenGui[, opts]) → UIScale, cleanupFn
- Events: None.
- Code Example:
```
local scale = Mint.Responsive.Attach(screenGui)
```

### Storage
- Purpose: Pluggable persistence for scripts/settings; supports autosave.
- Methods:
  - setBackend({ save=function(key,t), load=function(key) end })
  - save(key, table)
  - load(key) → table|nil
  - enableAuto(key, getterFn[, intervalSeconds])
- Events: None.
- Code Example:
```
Mint.Storage.save("active", { text = "hi" })
```

### ThemeManager
- Purpose: Manage themes (Dark/Light/custom) and notify listeners.
- Methods:
  - current() → theme
  - set(name) → bool
  - toggle()
  - register(name, themeTable)
- Events:
  - changed:Connect(function(theme) ... end)
- Code Example:
```
Mint.ThemeManager.set("Light")
```

### Util
- Purpose: Helpers for Instances, layout, padding, rounding, tween wrapper.
- Methods:
  - Create(className, props?, children?) → Instance
  - Tween(inst, tweenInfo, goal) → Tween?
  - Roundify(inst[, radius][, strokeColor][, strokeTransparency])
  - Padding(frame[, px]) → UIPadding
  - VList(parent, spacing[, align]) / HList(parent, spacing[, align]) → UIListLayout
- Events: None.
- Code Example:
```
local frame = Mint.Util.Create("Frame", { Size = UDim2.fromOffset(200,100) })
```

### Validator
- Purpose: Lightweight syntax checks (bracket balance, unterminated strings).
- Methods:
  - basicSyntax(text) → true | false, { line, col, msg }
- Events: None.
- Code Example:
```
local ok, err = Mint.Validator.basicSyntax(code)
```

---

## UI Components (Alphabetical)
All components: comp = Mint.components.Name.new(props); comp.Instance is the Instance; comp:Destroy() cleans up.

### Button
- Purpose: Clickable button with styles and micro-interactions.
- Props:
  - Text (string, optional): Label text.
  - Icon (string, optional): Image asset id.
  - Action (string, optional): Registry action name to invoke on click.
  - OnClick (function, optional): Callback on click.
  - Style (string, optional): "Primary"|"Secondary"|"Ghost" (default Primary).
  - Size (UDim2, optional): Default (160x36).
  - Parent (Instance, optional): Auto-parent target.
- Methods:
  - Destroy(): Cleanup and destroy instances.
- Events: None.
- Code Example:
```
local btn = Mint.components.Button.new({ Text = "Run", Action = "RunScript", Parent = app.Root })
```

### CodeEditor
- Purpose: Multi-line code editor with simple Lua highlighting, line numbers, autosave.
- Props:
  - Text (string, optional): Initial text.
  - AutoSaveKey (string, optional): Storage key for autosave.
  - OnChanged (function(string), optional): Called on text change.
  - OnValidate (function(string)→ok,errInfo, optional): Validate function (default Validator.basicSyntax).
  - Size (UDim2, optional)
  - Parent (Instance, optional)
- Methods:
  - SetText(text)
  - Destroy()
- Events: None.
- Code Example:
```
local editor = Mint.components.CodeEditor.new({ Text = "print('Hi')", AutoSaveKey = "mint_edit" })
```

### Console
- Purpose: Scrollable console for logs; filters by level; search; Clear.
- Props:
  - Size (UDim2, optional)
  - Levels (table set, optional): { info=true, success=true, warning=true, error=true, debug=true, output=true }
  - MaxEntries (number, optional): Cap on rendered rows (default 500)
  - Parent (Instance, optional)
- Methods:
  - Destroy()
- Events: Reflects LogManager events (internally subscribed).
- Code Example:
```
local console = Mint.components.Console.new({ MaxEntries = 1000 })
```

### Dropdown
- Purpose: Select from a list with a popover menu and overlay.
- Props:
  - Items (array, required): strings or { text=string, value=any }.
  - Placeholder (string, optional)
  - SelectedValue (any, optional)
  - OnChanged (function(value, item), optional)
  - Action (string, optional)
  - Size (UDim2, optional)
  - MaxMenuHeight (number, optional)
  - Parent (Instance, optional)
- Methods:
  - SetItems(items)
  - SetSelected(value[, fire])
  - Destroy()
- Events: None.
- Code Example:
```
local dd = Mint.components.Dropdown.new({ Items = {"Low","High"}, Placeholder = "Quality" })
```

### ExecutionControls
- Purpose: Play/Pause/Stop strip with visual state and hooks.
- Props:
  - State (string, optional): "stopped"|"running"|"paused" (default "stopped")
  - OnPlay (function, optional)
  - OnPause (function, optional)
  - OnStop (function, optional)
  - Actions (table, optional): { Play=string, Pause=string, Stop=string }
  - Parent (Instance, optional)
- Methods:
  - Destroy()
- Events: None.
- Code Example:
```
local ec = Mint.components.ExecutionControls.new({ Actions = { Play = "RunScript" } })
```

### FileBrowser
- Purpose: Tree/list script manager with expand/collapse and open/select.
- Props:
  - Items (array, required): nodes { id, name, isFolder, children? }
  - OnSelect (function(node), optional)
  - OnOpen (function(node), optional)
  - OnAction (function(actionName, node), optional)
  - Size (UDim2, optional)
  - Parent (Instance, optional)
- Methods:
  - Destroy()
- Events: None.
- Code Example:
```
local fb = Mint.components.FileBrowser.new({ Items = { { id="Scripts", name="Scripts", isFolder=true, _expanded=true } } })
```

### Label
- Purpose: Theme-aware text display.
- Props: Text (string), Size (UDim2, opt), TextSize (number, opt), Bold (boolean, opt), Parent (Instance, opt).
- Methods: Destroy()
- Events: None.
- Code Example:
```
local lbl = Mint.components.Label.new({ Text = "Status" })
```

### Modal
- Purpose: Overlay dialog with content and buttons.
- Props:
  - Title (string, optional)
  - Content (Instance|string, optional)
  - Buttons (array, optional): { text, style?, action? }
  - Size (UDim2, optional)
  - Parent (Instance, optional)
- Methods:
  - Open()
  - Close()
  - SetContent(value)
  - Destroy()
- Events: None.
- Code Example:
```
local modal = Mint.components.Modal.new({ Title = "Confirm" })
modal:Open()
```

### Panel
- Purpose: Themed container with optional layout helpers.
- Props: Size (UDim2), Padding (number, opt), Layout ("Vertical"|"Horizontal", opt), Parent (Instance, opt)
- Methods: Destroy()
- Events: None.
- Code Example:
```
local panel = Mint.components.Panel.new({ Size = UDim2.fromOffset(320,200), Layout = "Vertical" })
```

### PerformanceMonitor
- Purpose: Show memory usage and a run timer (Start/Pause/Stop).
- Props: Size (UDim2, opt), Parent (Instance, opt)
- Methods: Start(), Pause(), Stop(), Destroy()
- Events: None.
- Code Example:
```
local pm = Mint.components.PerformanceMonitor.new({})
pm.Start()
```

### ProgressBar
- Purpose: Visual progress indicator.
- Props: Value (number 0..1, opt), Label (string, opt), Size (UDim2, opt), Parent (Instance, opt)
- Methods: SetValue(number), Destroy()
- Events: None.
- Code Example:
```
local pb = Mint.components.ProgressBar.new({ Value = 0.4 })
```

### QueueManager
- Purpose: Visual manager for a Queue instance with inline controls.
- Props: Queue (Queue instance, required), Actions (table, opt), OnSelect (function, opt), Size (UDim2, opt), Parent (Instance, opt)
- Methods: Destroy()
- Events: Reflects Queue.changed (internally subscribed).
- Code Example:
```
local qm = Mint.components.QueueManager.new({ Queue = Mint.Queue.new() })
```

### StatusBar
- Purpose: Bottom status line with sandbox/connection indicator.
- Props: Text (string, opt), Sandbox (string, opt), Size (UDim2, opt), Parent (Instance, opt)
- Methods: SetText(text), SetSandbox(state), Destroy()
- Events: None.
- Code Example:
```
local sb = Mint.components.StatusBar.new({ Text = "Ready", Sandbox = "Sandboxed" })
```

### Tabs
- Purpose: Tabbed interface hosting content views.
- Props: Tabs (array, opt: { id, title, content }), OnChanged (function(id), opt), Size (UDim2, opt), Parent (Instance, opt)
- Methods: AddTab({ id, title, content }), Destroy()
- Events: None.
- Code Example:
```
local tabs = Mint.components.Tabs.new({}); tabs:AddTab({ id="one", title="One", content = Instance.new("Frame") })
```

### TextInput
- Purpose: Single-line text input with optional validation and submit.
- Props: Placeholder (string, opt), Text (string, opt), ClearTextOnFocus (bool, opt), OnChanged (fn), OnSubmitted (fn), Validate (fn), Action (string), Size (UDim2), Parent (Instance)
- Methods: SetText(text), Destroy()
- Events: None.
- Code Example:
```
local ti = Mint.components.TextInput.new({ Placeholder = "Type...", OnSubmitted = function(t) print(t) end })
```

### Toggle
- Purpose: Boolean toggle (switch) with animated knob.
- Props: Label (string), Value (bool, opt), OnChanged (function(bool), opt), Action (string, opt), Parent (Instance, opt)
- Methods: SetValue(bool), GetValue() → bool, Destroy()
- Events: None.
- Code Example:
```
local tg = Mint.components.Toggle.new({ Label = "Enable", Value = true })
```

### Toolbar
- Purpose: Horizontal button group for common actions.
- Props: Items (array: { id, text, icon?, style?, Action?, OnClick? }), Spacing (number, opt), Parent (Instance, opt)
- Methods: Destroy()
- Events: None.
- Code Example:
```
local tb = Mint.components.Toolbar.new({ Items = { { id="run", text="Run", Action="Run" } } })
```

### VariableInspector
- Purpose: Inspect and edit variables live (booleans, numbers, strings, nested tables).
- Props: Data (table) or Provider (function→table), OnChanged (function(path, value), opt), RefreshInterval (number, opt), Size (UDim2, opt), Parent (Instance, opt)
- Methods: SetData(table), Destroy()
- Events: None.
- Code Example:
```
local vi = Mint.components.VariableInspector.new({ Data = { speed = 1, verbose = true } })
```

### Notification (Manager)
- Purpose: Toast notifications for info/success/warning/error.
- Props: (Attach) opts table: { Duration?, MaxToasts?, Position? }
- Methods:
  - Notification.Attach(screenGui[, opts])
  - Notification.Detach()
  - Notification.Notify(level, message[, opts])
- Events: Bridges ErrorHandler automatically when attached.
- Code Example:
```
Mint.components.Notification.Attach(app.Root, { Position = "TopRight" })
Mint.ErrorHandler.success("Ready")
```
