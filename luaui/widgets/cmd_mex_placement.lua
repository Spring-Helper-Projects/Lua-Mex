
function widget:GetInfo()
	return {
		name      = "Mex Placement Handler",
		desc      = "Places mexes in the correct position DO NOT DISABLE",
		author    = "Google Frog with some from Niobium and Evil4Zerggin.",
		version   = "v1",
		date      = "22 April, 2012", --2 April 2013
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
		handler   = true
	}
end

if Spring.GetModOptions().luamex ~= "enabled" then return false end

VFS.Include("LuaRules/Configs/customcmds.h.lua")
local font = gl.LoadFont(LUAUI_DIRNAME.."Fonts/FreeSansBold.otf", 55, 7, 4)

------------------------------------------------------------
-- Speedups
------------------------------------------------------------
local spGetActiveCommand    = Spring.GetActiveCommand
local spGetMouseState       = Spring.GetMouseState
local spTraceScreenRay      = Spring.TraceScreenRay
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetMyAllyTeamID     = Spring.GetMyAllyTeamID
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spGetUnitHealth       = Spring.GetUnitHealth
local spGetSelectedUnits    = Spring.GetSelectedUnits
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spGetUnitPosition     = Spring.GetUnitPosition 
local spGetTeamUnits        = Spring.GetTeamUnits
local spGetMyTeamID         = Spring.GetMyTeamID
local spTestBuildOrder      = Spring.TestBuildOrder
local spGetUnitsInRectangle = Spring.GetUnitsInRectangle
local spGiveOrder           = Spring.GiveOrder	
local spGetGroundInfo       = Spring.GetGroundInfo
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetMapDrawMode      = Spring.GetMapDrawMode
local spGetGameFrame        = Spring.GetGameFrame
local spGetSpectatingState  = Spring.GetSpectatingState
local spGetAllUnits         = Spring.GetAllUnits
local spGetPositionLosState = Spring.GetPositionLosState

local glLineWidth        = gl.LineWidth
local glColor            = gl.Color
local glRect             = gl.Rect
local glText             = gl.Text
local glGetTextWidth     = gl.GetTextWidth
local glPolygonMode      = gl.PolygonMode
local glDrawGroundCircle = gl.DrawGroundCircle
local glUnitShape        = gl.UnitShape
local glDepthTest        = gl.DepthTest
local glLighting         = gl.Lighting
local glScale            = gl.Scale
local glBillboard        = gl.Billboard
local glAlphaTest        = gl.AlphaTest
local glTexture          = gl.Texture
local glTexRect          = gl.TexRect
local glVertex           = gl.Vertex
local glBeginEnd         = gl.BeginEnd
local glLoadIdentity     = gl.LoadIdentity
local glRotate           = gl.Rotate
local glPopMatrix        = gl.PopMatrix
local glPushMatrix       = gl.PushMatrix
local glTranslate        = gl.Translate
local glCallList         = gl.CallList
local glCreateList       = gl.CreateList

local GL_FRONT_AND_BACK = GL.FRONT_AND_BACK
local GL_FILL           = GL.FILL
local GL_GREATER         = GL.GREATER

local floor = math.floor
local min, max = math.min, math.max
local strFind = string.find
local strFormat = string.format	

local CMD_OPT_SHIFT = CMD.OPT_SHIFT

local sqrt = math.sqrt
local tasort = table.sort
local taremove = table.remove

local myAllyTeam = spGetMyAllyTeamID()

local mapX = Game.mapSizeX
local mapZ = Game.mapSizeZ
local mapXinv = 1/mapX
local mapZinv = 1/mapZ

local METAL_MAP_SQUARE_SIZE = 16
local MEX_RADIUS = Game.extractorRadius
local MAP_SIZE_X = Game.mapSizeX
local MAP_SIZE_X_SCALED = MAP_SIZE_X / METAL_MAP_SQUARE_SIZE
local MAP_SIZE_Z = Game.mapSizeZ
local MAP_SIZE_Z_SCALED = MAP_SIZE_Z / METAL_MAP_SQUARE_SIZE

