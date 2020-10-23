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

-- Import required libraries
local component = require("component")
local buffer = require("doubleBuffering")
local keyboard = require("keyboard")
local mouseEvent = require("mouseEvent")
local serialization = require("serialization")
local event = require("event")
local modem = component.modem
local model1 = {'┌','┐','└','┘','─','│'}
local model2 = {'╔','╗','╚','╝','═','║'}
--local color_map = {0x0000FF, 0x00FF00, 0xFF0000, 0xFFFF00, 0xFF9900,0x00FFFF}--blue,green,red,yellow,orange,lightblue
local groups = {}
----config
local openPort,serverPort
----net
local listen
------------------------logic-----------------------
local function setMachineState(state, group, index, switch)
	local ids = {}
	if index ~=nil then
		if switch ~=nil then
			ids[1] = groups[group].Machines[index].subMachines[switch][5]
		else
			local subMachines = groups[group].Machines[index].subMachines
			for i=1,#subMachines do ids[i] = subMachines[i][5] end 
		end
	else
		for j=1,#groups[group].Machines do
			local subMachines = groups[group].Machines[j].subMachines
			for i=1,#subMachines do table.insert(ids,subMachines[i][5]) end 
		end
	end
	groups[group].finishSetting = false
	modem.send(groups[group].addr, serverPort,1, state, serialization.serialize(ids)) --- 1-update settings
end

-----------------------render-----------------------
local function drawProgress(x,y,width,percentage,color)
	buffer.drawRectangle(x, y, width, 1, 0x808080, 0x808080, ' ')
	buffer.drawRectangle(x, y, math.ceil(percentage*width), 1, 0x808080, color, '▉')
end

local function drawBlock(x,y,width,height,color,model)
	buffer.set(x,y,0,color, model[1])
	buffer.set(x+width,y,0,color, model[2])
	buffer.set(x,y+height,0,color, model[3])
	buffer.set(x+width,y+height,0,color, model[4])
	buffer.drawRectangle(x+1, y, width-1, 1, 0, color, model[5])
	buffer.drawRectangle(x+1, y+height, width-1,1,0,color,model[5])
	buffer.drawRectangle(x, y+1,1,height-1,0,color,model[6])
	buffer.drawRectangle(x+width,y+1,1,height-1, 0,color, model[6])
end

local function drawMachine(group, index, isSelected, x, y)
	local subMachines = groups[group].Machines[index].subMachines
	local offset = groups[group].offset
	local title = (groups[group].Machines)[index].Type
	---selected
	local _y
	if isSelected then
		x,y,_y = x,y,math.floor(y/2)+1
		buffer.drawText(x-2,_y+1,0xFFFFFF,tostring(index))
		buffer.drawText(x+9,_y+3,0xFFFFFF,title)
	else
	    x,y,_y = group*40-34, 18+6*(index-offset),9+3*(index-offset)+1
	end
	buffer.drawSemiPixelRectangle(x,y,4,4,0x0000FF)
	local line_color = 0x0000FF
	if groups[group].selected == index then
		buffer.drawSemiPixelRectangle(x,y,4,4,0x00FFFF)
		line_color = 0xFFFF00
	end
	buffer.drawText(x+4,_y,line_color, '├──┼─')
	buffer.drawText(x+5,_y-1,0xFFFFFF,machineMap[title])
	local as = true
	local loading = 0
	local eu = 0
	for  i=1, #subMachines do -- isActive, progress, workingEnable, lowPower, id, Type
		buffer.set(i*3+x+7,_y,0,line_color,'─')
		if isSelected then buffer.drawText(i*3+x+8,_y+2,0xFFFFFF,tostring(subMachines[i][5])) 
		else buffer.drawRectangle(i*3+x+8,_y-1,3,1,0,0,' ') end	
		if subMachines[i][1] then 
			color=0xFF9900 
			loading = loading + 1
			if subMachines[i][2] > 9 then
				buffer.drawText(i*3+x+8,_y-1,0xFFFFFF,tostring(subMachines[i][2]))
			else buffer.drawText(i*3+x+9,_y-1,0xFFFFFF,tostring(subMachines[i][2])) end
		else color = 0x00FF00 end
		if subMachines[i][4] then color = 0xFF0000; eu = eu+1; end
		if subMachines[i][3] then 
			buffer.drawText(i*3+x+8,_y+1,0x00FF00,'└┘')
			as = false
		else
			color = 0xFF0000
			buffer.drawText(i*3+x+8,_y+1,0xFF0000,'└─')
		end
		buffer.drawText(i*3+x+8,_y,color,'██')
	end
	
	if as then 
		buffer.drawText(x+9,_y,0xFF0000, '☐')
		buffer.drawSemiPixelRectangle(x+1,y+1,2,2,0xFF0000)
	else
		buffer.drawText(x+9,_y,0x00FF00, '▣')
		if loading > 0 then buffer.drawSemiPixelRectangle(x+1,y+1,2,2,0xFF9900) else buffer.drawSemiPixelRectangle(x+1,y+1,2,2,0x00FF00) end
	end
	
	return as, loading > 0, loading/#subMachines, eu/#subMachines
