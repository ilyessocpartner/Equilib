--!nonstrict
-- Distribution des recompenses (quotidien, temps de jeu, saison, codes, offres).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Shared.Economy)
local MonsterData = require(ReplicatedStorage.Shared.MonsterData)

local RewardService = {}
local S

function RewardService.init(services)
	S = services
end

-- Applique une recompense et retourne un texte descriptif.
-- reward : { Type = "Coins"|"CoinsBoost"|"LuckBoost"|"NightmareCoffin"|"Monster", ... }
function RewardService.grant(player, reward, scaleWithRebirth)
	local data = S.Data.get(player)
	if not data then
		return nil
	end
	if reward.Type == "Coins" then
		local amount = reward.Amount
		if scaleWithRebirth ~= false then
			amount = math.floor(amount * Economy.rebirthMultiplier(data.Rebirths))
		end
		S.Economy.addCoins(player, amount)
		return "+" .. Economy.format(amount) .. " coins"
	elseif reward.Type == "CoinsBoost" then
		local seconds = reward.Seconds or (reward.Minutes or 0) * 60
		S.Economy.addBoost(player, "Coins", seconds)
		return "2x Coins pendant " .. math.floor(seconds / 60) .. " min"
	elseif reward.Type == "LuckBoost" then
		local seconds = reward.Seconds or (reward.Minutes or 0) * 60
		S.Economy.addBoost(player, "Luck", seconds)
		return "2x Chance pendant " .. math.floor(seconds / 60) .. " min"
	elseif reward.Type == "NightmareCoffin" then
		data.NightmareCoffins += (reward.Amount or 1)
		player:SetAttribute("NightmareCoffins", data.NightmareCoffins)
		return (reward.Amount or 1) .. " Cercueil(s) Cauchemar"
	elseif reward.Type == "Monster" then
		local def = MonsterData.get(reward.Id)
		if not def then
			return nil
		end
		S.Inventory.addMonster(player, reward.Id, true)
		return "Monstre exclusif : " .. def.Name
	end
	return nil
end

return RewardService
