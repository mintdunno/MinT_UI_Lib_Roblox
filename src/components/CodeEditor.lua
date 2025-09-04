-- CodeEditor component (basic multi-line editor with simple Lua highlighting, line numbers, and scrolling)
-- Props:
-- Text (string)
-- OnChanged (function:string)
-- OnValidate (function:string -> ok, errInfo?) optional; defaults to Validator.basicSyntax
-- Size (UDim2) default (480, 260)
-- AutoSaveKey (string) optional to auto-save via Storage
-- Parent (Instance) optional

local Util = require(script.Parent.Parent.core.Util)
local Theme = require(script.Parent.Parent.core.ThemeManager)
local Animator = require(script.Parent.Parent.core.Animator)
local Storage = require(script.Parent.Parent.core.Storage)
local Validator = require(script.Parent.Parent.core.Validator)
local Base = require(script.Parent.Parent.core.ComponentBase)

local CodeEditor = Base.extend({})

local KEYWORDS = {
	["local"]=true, ["function"]=true, ["end"]=true, ["if"]=true, ["then"]=true,
	["else"]=true, ["elseif"]=true, ["for"]=true, ["in"]=true, ["do"]=true,
	["while"]=true, ["repeat"]=true, ["until"]=true, ["return"]=true, ["and"]=true,
	["or"]=true, ["not"]=true, ["nil"]=true, ["true"]=true, ["false"]=true,
}

local function escapeXml(s)
	s = s:gsub("&", "&amp;")
	s = s:gsub("<", "&lt;")
	s = s:gsub(">", "&gt;")
	return s
end

local function rgbhex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
end

