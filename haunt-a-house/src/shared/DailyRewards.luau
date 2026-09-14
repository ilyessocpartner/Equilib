--!nonstrict
-- Recompenses quotidiennes avec serie (streak). Logique pure.
local DailyRewards = {}

DailyRewards.Cycle = {
	{ Day = 1, Type = "Coins", Amount = 500, Label = "500 coins" },
	{ Day = 2, Type = "Coins", Amount = 1000, Label = "1 000 coins" },
	{ Day = 3, Type = "Coins", Amount = 2500, Label = "2 500 coins" },
	{ Day = 4, Type = "CoinsBoost", Minutes = 20, Label = "2x Coins 20 min" },
	{ Day = 5, Type = "Coins", Amount = 8000, Label = "8 000 coins" },
	{ Day = 6, Type = "LuckBoost", Minutes = 20, Label = "2x Chance 20 min" },
	{ Day = 7, Type = "NightmareCoffin", Amount = 1, Coins = 30000, Label = "Cercueil Cauchemar + 30 000 coins" },
}

DailyRewards.ClaimInterval = 20 * 3600 -- on peut reclamer apres 20h (tolerance)
DailyRewards.StreakBreak = 48 * 3600 -- serie perdue apres 48h sans reclamer

-- Retourne { CanClaim, SecondsUntil, Streak (serie apres reclamation), Reset }
function DailyRewards.evaluate(lastClaim, streak, now)
	lastClaim = lastClaim or 0
	streak = streak or 0
	if lastClaim <= 0 then
		return { CanClaim = true, SecondsUntil = 0, Streak = 1, Reset = false }
	end
	local elapsed = now - lastClaim
	if elapsed < DailyRewards.ClaimInterval then
		return { CanClaim = false, SecondsUntil = DailyRewards.ClaimInterval - elapsed, Streak = streak, Reset = false }
	end
	if elapsed > DailyRewards.StreakBreak then
		return { CanClaim = true, SecondsUntil = 0, Streak = 1, Reset = true }
	end
	return { CanClaim = true, SecondsUntil = 0, Streak = streak + 1, Reset = false }
end

-- Jour du cycle (1..7) pour une serie donnee
function DailyRewards.dayForStreak(streak)
	local cycle = #DailyRewards.Cycle
	local day = ((math.max(1, streak) - 1) % cycle) + 1
	return day
end

function DailyRewards.rewardForStreak(streak)
	return DailyRewards.Cycle[DailyRewards.dayForStreak(streak)]
end

return DailyRewards
