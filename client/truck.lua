local isAttached = false
local side = nil
local currentTruck = nil

local function attachPedSx(veh)
    local playerPed = PlayerPedId()

    -- Disattiva le collisioni (evita che il camion ti respinga)
    SetEntityCollision(playerPed, false, false)

    AttachEntityToEntity(
        playerPed, veh, 0, 
        -1.0, -5.0, 0.5, 
        0.0, 0.0, 0.0, 
        false, false, false, true, 0, true
    )
end

local function attachPedDx(veh)
    local playerPed = PlayerPedId()
    -- Disable collisions
    SetEntityCollision(playerPed, false, false)

    AttachEntityToEntity(
        playerPed, veh, 0, 
        1.0, -5.0, 0.5, 
        0.0, 0.0, 0.0, 
        false, false, false, true, 0, true
    )
end

local function detachPed()
    isAttached = false
    DetachEntity(PlayerPedId(), true, true)
    SetEntityCollision(PlayerPedId(), true, true)
end

CreateThread(function()
    exports.ox_target:addModel(Config.Vehicle.Model, {
            {
            name = 'trash',
            icon = 'fas fa-trash',
            label = 'Deposita Rifiuti',
            canInteract = function(entity, distance, coords, name, bone)
                local playerPed = PlayerPedId()
                
                local playerCoords = GetEntityCoords(playerPed)
                local trunkDoor = 5
                local isDoorOpen = GetVehicleDoorAngleRatio(entity, trunkDoor) > 0.0

                if not CurrentGarbageProp or not DoesEntityExist(CurrentGarbageProp) then
                    return false -- Non puoi interagire se non hai un sacco di rifiuti
                end

                if distance > 2.0 then
                    return false -- Troppo lontano dal veicolo
                end

                if not isDoorOpen then
                    return false -- Il portellone del veicolo deve essere aperto
                end

                return true -- Tutte le condizioni sono soddisfatte
            end,
            onSelect = function(data)

                if not CurrentGarbageProp or not DoesEntityExist(CurrentGarbageProp) then
                    lib.notify({
                        title = 'Raccolta Rifiuti',
                        description = 'Non hai un sacco di rifiuti da depositare.',
                        type = 'error'
                    })
                    return
                end


                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)
                local trunkDoor = 5
                local isDoorOpen = GetVehicleDoorAngleRatio(data.entity, trunkDoor) > 0.0

                removeGarbageBag()

                if not isDoorOpen then
                    -- Apre la porta (false = animazione fluida, false = non istantaneo)
                    SetVehicleDoorOpen(data.entity, trunkDoor, false, false)
                    print("Portellone aperto.")
                end

                local plate = GetVehicleNumberPlateText(data.entity)

                TriggerServerEvent('garbageCollectorJob:server:transferGarbagebagToVeh', plate)

                Wait(1000)

                -- Close the trash's "door"
                SetVehicleDoorShut(data.entity, trunkDoor, false)
                print("Portellone chiuso.")

            end,
        },
        {
            name = 'trash',
            icon = 'fas fa-door-closed',
            label = 'Apri/Chiudi Portellone',
            canInteract = function(entity, distance, coords, name, bone)
                return true
            end,
            onSelect = function(data)
                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)
                local trunkDoor = 5
                local isDoorOpen = GetVehicleDoorAngleRatio(data.entity, trunkDoor) > 0.0

                if not isDoorOpen then
                    -- Apre la porta (false = animazione fluida, false = non istantaneo)
                    SetVehicleDoorOpen(data.entity, trunkDoor, false, false)
                    print("Portellone aperto.")
                else
                    -- Close the trash's "door"
                    SetVehicleDoorShut(data.entity, trunkDoor, false)
                    print("Portellone chiuso.")
                end

            end,
        },
        {
            name = 'trash_attach_dx',
            icon = 'fa-solid fa-link',
            label = 'Aggancio Destra',
            distance = 3.0,
            onSelect = function(data)
                local playerPed = PlayerPedId()
                local camion = data.entity

                print(side)

                if not isAttached then
                    -- 1. SALI SUL CAMION
                    isAttached = true
                    side = 'dx'
                    currentTruck = camion

                    attachPedDx(camion)
                    -- Attacco super essenziale:
                    -- X: 0.0 (centro), Y: -3.0 (dietro), Z: 0.0 (altezza)
                    --[[AttachEntityToEntity(
                        playerPed, camion, 0, 
                        1.0, -5.0, 0.5, 
                        0.0, 0.0, 0.0, 
                        false, false, false, true, 0, true
                    )]]--
                    
                    print("ATTACCATO! Premi X per scendere.")
                else
                    detachPed()
                    side = nil
                    currentTruck = nil
                    -- Change side
                    if side == 'sx' then
                        side = 'dx'
                        attachPedDx(camion)
                        print("Cambio lato: ora sei a destra.")
                    else
                        detachPed()
                        side = nil
                        currentTruck = nil
                        print("Sei già a destra.")
                    end
                end
            end
        },
        {
            name = 'trash_attach_sx',
            icon = 'fa-solid fa-link',
            label = 'Aggancio Sinistra',
            distance = 3.0,
            onSelect = function(data)
                local playerPed = PlayerPedId()
                local camion = data.entity

                print(side)

                if not isAttached then
                    -- 1. SALI SUL CAMION
                    isAttached = true
                    side = 'sx'
                    currentTruck = camion

                    attachPedSx(camion)
                    -- Attacco super essenziale:
                    -- X: 0.0 (centro), Y: -3.0 (dietro), Z: 0.0 (altezza)
                    --[[AttachEntityToEntity(
                        playerPed, camion, 0, 
                        -1.0, -5.0, 0.5, 
                        0.0, 0.0, 0.0, 
                        false, false, false, true, 0, true
                    )]]--
                    
                    print("ATTACCATO! Premi X per scendere.")
                else
                    
                    -- Change side
                    if side == 'dx' then
                        side = 'sx'
                        attachPedSx(camion)
                        print("Cambio lato: ora sei a sinistra.")
                    else
                        detachPed()
                        side = nil
                        currentTruck = nil
                        print("Sei già a sinistra.")
                    end
                end
            end
        }
    })
end)

-- Tasto X di emergenza per scendere se non riesci a mirare il target
CreateThread(function()
    while true do
        if isAttached then
            if IsControlJustPressed(0, 73) then -- Tasto X
                detachPed()
                currentTruck = nil
                print("STACCATO!")
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)