end

function drawSelected(group)
	---clean
	local x = (group-1)*40 + 12
	buffer.drawRectangle(x,6,28,3, 0,0,' ')
	buffer.drawRectangle(x+3,9,25,1, 0,0,' ')
	buffer.drawRectangle(x+8,10,20,1, 0,0,' ')
	buffer.drawRectangle(x+7,2,13,1, 0,0,' ')
	---draw
	--buffer.drawRectangle(x,1,28,1, 0,0xFFFF00,model2[5])
	buffer.drawRectangle(x,6,28,1,0,0xFFFF00, '┈')
	local subMachines = (groups[group].Machines)[groups[group].selected].subMachines
	local as,ew
	if groups[group].selected ~= nil then
		as,ew,loading,eu = drawMachine(group, groups[group].selected, true, x,12)
	end
	if as then buffer.drawText(x+7,2,0xFF0000, 'All Stoped')else
		if ew then
			buffer.drawText(x+7,2,0xFF9900, 'Exist Working')else
			buffer.drawText(x+7,2,0x00FF00, 'All Free')end end
	drawProgress(x+5,3,20,1-eu,0x00FF00);
	drawProgress(x+5,4,20,loading,0xFFCCCC);
end

local function drawLine(index, as)
	local x = (index-1)*40 + 4 
	local overCheck = #(groups[index].Machines) - groups[index].offset
	local size
	if overCheck > 10 then size=10 else size = overCheck end
	--main block
	drawBlock(x+1,1,35,10,0xFFFF00,model2)
	--line
	buffer.set(x+34,11,0,0xFFFF00, '╤')
	buffer.drawRectangle(x+34,12,1,30, 0,0xFFFF00, model1[6])
	buffer.set(x+34,42,0,0xFFFF00, '┴')
	for y=24,(size-2)*6+24,6 do
		_y = y/2
		buffer.set(x-1,_y-1,0,0xFFFF00, '│')
		buffer.set(x-1,_y,0,0xFFFF00,   '│')
		buffer.drawText(x-1,_y+1,0xFFFF00, '├──')
	end
	_y = (size-1)*3+12
	buffer.set(x-1,_y-1,0,0xFFFF00, '│')
	buffer.set(x-1,_y,0,0xFFFF00,   '│')
	if overCheck > 10 then
		buffer.drawText(x-1,_y+1,0xFFFF00, '├──')
		buffer.set(x-1,_y+2,0,0xFFFF00, '┷')
	else
		buffer.drawText(x-1,_y+1,0xFFFF00, '└──')
	end
	--all swith
	buffer.set(x-1,11,0,0xFFFF00, '╤')
	buffer.set(x-1,9,0,0xFFFF00, '╧')
	buffer.drawText(x-1,8,0xFFFF00, '┌─╢')
	if as then buffer.set(x-1,10,0,0xFF0000, '☐') else buffer.set(x-1,10,0,0x00FF00, '▣') end 
