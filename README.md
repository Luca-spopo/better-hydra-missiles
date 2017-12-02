# better-hydra-missiles
A better heat seeking missiles targetting and launching system for MTA San Andreas

Demo:
https://youtu.be/VtsQxDf__gA

# Installation
1. Make a new folder in `YOUR_MTA_SERVER/mods/deathmatch/resources`
2. Put all the files in here into that folder you just created
3. Optionally, you can enable/disable `focus.lua` and `vizor.lua` by excluding/including them in the `meta.xml` file.

# Usage
When you're in a Hydra, all vehicles that are in front of you (within your 120 degree view) get "locked on" after 2 seconds.

Lockon is disengaged if the target goes off camera, or is not in front of the hydra anymore.
You can have multiple vehicles "locked on" at the same time. Press the horn button (capslock) or use the mousewheel to cycle through potential targets.

Holding space and firing a missile will fire a heat seeking missile towards the currently targetted locked on vehicle.
Firing a missile without space held will just fire it forward, totally normally.

If `vizor.lua` is enabled, all vehicles (that qualify, as decided by `VALID_VEHICLE_FUNCTION` that you can set) will have a box around them along with some text. The colour of the box, and the text, can be customized on a case by case basis by defining the `LABEL_FUNCTION` and `COLOR_FUNCTION` in `vizor.lua`

If `focus.lua` is enabled, then holding space with a target will also fix your camera towards the current target, in addition toggling homing rockets. 

# Customization

## missile.lua

The top of the script `missile.lua` has some variables you can easily edit to change the behavior of the script.

```lua
local SHOOT_COOLDOWN = 1000 --Cooldown between homing shots
local LOCKON_TIME = 2000 --Time required to lock on to a target
local LOCK_RANGE = 330 --Maximum distance between you and the target
local LOCK_ANGLE = 1.0472 --(in radians) We cannot lock on targets unless they are within this angle of the front of the hydra
local VALID_TARGET_FUNCTION = nil --Used to decide whether a vehicle should appear as a lock-on option
```

### SHOOT_COOLDOWN:

Cooldown between homing rockets, in miliseconds

### LOCKON_TIME:

Time duration between the target being visible on screen and the target getting locked

### LOCK_RANGE:

The maximum range of lockon for missiles (in metres). Note that only currently rendered vehicles can be targetted, so this range doesn't let you target faraway vehicles that have not streamed in yet.

### LOCK_ANGLE:

The angle (on each side) (in radians) that is permissible for targetting

