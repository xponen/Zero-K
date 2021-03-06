local versionNumber = "1.21"

function widget:GetInfo()
	return {
	name	= "Startup Info and Selector",
	desc	= "[v" .. string.format("%s", versionNumber ) .. "] Shows important information and options on startup.",
	author	= "SirMaverick",
	date	= "2009,2010",
	license	= "GNU GPL, v2 or later",
	layer	= 0,
	enabled	= true
	}
end

--[[
-- Features:
_ Show a windows at game start with pictures to choose commander type.

-- To do:
_ Make a small (2-3 frames) animation when cursor hover comms' posters (like the unit highlight widget)and an highlight of the buttons hovered on. Can chili do that yet ?
_ Make each player broadcast their choice to their team in a way it can be used by chili_chatbubbles, I had issues with that, left it for later. Use Spring.SendCommands( ?

---- CHANGELOG -----
-- versus666, 		v1.2	(30oct2010)	:	Placed CreateWindow() @ _DrawScreen() to avoid showing commander selection after game start when DEBUG is FALSE and doing /luaui reload.
--											Thanks to [LCC]Quantum[0K] for spotting the little mistake which was blocking me for 1 complete day.
-- versus666,		v1.1	(28oct2010)	:	Corrected typos, cosmetic changes and added comments & infos about comm choices.
-- SirMaverick,		v1.0				:	Creation.
--]]
----------------------------------------------
local debug	= false --generates debug message
local Echo	= Spring.Echo
local spGetGameRulesParam = Spring.GetGameRulesParam

local coop = (Spring.GetModOptions().coop == 1) or false
local forcejunior = (Spring.GetModOptions().forcejunior == 1) or false
local dotaMode = Spring.GetModOptions().zkmode == "dota"
local ctfMode = Spring.GetModOptions().zkmode == "ctf"

local Chili
local Window
local screen0
local Image
local Button

local vsx, vsy
local modoptions = Spring.GetModOptions() --used in LuaUI\Configs\startup_info_selector.lua for planetwars
local selectorShown = false
local mainWindow
local actionShow = "showstartupinfoselector"
local optionData = include("Configs/startup_info_selector.lua")

local noComm = false
local gameframe = Spring.GetGameFrame()
---------------------------------------------
local function PlaySound(filename, ...)
	local path = filename..".WAV"
	if (VFS.FileExists(path)) then
		Spring.PlaySoundFile(path, ...)
	else
	--Spring.Echo(filename)
		Spring.Echo("<Startup Info Selector>: Error - file "..path.." doesn't exist.")
	end
end

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end

--local gameDate = os.date(t)
--if (gameDate.month == 4) and (gameDate.day == 1) then optionData.communism.sound = "LuaUI/Sounds/communism/tetris.wav" end

-- set poster size (3/4 ratio)
local function posterSize(num)
	if num < 2 then
		local a,b = 450, 600
	-- for those who play with 800x600; but consider card upgrade!
			if b > 0.8*vsy then
				local scale = 0.8*vsy/b
				a = scale * a
				b = scale * b
			end
			return a, b, 60
	else
	-- scale to 80% of screen width
		local spacex = vsx * 0.8 / num
		if spacex < 300 then
			return spacex, spacex*4/3, 60
		else
		return 300, 400, 60
		end
	end
end

-- needs to be a global so chili can reach out and call it?
function printDebug( value )
	if ( debug ) then Echo( value )
	end
end

function Close(commPicked)
	printDebug("<gui_startup_info_selector DEBUG >: closing")
	if not commPicked then
		Spring.Echo("Requesting baseline comm")
		Spring.SendLuaRulesMsg("faction:commbasic")
	end
	--Spring_SendCommands("say: a:I chose " .. option.button})
	if mainWindow then mainWindow:Dispose() end
end

