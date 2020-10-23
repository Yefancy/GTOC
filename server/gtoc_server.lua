local machineMap={}
machineMap.macerator = "MA"
machineMap.compressor = "CP"
machineMap.electric_furnace = "EF"
machineMap.fluid_heater = "FH"
machineMap.lathe = "LA"
machineMap.alloy_smelter = "AS"
machineMap.amplifab = "AM"
machineMap.ore_washer = "OW"
machineMap.electromagnetic_separator = "ES"
machineMap.bender = "BE"
machineMap.mixer = "MI"
machineMap.unpacker = "UP"
machineMap.canner = "CA"
machineMap.chemical_reactor = "CR"
machineMap.fluid_solidifier = "FS"
machineMap.fermenter = "FM"
machineMap.wiremill = "WI"
machineMap.cutter = "CU"
machineMap.packer = "PA"
machineMap.distillery = "DI"
machineMap.autoclave = "AU"
machineMap.forming_press = "FP"
machineMap.chemical_bath = "CB"
machineMap.polarizer = "PO"
machineMap.assembler = "AB"
machineMap.microwave = "MW"
machineMap.laser_engraver = "LE"
machineMap.fluid_canner = "FC"
machineMap.brewery = "BR"
machineMap.fluid_extractor = "FE"
machineMap.sifter = "SI"
machineMap.extractor = "EX"
machineMap.plasma_arc_furnace = "PF"
machineMap.centrifuge = "CE"
machineMap.electrolyzer = "EL"
machineMap.arc_furnace = "AF"
machineMap.thermal_centrifuge = "TC"
machineMap.forge_hammer = "HA"
machineMap.extruder = "ER"
machineMap.item_collector="IC"

local function splitMachine(str)
	local _i = string.find(string.reverse(str), '_')
	if _i == nil then return nil end
	local _s = string.len(str) - _i + 1
	return string.sub(str, 1, _s-1), string.sub(str, _s+1)
end

local component = require("component")
local event = require("event")
local keyboard = require("keyboard")
local serialization = require("serialization")
local modem = component.modem
local components
local machineProxy = {}
local group
local id = 1
---config
local checkDur,openPort,title
---net
local timer,listen
local clients={}


local function readMachineInfo(id)
	local m = machineProxy[id]
	-- isActive, progress, workingEnable, lowPower
	return {m.isActive(), math.ceil(m.getProgress()*100/m.getMaxProgress()), m.isWorkingEnabled(), m.getEnergyStored()*2<m.getEnergyCapacity()}
end

local function setWorkingEnabled(id, state)
	local m = machineProxy[id]
	if m == nil then return nil end
	-- isActive, progress, workingEnable, lowPower
	m.setWorkingEnabled(state)
	return m.setWorkingEnabled(state)
end

local function sendCompleteGroup(addr)
	modem.send(addr,clients[addr],0,serialization.serialize(group)) --- 0 client drawAll
end

local function loadAllMachines()
	group = {}
	group.Machines = {}
	group.V = title
	machineProxy = {}
	components = component.list()
	for k,v in pairs(components) do
		local machine, V = splitMachine(v)
		if machineMap[machine] ~= nil then 
			machineProxy[id] = component.proxy(k)
			local insertFlag = true
			for k1,v1 in pairs(group.Machines) do
				if v1.Type == machine then
					if #(v1.subMachines) < 6 then
						local _m = readMachineInfo(id); _m[5] = id; _m[6] = V;
						table.insert(v1.subMachines,_m)
						insertFlag = false
						break
					end
				end
			end
			if insertFlag then
				local Machines = {}
				Machines.Type = machine
				Machines.subMachines = {}
				local _m = readMachineInfo(id); _m[5] = id; _m[6] = V;
				table.insert(Machines.subMachines, _m)
				table.insert(group.Machines, Machines)
			end
			id = id+1
		end
	end
	print("update group")
	return group
end

local function updateMachineInfo()
	for i=1, #(group.Machines) do
		for j=1, #(group.Machines[i].subMachines) do
			local machine = group.Machines[i].subMachines[j]
			local ok, newInfo = pcall(readMachineInfo, machine[5])
			if not ok then 
				loadAllMachines()
				for k,v in pairs(clients) do
					sendCompleteGroup(k)
				end
				print("update group to all clients.")
				return
			end
			local sameflag = true
			for k=1,#newInfo do
				if machine[k] ~= newInfo[k] then sameflag = false; machine[k]=newInfo[k]; end
			end
			if not sameflag then
				for k,v in pairs(clients) do
					modem.send(k,v,1,i,j,serialization.serialize(machine)) --- 1 client drawUpdate
				end
			end
		end
	end
end

------------------------Main-----------------------
print("Title of Server:")
title = io.read()

print("Modem Listen Port:")
openPort = tonumber(io.read())
if openPort == nil then print("error input, expect a number.") os.exit() end
modem.open(openPort)

print("Interval Minutes of Travsel (recommend bigger than 5):")
checkDur = tonumber(io.read())
if checkDur == nil then print("error input, expect a number.") os.exit() end


print("Keeping Ctrl+C 5 seconds to stop server")
timer = event.timer(checkDur*60, function()
	local _components = component.list()
	local noChange = true
	for k,v in pairs(_components) do 
		if components[k] == nil then
			local machine, V = splitMachine(v)
			if machineMap[machine] then noChange = false; break; end
		end
	end
	if not noChange then 
		loadAllMachines()
		for k,v in pairs(clients) do sendCompleteGroup(k) end
		print("update group to all clients.")	
	end
end, math.huge)

loadAllMachines()


listen = event.listen("modem_message", function(_, _, from, port, _, ...)
	local args = table.pack(...)
	---opcode 
	if args[1] == 0 then -- 0- first connect server
		print("first connect server from:"..from)
		clients[from] = args[2] -- port
		sendCompleteGroup(from)
	elseif args[1] == 1 then -- 1- update settings
		print("client setting request:"..from)
		local state,ids = args[2],serialization.unserialize(args[3])
		for i=1, #ids do
			print(tostring(ids[i])..tostring(state))
			setWorkingEnabled(ids[i],state)
		end
		modem.send(from,port,2,true) --- 2 client setting callback
	elseif args[1] == 2 then -- 2- client exit
		clients[from] = nil
	end
end)

while true do
	os.sleep(5)
	updateMachineInfo()
	if keyboard.isKeyDown(keyboard.keys.c) and keyboard.isControlDown() then
		print("Stoping Server...")
		modem.close(openPort)
		event.cancel(timer)
		event.cancel(listen)
        os.exit()
	end
end

