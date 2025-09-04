-- LogManager: central log bus with levels, filtering, and events
local Event = require(script.Parent.Event)

local LogManager = {}

LogManager.added = Event.new() -- fires (entry)
LogManager.cleared = Event.new()

LogManager._logs = {}
LogManager._max = 1000

-- entry: { t = os time, level = 'info'|'warn'|'error'|'debug'|'output', message = string }
function LogManager.append(level, message)
	local entry = {
		t = os.time(),
		level = string.lower(level or 'info'),
		message = tostring(message or ''),
	}
	LogManager._logs[#LogManager._logs+1] = entry
	if #LogManager._logs > LogManager._max then
		table.remove(LogManager._logs, 1)
	end
	LogManager.added:Fire(entry)
	return entry
end

function LogManager.clear()
	LogManager._logs = {}
	LogManager.cleared:Fire()
end

function LogManager.list(filter)
	filter = filter or {}
	local out = {}
	for _, e in ipairs(LogManager._logs) do
		local ok = true
		if filter.level and e.level ~= filter.level then ok = false end
		if filter.search and filter.search ~= '' then
			if not string.find(string.lower(e.message), string.lower(filter.search), 1, true) then ok = false end
		end
		if ok then out[#out+1] = e end
	end
	return out
end

return LogManager

