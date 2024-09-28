local rifiutiButtati = {}

RegisterServerEvent('registraRifiutoButtato')
AddEventHandler('registraRifiutoButtato', function()
    local playerId = source
    if not rifiutiButtati[playerId] then
        rifiutiButtati[playerId] = 0
    end
    rifiutiButtati[playerId] = rifiutiButtati[playerId] + 1
    TriggerClientEvent('ox_lib:notify', playerId, {title = 'inform',description = Config.Scritte.threwgarbage .. rifiutiButtati[playerId],type = 'inform', position = 'top'})
end)

RegisterServerEvent('vendiRifiutiServer')
AddEventHandler('vendiRifiutiServer', function()
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)

    if xPlayer then
        local numeroRifiutiButtati = rifiutiButtati[playerId] or 0

        if numeroRifiutiButtati > 0 then
            local pagamentoTotale = numeroRifiutiButtati * Config.Soldi
            rifiutiButtati[playerId] = 0
            xPlayer.addMoney(pagamentoTotale)
            TriggerClientEvent('ox_lib:notify', playerId, {title = 'Sell',description = Config.Scritte.selling .. pagamentoTotale,type = 'succes', position = 'top'})
        else
            TriggerClientEvent('ox_lib:notify', playerId, {title = 'Attention',description = Config.Scritte.nosell,type = 'inform', position = 'top'})
        end
    end
end)