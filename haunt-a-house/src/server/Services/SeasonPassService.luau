--!nonstrict
-- Passe de saison : XP, paliers, recompenses gratuites et premium.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local SeasonPass = require(ReplicatedStorage.Shared.SeasonPass)

local SeasonPassService = {}
local S

function SeasonPassService.addXp(player, amount)
	local data = S.Data.get(player)
	if not data or amount <= 0 then
		return
	end
	if os.time() > Config.Season.EndsAt then
		return
	end
	local before = SeasonPass.tierForXp(data.Season.Xp)
	data.Season.Xp += amount
	player:SetAttribute("SeasonXp", data.Season.Xp)
	local after = SeasonPass.tierForXp(data.Season.Xp)
	if after > before then
		S.Net.notify(player, "🎃 Passe Spooky : palier " .. after .. " atteint ! Récupère ta récompense.", "success")
	end
end

function SeasonPassService.claim(player, tier, premium)
	local data = S.Data.get(player)
	tier = tonumber(tier)
	if not tier or tier < 1 or tier > SeasonPass.TierCount or tier % 1 ~= 0 then
		return { ok = false, message = "Palier invalide." }
	end
	if SeasonPass.tierForXp(data.Season.Xp) < tier then
		return { ok = false, message = "Tu n'as pas encore atteint ce palier." }
	end
	local rewards = SeasonPass.Rewards[tier]
	local claimed = premium and data.Season.ClaimedPremium or data.Season.ClaimedFree
	local key = tostring(tier)
	if claimed[key] then
		return { ok = false, message = "Récompense déjà récupérée." }
	end
	if premium and not S.Shop.ownsPass(player, "SeasonPremium") then
		return { ok = false, message = "Le Passe Spooky Premium est nécessaire pour cette récompense." }
	end
	local reward = premium and rewards.Premium or rewards.Free
	local text = S.Reward.grant(player, reward, true)
	claimed[key] = true
	S.Player.sendState(player)
	S.Net.notify(player, "🎃 Palier " .. tier .. " : " .. tostring(text), "success")
	return { ok = true, message = text }
end

function SeasonPassService.init(services)
	S = services
	S.Net.register("ClaimSeason", "Shop", function(player, payload)
		return SeasonPassService.claim(player, payload.Tier, payload.Premium == true)
	end)
end

return SeasonPassService
