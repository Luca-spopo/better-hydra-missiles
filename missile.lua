--[[
Luca aka
specahawk aka
spopo aka
Anirudh Katoch aka

(All rights reserved)
MIT License - Do whatever you want.
]]

----User settings---

local SHOOT_COOLDOWN = 1000 --Cooldown between homing shots
local LOCKON_TIME = 2000 --Time required to lock on to a target
local LOCK_RANGE = 330 --Maximum distance between you and the target
local LOCK_ANGLE = 1.0472 --(in radians) We cannot lock on targets unless they are within this angle of the front of the hydra
local VALID_TARGET_FUNCTION = nil --Used to decide whether a vehicle should appear as a lock-on option
--[[
	to implement team tagging, or to disallow certain vehicles from being targetted, define the VALID_TARGET_FUNCTION
	VALID_TARGET_FUNCTION should take as parameter a vehicle, and return a boolean (true means it can be targetted)
	Here is an example of a function that will only let us target HYDRAS of OTHER TEAMS that are MORE THAN 50m AWAY and are DIRECTLY VISIBLE
	local VALID_TARGET_FUNCTION = function(vehicle)
		local targetTeam = vehicle.controller and vehicle.controller.team
		local ourTeam = localPlayer.team
		if targetTeam and ourTeam and targetTeam == ourTeam then
			return false --The target vehicle has someone driving, and both of you are on the same team
		end
		if vehicle.model ~= 520 then
			return false --Target is not a hydra, so it's not allowed
		end
		if (vehicle.position-localPlayer.position).length < 50 then
			return false --Closer than 50 metres
		end
		if not isLineOfSightClear(localPlayer.position, vehicle.position, true, false) then
			return false --Not directly visible
			--(Remember to account for your own vehicle and the target blocking the line)
		end
		return true --Target satisfied all criteria
	end
]]

---Don't touch stuff below this line---

local sx_, sy_ = guiGetScreenSize()
local validTarget = VALID_TARGET_FUNCTION or function() return true end
LOCK_ANGLE = math.cos(LOCK_ANGLE)

local inHydra = false
local firestate = nil
local visibleVehicles = {}
local lockedVehicles = {}

local target
local function switchTarget()
	if not inHydra then
		return
	end
	if target and not lockedVehicles[target] then
		target = nil
	end
	target = (next(lockedVehicles, target))
	if target == nil then --i.e. was last item
		target = (next(lockedVehicles, target))
	end
end
local function getTarget()
	if not inHydra then
		return
	end
	if not target or not lockedVehicles[target] then
		switchTarget()
	end
	return target
end

local lastShot = SHOOT_COOLDOWN*-2
local function shootMissile()
	if not inHydra then
		return
	end
	local target = getTarget()
	if not target or getTickCount() < lastShot + SHOOT_COOLDOWN then
		return
	end
	lastShot = getTickCount()
	local hydra = localPlayer.vehicle
	createProjectile( hydra, 20, hydra.position, 1, target)
end



