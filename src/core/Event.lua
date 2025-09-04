-- Simple Signal/Event utility
local Event = {}
Event.__index = Event

function Event.new()
	local self = setmetatable({}, Event)
	self._bindable = Instance.new("BindableEvent")
	self._connections = {}
	return self
end

function Event:Connect(fn)
	local conn = self._bindable.Event:Connect(fn)
	table.insert(self._connections, conn)
	return conn
end

function Event:Once(fn)
	local connection
	connection = self:Connect(function(...)
		if connection.Connected then connection:Disconnect() end
		fn(...)
	end)
	return connection
end

function Event:Fire(...)
	self._bindable:Fire(...)
end

function Event:Destroy()
	for _, c in ipairs(self._connections) do
		if c.Connected then c:Disconnect() end
	end
	self._connections = {}
	self._bindable:Destroy()
end

return Event

