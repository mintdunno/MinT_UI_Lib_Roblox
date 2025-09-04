-- Storage: pluggable auto-save/load system for scripts and settings
-- Default is in-memory. Consumers can provide backend via Storage.setBackend({ save = fn(key, tbl), load = fn(key) -> tbl })
-- API: Storage.save(key, tbl), Storage.load(key) -> tbl|nil, Storage.enableAuto(key, getterFn, intervalSec)

local HttpService = game:GetService("HttpService")

local Storage = {}

local _backend = {
	save = function(key, tbl)
		Storage._memory = Storage._memory or {}
		Storage._memory[key] = HttpService:JSONEncode(tbl)
		return true
	end,
	load = function(key)
		if Storage._memory and Storage._memory[key] then
			local ok, decoded = pcall(function()
				return HttpService:JSONDecode(Storage._memory[key])
			end)
			if ok then return decoded end
		end
		return nil
	end,
}

function Storage.setBackend(impl)
	if type(impl) == "table" and type(impl.save) == "function" and type(impl.load) == "function" then
		_backend = impl
	else
		error("Storage.setBackend expects { save=function, load=function }")
	end
end

function Storage.save(key, tbl)
	return _backend.save(tostring(key), tbl)
end

function Storage.load(key)
	return _backend.load(tostring(key))
end

-- Auto-save helper: periodically calls getterFn() and saves under key
function Storage.enableAuto(key, getterFn, interval)
	interval = interval or 10
	task.spawn(function()
		while true do
			task.wait(interval)
			local ok, data = pcall(getterFn)
			if ok and data ~= nil then
				pcall(Storage.save, key, data)
			end
		end
	end)
end

return Storage

