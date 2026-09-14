--!nonstrict
-- Recompenses de temps de jeu (par session).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)

local PlaytimeService = {}
local S

local sessions = {} -- [player] = { Start = os.clock(), Claimed = { [index] = true } }

function PlaytimeService.start(player)
	sessions[player] = { Start = os.clock(), Claimed = {} }
end

function PlaytimeService.claimedList(player)
	local session = sessions[player]
	local list = {}
	for index = 1, #Config.Playtime do
		list[index] = session ~= nil and session.Claimed[index] == true
	end
	return list
end

function PlaytimeService.claim(player, index)
	local session = sessions[player]
	index = tonumber(index)
	local entry = index and Config.Playtime[index]
	if not session or not entry then
		return { ok = false, message = "Récompense inconnue." }
	end
	if session.Claimed[index] then
		return { ok = false, message = "Déjà récupérée cette session." }
	end
	local elapsed = os.clock() - session.Start
	if elapsed < entry.Minutes * 60 then
		return { ok = false, message = "Encore " .. math.ceil((entry.Minutes * 60 - elapsed) / 60) .. " min de jeu pour cette récompense." }
	end
	session.Claimed[index] = true
	local reward = { Type = entry.Type, Amount = entry.Amount, Minutes = entry.Minutes2 }
	local text = S.Reward.grant(player, reward, true)
	S.Player.sendState(player)
	S.Net.notify(player, "⏱️ Récompense de temps de jeu : " .. tostring(text), "success")
	return { ok = true, message = text }
end

function PlaytimeService.init(services)
	S = services
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
	S.Net.register("ClaimPlaytime", "Shop", function(player, payload)
		return PlaytimeService.claim(player, payload.Index)
	end)
end

return PlaytimeService
