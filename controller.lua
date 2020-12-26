Controller = {
    open = false,
    visible = true,
    WindowStyle = {
            ["Text"] = { [1] = 0, [2] = 0, [3] = 0, [4] = 0 },
            ["WindowBg"] = { [1] = 0, [2] = 0, [3] = 0, [4] = 0.85 },
            ["Button"] = { [1] = 20, [2] = 75, [3] = 100, [4] = 1 },
            ["ButtonHovered"] = { [1] = 15, [2] = 31, [3] = 90, [4] = 0.75 },
            ["CheckMark"] = { [1] = 250, [2] = 250, [3] = 250, [4] = 1 },
            ["TextSelectedBg"] = { [1] = 0, [2] = 0, [3] = 0, [4] = 0 },
            ["TooltipBg"] = { [1] = 7, [2] = 0, [3] = 12, [4] = 1 },
			["ModalWindowDarkening"] = { [1] = 7, [2] = 0, [3] = 12, [4] = 0.75 },
    },
    Settings = {
		enabled = true,
		firstTime = true,
	},
	Data = {},
}
local MinionPath = GetStartupPath()
local LuaModsPath = GetLuaModsPath()
local ModulePath = LuaModsPath .. [[Music Controller\]]
local ModuleSettings = ModulePath .. [[data\Settings.lua]]
local Settings = Controller.Settings
local Data = Controller.Data

local PreviousSettingsSave,PreviousAnalyticsSave,lastcheck = {},{},0
function Controller.save(force)
	if (force or TimeSince(lastcheck) > 30000) then
		lastcheck = Now()
		if not table.deepcompare(Controller.Settings,PreviousSettingsSave) then
			FileSave(ModuleSettings,Controller.Settings)
			PreviousSettingsSave = table.deepcopy(Controller.Settings)
        end
        if not table.deepcompare(Controller.Analytics,PreviousAnalyticsSave) then
			FileSave(ModuleAnalytics,Controller.Analytics)
			PreviousAnalyticsSave = table.deepcopy(Controller.Analytics)
		end
	end
end
local save = Controller.save

local v = table.valid
function Controller.valid(...)
	local tbl = {...}
	local size = #tbl
	if size > 0 then
		local count = tbl[1]
		if type(count) == "number" then
			if size == (count + 1) then
				for i = 2, size do
					if not v(tbl[i]) then return false end
				end
				return true
			end
		else
			for i = 1, size do
				if not v(tbl[i]) then return false end
			end
			return true
		end
	end
	return false
end
local valid = Controller.valid

local function LoadSettings()
    local tbl = FileLoad(ModuleSettings)
    local function scan(tbl,tbl2,depth)
        depth = depth or 0
        if Controller.valid(2,tbl,tbl2) then
            for k,v in pairs(tbl2) do
                if type(v) == "table" then
                    if tbl[k] and Controller.valid(tbl[k]) then
                        tbl[k] = table.merge(tbl[k],scan(tbl[k],v,depth+1))
                    else
                        tbl[k] = v
                    end
                else
                    if tbl[k] ~= tbl2[k] then tbl[k] = tbl2[k] end
                end
            end
        end
        return tbl
    end
    Controller.Settings = scan(Controller.Settings,tbl)
end

function Controller.log(text, n)
	local time = os.date("%H:%M:%S")
	if n == 1 or n == nil then
		d("[Controller] "..text)
	elseif n == 2 then
		ml_gui.showconsole = true
		d("[Controller] CRITICAL ERROR")
		d("[Controller]"..text)
	end
end
local log = Controller.log

function Controller.firstTimeSetup()
	local components = [[%ProgramFiles(x86)\foobar2000\components]]
	local config = [[%appdata%\foobar2000\configuration]]
	io.popen([[c: & cd ]]..ModulePath..[[\data & copy /y foo_np_simple.dll.cfg, ]]..config..[[]]):close()
	log("First time setup complete.")
	Settings.firstTime = false
	save(true)
end

function Controller.sendCommand(cmd)
	if cmd ~= "rand" then 
		io.popen([[c: & cd C:\Program Files (x86)\foobar2000 & foobar2000.exe "/command:]]..cmd..[["]]):close()
	elseif cmd == "rand" then
		io.popen([[c: & cd C:\Program Files (x86)\foobar2000 & foobar2000.exe "/rand"]]):close()
	end
	log("Sending command to foobar: "..cmd)
