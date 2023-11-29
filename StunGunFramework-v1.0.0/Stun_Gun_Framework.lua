```lua
local taserLaser = true
local taserFlashlight = true
local taserPower = false
local taserCartridges = 2
local prongAttached = false
local prongCooldown = false
local suspectTased = false
local taserOn = false

local function togglePower()
    taserOn = not taserOn
    taserPower = taserOn  -- Update taserPower with taserOn value
    if taserOn then
        taserLaser = true
        taserFlashlight = true
        TriggerEvent("chat:addMessage", {
            color = {255,255,255}, -- White color for "Powered"
            multiline = true,
            args = {"[Stun Gun]", "^7Powered ^2ON^7!"} -- Using "^2" for green color and "^7" for white color
        })
    else
        taserLaser = false
        taserFlashlight = false
        prongAttached = false  -- Make sure prong is not attached when powered off
        TriggerEvent("chat:addMessage", {
            color = {255,255,255}, -- White color for "Powered"
            multiline = true,
            args = {"[Stun Gun]", "^7Powered ^1OFF^7!"} -- Using "^1" for red color and "^7" for white color
        })
    end
end

local reloadAnimDict = "anim@mp_snowball"
local reloadAnimName = "pickup_snowball"

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(0, 73) and IsPedInAnyVehicle(PlayerPedId(), false) and DoesEntityExist(GetClosestPed(GetEntityCoords(PlayerPedId()), 1.5)) then
            if taserCartridges > 0 then
                if not prongAttached and not prongCooldown then
                    prongAttached = true
                    prongCooldown = true
                    TriggerServerEvent("taser:hitPed")  -- Trigger event on server to apply taser effect
                    TriggerEvent("chat:addMessage", {
                        color = {255,0,0},
                        multiline = true,
                        args = {"[Stun Gun]", "Suspect Hit!"}
                    })
                    Citizen.Wait(2000) -- Wait time before able to tase again
                    prongAttached = false
                end
            elseif taserCartridges == 0 then
                TriggerEvent("chat:addMessage", {
                    color = {255,0,0},
                    multiline = true,
                    args = {"[Stun Gun]", "Out of cartridges!"}
                })
            end
        end

        if IsControlJustPressed(0, 73) and IsPedInAnyPoliceVehicle(PlayerPedId()) then
            togglePower()
        end
        
        if IsControlJustPressed(0, 29) and prongAttached and not IsPedInAnyVehicle(PlayerPedId()) then
            prongAttached = false
            TriggerEvent("chat:addMessage", {
                color = {255,0,0},
                multiline = true,
                args = {"[Stun Gun]", "Prong was removed!"}
            })
        end
        
        if IsControlJustPressed(0, 45) then
            if prongAttached then
                prongAttached = false
                TriggerEvent("chat:addMessage", {
                    color = {255,0,0},
                    multiline = true,
                    args = {"[Stun Gun]", "Prong was removed!"}
                })
            elseif not prongAttached and taserCartridges > 0 then
                taserCartridges = taserCartridges - 1  -- Subtract 1 from the current number of cartridges
                PlaySoundFrontend(-1, "WEAPON_PISTOL_RELOAD", "HUD_AMMO_SHOP_SOUNDSET", 1)  -- Play reload sound
                loadAnimDict(reloadAnimDict)
                TaskPlayAnim(PlayerPedId(), reloadAnimDict, reloadAnimName, 4.0, -4.0, -1, 0, 0, false, false, false)
                Citizen.Wait(4000)  -- Wait for reload animation to finish
                ClearPedTasks(PlayerPedId())
            end
        end
        
        if IsControlJustPressed(0, 19) then
            if prongAttached then
                prongAttached = false
                TriggerEvent("chat:addMessage", {
                    color = {255,0,0},
                    multiline = true,
                    args = {"[Stun Gun]", "Prong was removed!"}
                })
            else
                taserCartridges = 2  -- Set the number of cartridges to the maximum (2)
            end
        end
        
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if taserPower then
            if taserLaser then
                SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_PISTOL"), true) -- Enable laser
            else
                SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_UNARMED"), true) -- Disable laser
            end
            
            if IsPedArmed(PlayerPedId(), 7) then
                if not IsFlashLightOn(PlayerPedId()) then
                    SetFlashLightKeepOnWhileMoving(PlayerPedId(), true) -- Keep flashlight on while moving
                end
                if taserFlashlight then
                    SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_FLASHLIGHT"), true) -- Enable flashlight
                else
                    SetFlashLightEnabled(PlayerPedId(), false) -- Disable flashlight
                end

                if taserLaser and taserFlashlight and IsPedArmed(PlayerPedId(), 7) and IsFlashLightOn(PlayerPedId()) then
                    local playerPos = GetEntityCoords(PlayerPedId())
                    local playerHeading = GetEntityHeading(PlayerPedId())

                    local x = playerPos.x + math.sin(math.rad(playerHeading)) * 0.2
                    local y = playerPos.y + math.cos(math.rad(playerHeading)) * 0.2
                    local z = playerPos.z + 0.4

                    local targetX = playerPos.x + math.sin(math.rad(playerHeading)) * 1.0
                    local targetY = playerPos.y + math.cos(math.rad(playerHeading)) * 1.0
                    local targetZ = playerPos.z + 0.4

                    DrawSpotLight(
                        x, y, z, -- Light position
                        targetX, targetY, targetZ, -- Light target position
                        255, 255, 255, -- Light color (white)
                        1, -- Light intensity
                        10, -- Light distance
                        1.0 -- Light angle
                    )
                end
            end
            
        else
            SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_UNARMED"), true) -- Disable laser
            SetFlashLightKeepOnWhileMoving(PlayerPedId(), false) -- Disable flashlight keep on while moving
            SetFlashLightEnabled(PlayerPedId(), false) -- Disable flashlight
        end
        
        -- Display ammo bar here
        DrawText(0.9, 0.02, 0.0, 0.0, 0.4, tostring(taserCartridges) .. "x Cartridges", 255, 255, 255, 255)
        
        -- Display screen distortion here if suspectTased is true
        if suspectTased then
            SetTimecycleModifier("hud_def_blur")  -- Apply screen distortion
        else
            ClearTimecycleModifier()  -- Clear screen distortion
        end
    end
end)

function DrawText(x, y, width, height, scale, text, r, g, b, a)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(x, y + 0.0150, width, height + 0.03, 0, 0, 0, 80)
end

function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Citizen.Wait(10)
    end
end

RegisterNetEvent("taser:hitPed")
AddEventHandler("taser:hitPed", function()
    local ped = GetClosestPed(GetEntityCoords(PlayerPedId()), 1.5)
    if DoesEntityExist(ped) then
        local taserHash = GetHashKey("WEAPON_STUNGUN")
        local aimPos = GetPedBoneCoords(ped, 0x2e28, 0.0, 0.0, 0.0)  -- Aim for the center mass bone
        local playerPos = GetEntityCoords(PlayerPedId())
        local playerHeading = GetEntityHeading(PlayerPedId())
        local shotOffset = GetOffsetFromEntityGivenWorldCoords(PlayerPedId(), aimPos)
        local shotDir = GetNormalizedVector(shotOffset)

        AddExplosion(playerPos.x + math.sin(math.rad(playerHeading)) * 0.2, playerPos.y + math.cos(math.rad(playerHeading)) * 0.2, playerPos.z + 0.4, 23, 1.0, false, false, 1.0)
        TaskShootAtCoord(PlayerPedId(), aimPos.x, aimPos.y, aimPos.z, 1000, taserHash, 0x2c780ffe, 1)
        SetCurrentPedWeapon(PlayerPedId(), taserHash, true)

        Citizen.Wait(500)  -- Adjust this delay as needed
        local rayHandle = CastRayPointToPoint(playerPos.x + math.sin(math.rad(playerHeading)) * 0.2, playerPos.y + math.cos(math.rad(playerHeading)) * 0.2, playerPos.z + 0.4, shotDir.x, shotDir.y, shotDir.z, 10, ped, 0)
        local _, _, _, _, pedInRayHandle = GetRaycastResult(rayHandle)
        if ped == pedInRayHandle then
            TriggerServerEvent("taser:sendTased", ped)  -- Trigger event on server to apply taser effect to ped
        end
    end
end)

RegisterNetEvent("taser:applyTased")
AddEventHandler("taser:applyTased", function(ped)
    TaskPlayAnim(ped, "combat@damage@rb_writhe", "rb_writhe_loop", 2.0, 2.0, -1, 1, 0, false, false, false)  -- Apply "tased" animation
    suspectTased = true
    Citizen.Wait(3000)  -- Adjust this delay as needed
    ClearPedTasks(ped)  -- Clear "tased" animation
    suspectTased = false
end)

RegisterCommand("refillcart", function(source, args, rawCommand)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        taserCartridges = 2
        TriggerEvent("chat:addMessage", {
            color = {255, 0, 0},
            multiline = true,
            args = {"[Stun Gun]", "Cartridges refilled!"}
        })
    else
        TriggerEvent("chat:addMessage", {
            color = {255, 0, 0},
            multiline = true,
            args = {"[Stun Gun]", "You must be inside a vehicle to refill cartridges!"}
        })
    end
end)
``` 