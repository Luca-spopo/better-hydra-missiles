--[[
Luca aka
specahawk aka
spopo aka
Anirudh Katoch

(All rights reserved)
MIT License - Do whatever you want.
]]

----User settings---

local RANGE = 200 --Elements further away don't get a box around them
local LABEL_FUNCTION = nil --Should take a vehicle and return the text to be shown for it (e.g. Player's clan, or vehicle model, or score etc.)
local COLOR_FUNCTION = nil --Should take a vehicle (may be empty vehicle) and return R,G,B of colour of the box around it (e.g. team color, or just red and green for "enemy and ally")
--examples for both of these are the default functions below
local VALID_VEHICLE_FUNCTION = nil --Similar to VALID_TARGET_FUNCTION in missile.lua

---------------------

local getScreenFromWorldPosition, getVehicleName, root, localPlayer, tocolor, math, table, dxDrawLine, dxDrawText, ipairs, pairs, addEventHandler, getPlayerNametagColor, removeEventHandler =
      getScreenFromWorldPosition, getVehicleName, root, localPlayer, tocolor, math, table, dxDrawLine, dxDrawText, ipairs, pairs, addEventHandler, getPlayerNametagColor, removeEventHandler;

LABEL_FUNCTION = LABEL_FUNCTION or function(vehicle)
	return getVehicleName(vehicle)
end
COLOR_FUNCTION = COLOR_FUNCTION or function ( vehicle )
	local plr = vehicle.controller
	if not plr then
		return 255,255,255
	else
		--return getPlayerNametagColor(plr)
		if plr.team and plr.team == localPlayer.team then
			return 30, 255, 30
		else
			return 255, 30, 30
		end
	end
end
VALID_VEHICLE_FUNCTION = VALID_VEHICLE_FUNCTION or function() return true end

local function update()	
	for i, v in ipairs(getNearbyVehicles()) do
		local aX, aY = getScreenFromWorldPosition(v.position)
		local dist = (v.position-localPlayer.position).length
		if aY and not v.blown and localPlayer.vehicle ~= v and dist<RANGE and VALID_VEHICLE_FUNCTION(v) then
			local R = 1000/math.min(math.max(dist, 20), 100)
			local r, g, b = COLOR_FUNCTION(v)
			local alpha = math.min(60, 60*(RANGE-dist)/50)
			local color = tocolor(r, g, b, alpha)
			dxDrawLine( aX+R, aY+R, aX-R, aY+R, color, 2 )
			dxDrawLine( aX+R, aY-R, aX-R, aY-R, color, 2 )
			dxDrawLine( aX+R, aY-R, aX+R, aY+R, color, 2 )
			dxDrawLine( aX-R, aY-R, aX-R, aY+R, color, 2 )
			dxDrawText( math.floor( dist ).."m", aX-20, aY+25, 25, 20, color, 0.9 )
			dxDrawText(LABEL_FUNCTION(v), aX-20, aY+40, 25, 20, color, 0.9)
		end
	end
end

addEventHandler("onClientHydraMissilesSystemStart", localPlayer, function()
	addEventHandler( "onClientRender", root,  update)
end)
addEventHandler("onClientHydraMissilesSystemStop", localPlayer, function()
	removeEventHandler( "onClientRender", root,  update)
end)