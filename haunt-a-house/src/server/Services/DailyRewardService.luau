--!nonstrict
-- Recompense quotidienne avec serie.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DailyRewards = require(ReplicatedStorage.Shared.DailyRewards)
local Economy = require(ReplicatedStorage.Shared.Economy)

local DailyRewardService = {}
local S

function DailyRewardService.claim(player)
	local data = S.Data.get(player)
	local now = os.time()
	local result = DailyRewards.evaluate(data.Daily.LastClaim, data.Daily.Streak, now)
	if not result.CanClaim then
		return { ok = false, message = "Reviens dans " .. Economy.formatTime(result.SecondsUntil) .. " pour ta prochaine récompense." }
	end
	local reward = DailyRewards.rewardForStreak(result.Streak)
	local texts = {}
	local text = S.Reward.grant(player, reward, true)
	if text then
		table.insert(texts, text)
	end
	if reward.Coins then
		local bonus = S.Reward.grant(player, { Type = "Coins", Amount = reward.Coins }, true)
		if bonus then
			table.insert(texts, bonus)
		end
	end
	data.Daily.LastClaim = now
	data.Daily.Streak = result.Streak
	S.Season.addXp(player, Config.Season.XpDaily)
	S.Player.refreshAttributes(player)
	local message = "Jour " .. DailyRewards.dayForStreak(result.Streak) .. " de ta série : " .. table.concat(texts, " + ")
	if result.Reset then
		message = "Série perdue, on repart de zéro ! " .. message
	end
	S.Net.notify(player, "🎁 " .. message, "success")
	return { ok = true, message = message, data = { Streak = result.Streak } }
end

function DailyRewardService.init(services)
	S = services
	S.Net.register("ClaimDaily", "Shop", function(player)
		return DailyRewardService.claim(player)
	end)
end

return DailyRewardService