end

local function drawGroup(index)
	local ass,eww = true,false
	local x = (index-1)*40
	local group = groups[index]
	--clean
	buffer.drawRectangle(x+1,1,40,41,0,0,' ')
	--check page
	local endIndex = #(group.Machines)
	if endIndex - group.offset > 10 then endIndex = group.offset + 10 end
	for i = group.offset + 1, endIndex do
		as, ew = drawMachine(index, i) 
		if not as then ass = false end
		if ew then eww = true end
	end
	--draw page button
	if group.offset > 0 then buffer.drawText(x+36,38,0xFFFF00, '◢◣') end
	if #(group.Machines) > endIndex then buffer.drawText(x+36,40,0xFFFF00, '◥◤') end
	--draw line
	drawLine(index, ass)
	--server title
	buffer.drawRectangle(x+7,1,string.len(group.V),1,0xFFFF00,0, " ")
	buffer.drawText(x+7,1,0, group.V)
	--draw select
	buffer.drawText(x+6,2,0xFFFFFF, 'Group Status:')
	buffer.drawText(x+6,3,0xFFFFFF, 'EU Stored:');
	buffer.drawText(x+6,4,0xFFFFFF, 'Loading:');
	buffer.drawRectangle(x+6,5,34,1,0,0xFFFF00, '┈')
	------
	buffer.drawRectangle(x+6,6,6,1,0,0xFFFF00, '┈')
	buffer.drawText(x+6,8,0xFFFFFF, 'Sel:')
	buffer.drawText(x+6,9,0xFFFFFF, 'Sub-M ID:')
	buffer.drawText(x+6,10,0xFFFFFF, 'Machines Name:')
	drawSelected(index)
end

