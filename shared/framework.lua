Framework = {
    name = 'standalone'
}
local function setAutoFramework()
    if Config.Framework ~= 'auto' then
        Framework.name = Config.Framework
    elseif GetResourceState('es_extended') == 'started' then
        Framework.name = 'esx'
    elseif GetResourceState('qb_core') == 'started' then
        Framework.name = 'qb'
    elseif GetResourceState('qbx_core') == 'started' then
        Framework.name = 'qbx'
    elseif GetResourceState('ox_core') == 'started' then
        Framework.name = 'ox'
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    -- Verifica che l'evento sia scattato per QUESTA risorsa e non per altre
    if GetCurrentResourceName() ~= resourceName then return end
    
    setAutoFramework()
    print('[GarbageCollectorJob] Set framework to ' .. Framework.name)
end)