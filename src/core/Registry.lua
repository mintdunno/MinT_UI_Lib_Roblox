-- Registry: maps string action names to callable functions
local Event = require(script.Parent.Event)
local ErrorHandler = require(script.Parent.ErrorHandler)

local Registry = {
	_map = {},
	changed = Event.new(),
}

-- Register a function by name
function Registry.register(name, fn, meta)
	assert(type(name) == "string" and name ~= "", "Registry.register requires a non-empty string name")
	assert(type(fn) == "function", "Registry.register requires a function")
	Registry._map[name] = { fn = fn, meta = meta }
	Registry.changed:Fire("register", name)
	return true
end

-- Remove a function
function Registry.unregister(name)
	if Registry._map[name] then
		Registry._map[name] = nil
		Registry.changed:Fire("unregister", name)
		return true
	end
	return false
end

function Registry.has(name)
	return Registry._map[name] ~= nil
end

function Registry.list()
	local items = {}
	for k, v in pairs(Registry._map) do
		items[#items+1] = { name = k, meta = v.meta }
	end
	table.sort(items, function(a,b) return a.name < b.name end)
	return items
end

-- Invoke a function by name. Returns ok, resultOrErr
function Registry.invoke(name, ...)
	local entry = Registry._map[name]
	if not entry then
		local msg = string.format("No action '%s' registered", tostring(name))
		ErrorHandler.notify("warning", msg)
		return false, msg
	end
	local ok, result = pcall(entry.fn, ...)
	if not ok then
		local err = string.format("Action '%s' failed: %s", tostring(name), tostring(result))
		ErrorHandler.notify("error", err)
		return false, err
	end
	return true, result
end

return Registry