local function CreateWindow()
	if mainWindow then
		mainWindow:Dispose()
	end
	
	printDebug("<gui_startup_info_selector DEBUG >: create window.")
	-- count options
	local active = 0
	for index,option in pairs(optionData) do
		if option:enabled() then
			active = active + 1
		end
	end

	local posterx, postery, buttonspace = posterSize(active)

	-- create window if necessary
	if active > 0 then
		mainWindow = Window:New{
			resizable = false,
			draggable = false,
			clientWidth  = posterx*active,
			clientHeight = postery + buttonspace +12 ,--there is a title (caption below), height is not just poster+buttons
			x = (vsx - posterx*active)/2,
			y = ((vsy - postery - buttonspace)/2),
			parent = screen0,
			caption = "STARTUP SELECTOR",
			}
		
		-- add posters
		local i = 0
		for index,option in ipairs(optionData) do
			if option:enabled() then
				local image = Image:New{
					parent = mainWindow,
					file = option.poster,--lookup Configs/startup_info_selector.lua to get optiondata
					file2 = option.poster2,
					tooltip = option.tooltip,
					caption = option.selector,
					width = posterx,
					height = postery,
					x = (i*posterx),
					padding = {1,1,1,1},
					OnClick = {option.button},
					y = 9 
					}
				local buttonWidth = posterx*2/3
					if (option.button ~= nil) then 
						local button = Button:New {
							parent = mainWindow,
							x = i*posterx + (posterx - buttonWidth)/2, --placement of comms names' buttons @ the middle of each poster
							y = postery+12,
							caption = option.selector,
							tooltip = option.tooltip, --added comm name under cursor on tooltip too, like for posters
							width = buttonWidth,
							height = 30,
							padding={1,1,1,1},
							OnClick = {option.button},-- used onclick in case people change their mind, mouseup register the option you were when pressed on, even if you moved somewhere else while still hold mouse button. onclick register it only if you're still on it (even if you moved to another part of the comm button).
							}
					end 
				i = i + 1
			end
		end
		local cbWidth = posterx*active*0.75-- calculate width of close button depending of number or posters
		local closeButton = Button:New{
			parent = mainWindow,
			caption = "CLOSE  (defaults to baseline commander)",
			tooltip = "CLOSE\nNo commander selection made, will use a basic Strike Commander",
			--caption = "CLOSE  (make no selection)",
			--tooltip = "CLOSE\nNo commander selection made\nTo choose your commander later, open the Esc menu and go to Game Actions -> Select Comm",
			width = cbWidth,
			height = 30,
			x = (posterx*active - cbWidth)/2,
			y = postery + (buttonspace)/2+14,
			OnClick = {function() Close(false) end}
		}
	else
		Close(false)
	end
end

function widget:Initialize()
	if not (WG.Chili) then
		widgetHandler:RemoveWidget()
	end
	 if (Spring.GetSpectatingState() or Spring.IsReplay() or forcejunior) and (not Spring.IsCheatingEnabled()) then
		Spring.Echo("<Startup Info and Selector> Spectator mode, Junior forced, or replay. Widget removed.")
		widgetHandler:RemoveWidget()
		return
	end
	-- chili setup
	Chili = WG.Chili
	Window = Chili.Window
	screen0 = Chili.Screen0
	Image = Chili.Image
	Button = Chili.Button
	
	-- FIXME: because this code runs before gadget:GameLoad(), the selector window pops up
	-- even if comm is already selected
	-- nothing serious, just annoying
	local playerID = Spring.GetMyPlayerID()
	local teamID = Spring.GetMyTeamID()
	if (coop and playerID and Spring.GetGameRulesParam("commSpawnedPlayer"..playerID) == 1)
	or (not coop and Spring.GetTeamRulesParam(teamID, "commSpawned") == 1)	then 
		noComm = true	-- will prevent window from auto-appearing; can still be brought up from the button
	end
	PlaySound("LuaUI/Sounds/Voices/initialized_core_1", 1, 'ui')


	vsx, vsy = widgetHandler:GetViewSizes()

	widgetHandler:AddAction(actionShow, CreateWindow, nil, "t")
	if (not noComm) or dotaMode then
		buttonWindow = Window:New{
			resizable = false,
			draggable = false,
			width = 64,
			height = 64,
			right = 0,
			y = 160,
			tweakDraggable = true,
			color = {0, 0, 0, 0},
			padding = {0, 0, 0, 0},
			itemMargin = {0, 0, 0, 0}
		}
		if Spring.GetGameSeconds() <= 0 then
			screen0:AddChild(buttonWindow)
		end
		
		button = Button:New{
			parent = buttonWindow,
			caption = '',
			tooltip = "Open comm selection screen",
			width = "100%",
			height = "100%",
			x = 0,
			y = 0,
			OnClick = {function() Spring.SendCommands({"luaui "..actionShow}) end}	
		}
		
		buttonImage = Image:New{
			parent = button,
			width="100%";
			height="100%";
			x=0;
			y=0;
			file = "LuaUI/Images/startup_info_selector/selecticon.png",
			keepAspect = false,
		}	
		CreateWindow()
	end
end

-- hide window if game was loaded
local timer = 0
function widget:Update(dt)
	if gameframe < 1 then
		timer = timer + dt
		if timer >= 0.1 then
			if (spGetGameRulesParam("loadedGame") == 1) and mainWindow then
				mainWindow:Dispose()
			end
		end
	end
end

function widget:Shutdown()
  --if mainWindow then
	--mainWindow:Dispose()
  --end
  widgetHandler:RemoveAction(actionShow)
end

function widget:Gameframe(n)
	gameframe = n
end

function widget:GameStart()
	if (not dotaMode) and (not ctfMode) then
		screen0:RemoveChild(buttonWindow)
	end
end

-----
-----