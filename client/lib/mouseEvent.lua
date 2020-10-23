local event = require("event")

local dropMap = {}
local id = 0
local mouseEvent={}
local eid = -1

function mouseEvent.registerClick(x, y, width, height, func, ...)
	id = id + 1
	if dropMap[id] ~= nil then return -1 end
	dropMap[id] = {}
	dropMap[id].x=x
	dropMap[id].y=y
	dropMap[id].width=width
	dropMap[id].height=height
	dropMap[id].func=func
	dropMap[id].args=table.pack(...)
	return id
end

function mouseEvent.deregisterClick(id)
	if dropMap[id] == nil then return false end
	dropMap[id] = nil
	return true
end

function mouseEvent.cleanEvents()
	dropMap={}
	id=0
end

if eid == -1 then
	eid = event.listen("touch", function (e, screenAddress, x, y, button, playerName)
		for k,v in pairs(dropMap) do
			if v.x <= x and x < (v.x+v.width) and v.y <= y and y < (v.y+v.height) then
				v.func(table.unpack(v.args))
				return
			end
		end
	end)
end
return mouseEvent