local function highlightLua(text, theme)
	-- Very simple highlighter: strings, comments, numbers, keywords
	local t = theme.colors
	local colStr = rgbhex(t.accent)
	local colCom = rgbhex(t.textMuted)
	local colNum = rgbhex(t.warning)
	local colKey = rgbhex(t.primary)

	local out = {}
	for line in (text.."\n"):gmatch("(.-)\n") do
		local s = escapeXml(line)
		-- comments -- ...
		local comment = s:match("%-%-.*$")
		if comment then
			s = s:gsub("%-%-.*$", function(c)
				return string.format("<font color=\"%s\">%s</font>", colCom, escapeXml(c))
			end)
		end
		-- strings (simple): '...' or "..."
		s = s:gsub("'(.-)'", function(str)
			return string.format("<font color=\"%s\">'%s'</font>", colStr, escapeXml(str))
		end)
		s = s:gsub('"(.-)"', function(str)
			return string.format("<font color=\"%s\">\"%s\"</font>", colStr, escapeXml(str))
		end)
		-- numbers
		s = s:gsub("(%f[%w_][0-9]+%f[^%w_])", function(num)
			return string.format("<font color=\"%s\">%s</font>", colNum, num)
		end)
		-- keywords
		s = s:gsub("(%f[%a_][%a_]+%f[^%a_])", function(word)
			if KEYWORDS[word] then
				return string.format("<font color=\"%s\">%s</font>", colKey, word)
			end
			return word
		end)
		out[#out+1] = s
	end
	return table.concat(out, "\n")
end

function CodeEditor.new(props)
	props = props or {}
	local self = setmetatable({}, CodeEditor)
	self.Text = tostring(props.Text or "")
	self.AutoSaveKey = props.AutoSaveKey
	self.OnChanged = props.OnChanged
	self.OnValidate = props.OnValidate or Validator.basicSyntax

	-- Load autosave
	if self.AutoSaveKey then
		local saved = Storage.load(self.AutoSaveKey)
		if type(saved) == "table" and type(saved.text) == "string" then
			self.Text = saved.text
		end
	end

	local theme = Theme.current()

	local root = Util.Create("Frame", {
		Name = "MintCodeEditor",
		BackgroundColor3 = theme.colors.surface,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(520, 260),
		ClipsDescendants = true,
	})
	self:_own(root)
	Util.Roundify(root, 8, theme.colors.border, 0.9)

	-- Top bar (validation state)
	local status = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 16),
		Position = UDim2.fromOffset(4, 4),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "",
		TextColor3 = theme.colors.textMuted,
		Font = Enum.Font.Gotham,
		TextSize = 12,
	})
	status.Parent = root

	local editorArea = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 1, -28),
		Position = UDim2.fromOffset(4, 20),
	})
	editorArea.Parent = root

	-- Line numbers scroll view
	local gutter = Util.Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		Size = UDim2.new(0, 36, 1, 0),
		CanvasSize = UDim2.new(0,0,0,0),
	})
	gutter.Parent = editorArea
	local gutterText = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = "",
		TextColor3 = theme.colors.textMuted,
		Font = Enum.Font.Code,
		TextSize = 14,
	})
	gutterText.Parent = gutter

	-- Main editor viewport
	local viewport = Util.Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		Size = UDim2.new(1, -36, 1, 0),
		Position = UDim2.new(0, 36, 0, 0),
		CanvasSize = UDim2.new(0,0,0,0),
		ScrollBarImageTransparency = 0.5,
	})
	viewport.Parent = editorArea

	local highlight = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.Code,
		TextSize = 14,
		Text = "",
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(1, -6, 0, 0),
	})
	highlight.Parent = viewport

	local input = Util.Create("TextBox", {
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		MultiLine = true,
		TextEditable = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.Code,
		TextSize = 14,
		Text = self.Text,
		CursorPosition = #self.Text + 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(1, -6, 0, 0),
	})
	input.Parent = viewport

	-- Ensure TextBox is on top for input
	input.ZIndex = 2
	highlight.ZIndex = 1

	local function updateLineNumbers(lines)
		local buff = {}
		for i = 1, lines do buff[i] = tostring(i) end
		gutterText.Text = table.concat(buff, "\n")
		gutterText.Size = UDim2.new(1, 0, 0, gutterText.TextBounds.Y)
		gutter.CanvasSize = UDim2.new(0,0,0, gutterText.TextBounds.Y + 8)
	end

	local function refresh()
		-- Highlight
		highlight.Text = highlightLua(self.Text, Theme.current())
		-- Resize based on bounds
		input.Text = self.Text
		input.Size = UDim2.new(1, -6, 0, input.TextBounds.Y)
		highlight.Size = UDim2.new(1, -6, 0, input.TextBounds.Y)
		viewport.CanvasSize = UDim2.new(0,0,0, input.TextBounds.Y + 8)
		-- Line numbers
		local _, lines = self.Text:gsub("\n", "")
		updateLineNumbers(lines + 1)
		-- Validate
		local ok, err = self.OnValidate(self.Text)
		if ok then
			status.Text = "Valid"
			status.TextColor3 = Theme.current().colors.success
		else
			status.Text = string.format("Error: line %d col %d - %s", err.line or 0, err.col or 0, err.msg or "")
			status.TextColor3 = Theme.current().colors.error
		end
	end

	-- Sync scroll of gutter with viewport
	self:_trackConn(viewport:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		gutter.CanvasPosition = Vector2.new(0, viewport.CanvasPosition.Y)
	end))

	-- Change handler
	self:_trackConn(input:GetPropertyChangedSignal("Text"):Connect(function()
		self.Text = input.Text
		refresh()
		if self.OnChanged then
			local ok, err = pcall(self.OnChanged, self.Text)
			if not ok then warn(err) end
		end
		if self.AutoSaveKey then
			Storage.save(self.AutoSaveKey, { text = self.Text })
		end
	end))

	-- Initial populate
	refresh()

	self:_trackConn(Theme.changed:Connect(function(newTheme)
		root.BackgroundColor3 = newTheme.colors.surface
		local s = root:FindFirstChildOfClass("UIStroke"); if s then s.Color = newTheme.colors.border end
		status.TextColor3 = newTheme.colors.textMuted
		refresh()
	end))

	self.Instance = root
	self.Viewport = viewport
	self.Input = input
	if props.Parent then root.Parent = props.Parent end
	return self
end

function CodeEditor:SetText(t)
	self.Text = tostring(t or "")
	if self.Input then self.Input.Text = self.Text end
end

return CodeEditor