local function drawInstructions()
	drawBlock(1,42,159,8,0xFFFF00,model1)
	buffer.drawText(2,42,0xFFFFFF, 'Instructions')
	---
	buffer.set(3,44,0,0xFF0000, '☐'); buffer.drawText(7,44,0xFFFFFF, '--switch(turn off)')
	buffer.set(3,46,0,0x00FF00, '▣'); buffer.drawText(7,46,0xFFFFFF, '--switch(turn on)')
	buffer.drawSemiPixelRectangle(2,94,4,4,0x0000FF)
	buffer.drawSemiPixelRectangle(3,95,2,2,0x00FF00); buffer.drawText(7,48,0xFFFFFF, '--machine group(free)'); buffer.drawText(23,48,0x00FF00, 'free')
	---
	buffer.drawSemiPixelRectangle(30,94,4,4,0x0000FF)
	buffer.drawSemiPixelRectangle(31,95,2,2,0xFF9900); buffer.drawText(35,48,0xFFFFFF, '--machine group(working)'); buffer.drawText(51,48,0xFF9900, 'working')
	buffer.drawSemiPixelRectangle(30,88,4,4,0x0000FF)
	buffer.drawSemiPixelRectangle(31,89,2,2,0xFF0000); buffer.drawText(35,45,0xFFFFFF, '--machine group(stoped)'); buffer.drawText(51,45,0xFF0000, 'stoped')
	---
	buffer.drawText(61,44,0x00FF00,'██'); buffer.drawText(65,44,0xFFFFFF, '--machine(free)');buffer.drawText(75,44,0x00FF00, 'free')
	buffer.drawText(61,46,0xFF9900,'██'); buffer.drawText(65,46,0xFFFFFF, '--machine(working)');buffer.drawText(75,46,0xFF9900, 'working')
	buffer.drawText(61,48,0xFF0000,'██'); buffer.drawText(65,48,0xFFFFFF, '--machine(stoped / no power)');buffer.drawText(75,48,0xFF0000, 'stoped / no power')
	---
	buffer.drawText(94,44,0xFFFFFF,'93'); buffer.drawText(98,44,0xFFFFFF, '--progress')
	buffer.drawText(94,46,0x00FF00,'└┘'); buffer.drawText(98,46,0xFFFFFF, '--switch(turn on)')
	buffer.drawText(94,48,0xFF0000,'└─'); buffer.drawText(98,48,0xFFFFFF, '--switch(turn off)')
	---
	buffer.drawText(117,44,0xFFFF00, '├──┤');buffer.drawText(118,43,0xFFFFFF, 'AS');buffer.drawText(123,44,0xFFFFFF, '--type of machine group')
	---G
	buffer.drawSemiPixelRectangle(120,91,3,1,0x00FFFF)
	buffer.drawSemiPixelRectangle(119,92,1,3,0x00FFFF)
	buffer.drawSemiPixelRectangle(120,95,3,1,0x00FFFF)
	buffer.drawSemiPixelRectangle(121,93,2,1,0x00FFFF)
	buffer.drawSemiPixelRectangle(123,94,1,1,0x00FFFF)
	---T
	buffer.drawSemiPixelRectangle(125,91,3,1,0x00FFFF)
	buffer.drawSemiPixelRectangle(126,92,1,4,0x00FFFF)
	---C
	buffer.drawSemiPixelRectangle(130,91,3,1,0x00FFFF)
	buffer.drawSemiPixelRectangle(129,92,1,3,0x00FFFF)
	buffer.drawSemiPixelRectangle(130,95,3,1,0x00FFFF)
	---E
	buffer.drawSemiPixelRectangle(135,91,3,1,0x00FFFF)
	buffer.drawSemiPixelRectangle(134,92,1,3,0x00FFFF)
	buffer.drawSemiPixelRectangle(135,93,2,1,0x00FFFF)
	buffer.drawSemiPixelRectangle(135,95,3,1,0x00FFFF)
	--- ---
	buffer.drawSemiPixelRectangle(139,93,7,1,0x00FFFF)
	---O
	buffer.drawSemiPixelRectangle(148,91,2,1,0x00FFFF)
	buffer.drawSemiPixelRectangle(148,95,2,1,0x00FFFF)
	buffer.drawSemiPixelRectangle(147,92,1,3,0x00FFFF)
	buffer.drawSemiPixelRectangle(150,92,1,3,0x00FFFF)
	---C
	buffer.drawSemiPixelRectangle(153,91,3,1,0x00FFFF)
	buffer.drawSemiPixelRectangle(152,92,1,3,0x00FFFF)
	buffer.drawSemiPixelRectangle(153,95,3,1,0x00FFFF)
	--- author
	buffer.drawText(125,49,0xFFFFFF,'---  Designed by KilaBash');
end