![lock_angle](https://user-images.githubusercontent.com/13986150/33270481-34acb21e-d3aa-11e7-8c36-21d1fc2f679e.png)

### VALID_TARGET_FUNCTION:

Every vehicle that is visible is passed to this function, and only if it returns true does it allow it to be locked on.
Here is an example of a function that will only let us target __Hydras__ of __other teams__ that are __directly visible__ and __more than 50m away__
```lua
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
```
The default VALID_TARGET_FUNCTION only disables targetting of teammates. You can customize it for your own clan system.

## vizor.lua

```lua
local RANGE = 200 --Elements further away don't get a box around them
local LABEL_FUNCTION = nil --Should take a vehicle and return the text to be shown for it (e.g. Player's clan, or vehicle model, or score etc.)
local COLOR_FUNCTION = nil --Should take a vehicle (may be empty vehicle) and return R,G,B of colour of the box around it (e.g. team color, or just red and green for "enemy and ally")
--examples for both of these are the default functions below
local VALID_VEHICLE_FUNCTION = nil --Similar to VALID_TARGET_FUNCTION in missile.lua
```

### RANGE

Boxes will show up around vehicles up to these many metres away. Boxes only show up around vehicles that are streamed in.

### LABEL_FUNCTION

This function should take a vehicle and return a string, the string is the text that will be shown under the box.

### COLOR_FUNCTION

This function should take a vehicle and return three numbers (Red Green Blue). The return value of this function is used to decide the colour of the box around a vehicle. The default function for COLOR_FUNCTION shows unoccupied vehicles as white, vehicles controlled by teammates as green, and vehicles controlled by other players as red.

### VALID_VEHICLE_FUNCTION

This function should take a vehicle and return a boolean. A vehicle has a box drawn around it only if the value returned by this is truthy.

## focus.lua

```lua
local CAMERA_DISTANCE = 40
```

### CAMERA_DISTANCE

The distance between your hydra and you (in metres), when using focus on an enemy.

# Events

This script emits events that can be handled by other resources using MTA's event system.
The source of all these events is localPlayer

```lua
addEvent("onClientHydraMissilesSystemStart")
addEvent("onClientHydraMissilesSystemStop")
addEvent("onClientHydraMissilesSystemLockonStart")
addEvent("onClientHydraMissilesSystemLockonEnd")
addEvent("onClientHydraMissilesSystemLockout")
addEvent("onClientHydraMissilesSystemTargetChange")
addEvent("onClientHydraMissilesSystemShootHoming")
addEvent("onClientHydraMissilesSystemHomingStateOn")
addEvent("onClientHydraMissilesSystemHomingStateOff")
```

### onClientHydraMissilesSystemStart

Triggered when a player gets in a Hydra and the missile system (lock ons, vizor etc) kick in.

### onClientHydraMissilesSystemStop

Triggered when the missile system stops for whatever reason (Maybe player left the vehicle, or the vehicle element was destroyed, or the player died, or the resource stopped etc)

### onClientHydraMissilesSystemLockonStart

Triggered when a vehicle is in lock-on range, and the lockon timer has started. Callback (handler) function receives one argument, which is the vehicle that the lockon was started on.

### onClientHydraMissilesSystemLockonEnd

Triggered when a lock on is complete. A player can target the vehicle once lockon is complete. You can have multiple vehicles completely locked on, but only one target at a time. Callback function gets the locked on vehicle as argument.

As an example, here is a snippet that would alert a player if he has been locked on by another Hydra.
```lua
addEventHandler("onClientHydraMissilesSystemLockonEnd", localPlayer, function(veh)
	if veh.controller then
		callServerFunction("alert", veh.controller, localPlayer.name.." has a lock on you!")
	end
end)
```

### onClientHydraMissilesSystemLockout

Triggered when a lock on is disengaged. The lockon does not have to have been completed.

You can have a "LockonStart" event and then a "Lockout" event if the target went off screen before the lockon completed.

If the target went off screen after a lock on completed, you will get "LockonStart", "LockonEnd" and then a "Lockout" event.


This is also triggered when the lockout is due to unnatural reasons such as the localPlayer dying, or a locked in vehicle exploding. In general, lockout event is called on each locked in vehicle one at a time if `onClientHydraMissilesSystemStop` fires.

The callback gets the formerly locked in vehicle as a parameter.

### onClientHydraMissilesSystemTargetChange

Triggered whenever the player's current target changes. This can be due to a lockout, due to the player changing targets himself, or even unnatural causes such as the player exiting his hydra.

This function is called either when the target changes to another vehicle, or when there was a target and there isn't one anymore.

The callback function gets the current target as a parameter. This can be a vehicle, or `nil` (if there was a target earlier and there isn't one now)

### onClientHydraMissilesSystemShootHoming

Triggered when the client shoots a homing missile from the hydra. Using `cancelEvent()` will prevent the missile from being fired.

The callback function gets the target vehicle as a parameter.

This event is NOT triggered for non-homing missiles.

### onClientHydraMissilesSystemHomingStateOn

This event is triggered when the player presses handbrake while in a hydra, to shoot homing missiles instead of regular ones.

### onClientHydraMissilesSystemHomingStateOff

This event is triggered when the player releases handbrake while in a hydra, to shoot regular missiles instead of heat seeking ones.

# Very Thank

In case of any questions or bug reports, open an issue on this repo.

Pull requests are welcome too.
