local function spawnLocalPed(coords, modelHash)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(0)
    end

    -- Genera il ped localmente
    local ped = CreatePed(0, modelHash, coords.x, coords.y, coords.z - 1.0, coords.w or 0.0, false, false)
    
    -- Configura le proprietà per renderlo un NPC statico da negozio/interazione
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)

    SetModelAsNoLongerNeeded(modelHash)
    return ped
end

-- Configurazione del Punto con ox_lib
lib.points.new({
    coords = vec3(Config.PedPosition.x, Config.PedPosition.y, Config.PedPosition.z), -- Modifica con le tue coordinate
    distance = 40,
    onEnter = function(self)
        local model = Config.PedModel
        
        self.pedHandle = spawnLocalPed(vec4(self.coords.x, self.coords.y, self.coords.z, Config.PedPosition.w), model)

        exports.ox_target:addLocalEntity(self.pedHandle, {
            {
                name = 'spawn_garbage-collector_vehicle',
                icon = 'fas --comment', -- Icona di FontAwesome
                label = 'Prendi veicolo', -- Testo visibile a schermo
                distance = 2.5, -- Distanza massima per interagire
                onSelect = function(data)
                    local netVeh = lib.callback.await('garbageCollectorJob:server:spawnJobVeh', false, true)
                    local veh = NetworkGetEntityFromNetworkId(netVeh)
                    local plate = GetVehicleNumberPlateText(veh)
                    
                    Config.Vehicle.GetVehicleKeys(plate)

                    -- Teleport ped into the veh
                    SetPedIntoVehicle(cache.ped, veh, -1)

                end,
                canInteract = function()
                    return IsJobActive
                end
            },
            {
                name = 'remove_garbage-collector_vehicle',
                icon = 'fas --comment', -- Icona di FontAwesome
                label = 'Deposita veicolo', -- Testo visibile a schermo
                distance = 2.5, -- Distanza massima per interagire
                onSelect = function(data)
                    TriggerServerEvent('garbageCollectorJob:server:removeJobVeh')
                end,
                canInteract = function()
                    return IsJobActive
                end
            },
            {
                name = 'get_dressed_garbage-collector_clothes',
                icon = 'fas --comment', -- Icona di FontAwesome
                label = 'Indossa / Rimuovi abiti da lavoro', -- Testo visibile a schermo
                distance = 2.5, -- Distanza massima per interagire
                onSelect = function(data)
                    if IsWearingJobsClothes then
                        RemoveJobsClothes()
                        lib.notify({
                            title = "Vestiti lavoro rimossi",
                            description = "Hai rimosso i vestiti da lavoro.",
                            type = "success"
                        })
                    else
                        SavePlayerClothes()
                        Wait(200)
                        WearJobsClothes()
                        lib.notify({
                            title = "Vestiti lavoro indossati",
                            description = "Hai indossato i vestiti da lavoro.",
                            type = "success"
                        })
                    end
                end,
                canInteract = function()
                    return IsJobActive
                end
            }
        })
    end,
    onExit = function(self)
        if self.pedHandle and DoesEntityExist(self.pedHandle) then
            exports.ox_target:removeLocalEntity(self.pedHandle)
            DeleteEntity(self.pedHandle)
            self.pedHandle = nil
        end
    end
})