end
local sendCommand = Controller.sendCommand

function Controller.updateStatus()
	if FileExists(ModulePath.."\\data\\nowplaying.txt") then
		local info = FileLoad(ModulePath.."\\data\\nowplaying.txt")
		if info[1] ~= nil then Data.playbackstatus = info[1] else Data.playbackstatus = "no playback status data" end
		if info[2] ~= nil and info[2] ~= "?\r" then Data.currentartist = info[2] else Data.currentartist = "no artist data" end
		if info[3] ~= nil and info[3] ~= "?\r" then Data.currentsong = info[3] else Data.currentsong = "no song data" end
		if info[4] ~= nil and info[4] ~= "?\r" then Data.volume = info[4] else Data.volume = nil end
		if info[5] ~= nil and info[5] ~= "?\r" then Data.songLength = info[5] else Data.songLength = nil end
		if info[6] ~= nil and info[6] ~= "?\r" then Data.elapsedTime = info[6] else Data.elapsedTime = nil end
		if info[7] ~= nil and info[7] ~= "?\r" then Data.elapsedTimeSeconds = tonumber(info[7]) else Data.elapsedTimeSeconds = nil end
		if info[8] ~= nil and info[8] ~= "?\r" and info[8] ~= "?" then Data.songLengthSeconds = tonumber(info[8]) else Data.songLengthSeconds = nil end
		Data.NoTextFile = false
	else
		Data.NoTextFile = true
	end
end

function Controller.Update(event, ticks)
	local gamestate = GetGameState()
    if (gamestate == FFXIV.GAMESTATE.INGAME) and Settings.enabled == true and Controller.open == true then
		if Data.lastStatusCheck ~= nil and TimeSince(Data.lastStatusCheck) >= 1000 then
			Controller.updateStatus()
			Data.lastStatusCheck = Now()
		elseif Data.lastStatusCheck == nil then
			Data.lastStatusCheck = Now()
		end
	end
end

