--!nonstrict
-- Rebirth : remise a zero contre un multiplicateur permanent et des deblocages.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Shared.Economy)

local RebirthService = {}
local S

function RebirthService.perform(player, free)
	local data = S.Data.get(player)
	if not data then
		return { ok = false, message = "Données non chargées." }
	end
	local cost = Economy.rebirthCost(data.Rebirths)
	if not free and data.Coins < cost then
		return { ok = false, message = "Il te manque " .. Economy.format(cost - data.Coins) .. " coins pour ce rebirth." }
	end
	data.Coins = 0
	data.Rebirths += 1
	S.Inventory.wipeForRebirth(player)
	local st = S.Economy.getState(player)
	st.Uncollected = 0
	S.Plot.updateBooth(player, 0)
	S.Economy.recalculate(player)
	S.Plot.refreshPads(player)
	S.Player.sendState(player)
	S.Net.announce("♻️ " .. player.DisplayName .. " vient de faire son rebirth n°" .. data.Rebirths .. " ! (x" .. Economy.rebirthMultiplier(data.Rebirths) .. " coins)", "rebirth")
	S.Net.fire(player, "RebirthDone", { Rebirths = data.Rebirths, Multiplier = Economy.rebirthMultiplier(data.Rebirths) })
	return { ok = true, data = { Rebirths = data.Rebirths } }
end

function RebirthService.init(services)
	S = services
	S.Net.register("Rebirth", "Shop", function(player)
		return RebirthService.perform(player, false)
	end)
end

return RebirthService