local allyMexColor = {[1] = {0, 1, 1, 0.7}, [2] = {0, 1, 1, 1}}
local neutralMexColor = {[1] = {1.0, 1.0, 1.0, 0.7}, [2] = {1.0, 1.0, 1.0, 1}}
local enemyMexColor = {[1] = {1, 0, 0, 0.7}, [2] = {1, 0, 0, 1}}

local allyTeams = {}	-- [id] = {team1, team2, ...}

------------------------------------------------------------
-- Config
------------------------------------------------------------

local TEXT_SIZE = 15

local MINIMAP_DRAW_SIZE = math.max(mapX,mapZ) * 0.0145

options_path = 'Settings/Interface/Map/Metal Spots'
options_order = { 'drawicons', 'size', 'specPlayerColours', 'rounding'}
options = {

	drawincome = {
		name = 'Should income be drawn below the mex spot?',
		type = 'bool',
		value = true,
		tooltip = "When disabled, this will prevent income from being drawn below the mex spot.",
		OnChange = function() updateMexDrawList() end
	},	
	drawcustomincomeamount = {
		name = 'Draw a custom mex income amount under each spot instead of the automatically calculated one?',
		type = 'bool',
		value = false,
		tooltip = "Enabled, this will allow you to draw a custom amount underneath each mex spot.",
		OnChange = function() updateMexDrawList() end
	},	
	drawicons = {
		name = 'Show Income as Icon',
		type = 'bool',
		value = false,
		tooltip = "When enabled income is shown pictorially. When disabled income is shown as a number.",
		OnChange = function() updateMexDrawList() end
	},
	size = {
		name = "Income Display Size", 
		type = "number", 
		value = 40, 
		min = 10,
		max = 150,
		step = 5,
		OnChange = function() updateMexDrawList() end
	},
	rounding = {
		name = "Display digits",
		type = "number",
		value = 1,
		min = 1,
		max = 4,
		advanced = true,
		OnChange = function() updateMexDrawList() end
	},
	multiplier = {
		name = "Multiplier used for base mex value",
		type = "number",
		value = 1, -- Most games will use 1 for this value as most games base mex income around a mex giving 2.0. Please not that changing this value only changes the number visually displayed underneath the mex spot. The actual multiplier is determined in the mex unitdef customparam "metal_extractor = <multiplier>,"
		min = 0,
		max = 100,
		OnChange = function() updateMexDrawList() end
	},
	customamount = {
		name = "Custom amount to be drawn under each mex",
		type = "number",
		value = 2.0, -- Most games will use 1 for this value as most games base mex income around a mex giving 2.0. Please not that changing this value only changes the number visually displayed underneath the mex spot. The actual multiplier is determined in the mex unitdef customparam "metal_extractor = <multiplier>,"
		min = 0,
		max = 100,
		OnChange = function() updateMexDrawList() end
	},
	specPlayerColours = {
		name = "Use player colours when spectating",
		type = "bool",
		value = true,
		OnChange = function() updateMexDrawList() end
	}
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Mexes and builders

local mexDefID = {}
for udid, ud in pairs(UnitDefs) do
	if ud.customParams.metal_extractor then
		mexDefID[udid] = tonumber (ud.customParams.metal_extractor)
	end
end

local mexBuilder = {}

local mexBuilderDefs = {}
for udid, ud in ipairs(UnitDefs) do 
	if ud.customParams.area_mex_def then
		mexBuilderDefs[udid] = UnitDefNames[ud.customParams.area_mex_def].id
	end
end

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

WG.mouseoverMexIncome = 0

local spotByID = {}
local spotData = {}

local wasSpectating = spGetSpectatingState()
local metalSpotsNil = true

------------------------------------------------------------
-- Functions
------------------------------------------------------------
local function GetNearestMex (x, z)
	local units = Spring.GetUnitsInRectangle(x-1, z-1, x+1, z+1)
	local myAlly = spGetMyAllyTeamID()
	for i = 1, #units do
		local unitID = units[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		if unitDefID and mexDefID[unitDefID] and spGetUnitAllyTeam(unitID) == myAlly then
			return unitID
		end
	end
end

local function GetClosestMetalSpot(x, z) --is used by single mex placement, not used by areamex
	local bestSpot
	local bestDist = math.huge
	local bestIndex 
	for i = 1, #WG.metalSpots do
		local spot = WG.metalSpots[i]
		local dx, dz = x - spot.x, z - spot.z
		local dist = dx*dx + dz*dz
		if dist < bestDist then
			bestSpot = spot
			bestDist = dist
			bestIndex = i
		end
	end
	return bestSpot, sqrt(bestDist), bestIndex
end

local function Distance(x1,z1,x2,z2)
	local dis = (x1-x2)*(x1-x2)+(z1-z2)*(z1-z2)
	return dis
end


local function IntegrateMetal(x, z, forceUpdate)
	local newCenterX, newCenterZ
	
	newCenterX = (floor( x / METAL_MAP_SQUARE_SIZE) + 0.5) * METAL_MAP_SQUARE_SIZE
	newCenterZ = (floor( z / METAL_MAP_SQUARE_SIZE) + 0.5) * METAL_MAP_SQUARE_SIZE
	
	if (centerX == newCenterX and centerZ == newCenterZ and not forceUpdate) then 
		return 
	end
	
	centerX = newCenterX
	centerZ = newCenterZ
	
	local startX = floor((centerX - MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	local startZ = floor((centerZ - MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	local endX = floor((centerX + MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	local endZ = floor((centerZ + MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	startX, startZ = max(startX, 0), max(startZ, 0)
	endX, endZ = min(endX, MAP_SIZE_X_SCALED - 1), min(endZ, MAP_SIZE_Z_SCALED - 1)
	
	local mult = Spring.GetGameRulesParam("base_extraction")
	local result = 0

	for i = startX, endX do
		for j = startZ, endZ do
			local cx, cz = (i + 0.5) * METAL_MAP_SQUARE_SIZE, (j + 0.5) * METAL_MAP_SQUARE_SIZE
			local dx, dz = cx - centerX, cz - centerZ
			local dist = sqrt(dx * dx + dz * dz)

			if (dist < MEX_RADIUS) then
				local _, metal = spGetGroundInfo(cx, cz)
				result = result + metal
			end
		end
	end

	extraction = result * mult
end

------------------------------------------------------------
-- Command Handling
------------------------------------------------------------

function widget:CommandNotify(cmdID, params, options)	
	if (cmdID == CMD_AREA_MEX and WG.metalSpots) then

		local cx, cy, cz, cr = params[1], params[2], params[3], math.max((params[4] or 60),60)
		
		local xmin = cx-cr
		local xmax = cx+cr
		local zmin = cz-cr
		local zmax = cz+cr
		
		local commands = {}
		local orderedCommands = {}
		local dis = {}
		
		local ux = 0
		local uz = 0
		local us = 0
		
		local aveX = 0
		local aveZ = 0
		
		local units = spGetSelectedUnits()

		for i = 1, #units do 
			local unitID = units[i]
			if mexBuilder[unitID] then
				local x,_,z = spGetUnitPosition(unitID)
				ux = ux+x
				uz = uz+z
				us = us+1
			end
		end
	
		if (us == 0) then
			return
		else
			aveX = ux/us
			aveZ = uz/us
		end
	
		for i = 1, #WG.metalSpots do		
			local mex = WG.metalSpots[i]
			--if (mex.x > xmin) and (mex.x < xmax) and (mex.z > zmin) and (mex.z < zmax) then -- square area, should be faster
			if (Distance(cx,cz,mex.x,mex.z) < cr*cr) then -- circle area, slower
				commands[#commands+1] = {x = mex.x, z = mex.z, d = Distance(aveX,aveZ,mex.x,mex.z)}
			end
		end

		local noCommands = #commands
		while noCommands > 0 do
	  
			tasort(commands, function(a,b) return a.d < b.d end)
			orderedCommands[#orderedCommands+1] = commands[1]
			aveX = commands[1].x
			aveZ = commands[1].z
			taremove(commands, 1)
			for k, com in pairs(commands) do		
				com.d = Distance(aveX,aveZ,com.x,com.z)
			end
			noCommands = noCommands-1
		end
	
		local shift = options.shift

		local buildersByType = {}
		for i = 1, #units do
			local unitID = units[i]
			local mexType = mexBuilder[unitID]
			if mexType then
				buildersByType[mexType] = buildersByType[mexType] or {}
				local array = buildersByType[mexType]
				array[#array + 1] = unitID
			end
		end
		for mexType, unitArrayToReceive in pairs (buildersByType) do
			local commandArrayToIssue={}

			--prepare command list
			if not shift then
				commandArrayToIssue[1] = {CMD.STOP, {} , {}}
			end
			for i, command in ipairs(orderedCommands) do
				local x = command.x
				local z = command.z
				local y = Spring.GetGroundHeight(x, z)

				local unit = GetNearestMex (x, z)
				if unit then
					if Spring.GetUnitDefID(unit) ~= mexType then
						commandArrayToIssue[#commandArrayToIssue+1] = {CMD.RECLAIM, {unit}, {"shift"}}
						commandArrayToIssue[#commandArrayToIssue+1] = {CMD.INSERT, {-1, -mexType, CMD.OPT_INTERNAL, x,y,z,0}, {"alt"}}
					elseif select (5, Spring.GetUnitHealth (unit)) < 1 then
						commandArrayToIssue[#commandArrayToIssue+1] = {CMD.REPAIR, {unit}, {"shift"}}
					end
				else
					commandArrayToIssue[#commandArrayToIssue+1] = {-mexType, {x,y,z,0} , {"shift"}}
				end
			end

			if (#commandArrayToIssue > 0) then
				Spring.GiveOrderArrayToUnitArray(unitArrayToReceive,commandArrayToIssue)
			end
		end
		return true
	end

	if mexDefID[-cmdID] and WG.metalSpots then
		local bx, bz = params[1], params[3]
		local closestSpot = GetClosestMetalSpot(bx, bz)
		if closestSpot then
			local commandHeight = math.max(0, Spring.GetGroundHeight(closestSpot.x, closestSpot.z))
			local foundUnit = GetNearestMex (closestSpot.x, closestSpot.z)
			if foundUnit then
				if Spring.GetUnitDefID(foundUnit) ~= mexType then
					spGiveOrder(CMD.RECLAIM, {foundUnit}, CMD.OPT_INTERNAL)
					spGiveOrder(CMD.INSERT, {-1, cmdID, options.coded, closestSpot.x, commandHeight, closestSpot.z, params[4]} , {"alt"})
				elseif select (5, Spring.GetUnitHealth (foundUnit)) < 1 then
					spGiveOrder(CMD.REPAIR, {foundUnit}, options.coded)
				end
			else
				spGiveOrder(cmdID, {closestSpot.x, commandHeight, closestSpot.z, params[4]}, options.coded)
			end
		end
		return true
	end
end

function widget:UnitCreated(unitID, unitDefID)
	mexBuilder[unitID] = mexBuilderDefs[unitDefID]
end

function widget:UnitFinished(unitID, unitDefID, teamID)
	if mexDefID[unitDefID] and WG.metalSpots then
		if spGetSpectatingState() then
			local x,_,z = Spring.GetUnitPosition(unitID)
			local spotID = WG.metalSpotsByPos[x] and WG.metalSpotsByPos[x][z]
			if spotID then
				spotByID[unitID] = spotID
				spotData[spotID] = {unitID = unitID, team = Spring.GetUnitTeam(unitID), allyTeam = spGetUnitAllyTeam(unitID)}
				updateMexDrawList()
			end
		elseif spGetUnitAllyTeam(unitID) == myAllyTeam then
			local x,_,z = Spring.GetUnitPosition(unitID)
			local spotID = WG.metalSpotsByPos[x] and WG.metalSpotsByPos[x][z]
			if spotID then
				spotByID[unitID] = spotID
				spotData[spotID] = {unitID = unitID, team = Spring.GetUnitTeam(unitID)}
				updateMexDrawList()
			end
		end
	end
end

function widget:UnitDestroyed(unitID, unitDefID)
	if mexDefID[unitDefID] and spotByID[unitID] then
		spotData[spotByID[unitID]] = nil
		spotByID[unitID] = nil
		updateMexDrawList()
	end
	mexBuilder[unitID] = nil
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	mexBuilder[unitID] = mexBuilderDefs[unitDefID]
	if mexDefID[unitDefID] then
		local done = select(5, spGetUnitHealth(unitID))
		if done == 1 then
			widget:UnitFinished(unitID, unitDefID,unitDefID)
		end
	end
end

function widget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	widget:UnitDestroyed(unitID, unitDefID, oldTeamID)
end

local function Initialize() 

	local units = spGetAllUnits()
	for i, unitID in ipairs(units) do 
		local unitDefID = spGetUnitDefID(unitID)
		widget:UnitCreated(unitID, unitDefID)
		if mexDefID[unitDefID] then
			local done = select(5, spGetUnitHealth(unitID))
			if done == 1 then
				widget:UnitFinished(unitID, unitDefID,team)
			end
		end
	end
	if WG.metalSpots then
		--Spring.Echo("Mex Placement Initialised with " .. #WG.metalSpots .. " spots.")
		updateMexDrawList()
	else
		--Spring.Echo("Mex Placement Initialised with metal map mode.")
	end
end

local mexSpotToDraw = false
local drawMexSpots = false

function widget:Update()
	if WG.metalSpots and (not wasSpectating) and spGetSpectatingState() then
		spotByID = {}
		spotData = {}
		wasSpectating = true
		local units = spGetAllUnits()
		for i, unitID in ipairs(units) do 
			local unitDefID = spGetUnitDefID(unitID)
		if mexDefID[unitDefID] then
			local done = select(5, spGetUnitHealth(unitID))
				if done == 1 then
					widget:UnitFinished(unitID, unitDefID,team)
				end
			end
		end
	end
	if metalSpotsNil and WG.metalSpots ~= nil then
		Initialize()
		metalSpotsNil = false
	end
	
	WG.mouseoverMexIncome = false
	
	if mexSpotToDraw and WG.metalSpots then
		WG.mouseoverMexIncome = mexSpotToDraw.metal
		WG.mouseoverMex = mexSpotToDraw
	else
		local _, cmd_id = spGetActiveCommand()
		if not cmd_id or not mexDefID[-cmd_id] then
			return
		end
		local mx, my = spGetMouseState()
		local _, coords = spTraceScreenRay(mx, my, true, true)
		if (not coords) then 
			return 
		end
		IntegrateMetal(coords[1], coords[3])
		WG.mouseoverMexIncome = extraction * mexDefID[-cmd_id]
	end
end

------------------------------------------------------------
-- Drawing
------------------------------------------------------------

local centerX 
local centerZ
local extraction = 0

local mainMexDrawList = 0
local miniMexDrawList = 0

local function getSpotColor(x,y,z,id, specatate, t)
	if specatate then
		if spotData[id] then
			if options.specPlayerColours.value then
				local r, g, b = Spring.GetTeamColor(spotData[id].team)
				local alpha = t == 1 and 0.7 or 1.0 --Judging by colours set up top
				return {r, g, b, alpha}
			else
				local r, g, b = Spring.GetTeamColor(Spring.GetTeamList(spotData[id].allyTeam)[1])
				local alpha = t == 1 and 0.7 or 1.0 --Judging by colours set up top
				return {r, g, b, alpha}
			end
		else
			return neutralMexColor[t]
		end
	else
		if spotData[id] then
			local r, g, b = Spring.GetTeamColor(spotData[id].team)
			local alpha = t == 1 and 0.7 or 1.0 --Judging by colours set up top
			return {r, g, b, alpha}
		else
			return neutralMexColor[t]
		end
	end
end

function calcMainMexDrawList()
	local specatate = spGetSpectatingState()

	if WG.metalSpots then
		for i = 1, #WG.metalSpots do
			local spot = WG.metalSpots[i]
			local x,z = spot.x, spot.z
			local y = spGetGroundHeight(x,z)
			if y < 0 then y = 0 end

			local mexColor = getSpotColor(x,y+45,z,i,specatate,1)
			local metal = spot.metal
		

			glPushMatrix()	
			
			gl.DepthTest(true)

			glColor(0,0,0,0.7)
			-- glDepthTest(false)
			glLineWidth(spot.metal*2.4)
			glDrawGroundCircle(x, 1, z, 40, 32)
			glColor(mexColor)
			glLineWidth(spot.metal*1.5)
			glDrawGroundCircle(x, 1, z, 40, 32)	
			
			glPopMatrix()	
			
			glPushMatrix()
			
			glDepthTest(false)
			if options.drawicons.value then
				local size = 1
				if metal > 10 then
					if metal > 100 then
						metal = metal*0.01
						size = 5
					else
						metal = metal*0.1
						size = 2.5
					end
				end
				
				size = options.size.value
				
				glRotate(90,1,0,0)	
				glTranslate(0,0,-y-10)
				glColor(1,1,1)
				glTexture("LuaUI/Images/ibeam.png")
				local width = metal*size
				glTexRect(x-width/2, z+40, x+width/2, z+40+size,0,0,metal,1)
				glTexture(false)
			else
				if options.drawincome.value == true then
					-- Draws the metal spot's base income "south" of the metal spot
					glRotate(270,1,0,0)
					glColor(1,1,1)
					glTranslate(x,-z-40-options.size.value, y)
					
					--glText("+" .. ("%."..options.rounding.value.."f"):format(metal), 0.0, 0.0, options.size.value , "cno")
					font:Begin()
					font:SetTextColor(1,1,1)
					font:SetOutlineColor(0,0,0)
					if options.drawcustomincomeamount.value ~= true then
							font:Print("+" .. ("%."..options.rounding.value.."f"):format(metal*options.multiplier.value), 0, 0, options.size.value, "con")
					else
						font:Print("+" .. ("%."..options.rounding.value.."f"):format(options.customamount.value), 0, 0, options.size.value, "con")
					end
					font:End()
				end
			end	
	
			glPopMatrix()	
		end

		glLineWidth(1.0)
		glColor(1,1,1,1)
	end
end

function updateMexDrawList()
	if (mainMexDrawList) then 
		gl.DeleteList(mainMexDrawList); 
		mainMexDrawList = nil 
	end --delete previous list if exist (ref:gui_chicken.lua by quantum)
	mainMexDrawList = glCreateList(calcMainMexDrawList)
	--miniMexDrawList = glCreateList(calcMiniMexDrawList)
end

function widget:Shutdown()
	gl.DeleteList(mainMexDrawList)
end

local function DoLine(x1, y1, z1, x2, y2, z2)
    gl.Vertex(x1, y1, z1)
    gl.Vertex(x2, y2, z2)
end

function widget:DrawWorldPreUnit()

	-- Check command is to build a mex
	local _, cmdID = spGetActiveCommand()
	local peruse = spGetGameFrame() < 1 or spGetMapDrawMode() == 'metal'

	drawMexSpots = WG.metalSpots and ((cmdID and mexDefID[-cmdID]) or CMD_AREA_MEX == cmdID or peruse)

	if drawMexSpots then
			
			gl.DepthTest(true)
			gl.DepthMask(true)
		glCallList(mainMexDrawList)
			
			gl.DepthTest(false)
			gl.DepthMask(false)
	end
end

function widget:DrawWorld()
	
	-- Check command is to build a mex
	local _, cmdID = spGetActiveCommand()
	local peruse = spGetGameFrame() < 1 or spGetMapDrawMode() == 'metal'

	local mx, my = spGetMouseState()
	local _, pos = spTraceScreenRay(mx, my, true)
	
	mexSpotToDraw = false
	
	if WG.metalSpots and pos and ((cmdID and mexDefID[-cmdID]) or peruse or CMD_AREA_MEX == cmdID) then
	
		-- Find build position and check if it is valid (Would get 100% metal)
		local bx, by, bz
		if cmdID and cmdID < 0 then
			bx, by, bz = Spring.Pos2BuildPos(-cmdID, pos[1], pos[2], pos[3])
		else
			bx, by, bz = pos[1], pos[2], pos[3]
		end
		local bface = Spring.GetBuildFacing()
		local closestSpot, distance, index = GetClosestMetalSpot(bx, bz)
		
		if closestSpot and ((cmdID and mexDefID[-cmdID]) or not ((CMD_AREA_MEX == cmdID or peruse) and distance > 60)) and (not spotData[index]) then 
		
			mexSpotToDraw = closestSpot
			
			local height = spGetGroundHeight(closestSpot.x,closestSpot.z)
			height = height > 0 and height or 0
			
			gl.DepthTest(false)
			
			gl.LineWidth(1.49)
			gl.Color(1, 1, 0, 0.5)
			gl.BeginEnd(GL.LINE_STRIP, DoLine, bx, by, bz, closestSpot.x, height, closestSpot.z)
			gl.LineWidth(1.0)
			
			gl.DepthTest(true)
			gl.DepthMask(true)
			
			gl.Color(1, 1, 1, 0.5)
			gl.PushMatrix()
			gl.Translate(closestSpot.x, height, closestSpot.z)
			gl.Rotate(90 * bface, 0, 1, 0)
			if (cmdID and cmdID < 0) then
				gl.UnitShape(-cmdID, Spring.GetMyTeamID(), false, true, false)
			end
			gl.PopMatrix()
			
			gl.DepthTest(false)
			gl.DepthMask(false)
		end
	end
	
	gl.Color(1, 1, 1, 1)
end

function widget:DrawInMiniMap()

	if drawMexSpots then
		local specatate = spGetSpectatingState()
		
		glLoadIdentity()
		glTranslate(0,1,0)
		glScale(mapXinv , -mapZinv, 1)
		glRotate(270,1,0,0)

		for i = 1, #WG.metalSpots do
			local spot = WG.metalSpots[i]
			local x,z = spot.x, spot.z
			local y = spGetGroundHeight(x,z)

			local mexColor = getSpotColor(x,y,z,i,specatate,2)
			
			glLighting(false)
			glColor(0,0,0,1)
			glLineWidth(((spot.metal > 0 and spot.metal) or 0.1)*2.0)
			glDrawGroundCircle(x, 0, z, MINIMAP_DRAW_SIZE, 32)
			glLineWidth((spot.metal > 0 and spot.metal) or 0.1)
			glColor(mexColor)
			
			glDrawGroundCircle(x, 0, z, MINIMAP_DRAW_SIZE, 32)
		end

		glLineWidth(1.0)
		glColor(1,1,1,1)
		
	end

end