local function update( )
	local curtime = getTickCount()
	if not inHydra or not localPlayer.vehicle then
		removeEventHandler("onClientRender", root, update)
		return
	end
	local target = getTarget()
	for _, vehicle in ipairs( getElementsByType("vehicle" ) )do
		local visibleNow = false
		local locked = lockedVehicles[vehicle]
		if not isVehicleBlown(vehicle) and validTarget(vehicle) then
			local x,y,z = getElementPosition( vehicle )
			local cx,cy,cz = getElementPosition( localPlayer )
			local displacement = vehicle.position - localPlayer.position
			local dist = displacement.length
			local cosAngle = localPlayer.vehicle.matrix.forward:dot(displacement)/dist
			if dist < LOCK_RANGE and cosAngle>LOCK_ANGLE then
				if  vehicle ~= getPedOccupiedVehicle( localPlayer ) then
					local aX, aY, aZ = getScreenFromWorldPosition( x, y, z )
					if( aX and aY and aZ )then
						visibleNow = true
						local pclr1,pclr2,pclr3
						local ctrlr = getVehicleController( vehicle )
						if ctrlr then
							pclr1,pclr2,pclr3 = getPlayerNametagColor( ctrlr )
						else
							pclr1,pclr2,pclr3 = 255,255,255
						end
						if locked then
							tween = 0
						else
							tween = 1 - (curtime - (visibleVehicles[vehicle] or curtime))/LOCKON_TIME
						end

						local color = tocolor(pclr1, pclr2, pclr3, (1-tween)*200)
						local R = 1000/math.min(math.max(dist, 20), 100)
						dxDrawLine( aX+R, aY+R, aX-R, aY+R,color, 2 )
						dxDrawLine( aX+R, aY-R, aX-R, aY-R,color, 2 )
						dxDrawLine( aX+R, aY-R, aX+R, aY+R,color, 2 )
						dxDrawLine( aX-R, aY-R, aX-R, aY+R,color, 2 )
						local suffix = " m"
						if locked then
							suffix = " m (LOCKED ON)"
						end
						dxDrawText( getVehicleName( vehicle ), aX-20, aY+25, 25, 20, color, 0.9)
						dxDrawText( math.floor( dist )..suffix, aX-20, aY+40, 25, 20, color, 0.9 )

						if vehicle == target then
							color = tocolor(255, 20, 20, (1-tween)*200)
						end
						tween=tween^4 --easing function
						do
							--Draw the corners of the target box outline
							dxDrawLine( aX+R+(8+tween*300), aY+R+(8+tween*300), aX+R*0.8, aY+R+(8+tween*300),color, 2 )
							dxDrawLine( aX+R+(8+tween*300), aY-R-(8+tween*300), aX+R*0.8, aY-R-(8+tween*300),color, 2 )
							dxDrawLine( aX+R+(8+tween*300), aY+R+(8+tween*300), aX+R+(8+tween*300), aY+R*0.8,color, 2 )
							dxDrawLine( aX-R-(8+tween*300), aY+R+(8+tween*300), aX-R-(8+tween*300), aY+R*0.8,color, 2 )

							dxDrawLine( aX-R-(8+tween*300), aY+R+(8+tween*300), aX-R*0.8, aY+R+(8+tween*300),color, 2 )
							dxDrawLine( aX-R-(8+tween*300), aY-R-(8+tween*300), aX-R*0.8, aY-R-(8+tween*300),color, 2 )
							dxDrawLine( aX+R+(8+tween*300), aY-R-(8+tween*300), aX+R+(8+tween*300), aY-R*0.8,color, 2 )
							dxDrawLine( aX-R-(8+tween*300), aY-R-(8+tween*300), aX-R-(8+tween*300), aY-R*0.8,color, 2 )
						end
					end
				end
			end
		end
		if not visibleNow then
			visibleVehicles[vehicle] = nil
			lockedVehicles[vehicle] = nil
		elseif visibleVehicles[vehicle] then
			if not locked and curtime - visibleVehicles[vehicle] > LOCKON_TIME then
				lockedVehicles[vehicle] = true
			end 
		else
			visibleVehicles[vehicle] = curtime
		end
	end
end


local function homingState(key,state)
	if not inHydra then return end
	if state == "down" then
		firestate = isControlEnabled("vehicle_secondary_fire")
		toggleControl("vehicle_secondary_fire",false)
		bindKey("vehicle_secondary_fire","down",shootMissile)
	else
		toggleControl("vehicle_secondary_fire",firestate)
		firestate = nil
		unbindKey("vehicle_secondary_fire","down",shootMissile)
	end
end

local function startHydra(vehicle)
	if not inHydra and vehicle and isElement(vehicle) and vehicle.model == 520 then
		inHydra = tostring(isControlEnabled("handbrake"))
		toggleControl("handbrake", false)
		bindKey("handbrake","down",homingState)
		bindKey("handbrake","up",homingState)
		bindKey("mouse_wheel_up","down",switchTarget)
		bindKey("mouse_wheel_down","down",switchTarget)
		bindKey("horn","down",switchTarget)
		addEventHandler( "onClientRender", root,  update)
	end
end
local function stopHydra()
	if inHydra then
		removeEventHandler("onClientRender", root, update)
		unbindKey("handbrake","down",homingState)
		unbindKey("handbrake","up",homingState)
		if firestate ~= nil then
			homingState("handbrake","up")
		end
		unbindKey("mouse_wheel_up","down",switchTarget)
		unbindKey("mouse_wheel_down","down",switchTarget)
		unbindKey("horn","down",switchTarget)
		toggleControl("handbrake", inHydra=="true")
		inHydra = false
	end
end

local function initScript()

	if localPlayer.vehicle and localPlayer.vehicle.model == 520 then
		startHydra(localPlayer.vehicle)
	end
	addEventHandler("onClientResourceStop", resourceRoot, stopHydra)
	addEventHandler("onClientPlayerVehicleExit",localPlayer,stopHydra)
	addEventHandler("onClientPlayerWasted",localPlayer,stopHydra)
	addEventHandler("onClientPlayerVehicleEnter",localPlayer,startHydra)
end

addEventHandler("onClientResourceStart",resourceRoot,initScript)