-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP / TUNNEL
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")

-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("admin", Creative)
vSERVER = Tunnel.getInterface("admin")

-----------------------------------------------------------------------------------------------------------------------------------------
-- TELEPORTWAY
-----------------------------------------------------------------------------------------------------------------------------------------
local WAYPOINT_BLIP = 8

RegisterNetEvent("admin:teleportWay")
AddEventHandler("admin:teleportWay", function()
    if Creative and Creative.teleportWay then
        Creative.teleportWay()
    end
end)

local function FindGroundZ(x, y)
    -- tenta várias alturas até achar o chão
    local tries = {1000.0, 900.0, 800.0, 700.0, 600.0, 500.0, 400.0, 300.0, 200.0, 150.0, 110.0, 90.0, 70.0, 50.0, 40.0, 30.0, 20.0, 10.0}
    for i = 1, #tries do
        local z = tries[i]
        local found, groundZ = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, z + 0.0, true)
        if found then
            return groundZ + 1.0
        end
        RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
        Wait(5)
    end


    -- última tentativa: nó de estrada mais próximo (teleporte seguro)
local nodeFound, nodePos = GetClosestVehicleNode(x + 0.0, y + 0.0, 0.0, 1, 3.0, 0.0)
if nodeFound and nodePos then
    return (nodePos.z or 200.0) + 1.0
end


    -- fallback
    return 200.0
end

function Creative.teleportWay()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    -- teleporta o veículo só se fores o condutor; caso contrário, só o ped
    local entity = ped
    if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
        entity = veh
    end

    -- waypoint
    local wayBlip = GetFirstBlipInfoId(WAYPOINT_BLIP)
    if not DoesBlipExist(wayBlip) then
        TriggerEvent("Notify", "Teleporte", "Marca um <b>waypoint</b> no mapa primeiro.", "amarelo", 5000)
        return
    end

    -- coords do waypoint (usar InfoIdCoord é mais estável)
    local wp = GetBlipInfoIdCoord(wayBlip)
    local destX, destY = wp.x + 0.0, wp.y + 0.0
    local finalZ = FindGroundZ(destX, destY)

    local ox, oy, oz = table.unpack(GetEntityCoords(entity))

    -- prepara teleporte
    RequestCollisionAtCoord(destX, destY, finalZ)
    FreezeEntityPosition(entity, true)

    -- aplica teleporte
    SetEntityCoordsNoOffset(entity, destX, destY, finalZ, false, false, false)

    -- aguarda colisão carregar no novo local
    local t0 = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(entity) and (GetGameTimer() - t0) < 1500 do
        RequestCollisionAtCoord(destX, destY, finalZ)
        Wait(0)
    end

    -- se for veículo, assenta no chão
    if entity ~= ped then
        SetVehicleOnGroundProperly(entity)
    end

    FreezeEntityPosition(entity, false)

    -- log para o servidor
    vSERVER.LogTeleport(ox + 0.0, oy + 0.0, oz + 0.0, destX, destY, finalZ)

    -- feedback
    TriggerEvent("Notify", "Teleporte", "Teletransportado para o <b>waypoint</b>.", "verde", 3000)
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- TELEPORTWAY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.teleportLimbo()
	local Ped = PlayerPedId()
	local Coords = GetEntityCoords(Ped)
	local _,Node = GetNthClosestVehicleNode(Coords["x"],Coords["y"],Coords["z"],1,0,0,0)

	SetEntityCoords(Ped,Node["x"],Node["y"],Node["z"] + 1)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADMIN:TUNING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("admin:Tuning")
