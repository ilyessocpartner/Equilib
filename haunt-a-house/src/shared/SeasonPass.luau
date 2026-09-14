--!nonstrict
-- Passe de saison : paliers, XP et recompenses (logique pure).
local SeasonPass = {}

SeasonPass.TierCount = 20

function SeasonPass.xpForTier(tier)
	return 1200 + 250 * tier
end

function SeasonPass.totalXpForTier(tier)
	local total = 0
	for t = 1, tier do
		total += SeasonPass.xpForTier(t)
	end
	return total
end

-- Palier atteint pour une quantite d'XP
function SeasonPass.tierForXp(xp)
	local tier = 0
	local acc = 0
	for t = 1, SeasonPass.TierCount do
		acc += SeasonPass.xpForTier(t)
		if xp >= acc then
			tier = t
		else
			break
		end
	end
	return tier
end

-- Progression dans le palier courant : xp dans le palier, xp requis
function SeasonPass.progress(xp)
	local tier = SeasonPass.tierForXp(xp)
	if tier >= SeasonPass.TierCount then
		return tier, 1, 1
	end
	local base = SeasonPass.totalXpForTier(tier)
	local need = SeasonPass.xpForTier(tier + 1)
	return tier, xp - base, need
end

local function coins(amount)
	return { Type = "Coins", Amount = amount }
end

SeasonPass.Rewards = {
	[1] = { Free = coins(500), Premium = coins(2500) },
	[2] = { Free = coins(800), Premium = { Type = "CoinsBoost", Minutes = 20 } },
	[3] = { Free = coins(1200), Premium = coins(5000) },
	[4] = { Free = { Type = "CoinsBoost", Minutes = 10 }, Premium = { Type = "LuckBoost", Minutes = 30 } },
	[5] = { Free = coins(2500), Premium = { Type = "NightmareCoffin", Amount = 2 } },
	[6] = { Free = coins(3500), Premium = coins(12000) },
	[7] = { Free = { Type = "LuckBoost", Minutes = 10 }, Premium = { Type = "CoinsBoost", Minutes = 45 } },
	[8] = { Free = coins(5000), Premium = coins(20000) },
	[9] = { Free = coins(6500), Premium = { Type = "LuckBoost", Minutes = 45 } },
	[10] = { Free = { Type = "NightmareCoffin", Amount = 1 }, Premium = { Type = "Monster", Id = "pass_phantom" } },
	[11] = { Free = coins(9000), Premium = coins(35000) },
	[12] = { Free = { Type = "CoinsBoost", Minutes = 15 }, Premium = { Type = "CoinsBoost", Minutes = 60 } },
	[13] = { Free = coins(12000), Premium = coins(50000) },
	[14] = { Free = coins(15000), Premium = { Type = "NightmareCoffin", Amount = 3 } },
	[15] = { Free = { Type = "LuckBoost", Minutes = 15 }, Premium = { Type = "LuckBoost", Minutes = 60 } },
	[16] = { Free = coins(20000), Premium = coins(80000) },
	[17] = { Free = coins(25000), Premium = { Type = "CoinsBoost", Minutes = 90 } },
	[18] = { Free = { Type = "NightmareCoffin", Amount = 1 }, Premium = { Type = "NightmareCoffin", Amount = 5 } },
	[19] = { Free = coins(35000), Premium = coins(150000) },
	[20] = { Free = { Type = "NightmareCoffin", Amount = 2 }, Premium = { Type = "Monster", Id = "season_reaper" } },
}

function SeasonPass.describe(reward)
	if reward.Type == "Coins" then
		return tostring(reward.Amount) .. " coins"
	elseif reward.Type == "CoinsBoost" then
		return "2x Coins " .. reward.Minutes .. " min"
	elseif reward.Type == "LuckBoost" then
		return "2x Chance " .. reward.Minutes .. " min"
	elseif reward.Type == "NightmareCoffin" then
		return reward.Amount .. " Cercueil(s) Cauchemar"
	elseif reward.Type == "Monster" then
		return "Monstre exclusif"
	end
	return "?"
end

return SeasonPass
