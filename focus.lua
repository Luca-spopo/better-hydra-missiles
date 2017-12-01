---User settings:

local CAMERA_DISTANCE = 40

----

local Vector3, addEventHandler, root, localPlayer, Camera, setCameraTarget =
      Vector3, addEventHandler, root, localPlayer, Camera, setCameraTarget;

local up = Vector3(0, 0, 5)
local target, homing, setCamTarg_flag
setCamTarg_flag = false
addEventHandler("onClientRender", root, function()
	if homing and target then
		setCamTarg_flag = true
		local dir = (localPlayer.position - target.position)
		dir:normalize()
		local campos = localPlayer.position + dir*CAMERA_DISTANCE + up
		Camera.setMatrix(campos, target.position)
	elseif setCamTarg_flag then
		setCameraTarget(localPlayer)
		setCamTarg_flag = false
	end
end)

addEventHandler("onClientHydraMissilesSystemTargetChange", localPlayer, function(t) target = t end)
addEventHandler("onClientHydraMissilesSystemHomingStateOn", localPlayer, function() homing = true end)
addEventHandler("onClientHydraMissilesSystemHomingStateOff", localPlayer, function() homing = false end)