AddEventHandler("admin:Tuning",function()
	local Ped = PlayerPedId()
	if IsPedInAnyVehicle(Ped) then
		local Vehicle = GetVehiclePedIsUsing(Ped)

		SetVehicleModKit(Vehicle,0)
		ToggleVehicleMod(Vehicle,18,true)
		SetVehicleMod(Vehicle,11,GetNumVehicleMods(Vehicle,11) - 1,false)
		SetVehicleMod(Vehicle,12,GetNumVehicleMods(Vehicle,12) - 1,false)
		SetVehicleMod(Vehicle,13,GetNumVehicleMods(Vehicle,13) - 1,false)
		SetVehicleMod(Vehicle,15,GetNumVehicleMods(Vehicle,15) - 1,false)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADMIN:INITSPECTATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("admin:initSpectate")
AddEventHandler("admin:initSpectate",function(source)
	if not NetworkIsInSpectatorMode() then
		local Pid = GetPlayerFromServerId(source)
		local Ped = GetPlayerPed(Pid)

		LocalPlayer["state"]:set("Spectate",true,false)
		NetworkSetInSpectatorMode(true,Ped)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADMIN:RESETSPECTATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("admin:resetSpectate")
AddEventHandler("admin:resetSpectate",function()
	if NetworkIsInSpectatorMode() then
		NetworkSetInSpectatorMode(false)
		LocalPlayer["state"]:set("Spectate",false,false)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
AddStateBagChangeHandler("Quake",nil,function(Name,Key,Value)
	ShakeGameplayCam("SKY_DIVING_SHAKE",1.0)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- LIMPAREA
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Limparea(Coords)
	ClearAreaOfPeds(Coords["x"],Coords["y"],Coords["z"],100.0,0)
	ClearAreaOfCops(Coords["x"],Coords["y"],Coords["z"],100.0,0)
	ClearAreaOfObjects(Coords["x"],Coords["y"],Coords["z"],100.0,0)
	ClearAreaOfProjectiles(Coords["x"],Coords["y"],Coords["z"],100.0,0)
	ClearArea(Coords["x"],Coords["y"],Coords["z"],100.0,true,false,false,false)
	ClearAreaOfVehicles(Coords["x"],Coords["y"],Coords["z"],100.0,false,false,false,false,false)
	ClearAreaLeaveVehicleHealth(Coords["x"],Coords["y"],Coords["z"],100.0,false,false,false,false)
end


---- TEMPO

local horaAtual = nil

RegisterNetEvent("hora:sincronizar")
AddEventHandler("hora:sincronizar", function(hora)
    horaAtual = tonumber(hora)
end)

CreateThread(function()
    while true do
        Wait(1000)
        if horaAtual then
            NetworkOverrideClockTime(horaAtual, 0, 0)
            PauseClock(true)
        end
    end
end)

---- GODSYN

local godsynActive = false

RegisterNetEvent("godsyn:toggle")
AddEventHandler("godsyn:toggle", function()
    godsynActive = not godsynActive
    local msg = godsynActive and "Modo ativado." or "Modo desativado."
    TriggerEvent("Notify", "GOD Syn", "<b>"..msg.."</b>", "deus", 5000)


    if godsynActive then
        Citizen.CreateThread(function()
            local ped = PlayerPedId()

            while godsynActive do
                SetPedInfiniteAmmoClip(ped, true)

                if IsPedArmed(ped, 6) and not IsPedReloading(ped) then
                    local _, target = GetEntityPlayerIsFreeAimingAt(PlayerId())
                    if DoesEntityExist(target) and IsEntityAPed(target) and not IsPedDeadOrDying(target) then
                        local targetHeadCoords = GetPedBoneCoords(target, 31086, 0.0, 0.0, 0.0)
                        local camCoords = GetGameplayCamCoord()
                        local cameraRotation = GetGameplayCamRot(2)
                        local inVehicle = IsPedInAnyVehicle(ped)

                        if inVehicle then
                            -- Ajuste para veículos
                            local adjustedTargetCoords = targetHeadCoords + vector3(0.0, 0.0, 0.1)
                            local aimCoords = vector3(
                                adjustedTargetCoords.x + math.sin(math.rad(cameraRotation.z)) * 0.5,
                                adjustedTargetCoords.y - math.cos(math.rad(cameraRotation.z)) * 0.5,
                                adjustedTargetCoords.z
                            )

                            SetPedShootsAtCoord(ped, aimCoords.x, aimCoords.y, aimCoords.z, true)
                        else
                            -- Mira direta à cabeça se estiver a pé
                            SetPedShootsAtCoord(ped, targetHeadCoords.x, targetHeadCoords.y, targetHeadCoords.z + 0.02, true)
                        end

                        -- Pequeno delay entre os tiros
                        Wait(50)
                    end
                end

                Wait(0)
            end
        end)
    end
end)

----- COLETE


local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(10)
    end
    return HasAnimDictLoaded(dict)
end

RegisterNetEvent("admin:applyArmour")
AddEventHandler("admin:applyArmour", function(amount)
    local ped = PlayerPedId()
    amount = math.floor(tonumber(amount) or 100)
    if amount < 0 then amount = 0 end
    if amount > 100 then amount = 100 end

    -- animação de vestir
    local dict, anim = "clothingshirt", "try_shirt_positive_d"
    if LoadAnimDict(dict) then
        TaskPlayAnim(ped, dict, anim, 8.0, 8.0, 1600, 48, 0.0, false, false, false)
        Wait(1100) -- deixa “vestir” antes de aplicar
        RemoveAnimDict(dict)
    end

    -- aplica o armor
    SetPedArmour(ped, amount)

    -- (opcional) se quiseres um “click” no HUD
    -- PlaySoundFrontend(-1, "ATM_WINDOW", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end)


----- GUARDARCOLETE

RegisterNetEvent("admin:checkArmourForSave")
AddEventHandler("admin:checkArmourForSave", function(token)
    local ped = PlayerPedId()
    local armour = GetPedArmour(ped) or 0
    TriggerServerEvent("admin:checkArmourForSave:response", token, armour)
end)

-- CLIENT-SIDE (admin/client-side/core.lua)

-- devolve o armor atual
RegisterNetEvent("admin:checkArmourForSave")
AddEventHandler("admin:checkArmourForSave", function(token)
    local ped = PlayerPedId()
    TriggerServerEvent("admin:checkArmourForSave:response", token, GetPedArmour(ped) or 0)
end)

-- remove armor + visual e toca animação de vestir/retirar
RegisterNetEvent("admin:removeArmour")
AddEventHandler("admin:removeArmour", function(playAnim)
    local ped = PlayerPedId()

    if playAnim then
        -- animação “vestir camisa”
        local dict, name = "clothingshirt", "try_shirt_positive_d"
        RequestAnimDict(dict)
        local tries = 0
        while not HasAnimDictLoaded(dict) and tries < 100 do
            Wait(10); tries = tries + 1
        end
        if HasAnimDictLoaded(dict) then
            TaskPlayAnim(ped, dict, name, 8.0, 8.0, 1600, 48, 0.0, false, false, false)
            Wait(1200)
        end
        RemoveAnimDict(dict)
    end

    -- zera barra de armor
    SetPedArmour(ped, 0)

    -- garante sync do HUD
    Wait(50)
    SetPedArmour(ped, 0)
end)



------------ GODMODE

local godmode = false

RegisterNetEvent("admin:toggleGodmode")
AddEventHandler("admin:toggleGodmode", function()
    local ped = PlayerPedId()
    godmode = not godmode

    SetEntityInvincible(ped, godmode)
    SetPlayerInvincible(PlayerId(), godmode)
    SetEntityProofs(ped, godmode, godmode, godmode, godmode, godmode, godmode, godmode, godmode)
    SetPedCanRagdoll(ped, not godmode)

    if godmode then
        TriggerEvent("Notify", "ATIVADO", "Godmode ativado.", 5000)
    else
        TriggerEvent("Notify", "DESATIVADO", "Godmode desativado.", 5000)
    end
end)


----- TAG STAFF

--- TAG STAFF BY SYNTHIX (adaptado sem Config)

local playerTags = {}

local function DrawText3D(x, y, z, text, scale)
    local camCoords = GetGameplayCamCoords()
    local dist = #(camCoords - vector3(x, y, z))
    local dynamicScale = (1 / dist) * 2.0
    local fov = (1 / GetGameplayCamFov()) * 100
    dynamicScale = dynamicScale * fov

    SetTextScale(0.0 * dynamicScale, 0.55 * dynamicScale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(1)

    SetDrawOrigin(x, y, z, 0)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function DrawTag()
    local nameOffset = 1.0
    local infoOffset = 1.14

    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for playerId, tagData in pairs(playerTags) do
            local targetPed = GetPlayerPed(GetPlayerFromServerId(playerId))
            if DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(playerCoords - targetCoords)

                if distance <= 50.0 and IsEntityOnScreen(targetPed) then
                    local tagText = "~g~[STAFF]~w~"

                    if tagData.tagType == "license:fc1ad7eead6a44c1102a1b2e18ae20caffd26fb4" then
                        tagText = "~r~[DONO]~w~"
                    elseif tagData.tagType == "license:3a61e278f67c966704a19d070ed45aaec630b3ec" then
                        tagText = "~b~[DEVELOPER]~w~"
                    elseif tagData.tagType == "license:64e4e726d0a1431b1b4028186dc2be0c663bc69b" then
                        tagText = "~b~[DEVELOPER]~w~"

                    end

                    local fullName = tagText .. " " .. tagData.playerName

                    if NetworkIsPlayerActive(GetPlayerFromServerId(playerId)) then
                        if tagData.infoText and tagData.infoText ~= "" then
                            DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + infoOffset, tagData.infoText, 0.5)
                        end

                        DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + nameOffset, fullName, 0.5)
                    end
                end
            end
        end
    end
end

RegisterNetEvent('admin:displayStaffTag', function(playerId, playerName, tagType)
    playerTags[playerId] = {playerName = playerName, tagType = tagType, infoText = ""}
end)

RegisterNetEvent('admin:removeStaffTag', function(playerId)
    playerTags[playerId] = nil
end)

RegisterNetEvent('admin:updateTags', function(updatedTags)
    playerTags = updatedTags
end)

CreateThread(DrawTag)

----- WALL
----- WALL
local wallEnabled = false
local activeWall = {}

RegisterNetEvent("wall:toggle")
AddEventHandler("wall:toggle", function(state, wallUsers)
	wallEnabled = state
	activeWall = wallUsers or {}
end)

-- função para texto 3D
local function DrawText3D(coords, text, scale)
	local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z + 0.90)
	if onScreen then
		SetTextScale(scale, scale)
		SetTextFont(4)
		SetTextProportional(1)
		SetTextCentre(true)
		SetTextColour(255, 255, 255, 215)
		SetTextOutline()
		SetTextEntry("STRING")
		AddTextComponentString(text)
		DrawText(_x, _y)
	end
end

-- função para desenhar linha secundária menor logo abaixo
local function DrawText3DSub(coords, text, scale)
	local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z + 0.97) -- ligeiramente mais baixo
	if onScreen then
		SetTextScale(scale, scale)
		SetTextFont(4)
		SetTextProportional(1)
		SetTextCentre(true)
		SetTextColour(255, 255, 255, 200)
		SetTextOutline()
		SetTextEntry("STRING")
		AddTextComponentString(text)
		DrawText(_x, _y)
	end
end

CreateThread(function()
	while true do
		Wait(0)
		if wallEnabled then
			for _, player in ipairs(GetActivePlayers()) do
				local target = GetPlayerPed(player)
				if DoesEntityExist(target) then
					local targetSrc = GetPlayerServerId(player)
					local myPed = PlayerPedId()
					local coords = GetEntityCoords(target)

					local distance = #(GetEntityCoords(myPed) - coords)
					if distance < 300.0 then
						local name = GetPlayerName(player)
						local passport = activeWall[targetSrc] and activeWall[targetSrc].passport or "?"
						local fullName = activeWall[targetSrc] and activeWall[targetSrc].name or "Desconhecido"

						local tag = string.format("%s ~b~[%d]~w~ - %s", fullName, targetSrc, passport)
						if activeWall[targetSrc] and activeWall[targetSrc].wall then
							tag = tag .. " ~r~[WALL]"
						end

						-- -- HP e Colete
						-- local hpRaw = GetEntityHealth(target)
						-- local hpMax = GetEntityMaxHealth(target)
						-- local hp = math.floor(math.max(0, math.min(100, ((hpRaw - 100) / math.max(1, (hpMax - 100))) * 100)) + 0.5)
						-- local armor = math.floor(math.max(0, math.min(100, GetPedArmour(target))) + 0.5)

						-- local sub = ("~g~HP~w~: %d - ~b~COLETE~w~: %d"):format(hp, armor)

						-- desenhar linha principal
						DrawText3D(coords, tag, 0.30)
						-- desenhar linha secundária menor
						-- DrawText3DSub(coords, sub, 0.25)
					end
				end
			end
		end
	end
end)




----- ALGEMAR

RegisterNetEvent("admin:ToggleHandcuff")
AddEventHandler("admin:ToggleHandcuff", function()
	local ped = PlayerPedId()
	local isCuffed = LocalPlayer["state"]["Handcuff"]

	LocalPlayer["state"]:set("Handcuff", not isCuffed, true)

	if not isCuffed then
		-- Algemar
		TriggerEvent("Notify", "Algemas", "Foste <b>algemado</b> por um staff.", "vermelho", 5000)
		-- (Opcional: meter animação de algemado)
	else
		-- Desalgemar
		ClearPedTasks(ped)
		TriggerEvent("Notify", "Algemas", "Foste <b>desalgemado</b> por um staff.", "verde", 5000)
	end
end)


------ EXPORT TELEMOVEL

-- Promessas por jogador
local phoneCheckPromise = nil

-- Recebe o resultado do servidor
RegisterNetEvent("inventory:hasPhone:result", function(hasPhone)
    if phoneCheckPromise then
        phoneCheckPromise:resolve(hasPhone)
        phoneCheckPromise = nil
    end

    -- Debug opcional
    -- TriggerEvent("Notify", "verde", hasPhone and "Tens telemóvel." or "Não tens telemóvel.")
end)

-- Export usado pelo NPWD
exports("hasPhone", function()
    local p = promise.new()
    phoneCheckPromise = p

    TriggerServerEvent("inventory:hasPhone:check")

    local result = Citizen.Await(p)
    return result
end)


-----------------------------------------------------------------------------------------------------------------------------------------
-- CLIENT: LIMPAR PEDS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("staff:ClearPeds")
AddEventHandler("staff:ClearPeds", function(tipo)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, entity in ipairs(GetGamePool("CPed")) do
        if not IsPedAPlayer(entity) then
            if tipo == "todos" or #(coords - GetEntityCoords(entity)) <= 50.0 then
                DeleteEntity(entity)
            end
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- CLIENT: LIMPAR OBJETOS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("staff:ClearObjects")
AddEventHandler("staff:ClearObjects", function(tipo)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, entity in ipairs(GetGamePool("CObject")) do
        if tipo == "todos" or #(coords - GetEntityCoords(entity)) <= 65.0 then
            DeleteEntity(entity)
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- DEBUG
-----------------------------------------------------------------------------------------------------------------------------------------

local debugOn = false
local lastNearby = { src = -1, passport = 0, fullname = "", stamp = 0 }
local _ping = 0

RegisterNetEvent("debug:setPing", function(val)
    _ping = tonumber(val) or 0
end)


-- ===== toggler + notif bonita =====
RegisterNetEvent("debug:toggle", function()
    debugOn = not debugOn
    if debugOn then
        TriggerEvent("Notify","Debug","<b>Debug ligado</b>. Painel no ecrã.", "verde", 3000)
        CreateThread(function()
            while debugOn do
                TriggerServerEvent("debug:reqPing")
                Wait(2000)
            end
        end)
    else
        TriggerEvent("Notify","Debug","<b>Debug desligado</b>.", "amarelo", 2500)
    end
end)

RegisterNetEvent("debug:replyPlayerInfo", function(data)
    if data and data.targetSrc == lastNearby.src then
        lastNearby.passport = data.passport or 0
        lastNearby.fullname = data.fullname or ""
        lastNearby.stamp = GetGameTimer()
    end
end)

-- ===== helpers universais =====
local function SafeZone()
    local safe = GetSafeZoneSize()
    local inv  = 1.0 - safe
    return inv * 0.5, inv * 0.5
end

local function DrawTxt(x, y, scale, text)
    local sx, sy = SafeZone()
    x = x + sx; y = y + sy

    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropshadow(1, 0, 0, 0, 255)
    SetTextOutline()
    SetTextColour(255,255,255,255)
    SetTextJustification(1) -- left

    SetTextEntry("STRING")
    AddTextComponentString(text) -- maior compatibilidade
    DrawText(x, y)
end

local function DrawBox(x,y,w,h,a)
    local sx, sy = SafeZone()
    DrawRect(x + sx + w/2, y + sy + h/2, w, h, 0, 0, 0, a)
end

local function round(n, d) return math.floor(n * 10^d + 0.5) / 10^d end

-- ===== data =====
local function getCoordsInfo()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local fwd = GetEntityForwardVector(ped)
    local streetHash, crossHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)
    local cross  = crossHash ~= 0 and GetStreetNameFromHashKey(crossHash) or ""
    local zoneName = GetNameOfZone(coords.x, coords.y, coords.z)
    local zone   = GetLabelText(zoneName)
    if zone == "NULL" then zone = zoneName end
    return {
        x=coords.x,y=coords.y,z=coords.z,h=h,
        fx=fwd.x,fy=fwd.y,fz=fwd.z,
        street=street,cross=cross,zone=zone
    }
end

local function RotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function rayCastFromCam(dist)
    local camRot = GetGameplayCamRot(2)
    local camPos = GetGameplayCamCoord()
    local dir    = RotationToDirection(camRot)
    local destX  = camPos.x + dir.x * dist
    local destY  = camPos.y + dir.y * dist
    local destZ  = camPos.z + dir.z * dist
    local ray = StartShapeTestRay(camPos.x, camPos.y, camPos.z, destX, destY, destZ, -1, PlayerPedId(), 0)
    local _, hit, endCoords, _, entityHit = GetShapeTestResult(ray)
    return hit == 1, endCoords, entityHit
end

local function entityInfo(entity)
    -- validações duras para evitar crash
    if not entity or type(entity) ~= "number" then
        return { type = "none" }
    end
    if entity == 0 then
        return { type = "none" }
    end
    -- alguns builds precisam de DoesEntityExist antes de QUALQUER native de entity
    if not DoesEntityExist(entity) then
        return { type = "none" }
    end

    local etype = "object"
    if IsEntityAVehicle(entity) then
        etype = "vehicle"
    elseif IsEntityAPed(entity) then
        etype = "ped"
    end

    local model = 0
    -- protege GetEntityModel com pcall caso algum wrapper esteja a interceptar
    local ok, m = pcall(GetEntityModel, entity)
    if ok and m then model = m end

    local netId = -1
    ok, m = pcall(NetworkGetNetworkIdFromEntity, entity)
    if ok and m then netId = m end

    local cx, cy, cz = table.unpack(GetEntityCoords(entity))
    return { type = etype, model = model, netId = netId, id = entity, x = cx, y = cy, z = cz }
end

local function nearbyPlayer()
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local closest, closestDist, closestServer = -1, 9999.0, -1

    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            local dist = #(GetEntityCoords(ped) - myCoords)
            if dist < closestDist then
                closest = player
                closestDist = dist
                closestServer = GetPlayerServerId(player)
            end
        end
    end

    if closest ~= -1 then
        if lastNearby.src ~= closestServer or (GetGameTimer() - lastNearby.stamp) > 3000 then
            lastNearby.src = closestServer
            TriggerServerEvent("debug:requestPlayerInfo", closestServer)
        end
        return { src=closestServer, dist=closestDist, passport=lastNearby.passport or 0, fullname=lastNearby.fullname or "" }
    end

    lastNearby = { src = -1, passport = 0, fullname = "", stamp = 0 }
    return { src=-1, dist=-1, passport=0, fullname="" }
end

local function vehicleInfo()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped,false) then return nil end
    local veh = GetVehiclePedIsIn(ped,false)
    local model = GetEntityModel(veh)
    local display = GetDisplayNameFromVehicleModel(model)
    local name = GetLabelText(display)
    if name == "NULL" then name = display end
    return {
        name=name, model=model, hash=model,
        plate=GetVehicleNumberPlateText(veh),
        health=GetVehicleEngineHealth(veh),
        netId=NetworkGetNetworkIdFromEntity(veh),
        id=veh
    }
end


local function dist3(a, b)
    return Vdist(a.x, a.y, a.z, b.x, b.y, b.z)
end

-- ===== painel =====
local function drawAllDebug()
    local ped = PlayerPedId()
    local c = getCoordsInfo()
    local fps = math.floor(1.0 / GetFrameTime())
    local ping = _ping
    local interior = GetInteriorFromEntity(ped)
    local hag = round(GetEntityHeightAboveGround(ped),2)
    local hour, minute = GetClockHours(), GetClockMinutes()
    local hit, hitPos, ent = rayCastFromCam(500.0)
    local e = entityInfo(ent)
    local myPos = GetEntityCoords(ped)
    local dist = hit and dist3(myPos, hitPos) or -1
    local near = nearbyPlayer()
    local veh = vehicleInfo()

    -- -- Banner TESTE grande (primeiras 2s após ligar)
    -- if (GetGameTimer() - (lastNearby.stamp or 0)) < 2000 then
    --     DrawBox(0.38, 0.04, 0.24, 0.05, 150)
    --     DrawTxt(0.395, 0.055, 0.5, "~b~DEBUG ATIVO~s~")
    -- end

    local x, y = 0.015, 0.50
    local lineH = 0.020
    local width = 0.40
    local baseLines = 16
    local lines = baseLines + (veh and 2 or 1)
    -- DrawBox(x-0.010, y-0.010, width+0.020, (lines+2)*lineH+0.010, 140)
    --  DrawTxt(x, y - 0.012, 0.90, "~b~DEBUG STAFF~s~  (/debug)")
    local line = 0
    local function L(txt) DrawTxt(x, y + line*lineH, 0.32, txt); line = line + 1 end

    L(("~y~LOCALIZAÇÃO~s~  x: ~b~%.3f~s~  y: ~b~%.3f~s~  z: ~b~%.3f~s~  h: ~b~%.2f"):format(c.x, c.y, c.z, c.h))
    L(("forward: ~b~(%.2f, %.2f, %.2f)"):format(c.fx, c.fy, c.fz))
    L(("rua: ~b~%s~s~  cruz.: ~b~%s~s~  zona: ~b~%s"):format(c.street, (c.cross ~= "" and c.cross or "-"), c.zone))
    L(("fps: ~b~%d~s~  ping: ~b~%d~s~  interior: ~b~%d~s~  HAG: ~b~%.2f~s~  hora: ~b~%02d:%02d"):format(fps, ping, interior, hag, hour, minute))

    L(" ")
    L("~y~MIRA")
    if hit then
        L(("coords: ~b~%.3f, %.3f, %.3f~s~  dist: ~b~%.2f"):format(hitPos.x, hitPos.y, hitPos.z, dist))
    else
        L("coords: ~r~sem hit")
    end
    L(("entity: ~b~%s~s~  model: ~b~%s~s~  netID: ~b~%d~s~  entID: ~b~%d"):format(e.type, (e.model ~= 0 and tostring(e.model) or "-"), e.netId or -1, e.id or -1))

    L(" ")
    L("~y~PRÓXIMO JOGADOR")
    if near.src ~= -1 then
        L(("src: ~b~%d~s~  passaporte: ~b~%d~s~  nome: ~b~%s~s~  dist: ~b~%.2f"):format(near.src, near.passport, (near.fullname ~= "" and near.fullname or "-"), near.dist))
    else
        L("~r~nenhum próximo")
    end

    L(" ")
    L("~y~VEÍCULO ATUAL")
    if veh then
        L(("nome: ~b~%s~s~  modelo/hash: ~b~%s / %d"):format(veh.name, GetDisplayNameFromVehicleModel(veh.model), veh.hash))
        L(("placa: ~b~%s~s~  motor: ~b~%.1f~s~  netID: ~b~%d~s~  entID: ~b~%d"):format(veh.plate, veh.health, veh.netId, veh.id))
    else
        L("~r~Não está em veículo.")
    end
end

-- ===== loop =====
CreateThread(function()
    while true do
        if debugOn then
            drawAllDebug()
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- FREEZE LOCAL (apenas o jogador alvo)
-----------------------------------------------------------------------------------------------------------------------------------------
local AdminFrozen = false

RegisterNetEvent("admin:toggleFreeze")
AddEventHandler("admin:toggleFreeze", function(state)
    local ped = PlayerPedId()
    AdminFrozen = state

    -- travar imediatamente
    ClearPedTasksImmediately(ped)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
    SetPedCanRagdoll(ped, not state)
    FreezeEntityPosition(ped, state)
    SetPlayerControl(PlayerId(), not state, 0) -- congela input real

    if state then
        -- loop anti-input
        CreateThread(function()
            while AdminFrozen do
                -- movimento a pé
                DisableControlAction(0, 30, true)   -- left/right
                DisableControlAction(0, 31, true)   -- fwd/back
                DisableControlAction(0, 21, true)   -- sprint
                DisableControlAction(0, 22, true)   -- jump
                DisableControlAction(0, 24, true)   -- attack
                DisableControlAction(0, 25, true)   -- aim
                DisableControlAction(0, 32, true)   -- W
                DisableControlAction(0, 33, true)   -- S
                DisableControlAction(0, 34, true)   -- A
                DisableControlAction(0, 35, true)   -- D
                -- em veículo
                DisableControlAction(0, 71, true)   -- acelera
                DisableControlAction(0, 72, true)   -- trava
                DisableControlAction(0, 63, true)   -- virar esq
                DisableControlAction(0, 64, true)   -- virar dir
                DisableControlAction(0, 75, true)   -- sair veículo
                DisableControlAction(0, 23, true)   -- entrar veículo
                Wait(0)
            end
        end)
    else
        -- restaurar
        EnableAllControlActions(0)
        SetPlayerControl(PlayerId(), true, 0)
        SetPedCanRagdoll(ped, true)
        FreezeEntityPosition(ped, false)
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- DESBUGAR: Death / Crawl / Handcuff / Tarefas / Colisões
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("admin:clearPlayerStates")
AddEventHandler("admin:clearPlayerStates", function()
    local ped = PlayerPedId()

    -- Death -> revive se necessário
    local isDead = IsEntityDead(ped) or (LocalPlayer and LocalPlayer.state and LocalPlayer.state.Death)
    if isDead then
        local c = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(c.x + 0.0, c.y + 0.0, c.z + 0.0, GetEntityHeading(ped), true, true, false)
        ClearPedBloodDamage(ped)
        SetEntityHealth(ped, 200)
        if LocalPlayer and LocalPlayer.state then
            LocalPlayer.state:set("Death", false, true)
        end
    end

    -- Crawl -> força off
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.Crawl then
        LocalPlayer.state:set("Crawl", false, true)
    end

    -- Respeita algemas: só limpa se NÃO estiver algemado
    local cuffed = LocalPlayer and LocalPlayer.state and LocalPlayer.state.Handcuff or false
    if not cuffed then
        SetEnableHandcuffs(ped, false)
        ClearPedTasksImmediately(ped)
        ClearPedSecondaryTask(ped)
        DetachEntity(ped, true, true)
        EnableAllControlActions(0)
    end

    -- Estados gerais
    ResetPedRagdollTimer(ped)
    SetPedCanRagdoll(ped, true)
    FreezeEntityPosition(ped, false)

    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        FreezeEntityPosition(veh, false)
        SetVehicleBrake(veh, false)
        SetVehicleHandbrake(veh, false)
    end
end)


---- FECHAR PERIMETRO

local vSERVER = Tunnel.getInterface("perimetro")

-- Interface client para o server chamar
local PERIMETRO_CLIENT = {}
Tunnel.bindInterface("perimetro", PERIMETRO_CLIENT)

function PERIMETRO_CLIENT.GetLocationLabel(coords)
    local x, y, z = coords.x + 0.0, coords.y + 0.0, coords.z + 0.0
    local s1, s2 = GetStreetNameAtCoord(x, y, z)
    local street  = s1 ~= 0 and GetStreetNameFromHashKey(s1) or nil
    local cross   = s2 ~= 0 and GetStreetNameFromHashKey(s2) or nil
    local zoneKey = GetNameOfZone(x, y, z)
    local zone    = (zoneKey and zoneKey ~= "") and GetLabelText(zoneKey) or nil

    local parts = {}
    if street and street ~= "" then table.insert(parts, street) end
    if cross and cross ~= "" then table.insert(parts, "x "..cross) end
    local left = table.concat(parts, " ")
    if left ~= "" and zone and zone ~= "" then
        return left.." — "..zone
    end
    if zone and zone ~= "" then return zone end
    if left ~= "" then return left end
    return ("%.1f, %.1f"):format(x, y) -- fallback
end

-- Estado
local PERIMETRO = {}
local BLIPS = {}
local inside = {}
local lastWarn = {}
local isPolice = false
local lastPoliceCheck = 0

-- Blips
local function createBlips(p)
    local rb = AddBlipForRadius(p.coords.x + 0.0, p.coords.y + 0.0, p.coords.z + 0.0, p.radius + 0.0)
    SetBlipColour(rb, 1)      -- vermelho
    SetBlipAlpha(rb, 120)

    local cb = AddBlipForCoord(p.coords.x, p.coords.y, p.coords.z)
    SetBlipSprite(cb, 60)     -- ícone polícia
    SetBlipColour(cb, 1)      -- vermelho
    SetBlipScale(cb, 0.9)
    SetBlipAsShortRange(cb, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(("🔴 ZONA PERIGOSA — %s"):format(p.name or "Local"))
    EndTextCommandSetBlipName(cb)

    BLIPS[p.id] = { rb, cb }
end

local function removeBlips(id)
    if BLIPS[id] then
        local rb, cb = table.unpack(BLIPS[id])
        if rb and DoesBlipExist(rb) then RemoveBlip(rb) end
        if cb and DoesBlipExist(cb) then RemoveBlip(cb) end
        BLIPS[id] = nil
    end
end

-- Sync
RegisterNetEvent("perimetro:syncAll")
AddEventHandler("perimetro:syncAll", function(list)
    for id,_ in pairs(BLIPS) do removeBlips(id) end
    PERIMETRO, inside, lastWarn = {}, {}, {}
    for id,data in pairs(list or {}) do
        PERIMETRO[id] = data
        createBlips(data)
    end
end)

RegisterNetEvent("perimetro:add")
AddEventHandler("perimetro:add", function(data)
    PERIMETRO[data.id] = data
    createBlips(data)
    TriggerEvent("Notify","🚧 Perímetro",("Ativado: <b>%s</b>. Cautela na área."):format(data.name or ("#"..data.id)),"azul",6000)
end)

RegisterNetEvent("perimetro:remove")
AddEventHandler("perimetro:remove", function(id)
    local old = PERIMETRO[id]
    PERIMETRO[id] = nil
    inside[id] = nil
    lastWarn[id] = nil
    removeBlips(id)
    local nome = old and old.name or ("#"..id)
    TriggerEvent("Notify","🚧 Perímetro",("Desativado: <b>%s</b>."):format(nome),"verde",4500)
end)

-- Pedir sync ao entrar/carregar
CreateThread(function()
    Wait(1500)
    TriggerServerEvent("perimetro:requestSync")
end)

-- Cache de permissão
CreateThread(function()
    while true do
        if GetGameTimer() - lastPoliceCheck > 5000 then
            lastPoliceCheck = GetGameTimer()
            local ok, res = pcall(function() return vSERVER.IsPolice() end)
            if ok then isPolice = res == true end
        end
        Wait(1000)
    end
end)

-- Avisos a civis
CreateThread(function()
    while true do
        local sleep = 750
        if not isPolice then
            local ped = PlayerPedId()
            local pcoords = GetEntityCoords(ped)
            for id, z in pairs(PERIMETRO) do
                local dist = #(pcoords - vector3(z.coords.x, z.coords.y, z.coords.z))
                if dist <= (z.radius + 0.1) then
                    sleep = 200
                    if not inside[id] then
                        inside[id] = true
                        lastWarn[id] = GetGameTimer()
                        TriggerEvent("Notify","🚨 ALERTA",
                            "Entraste numa <b>🔴 ZONA PERIGOSA</b> — <b>Afasta-te imediatamente!</b><br><i>Risco de bala perdida.</i>",
                            "vermelho", 9000)
                    else
                        local now = GetGameTimer()
                        if not lastWarn[id] or (now - lastWarn[id] >= 30000) then
                            lastWarn[id] = now
                            TriggerEvent("Notify","⚠️ Aviso",
                                "Continuas em <b>ZONA PERIGOSA</b>. Recuar da área é recomendado.",
                                "amarelo", 7000)
                        end
                    end
                else
                    if inside[id] then
                        inside[id] = false
                        TriggerEvent("Notify","✅ Seguro","Abandonaste a zona perigosa. Mantém-te atento.","verde",3500)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)


-----------------------------------------------------------------------------------------------------------------------------------------
-- RGB
-----------------------------------------------------------------------------------------------------------------------------------------
local rgbEnabled = false
local rgbThread = nil

local function setSynPlate(veh)
    SetVehicleNumberPlateText(veh, "SYNGOD")
end

local function startRGB(veh)
    if rgbThread then return end
    rgbThread = true
    CreateThread(function()
        local t = 0.0
        while rgbEnabled and DoesEntityExist(veh) do
            local r = math.floor((math.sin(t) * 0.5 + 0.5) * 255)
            local g = math.floor((math.sin(t + 2.094) * 0.5 + 0.5) * 255)
            local b = math.floor((math.sin(t + 4.188) * 0.5 + 0.5) * 255)

            -- Cor do carro
            SetVehicleCustomPrimaryColour(veh, r,g,b)
            SetVehicleCustomSecondaryColour(veh, r,g,b)

            -- Néons
            for i=0,3 do SetVehicleNeonLightEnabled(veh, i, true) end
            SetVehicleNeonLightsColour(veh, r,g,b)

            t = t + 0.05
            Wait(100)
        end
        rgbThread = nil
    end)
end

RegisterNetEvent("rgb:toggle")
AddEventHandler("rgb:toggle", function()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped,false) then
        TriggerEvent("Notify","RGB","Entra num veículo primeiro.", "amarelo", 5000)
        return
    end
    local veh = GetVehiclePedIsIn(ped,false)
    if GetPedInVehicleSeat(veh,-1) ~= ped then
        TriggerEvent("Notify","RGB","Precisas de estar ao volante.", "amarelo", 5000)
        return
    end

    rgbEnabled = not rgbEnabled
    if rgbEnabled then
        setSynPlate(veh)
        startRGB(veh)
        TriggerEvent("Notify","RGB","RGB <b>ATIVADO</b> com matrícula SYNGOD.", "verde", 5000)
    else
        TriggerEvent("Notify","RGB","RGB <b>DESATIVADO</b>.", "azul", 4000)
    end
end)


--------- INVIS


local invis = false
local collisionThread = nil

RegisterNetEvent("staff:ToggleInvis")
AddEventHandler("staff:ToggleInvis", function()
    local ped = PlayerPedId()
    invis = not invis

    if invis then
        -- Invisibilidade
        SetEntityVisible(ped,false,false)
        SetLocalPlayerVisibleLocally(true)
        SetEntityAlpha(ped,0,false)

        -- Esconder arma visível
        local currentWeapon = GetSelectedPedWeapon(ped)
        if currentWeapon and currentWeapon ~= `WEAPON_UNARMED` then
            local weaponObj = GetCurrentPedWeaponEntityIndex(ped, 0)
            if DoesEntityExist(weaponObj) then
                SetEntityVisible(weaponObj, false, false)
            end
        end

        -- Desativar colisão (loop para manter)
        collisionThread = CreateThread(function()
            while invis do
                local coords = GetEntityCoords(ped)
                -- Jogadores
                for _, player in ipairs(GetActivePlayers()) do
                    local otherPed = GetPlayerPed(player)
                    if otherPed ~= ped then
                        SetEntityNoCollisionEntity(ped, otherPed, true)
                        SetEntityNoCollisionEntity(otherPed, ped, true)
                    end
                end
                -- Veículos
                local veh = GetVehiclePedIsIn(ped, false)
                if veh > 0 then
                    for vehicle in EnumerateVehicles() do
                        if vehicle ~= veh then
                            SetEntityNoCollisionEntity(veh, vehicle, true)
                        end
                    end
                end
                Wait(0)
            end
        end)

        TriggerEvent("Notify","Staff","Invisibilidade e sem colisão ativadas.", "verde", 5000)
    else
        -- Visibilidade normal
        SetEntityVisible(ped,true,false)
        ResetEntityAlpha(ped)

        -- Mostrar arma de novo
        local currentWeapon = GetSelectedPedWeapon(ped)
        if currentWeapon and currentWeapon ~= `WEAPON_UNARMED` then
            local weaponObj = GetCurrentPedWeaponEntityIndex(ped, 0)
            if DoesEntityExist(weaponObj) then
                SetEntityVisible(weaponObj, true, false)
            end
        end

        -- Restaurar colisão
        SetEntityCollision(ped, true, true)
        local veh = GetVehiclePedIsIn(ped, false)
        if veh > 0 then
            SetEntityCollision(veh, true, true)
        end

        TriggerEvent("Notify","Staff","Invisibilidade e sem colisão desativadas.", "amarelo", 5000)
    end
end)

-- Enumerador de veículos (helper)
function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, veh = FindFirstVehicle()
        local success
        repeat
            coroutine.yield(veh)
            success, veh = FindNextVehicle(handle)
        until not success
        EndFindVehicle(handle)
    end)
end

-- =============================
-- Comandos /vec3 e /vec4 (Syn Network)
-- Requer o resource: syn_clipboard
-- =============================
RegisterCommand("vec3", function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local str = string.format("vec3(%.2f, %.2f, %.2f)", coords.x, coords.y, coords.z)

    local ok = pcall(function()
        return exports["syn_clipboard"]:Copy(str)
    end)

    if not ok then
        -- Fallback por evento (se preferires)
        TriggerEvent("syn_clipboard:Copy", str)
    end

    -- Também loga em consola para conferência
    print("[VEC3] "..str)
end)

RegisterCommand("vec4", function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local str = string.format("vec4(%.2f, %.2f, %.2f, %.2f)", coords.x, coords.y, coords.z, heading)

    local ok = pcall(function()
        return exports["syn_clipboard"]:Copy(str)
    end)

    if not ok then
        TriggerEvent("syn_clipboard:Copy", str)
    end

    print("[VEC4] "..str)
end)


-----------------------------------------------------------------------------------------------------------------------------------------
-- APLICAR PED TEMPORÁRIO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("staff:SetPedModel")
AddEventHandler("staff:SetPedModel", function(modelName)
    local hash = GetHashKey(modelName)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        TriggerEvent("Notify", "Sistema", "Modelo <b>inválido</b>.", "vermelho", 5000)
        return
    end

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- RESETAR PARA FREEMODE (M ou F consoante DB)
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("staff:ResetPedModel")
AddEventHandler("staff:ResetPedModel", function(sex, clothes, barber, tattoos)
    local modelName = (sex == "F") and "mp_f_freemode_01" or "mp_m_freemode_01"
    local hash = GetHashKey(modelName)

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)
    ped = PlayerPedId()

    -- garantir posição/heading inalterados
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, heading)
    SetPedDefaultComponentVariation(ped)

    -- aplica presets da DB (com segurança)
    if clothes and next(clothes) then
        pcall(function() exports["skinshop"]:Apply(clothes, ped) end)
    end
    if barber and next(barber) then
        pcall(function() exports["barbershop"]:Apply(barber, ped) end)
    end
    if tattoos and next(tattoos) then
        pcall(function() exports["tattooshop"]:Apply(tattoos, ped) end)
    end
end)

------------------------------------------------------ CURSOR

-- [RESCUE DO CURSOR] — Syn Network
-- Coloca isto em qualquer recurso client que carregue sempre.

local function ReleaseCursor(spamMs)
    spamMs = tonumber(spamMs) or 300
    local timeout = GetGameTimer() + spamMs

    -- força o clear várias frames (caso outro script esteja a re-setar)
    while GetGameTimer() < timeout do
        SetNuiFocus(false,false)
        SetNuiFocusKeepInput(false)
        -- recentra o cursor (opcional, ajuda a “soltar”)
        SetCursorLocation(0.5,0.5)
        -- garante controlo do jogador
        SetPlayerControl(PlayerId(), true, 0)
        Wait(0)
    end
end

-- Comando + Keybind (F10 por defeito)
RegisterCommand("fixcursor", function() ReleaseCursor(400) end)
RegisterKeyMapping("fixcursor","Libertar cursor preso (RESCUE)","keyboard","F10")

-- Evento público (para outros recursos chamarem)
RegisterNetEvent("cursor:release", function() ReleaseCursor(350) end)

-- Fecha sempre que o recurso do target para (ajusta o nome se precisares)
local TARGET_RESOURCE = "target"      -- <<-- muda para o nome do teu recurso de target, se for diferente
AddEventHandler("onResourceStop", function(res)
    if res == TARGET_RESOURCE or res == GetCurrentResourceName() then
        ReleaseCursor(250)
    end
end)

-- Fallback ao abrir o pause
CreateThread(function()
    local wasPaused = false
    while true do
        local paused = IsPauseMenuActive()
        if paused and not wasPaused then
            ReleaseCursor(200)
        end
        wasPaused = paused
        Wait(250)
    end
end)

-- Fallback no ESC/Backspace do frontend (solta caso algum menu NUI tenha crashado)
CreateThread(function()
    while true do
        -- 200=Pause, 322=ESC, 177=Backspace (frontend)
        if IsControlJustPressed(0,200) or IsControlJustPressed(0,322) or IsControlJustPressed(0,177) then
            ReleaseCursor(150)
        end
        Wait(0)
    end
end)

---------------------------------------------------------------------
-- SPEED BOOST (robusto: reaplica a cada frame)
---------------------------------------------------------------------
local Speed = { enabled = false, mult = 1.0, running = false }

RegisterNetEvent("admin:SpeedApply")
AddEventHandler("admin:SpeedApply", function(enable, mult)
    mult = tonumber(mult) or 1.0
    if mult < 1.0 then mult = 1.0 end
    if mult > 1.49 then mult = 1.49 end

    Speed.enabled = enable and mult > 1.0
    Speed.mult = mult

    if not Speed.enabled then
        -- reset
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        SetPedMoveRateOverride(PlayerPedId(), 1.0)
        return
    end

    if not Speed.running then
        Speed.running = true
        CreateThread(function()
            while Speed.enabled do
                local ped = PlayerPedId()
                -- aplicar continuamente (outros recursos podem resetar)
                SetRunSprintMultiplierForPlayer(PlayerId(), Speed.mult)
                SetPedMoveRateOverride(ped, Speed.mult)
                RestorePlayerStamina(PlayerId(), 1.0) -- evita cansar
                Wait(0) -- cada frame
            end
            -- reset ao sair do loop
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
            SetPedMoveRateOverride(PlayerPedId(), 1.0)
            Speed.running = false
        end)
    end
end)

-- segurança ao parar o resource
AddEventHandler("onResourceStop", function(res)
    if res == GetCurrentResourceName() then
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        SetPedMoveRateOverride(PlayerPedId(), 1.0)
    end
end)


---------------------------------------------------------------------
-- SINCRONIZAÇÃO LOCAL (opcional, dá jeito para outros scripts lerem)
-- O teu HUD envia "hud:Wanted" com os segundos restantes.
---------------------------------------------------------------------
RegisterNetEvent("hud:Wanted")
AddEventHandler("hud:Wanted", function(secondsLeft)
    local wanted = (tonumber(secondsLeft) or 0) > 0
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set("Wanted", wanted, true)
        LocalPlayer.state:set("WantedExpire", wanted and (GetCloudTimeAsInt() + secondsLeft) or nil, true)
    end
end)