function Controller.Draw(event, ticks) 	
	if ( Controller.open ) then	
		local Style = GUI:GetStyle()
		local c = 0
		for k,v in pairs(Controller.WindowStyle) do if v[4] ~= 0 then c = c + 1 loadstring([[GUI:PushStyleColor(GUI.Col_]]..k..[[, ]]..(v[1]/255)..[[, ]]..(v[2]/255)..[[, ]]..(v[3]/255)..[[, ]]..v[4]..[[)]])() end end
		local winSizeX,winSizeY = 400,120
		GUI:SetNextWindowSize(winSizeX,winSizeY,GUI.Always)
		Controller.visible, Controller.open = GUI:Begin("Controller", Controller.open, GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoScrollWithMouse + GUI.WindowFlags_NoCollapse)
		if ( Controller.visible ) then 
			if Data.NoTextFile == true then
				GUI:TextWrapped("Could not find any data from the NowPlaying-Simple plugin for Foobar. Make sure you've dragged the file 'foo_np_simple.dll' in "..ModulePath.."data to C:\\Program Files (x86)\\foobar2000\\components. Then restart Foobar and start playing a song to generate the first sample data.")
			else
				local button = Controller.buttons[3]
				GUI:Image(button.icon,button.size.x,button.size.y)
				if GUI:IsItemHovered() then
					GUI:BeginTooltip()
					GUI:PushTextWrapPos(300)
					GUI:Text(button.tooltip)
					GUI:PopTextWrapPos()
					GUI:EndTooltip()
					if GUI:IsItemClicked(0) then
						sendCommand(button.cmd)
					end
				end

				GUI:SameLine()

				local winX,winY = GUI:GetWindowSize()
				local itemSize = 25
				GUI:SameLine()
				GUI:Dummy(0,0) GUI:SameLine(winX/2.55-(itemSize/2))
				local button = Controller.buttons[6]
				GUI:Image(button.icon,button.size.x,button.size.y)
				if GUI:IsItemHovered() then
					GUI:BeginTooltip()
					GUI:PushTextWrapPos(300)
					GUI:Text(button.tooltip)
					GUI:PopTextWrapPos()
					GUI:EndTooltip()
					if GUI:IsItemClicked(0) then
						sendCommand(button.cmd)
					end
				end

				GUI:SameLine()
				GUI:Dummy(0,0) GUI:SameLine(winX/2-(itemSize/2))
				if Data.playbackstatus == "paused\r" then
					local button = Controller.buttons[1]
					GUI:Image(button.icon,button.size.x,button.size.y)
					if GUI:IsItemHovered() then
						GUI:BeginTooltip()
						GUI:PushTextWrapPos(300)
						GUI:Text(button.tooltip)
						GUI:PopTextWrapPos()
						GUI:EndTooltip()
						if GUI:IsItemClicked(0) then
							sendCommand(button.cmd)
						end
					end
				elseif Data.playbackstatus == "playing\r" then
					local button = Controller.buttons[2]
					GUI:Image(button.icon,button.size.x,button.size.y)
					if GUI:IsItemHovered() then
						GUI:BeginTooltip()
						GUI:PushTextWrapPos(300)
						GUI:Text(button.tooltip)
						GUI:PopTextWrapPos()
						GUI:EndTooltip()
						if GUI:IsItemClicked(0) then
							sendCommand(button.cmd)
						end
					end
				elseif Data.playbackstatus == "stopped\r" or Data.playbackstatus == "stopped" then
					local button = Controller.buttons[1]
					GUI:Image(button.icon,button.size.x,button.size.y)
					if GUI:IsItemHovered() then
						GUI:BeginTooltip()
						GUI:PushTextWrapPos(300)
						GUI:Text(button.tooltip)
						GUI:PopTextWrapPos()
						GUI:EndTooltip()
						if GUI:IsItemClicked(0) then
							sendCommand(button.cmd)
						end
					end
				end

				GUI:SameLine()
				GUI:Dummy(0,0) GUI:SameLine(winX/1.65-(itemSize/2))
				local button = Controller.buttons[5]
				GUI:Image(button.icon,button.size.x,button.size.y)
				if GUI:IsItemHovered() then
					GUI:BeginTooltip()
					GUI:PushTextWrapPos(300)
					GUI:Text(button.tooltip)
					GUI:PopTextWrapPos()
					GUI:EndTooltip()
					if GUI:IsItemClicked(0) then
						sendCommand(button.cmd)
					end
				end

				GUI:SameLine()
				local winX,winY = GUI:GetWindowSize()
				local itemSize = GUI:CalcItemWidth()
				GUI:Dummy(0,0)
				GUI:SameLine(winX/0.8-(itemSize/2))
				local button = Controller.buttons[4]
				GUI:Image(button.icon,button.size.x,button.size.y)
				if GUI:IsItemHovered() then
					GUI:BeginTooltip()
					GUI:PushTextWrapPos(300)
					GUI:Text(button.tooltip)
					GUI:PopTextWrapPos()
					GUI:EndTooltip()
					if GUI:IsItemClicked(0) then
						sendCommand(button.cmd)
					end
				end

				if Data.songLengthSeconds ~= nil and Data.elapsedTimeSeconds ~= nil then
					GUI:PushStyleColor(GUI.Col_PlotHistogram,0.1,0.6,0.1,1)
					GUI:PushStyleColor(GUI.Col_PlotHistogramHovered,0.1,0.1,0.1,1)
					local max,time = Data.songLengthSeconds,Data.elapsedTimeSeconds
					local progress = (function() if time == 0 then return 0 elseif time <= max then return time / max elseif time > max then return 1 else return 0 end end)()
					GUI:Dummy(1,0) GUI:SameLine(0,0)
					GUI:ProgressBar(progress, 385, 2, "")
					GUI:PopStyleColor(2)
				end
				if Data.currentsong ~= nil then
					local winX,winY = GUI:GetWindowSize()
					local fontSize = GUI:CalcTextSize(Data.currentsong)
					GUI:Dummy(0,0)
					GUI:SameLine(winX/2-(fontSize/2))
					GUI:Text(Data.currentsong)

					local winX,winY = GUI:GetWindowSize()
					local fontSize = GUI:CalcTextSize(Data.currentartist)
					GUI:Dummy(0,0)
					GUI:SameLine(winX/2-(fontSize/2))
					GUI:Text(Data.currentartist)
				end

				if Data.elapsedTime ~= nil and Data.songLength ~= nil then
					local text = Data.elapsedTime.." / "..Data.songLength
					local winX,winY = GUI:GetWindowSize()
					local fontSize = GUI:CalcTextSize(text)
					GUI:Dummy(0,0)
					GUI:SameLine(winX/2-(fontSize/2))
					GUI:TextColored(1,1,1,0.6,text)
				end

				if Data.volume ~= nil then
					local winX,winY = GUI:GetWindowSize()
					local fontSize = GUI:CalcTextSize(Data.volume.."+ -")
					GUI:Dummy(0,0)
					GUI:SameLine(winX/2-(fontSize/2))
					GUI:TextColored(1,1,1,0.6,Data.volume)

					GUI:SameLine()
					local button = Controller.buttons[8]
					GUI:Image(button.icon,button.size.x,button.size.y)
					if GUI:IsItemHovered() then
						GUI:BeginTooltip()
						GUI:PushTextWrapPos(300)
						GUI:Text(button.tooltip)
						GUI:PopTextWrapPos()
						GUI:EndTooltip()
						if GUI:IsItemClicked(0) then
							sendCommand(button.cmd)
						end
					end

					GUI:SameLine()
					local button = Controller.buttons[9]
					GUI:Image(button.icon,button.size.x,button.size.y)
					if GUI:IsItemHovered() then
						GUI:BeginTooltip()
						GUI:PushTextWrapPos(300)
						GUI:Text(button.tooltip)
						GUI:PopTextWrapPos()
						GUI:EndTooltip()
						if GUI:IsItemClicked(0) then
							sendCommand(button.cmd)
						end
					end
				end
			end
		end
		GUI:End()
		GUI:PopStyleColor(c)
    end
