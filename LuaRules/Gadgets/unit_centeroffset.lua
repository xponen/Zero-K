--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "Center Offset",
      desc      = "Offsets aimpoints",
      author    = "KingRaptor (L.J. Lim) and GoogleFrog",
      date      = "12.7.2012",
      license   = "Public Domain",
      layer     = 0,
      enabled   = true
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--SYNCED
if gadgetHandler:IsSyncedCode() then


local spGetUnitBuildFacing = Spring.GetUnitBuildFacing

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if not Spring.SetUnitMidAndAimPos then
	return
end

local armwarDefID = UnitDefNames["armwar"].id

local offsets = {}
local modelRadii = {}

local function UnpackInt3(str)
	local index = 0
	local ret = {}
	for i=1,3 do
		ret[i] = str:match("[-]*%d+", index)
		index = (select(2, str:find(ret[i], index)) or 0) + 1
	end
	return ret
end

for i=1,#UnitDefs do
	local midPosOffset = UnitDefs[i].customParams.midposoffset
	local aimPosOffset = UnitDefs[i].customParams.aimposoffset
	local modelRadius = UnitDefs[i].customParams.modelradius
	if midPosOffset or aimPosOffset then
		local mid = (midPosOffset and UnpackInt3(midPosOffset)) or {0,0,0}
		local aim = (aimPosOffset and UnpackInt3(aimPosOffset)) or mid
		offsets[i] = {
			mid = mid,
			aim = aim,
		}
	end
	if modelRadius then
		modelRadii[i] = tonumber(modelRadius)
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	---[[
	if offsets[unitDefID] then

		mid = offsets[unitDefID].mid
		aim = offsets[unitDefID].aim
		
		local bx, _, bz, ux, uy, uz = Spring.GetUnitPosition(unitID, true)
		local facing = spGetUnitBuildFacing(unitID)
		local mx, my, mz = ux + mid[1], uy + mid[2], uz + mid[3]
		local ax, ay, az = ux + aim[1], uy + aim[2], uz + aim[3]
		Spring.SetUnitMidAndAimPos(unitID, mx, my, mz, ax, ay, az)
	end
	if modelRadii[unitDefID] then
		Spring.SetUnitRadiusAndHeight(unitID,modelRadii[unitDefID])
	end
	--]]
	--[[
	local _,_,_, ux, uy, uz = Spring.GetUnitPosition(unitID, true)
	Spring.SetUnitMidAndAimPos(unitID, ux, uy, uz , ux, uy, uz)
	Spring.SetUnitRadiusAndHeight(unitID,22)
	--]]
end

--[[
function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end
--]]

------------------------------------------------------

end