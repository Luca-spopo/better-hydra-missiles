--[[
Luca aka
specahawk aka
spopo aka
Anirudh Katoch

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
local nearbyVehicles = {}
getNearbyVehicles = function() return nearbyVehicles end --Used by other files
local next, pairs, ipairs = next, pairs, ipairs
local getTarget, stopHydra

local function checkForLockout(vehicle)
	if visibleVehicles[vehicle] then
		triggerEvent("onClientHydraMissilesSystemLockout", localPlayer, vehicle)
		visibleVehicles[vehicle] = nil
		lockedVehicles[vehicle] = nil
		-- if getTarget() == vehicle then
			getTarget()
		-- end
	end
end

local function prev(t, index)
	local cur, val = next(t, index)
	while index ~= next(t, cur) do
		cur, val = next(t, cur)
	end
	return cur, val
end

local target
local function switchTarget(key, keystate, dir)
	if not inHydra then
		return
	end
	local it = next
	if dir == "back" then
		it = prev
	end
	local prev = target
	if target and not lockedVehicles[target] then
		target = nil
	end
	target = (it(lockedVehicles, target))
	if target == nil then --i.e. was last item
		target = (it(lockedVehicles, target))
	end
	if target~=prev then
		triggerEvent("onClientHydraMissilesSystemTargetChange", localPlayer, target)
	end
end
getTarget = function()
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
	if triggerEvent("onClientHydraMissilesSystemShootHoming", localPlayer, target)==true then
		createProjectile( hydra, 20, hydra.position, 1, target)
	end
end



local function update()
	local curtime = getTickCount()
	if not localPlayer.vehicle then --idk why, but sometimes the player has no vehicle sometime before vehicle exit event is fired
		stopHydra() --The Avengers
		return
	end
	local target = getTarget()
	for _, vehicle in ipairs(nearbyVehicles) do
		local visibleNow = false
		local locked = lockedVehicles[vehicle]
		if vehicle~=localPlayer.vehicle and not vehicle.blown and validTarget(vehicle) then
			local targPos = vehicle.position
			local myPos = localPlayer.position
			local displacement = targPos-myPos
			local dist = displacement.length
			local cosAngle = localPlayer.vehicle.matrix.forward:dot(displacement)/dist
			if dist < LOCK_RANGE and cosAngle>LOCK_ANGLE then
				local aX, aY = getScreenFromWorldPosition(targPos)
				if (aY) then
					local R = 1000/math.min(math.max(dist, 20), 100)
					local color
					visibleNow = true
					if locked then
						tween = 0
					else
						tween = 1 - (curtime - (visibleVehicles[vehicle] or curtime))/LOCKON_TIME
						tween=tween^4 --easing function

					end
					if vehicle == target then
						color = tocolor(255, 99, 71, 220)
					elseif locked then
						color = tocolor(255,165,0, 160)						
					else
						color = tocolor(255,215,0, (1-tween)*80)
					end
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
		if not visibleNow then
			checkForLockout(vehicle)
		elseif visibleVehicles[vehicle] then
			if not locked and curtime - visibleVehicles[vehicle] > LOCKON_TIME then
				lockedVehicles[vehicle] = true
				triggerEvent("onClientHydraMissilesSystemLockonEnd", localPlayer, vehicle)
			end 
		else
			triggerEvent("onClientHydraMissilesSystemLockonStart", localPlayer, vehicle)
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
		triggerEvent("onClientHydraMissilesSystemHomingStateOn", localPlayer, vehicle)
	else
		toggleControl("vehicle_secondary_fire",firestate)
		firestate = nil
		unbindKey("vehicle_secondary_fire","down",shootMissile)
		triggerEvent("onClientHydraMissilesSystemHomingStateOff", localPlayer, vehicle)
	end
end

local function streamInHandler()
	if getElementType( source ) == "vehicle" then
		outputChatBox("A vehicle streamed in")
		table.insert(nearbyVehicles, source)
	end
end
local function streamOutHandler()
	if getElementType( source ) == "vehicle" then
		outputChatBox("A vehicle streamed out")
		for i, v in ipairs(nearbyVehicles) do
			if v == source then
				checkForLockout(source)
				table.remove(nearbyVehicles, i)
				return
			end
		end
	end
end
local function startHydra(vehicle)
	if not inHydra and vehicle and isElement(vehicle) and vehicle.model == 520 then
		nearbyVehicles = getElementsByType("vehicle", root, true)
		addEventHandler("onClientElementStreamIn", getRootElement(), streamInHandler)
		addEventHandler("onClientElementStreamOut", getRootElement(), streamOutHandler)
		inHydra = tostring(isControlEnabled("handbrake"))
		toggleControl("handbrake", false)
		bindKey("handbrake","down",homingState)
		bindKey("handbrake","up",homingState)
		bindKey("mouse_wheel_up","down",switchTarget, "back")
		bindKey("mouse_wheel_down","down",switchTarget)
		bindKey("horn","down",switchTarget)
		addEventHandler( "onClientRender", root,  update)
		triggerEvent("onClientHydraMissilesSystemStart", localPlayer, vehicle)
	end
end
stopHydra = function()
	if inHydra then
		local target = getTarget()
		for i, v in ipairs(nearbyVehicles) do
			if v ~= target then
				checkForLockout(v)
			end
		end
		checkForLockout(target)
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
		removeEventHandler("onClientElementStreamIn", getRootElement(), streamInHandler)
		removeEventHandler("onClientElementStreamOut", getRootElement(), streamOutHandler)
		triggerEvent("onClientHydraMissilesSystemStop", localPlayer, vehicle)
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

addEvent("onClientHydraMissilesSystemStart")
addEvent("onClientHydraMissilesSystemStop")
addEvent("onClientHydraMissilesSystemLockonStart")
addEvent("onClientHydraMissilesSystemLockonEnd")
addEvent("onClientHydraMissilesSystemLockout")
addEvent("onClientHydraMissilesSystemTargetChange")
addEvent("onClientHydraMissilesSystemShootHoming")
addEvent("onClientHydraMissilesSystemHomingStateOn")
addEvent("onClientHydraMissilesSystemHomingStateOff")

addEventHandler("onClientResourceStart",resourceRoot,initScript)


local function callback()
	outputChatBox(eventName.." was called")
end
addEventHandler("onClientHydraMissilesSystemStart", localPlayer, callback)
addEventHandler("onClientHydraMissilesSystemStop", localPlayer, callback)
addEventHandler("onClientHydraMissilesSystemLockonStart", localPlayer, callback)
addEventHandler("onClientHydraMissilesSystemLockonEnd", localPlayer, callback)
addEventHandler("onClientHydraMissilesSystemLockout", localPlayer, callback)
addEventHandler("onClientHydraMissilesSystemTargetChange", localPlayer, callback)
addEventHandler("onClientHydraMissilesSystemShootHoming", localPlayer, callback)
addEventHandler("onClientHydraMissilesSystemHomingStateOn", localPlayer, callback)
addEventHandler("onClientHydraMissilesSystemHomingStateOff", localPlayer, callback)
