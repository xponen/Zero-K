local base, turret, spindle, fakespindle = piece('base', 'turret', 'spindle', 'fakespindle')

local guns = {} 
for i=1,6 do
	guns[i] = {
		center = piece('center'..i),
		sleeve = piece('sleeve'..i),
		barrel = piece('barrel'..i),
		flare = piece('flare'..i),
		y = 0,
		z = 0,
	}
end

local tau = math.pi*2
local pi = math.pi
local hpi = math.pi*0.5

local headingSpeed = math.rad(4)
local pitchSpeed = math.rad(140)

local spindleOffset = math.rad(60)
local spindlePitch = 0

guns[5].y = 11
guns[5].z = 7

local dis = math.sqrt(guns[5].y^2 + guns[5].z)
local ratio = math.tan(math.rad(60))*dis/dis

guns[6].y = guns[5].y + ratio*guns[5].z
guns[6].z = guns[5].z - ratio*guns[5].y
local dis6 = math.sqrt(guns[6].y^2 + guns[6].z^2)
guns[6].y = guns[6].y*dis/dis6
guns[6].z = guns[6].z*dis/dis6

guns[4].y = guns[5].y - ratio*guns[5].z
guns[4].z = guns[5].z + ratio*guns[5].y
local dis4 = math.sqrt(guns[4].y^2 + guns[4].z^2)
guns[4].y = guns[4].y*dis/dis4
guns[4].z = guns[4].z*dis/dis4

guns[1].y = -guns[4].y
guns[1].z = -guns[4].z

guns[2].y = -guns[5].y
guns[2].z = -guns[5].z

guns[3].y = -guns[6].y
guns[3].z = -guns[6].z

for i=1,6 do
	guns[i].ys = math.abs(guns[i].y)
	guns[i].zs = math.abs(guns[i].z)
end

local smokePiece = {spindle, turret}

include "constants.lua"

-- Signal definitions
local SIG_AIM = 2

local gunNum = 1
local weaponNum = 1
local randomize = false
local reloading = false


function script.Create()
	StartThread(SmokeUnit, smokePiece)
	Turn(spindle, x_axis, spindleOffset + spindlePitch)
	for i=1,6 do
		Turn(guns[i].flare, x_axis, (math.rad(-60)* i+1))
	end
end

function script.Activate()
	randomize = true
end

function script.Deactivate()
	randomize = false
end

function script.AimWeapon(num, heading, pitch)
	if weaponNum ~= num then 
		return false 
	end
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	
	local _,curHead, _ = Spring.UnitScript.GetPieceRotation(turret)
	local headDiff = heading-curHead
	if math.abs(headDiff) > pi then
		headDiff = headDiff - math.abs(headDiff)/headDiff*2*pi
	end
	--Spring.Echo(headDiff*180/math.pi)
	
	if math.abs(headDiff) > hpi then
		heading = (heading+pi)%tau
		pitch = -pitch+pi
	end
	spindlePitch = -pitch
	
	Turn( turret , y_axis, heading,  headingSpeed)
	Turn( spindle , x_axis, spindlePitch+spindleOffset, pitchSpeed )
	WaitForTurn(turret, y_axis)
	WaitForTurn(spindle, x_axis)
	while reloading do 
		Sleep(10) 
	end
	return true
end

function script.AimFromWeapon(num)
	return spindle
end

function script.QueryWeapon(num)
	return guns[gunNum].flare
end

function gunFire(num)
	Move( guns[num].barrel , z_axis, guns[num].z*1.2 , 8*guns[num].zs )
	Move( guns[num].barrel , y_axis, guns[num].y*1.2 , 8*guns[num].ys )
	WaitForMove(guns[num].barrel, y_axis)
	Move( guns[num].barrel , z_axis, 0 , 0.2*guns[num].zs )
	Move( guns[num].barrel , y_axis, 0 , 0.2*guns[num].ys )
end


function script.Shot(num)
	--EmitSfx(base, 1024) BASE IS NOT CENTRAL
	EmitSfx(guns[gunNum].flare, 1025)
	EmitSfx(guns[gunNum].flare, 1026)
	StartThread(gunFire, gunNum)
end

function script.FireWeapon(num)
	reloading = true
	gunNum = gunNum + 1
	if gunNum > 6 then gunNum = 1 end
	Sleep(120)
	spindleOffset = math.rad(60)*(gunNum)
	reloading = false
	if randomize then
		weaponNum = math.random(1,6)
	else
		weaponNum = weaponNum + 1
		if weaponNum > 6 then weaponNum = 1 end
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(base, sfxNone)
		Explode(spindle, sfxNone)
		Explode(turret, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(base, sfxNone)
		Explode(spindle, sfxNone)
		Explode(turret, sfxNone)
		return 1
	elseif severity <= .99  then
		Explode(base, sfxShatter)
		Explode(spindle, sfxShatter)
		Explode(turret, sfxShatter)
		return 2
	else
		Explode(base, sfxShatter)
		Explode(spindle, sfxShatter)
		Explode(turret, sfxShatter)
		return 2
	end
end