end

Controller.buttons = {
	[1] = {
		name = "Play",
		icon = ModulePath .. [[\images\play1.png]],
		cmd = [[Play]],
		tooltip = "play",
		size = { x = 25, y = 25},
		group = 1,
	},
	[2] = {
		name = "Pause",
		icon = ModulePath .. [[\images\pause2.png]],
		cmd = [[Pause]],
		tooltip = "pause",
		size = { x = 25, y = 25},
		group = 1,
	},
	[3] = {
		name = "Previous",
		icon = ModulePath .. [[\images\previous1.png]],
		cmd = [[Previous]],
		tooltip = "previous song",
		size = { x = 25, y = 25},
		group = 1,
	},
	[4] = {
		name = "Next",
		icon = ModulePath .. [[\images\next1.png]],
		cmd = [[Next]],
		tooltip = "next song",
		size = { x = 25, y = 25},
		group = 1,
	},
	[5] = {
		name = "Random",
		icon = ModulePath .. [[\images\refresh.png]],
		cmd = [[rand]],
		tooltip = "random song",
		size = { x = 25, y = 25},
		group = 1,
	},
	[6] = {
		name = "Shuffle",
		icon = ModulePath .. [[\images\shufflesmall.png]],
		cmd = [[Random]],
		tooltip = "shuffle order",
		size = { x = 25, y = 25},
		group = 2,
	},
	[7] = {
		name = "Default",
		icon = ModulePath .. [[\images\circlesmall.png]],
		cmd = [[Default]],
		tooltip = "default order",
		size = { x = 25, y = 25},
		group = 2,
	},
	[8] = {
		name = "Volume Up",
		icon = ModulePath .. [[\images\plus2.png]],
		cmd = [[Up]],
		tooltip = "volume up",
		size = { x = 8, y = 8},
		group = 3,
	},
	[9] = {
		name = "Volume Down",
		icon = ModulePath .. [[\images\minus1.png]],
		cmd = [[Down]],
		tooltip = "volume down",
		size = { x = 8, y = 8},
		group = 3,
	},
}

function Controller.Initialize()
	Controller.main_tabs = GUI_CreateTabs("Main")
	ml_gui.ui_mgr:AddMember({ id = "Controller", name = "Music Controller", onClick = function() Controller.open = not Controller.open end, tooltip = "Control your music from inside FFXIV." }, "FFXIVMINION##MENU_HEADER")
	LoadSettings()
	if Settings.firstTime == true then Controller.firstTimeSetup() end
	d("Loaded Controller.")
end
RegisterEventHandler("Gameloop.Draw", Controller.Draw, "Controller.Draw")
RegisterEventHandler("Gameloop.Update", Controller.Update, "Controller.Update")
RegisterEventHandler("Module.Initalize", Controller.Initialize, "Controller.Initialize")