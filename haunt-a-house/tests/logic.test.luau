-- Tests de la logique pure (economie, gacha, offres, recompenses, saison).
local Economy = require("./shared/Economy")
local GachaMath = require("./shared/GachaMath")
local Offers = require("./shared/Offers")
local DailyRewards = require("./shared/DailyRewards")
local SeasonPass = require("./shared/SeasonPass")
local CoffinData = require("./shared/CoffinData")
local MonsterData = require("./shared/MonsterData")
local Rarity = require("./shared/Rarity")
local Config = require("./shared/Config")

local failures = 0
local function check(cond, msg)
	if not cond then
		failures += 1
		print("  ECHEC : " .. msg)
	end
end

-- Formatage
check(Economy.format(999) == "999", "format 999")
check(Economy.format(1000) == "1K", "format 1K got " .. Economy.format(1000))
check(Economy.format(1500) == "1.5K", "format 1.5K got " .. Economy.format(1500))
check(Economy.format(2500000) == "2.5M", "format 2.5M got " .. Economy.format(2500000))
check(Economy.format(123456789) == "123M", "format 123M got " .. Economy.format(123456789))
check(Economy.formatTime(3661) == "1:01:01", "formatTime")

-- Salles
check(Economy.roomCount(0, 0, false, false) == 3, "rooms base")
check(Economy.roomCount(10, 10, true, true) == 18, "rooms max")

-- Rebirth
check(Economy.rebirthCost(0) == 25000, "rebirth cost 1")
check(Economy.rebirthCost(6) == 150000000, "rebirth cost 7 got " .. Economy.rebirthCost(6))
check(Economy.rebirthMultiplier(2) == 2, "rebirth mult")
check(Economy.incomeMultiplier({ Rebirths = 0 }) == 1, "income mult base")
check(math.abs(Economy.incomeMultiplier({ Rebirths = 1, DoubleCoins = true, VIP = true }) - 3.75) < 1e-9, "income mult stack")
check(Economy.luckMultiplier({ LuckyPass = true, LuckBoost = true, ServerLuck = true }) == 8, "luck stack")

-- Coherence des donnees : chaque contenu de cercueil existe, poids > 0
for _, coffin in ipairs(CoffinData.List) do
	local total = 0
	for _, entry in ipairs(coffin.Contents) do
		check(MonsterData.ById[entry.Id] ~= nil, "monstre inconnu " .. entry.Id)
		check(entry.Weight > 0, "poids nul " .. entry.Id)
		total += entry.Weight
	end
	check(math.abs(total - 100) < 1e-6, "poids du cercueil " .. coffin.Id .. " = " .. total)
end
for _, def in ipairs(MonsterData.List) do
	check(Rarity.Info[def.Rarity] ~= nil, "rarete inconnue " .. def.Id)
	check(def.Power > 0, "power " .. def.Id)
	check(def.Visual ~= nil, "visual " .. def.Id)
end
check(MonsterData.ById[Config.StarterPack.MonsterId] ~= nil, "monstre du starter pack")

-- Gacha : odds somment a 1, la chance augmente les rares
local function entries(coffin)
	local list = {}
	for _, e in ipairs(coffin.Contents) do
		table.insert(list, { Id = e.Id, Weight = e.Weight, Rank = Rarity.rank(MonsterData.ById[e.Id].Rarity) })
	end
	return list
end
local wooden = entries(CoffinData.ById.wooden)
local odds1 = GachaMath.weighted(wooden, 1)
local odds2 = GachaMath.weighted(wooden, 2)
local sum = 0
for _, e in ipairs(odds1) do
	sum += e.Chance
end
check(math.abs(sum - 1) < 1e-9, "somme odds")
check(odds2[4].Chance > odds1[4].Chance, "luck augmente rare")
check(odds2[1].Chance < odds1[1].Chance, "luck baisse commun")

-- Tirage deterministe : rng constant
check(GachaMath.roll(wooden, 1, function() return 0 end) == "ghosty", "roll min")
check(GachaMath.roll(wooden, 1, function() return 0.999999 end) == "mini_reaper", "roll max")
-- Distribution statistique
local counts = {}
local N = 200000
local seed = 42
local function rng()
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648
end
for _ = 1, N do
	local id = GachaMath.roll(wooden, 1, rng)
	counts[id] = (counts[id] or 0) + 1
end
check(math.abs(counts.ghosty / N - 0.6) < 0.01, "distribution ghosty " .. counts.ghosty / N)
check(math.abs((counts.skelly or 0) / N - 0.045) < 0.005, "distribution skelly")

-- Valeur de revente < cout du cercueil (pas de boucle infinie)
for _, coffin in ipairs(CoffinData.List) do
	if not coffin.EventOnly then
		local ev = 0
		for _, e in ipairs(coffin.Contents) do
			ev += (e.Weight / 100) * Economy.sellPrice(MonsterData.ById[e.Id].Rarity, coffin.Cost)
		end
		check(ev < coffin.Cost * 0.6, "EV revente trop haute " .. coffin.Id .. " = " .. ev / coffin.Cost)
	end
end

-- Offres flash
local idx, deal, remaining = Offers.getFlashDeal(0)
check(idx == 1 and deal.Key == "FlashCoinVault" and remaining == 8 * 3600, "flash deal t0")
local idx2 = Offers.getFlashDeal(8 * 3600 + 1)
check(idx2 == 2, "flash deal rotation")
check(Offers.starterRemaining(1000, false, 1000 + 3600) == 24 * 3600 - 3600, "starter remaining")
check(Offers.starterRemaining(1000, false, 1000 + 25 * 3600) == 0, "starter expired")
check(Offers.starterRemaining(1000, true, 1000) == 0, "starter purchased")

-- Recompenses quotidiennes
local e1 = DailyRewards.evaluate(0, 0, 1000)
check(e1.CanClaim and e1.Streak == 1, "daily first")
local e2 = DailyRewards.evaluate(1000, 1, 1000 + 3600)
check(not e2.CanClaim, "daily too soon")
local e3 = DailyRewards.evaluate(1000, 3, 1000 + 25 * 3600)
check(e3.CanClaim and e3.Streak == 4 and not e3.Reset, "daily continue")
local e4 = DailyRewards.evaluate(1000, 3, 1000 + 60 * 3600)
check(e4.CanClaim and e4.Streak == 1 and e4.Reset, "daily reset")
check(DailyRewards.dayForStreak(7) == 7 and DailyRewards.dayForStreak(8) == 1, "daily cycle")

-- Saison
check(SeasonPass.tierForXp(0) == 0, "season tier 0")
check(SeasonPass.tierForXp(SeasonPass.xpForTier(1)) == 1, "season tier 1")
check(SeasonPass.tierForXp(1e9) == 20, "season tier max")
local tier, cur, need = SeasonPass.progress(SeasonPass.xpForTier(1) + 10)
check(tier == 1 and cur == 10 and need == SeasonPass.xpForTier(2), "season progress")
for t = 1, SeasonPass.TierCount do
	check(SeasonPass.Rewards[t] ~= nil and SeasonPass.Rewards[t].Free and SeasonPass.Rewards[t].Premium, "reward tier " .. t)
end
print("XP total saison : " .. SeasonPass.totalXpForTier(20))

if failures == 0 then
	print("OK : tous les tests passent")
else
	print(failures .. " test(s) en echec")
	error("tests en echec")
end
