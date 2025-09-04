-- ComponentBase: provides lifecycle and connection/cleanup management
-- Usage:
-- local Base = require(script.Parent.ComponentBase)
-- local MyComp = Base.extend({})
-- function MyComp.new(props)
--   local self = Base.init({})
--   setmetatable(self, MyComp)
--   ...
--   self:_own(rootInstance)
--   self:_trackConn(SomeSignal:Connect(function() ... end))
--   self:_trackCleanup(function() ... end) -- any extra cleanup
--   self.Instance = rootInstance
--   return self
-- end
-- Now you can call myComp:Destroy() to disconnect and destroy.

local ComponentBase = {}
ComponentBase.__index = ComponentBase

function ComponentBase.extend(Class)
	Class.__index = Class
	Class._base = ComponentBase
	return Class
end

function ComponentBase.init(tbl)
	tbl = tbl or {}
	setmetatable(tbl, ComponentBase)
	tbl._conns = {}
	tbl._cleanups = {}
	tbl._owned = {}
	tbl._destroyed = false
	return tbl
end

function ComponentBase:_trackConn(conn)
	if conn then
		table.insert(self._conns, conn)
	end
	return conn
end

function ComponentBase:_trackCleanup(fn)
	if type(fn) == "function" then
		table.insert(self._cleanups, fn)
	end
	return fn
end

function ComponentBase:_own(inst)
	if typeof(inst) == "Instance" then
		table.insert(self._owned, inst)
	end
	return inst
end

function ComponentBase:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	-- Disconnect signal connections
	for _, c in ipairs(self._conns) do
		pcall(function()
			if c and c.Connected ~= nil then
				if c.Connected then c:Disconnect() end
			elseif type(c) == "table" and c.Disconnect then
				c:Disconnect()
			end
		end)
	end
	self._conns = {}
	-- Run cleanups
	for i = #self._cleanups, 1, -1 do
		local fn = self._cleanups[i]
		pcall(fn)
		self._cleanups[i] = nil
	end
	self._cleanups = {}
	-- Destroy owned instances (root first usually last added? destroy all)
	for i = #self._owned, 1, -1 do
		local inst = self._owned[i]
		if inst and inst.Destroy then
			pcall(function() inst:Destroy() end)
		end
		self._owned[i] = nil
	end
	self._owned = {}
	-- Allow subclasses to override OnDestroy if needed
	if type(self.OnDestroy) == "function" then
		pcall(function() self:OnDestroy() end)
	end
end

return ComponentBase