-----------------------register-----------------------
local function registerSwitchClick()
	for x=0,3 do
		for i=0,5 do
			---machine switch
			mouseEvent.registerClick(x*40+23 + i*3,8,2,1,function(group, switch)
				if group > #groups then return end
				local machine = groups[group].Machines[groups[group].selected].subMachines[switch]
				if machine == nil then return end
				if machine[3] then
					setMachineState(false, group, groups[group].selected, switch)
					machine[3] = false
				else
					setMachineState(true, group, groups[group].selected, switch)
					machine[3] = true
				end
				drawGroup(group)
				buffer.drawChanges()
			end, x+1, i+1)
		end
		---machines switch
		mouseEvent.registerClick(x*40+21,7,1,1,function(group)
			if group > #groups then return end
			local bg,fg,sb = buffer.get(x*40+21,7)
			local sw = true
			if sb == '▣'then sw = false end
			local subMachines = groups[group].Machines[groups[group].selected].subMachines
			for i=1, #subMachines do
				if subMachines[i][3] ~= sw then 
					subMachines[i][3] = sw;
				end
			end
			setMachineState(sw, group, groups[group].selected)
			drawGroup(group)
			buffer.drawChanges()
		end, x+1)
		---group switch
		mouseEvent.registerClick(x*40+3,10,1,1,function(group)
			if group > #groups then return end
			local bg,fg,sb = buffer.get(x*40+3,10)
			local sw = true
			if sb == '▣'then sw = false end
			local Machines = groups[group].Machines
			for j=1, #Machines do
				local subMachines = groups[group].Machines[j].subMachines
				for i=1, #subMachines do
					if subMachines[i][3] ~= sw then 
						subMachines[i][3] = sw;
					end
				end
			end
			setMachineState(sw, group)
			drawGroup(group)
			buffer.drawChanges()
		end, x+1)
		---selected button
		for i=0,9 do
			mouseEvent.registerClick(x*40+6, 12+3*i,4,3,function(group, index)
				if group > #groups then return end
				local last_selected, offset = groups[group].selected, groups[group].offset
				index = index + offset
				if index > #(groups[group].Machines) then return end
				groups[group].selected = index
				if offset < last_selected and last_selected < offset+11  then drawMachine(group,last_selected) end
				drawMachine(group,index)
				drawSelected(group)
				buffer.drawChanges()
			end, x+1, i+1)
		end
		-- ---page up
		mouseEvent.registerClick(x*40+36, 38,2,1,function(group)
			if group > #groups then return end
			local offset = groups[group].offset
			if offset > 0 then groups[group].offset = offset - 1; drawGroup(group); buffer.drawChanges(); end
		end, x+1)
		---page down
		mouseEvent.registerClick(x*40+36, 40,2,1,function(group)
			if group > #groups then return end
			local offset = groups[group].offset
			if #(groups[group].Machines) > offset + 10 then groups[group].offset = offset + 1; drawGroup(group); buffer.drawChanges(); end
		end, x+1)
	end
end

------------------------Main-----------------------
print("Modem Listen Port:")
openPort = tonumber(io.read())
if openPort == nil then print("error input, expect a number.") os.exit() end
modem.open(openPort)

print("Servers Port:")
serverPort = tonumber(io.read())
if serverPort == nil then print("error input, expect a number.") os.exit() end

modem.broadcast(serverPort, 0, openPort) -- 0-first connect server
---clean screen
buffer.clear()
buffer.drawRectangle(1,1,160,50,1,0,' ')
buffer.drawChanges()
buffer.drawRectangle(1,1,160,50,0,0,' ')
buffer.drawChanges()
drawInstructions()
mouseEvent.cleanEvents()
registerSwitchClick()
buffer.drawChanges()
listen = event.listen("modem_message", function(_, _, from, port, _, ...)
	local args = table.pack(...)
	---opcode 
	if args[1] == 0 then --- 0 client drawAllGroup
		local group = serialization.unserialize(args[2]) -- group
		local findFlag = true
		group.addr = from; group.selected = 1; group.offset = 0;group.finishSetting = true;
		for i=1,#groups do
			if groups[i].addr == from then
				if groups[i].selected <= #(group.Machines) then group.selected = groups[i].selected end
				if groups[i].offset + 9 < #(group.Machines) then group.selected = groups[i].offset end
				groups[i] = group; drawGroup(i);
				findFlag = false; break
			end
		end
		if findFlag then
			if #groups < 4 then table.insert(groups, group); drawGroup(#groups); end
		end
	elseif args[1] == 1 then --- 1 client drawUpdate
		local i,j,machine = args[2],args[3],serialization.unserialize(args[4])
		for k=1,#groups do
			if groups[k].addr == from and groups[k].finishSetting then
				groups[k].Machines[i].subMachines[j] = machine; drawGroup(k);
			end
		end
	elseif args[1] == 2 then --- 2 client setting callback
		for k=1,#groups do
			if groups[k].addr == from then
				groups[k].finishSetting = true
			end
		end
	end
	buffer.drawChanges()
end)
while true do
	os.sleep(3)
	if keyboard.isKeyDown(keyboard.keys.c) and keyboard.isControlDown() then
		for group=1,#groups do modem.send(groups[group].addr, serverPort,2) --- 2- client exit
		end
		modem.close(openPort)
		mouseEvent.cleanEvents()
		event.cancel(listen)
        os.exit()
	end
end