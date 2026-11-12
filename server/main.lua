local OxInventory = exports.ox_inventory

local function getJobVehicle(playerId)
    local nearbyVehicles = {}

    local vehicles = GetGamePool('CVehicle')

    for i = 1, #vehicles do
        local veh = vehicles[i]
        if DoesEntityExist(veh) then
            local vehCoords = GetEntityCoords(veh)

            if Entity(veh).state.garbagecollectorjob == playerId then
                return veh
            end
        end
    end

    return nil
end

lib.callback.register('garbageCollectorJob:server:spawnJobVeh', function (source, getIntoVeh)
    local playerId = source

    local jobVeh = getJobVehicle(playerId)
    if DoesEntityExist(jobVeh) then
        local maxDist = Config.Vehicle.CheckDistance or 10.0
        local origin = GetEntityCoords(GetPlayerPed(playerId))
        --local isJobVehNear = #(origin - GetEntityCoords(jobVeh)) <= maxDist

        TriggerClientEvent('ox_lib:notify', playerId, { title = 'Errore', description = 'Hai già il veicolo del lavoro!', type = 'error' })
        return
    end

    local playerPed = GetPlayerPed(playerId)
    local coords = Config.Vehicle.SpawnPoint

    local modelHash = Config.Vehicle.Model

    local vehicle = CreateVehicleServerSetter(modelHash, "automobile", coords.x, coords.y, coords.z, coords.w)

    Wait(200)

    if DoesEntityExist(vehicle) then
        --if getIntoVeh then SetPedIntoVehicle(playerPed, vehicle, -1) end
        Entity(vehicle).state:set('garbagecollectorjob', playerId, true)
        print("Veicolo spawnato correttamente (ID entità: " .. vehicle .. ") ")
        return NetworkGetNetworkIdFromEntity(vehicle)
    else
        print("Errore nel spawn del veicolo")
    end
end)

RegisterNetEvent('garbageCollectorJob:server:spawnJobVeh', function (getIntoVeh)
    
end)

RegisterNetEvent('garbageCollectorJob:server:removeJobVeh', function ()
    local playerId = source

    local jobVeh = getJobVehicle(playerId)
    if DoesEntityExist(jobVeh) then
        local maxDist = Config.Vehicle.CheckDistance or 10.0
        local origin = GetEntityCoords(GetPlayerPed(playerId))
        local isJobVehNear = #(origin - GetEntityCoords(jobVeh)) > maxDist

        if isJobVehNear then
            TriggerClientEvent('ox_lib:notify', playerId, { title = 'GarbageCollectorJob', description = 'Il veicolo è troppo lontano!', type = 'error' })
            return
        end

        DeleteEntity(jobVeh)
        TriggerClientEvent('ox_lib:notify', playerId, { title = 'GarbageCollectorJob', description = 'Veicolo depositato', type = 'success' })
    else
        TriggerClientEvent('ox_lib:notify', playerId, { title = 'GarbageCollectorJob', description = 'Il veicolo non esiste!', type = 'error' })
    end
end)

RegisterNetEvent('garbageCollectorJob:server:giveGarbageBag', function()
    local itemName = Config.GarbageItem
    local src = source
    
    if OxInventory:CanCarryItem(src, itemName, 1) then
        OxInventory:AddItem(src, itemName, 1)
        
        TriggerClientEvent('ox_lib:notify', src, { title = 'GarbageCollectorJob', description = 'Sacco preso!', type = 'success' })
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'GarbageCollectorJob', description = "Non hai spazio nell'inventario!", type = 'error' })
    end
end)

RegisterNetEvent('garbageCollectorJob:server:transferGarbagebagToVeh', function(plate)
    local itemName = Config.GarbageItem
    local src = source
    
    local trunkInventoryId = "trunk" .. plate

    local playerItem = OxInventory:GetItem(src, itemName, nil, false)
    
    if playerItem and playerItem.count > 0 then
        if OxInventory:CanCarryItem(trunkInventoryId, itemName, playerItem.count) then

            OxInventory:RemoveItem(src, itemName, playerItem.count)
            OxInventory:AddItem(trunkInventoryId, itemName, playerItem.count)
            
            TriggerClientEvent('ox_lib:notify', src, { title = 'Successo', description = 'Sacco caricato nel camion!', type = 'success' })
        else
            TriggerClientEvent('ox_lib:notify', src, { title = 'Errore', description = 'Il cassone del camion è pieno!', type = 'error' })
        end
    end
end)

RegisterNetEvent('garbageCollectorJob:server:giveMoney', function()
    local itemName = Config.GarbageItem
    local src = source

    local jobVeh = getJobVehicle(src)
    if DoesEntityExist(jobVeh) then
        local maxDist = Config.Vehicle.CheckDistance or 10.0
        local origin = GetEntityCoords(GetPlayerPed(src))
        local isJobVehNear = #(origin - GetEntityCoords(jobVeh)) > maxDist

        if isJobVehNear then
            TriggerClientEvent('ox_lib:notify', src, { title = 'GarbageCollectorJob', description = 'Il veicolo è troppo lontano!', type = 'error' })
            return
        end

        local playerItem = OxInventory:GetItem(src, itemName, nil, false)
    
        if playerItem and playerItem.count > 0 then
            OxInventory:RemoveItem(src, itemName, playerItem.count)
            OxInventory:AddItem(src, 'cash', playerItem.count * Config.MoneyRewardAmountPerBag)
            
            TriggerClientEvent('ox_lib:notify', src, { title = 'Successo', description = 'Hai consegnato i rifiuti!', type = 'success' })
        else
            TriggerClientEvent('ox_lib:notify', src, { title = 'Errore', description = 'Non hai i rifiuti', type = 'error' })
        end

    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'GarbageCollectorJob', description = 'Non hai il veicolo del lavoro', type = 'error' })
    end
end)