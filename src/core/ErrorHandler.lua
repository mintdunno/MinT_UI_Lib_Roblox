-- ErrorHandler: centralized user feedback and logging with levels
local Event = require(script.Parent.Event)

local ErrorHandler = {}

ErrorHandler.event = Event.new() -- fires (level, message)

local validLevels = {
	info = true,
	success = true,
	warning = true,
	error = true,
}

local function log(level, msg)
	local prefix = string.upper(level)
	if level == "error" then
		warn("[Mint][" .. prefix .. "] " .. tostring(msg))
	else
		print("[Mint][" .. prefix .. "] " .. tostring(msg))
	end
end

function ErrorHandler.notify(level, message)
	level = string.lower(level or "info")
	if not validLevels[level] then level = "info" end
	log(level, message)
	ErrorHandler.event:Fire(level, message)
end

-- Helper wrappers
function ErrorHandler.info(msg) ErrorHandler.notify("info", msg) end
function ErrorHandler.success(msg) ErrorHandler.notify("success", msg) end
function ErrorHandler.warn(msg) ErrorHandler.notify("warning", msg) end
function ErrorHandler.error(msg) ErrorHandler.notify("error", msg) end

return ErrorHandler

