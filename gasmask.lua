-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES (GasMask)
-----------------------------------------------------------------------------------------------------------------------------------------
local GasMask = nil
local HasGasMask = false
local GAS_STATE_KEY = "GasMask" -- lido pelo script da smoke

-- offsets/rotação 
local GAS_MODEL  = "p_s_scuba_mask_s"
local GAS_BONEID = 12844
local GAS_OFFS   = vec3(0.0, 0.0, 0.0)
local GAS_ROTS   = vec3(180.0, 90.0, 0.0)

local function SetGasMaskState(on)
    HasGasMask = on and true or false
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set(GAS_STATE_KEY, HasGasMask, true)
    end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:GASMASKREMOVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:GasMaskRemove")
AddEventHandler("inventory:GasMaskRemove", function()
    if DoesEntityExist(GasMask) then
        TriggerServerEvent("DeleteObject", ObjToNet(GasMask))
        GasMask = nil
    end
    if HasGasMask then
        TriggerEvent("Notify","Inventário","Removeste a <b>máscara de gás</b>.","amarelo",3500)
    end
    SetGasMaskState(false)
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:GASMASK (toggle: equipa/retira)
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:GasMask")
AddEventHandler("inventory:GasMask", function()
    if GasMask ~= nil and DoesEntityExist(GasMask) then
        -- já equipada -> remove
        TriggerEvent("inventory:GasMaskRemove")
        return
    end

    -- equipa
    local Ped = PlayerPedId()
    local Coords = GetEntityCoords(Ped)

    local Progression, Network = vRPS.CreateObject(GAS_MODEL, Coords.x, Coords.y, Coords.z)
    if Progression then
        GasMask = LoadNetwork(Network)
    end

    -- fallback local se necessário
    if not GasMask or not DoesEntityExist(GasMask) then
        local hash = GetHashKey(GAS_MODEL)
        if not HasModelLoaded(hash) then
            RequestModel(hash)
            local dl = GetGameTimer() + 2500
            while not HasModelLoaded(hash) and GetGameTimer() < dl do Wait(0) end
        end
        if HasModelLoaded(hash) then
            GasMask = CreateObjectNoOffset(hash, Coords.x, Coords.y, Coords.z, false, false, false)
        end
    end

    if GasMask and DoesEntityExist(GasMask) then
        AttachEntityToEntity(
            GasMask, Ped, GetPedBoneIndex(Ped, GAS_BONEID),
            GAS_OFFS.x, GAS_OFFS.y, GAS_OFFS.z,
            GAS_ROTS.x, GAS_ROTS.y, GAS_ROTS.z,
            true, true, false, false, 2, true
        )
        SetEntityCollision(GasMask, false, false)
        SetEntityInvincible(GasMask, true)

        SetGasMaskState(true)
        TriggerEvent("Notify","Inventário","<b>Máscara de gás</b> equipada.","azul",4000)
    else
        TriggerEvent("Notify","Inventário","Não foi possível equipar a <b>máscara de gás</b>.","vermelho",5000)
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- SAFETY: limpa se morrer / prop perdido
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
    while true do
        if HasGasMask then
            local ped = PlayerPedId()
            if (not DoesEntityExist(ped)) or IsEntityDead(ped) or (not GasMask) or (not DoesEntityExist(GasMask)) then
                TriggerEvent("inventory:GasMaskRemove")
            end
        end
        Wait(1000)
    end
end)
