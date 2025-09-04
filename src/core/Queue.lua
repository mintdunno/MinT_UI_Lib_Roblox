-- Queue: simple queue manager for script tasks
-- API:
-- local q = Queue.new()
-- local id = q:enqueue({ name = "Script A", payload = any })
-- q:start(id) / q:pause(id) / q:stop(id) / q:remove(id)
-- Events: q.changed (operation, item)

local HttpService = game:GetService("HttpService")
local Event = require(script.Parent.Event)

local Queue = {}
Queue.__index = Queue

function Queue.new()
	local self = setmetatable({}, Queue)
	self.items = {}
	self.order = {}
	self.changed = Event.new()
	return self
end

local function findIndex(t, id)
	for i, v in ipairs(t) do if v == id then return i end end
	return nil
end

function Queue:_emit(op, item)
	self.changed:Fire(op, item)
end

function Queue:enqueue(meta)
	local id = HttpService:GenerateGUID(false)
	local item = {
		id = id,
		name = (meta and meta.name) or ("Item " .. tostring(#self.order+1)),
		status = "queued", -- queued | running | paused | done | failed | stopped
		progress = 0,
		payload = meta and meta.payload,
		result = nil,
	}
	self.items[id] = item
	table.insert(self.order, id)
	self:_emit("enqueue", item)
	return id, item
end

function Queue:get(id)
	return self.items[id]
end

function Queue:list()
	local out = {}
	for _, id in ipairs(self.order) do out[#out+1] = self.items[id] end
	return out
end

function Queue:update(id, patch)
	local item = self.items[id]
	if not item then return false end
	for k, v in pairs(patch) do item[k] = v end
	self:_emit("update", item)
	return true
end

function Queue:start(id)
	return self:update(id, { status = "running" })
end

function Queue:pause(id)
	return self:update(id, { status = "paused" })
end

function Queue:stop(id)
	return self:update(id, { status = "stopped" })
end

function Queue:complete(id, ok, result)
	return self:update(id, { status = ok and "done" or "failed", result = result, progress = 1 })
end

function Queue:remove(id)
	local idx = findIndex(self.order, id)
	if not idx then return false end
	table.remove(self.order, idx)
	local item = self.items[id]
	self.items[id] = nil
	self:_emit("remove", item)
	return true
end

function Queue:clear()
	self.items = {}
	self.order = {}
	self:_emit("clear")
end

return Queue

