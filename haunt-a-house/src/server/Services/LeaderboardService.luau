--!nonstrict
-- Classements globaux (OrderedDataStore) affiches sur les tableaux du hub.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)

local LeaderboardService = {}
local S

local BOARDS = {
	{ Key = "Coins", Store = "HAH_TopCoins_v1", Value = function(data) return data.TotalCoins end },
	{ Key = "Rebirths", Store = "HAH_TopRebirths_v1", Value = function(data) return data.Rebirths end },
	{ Key = "Power", Store = "HAH_TopPower_v1", Value = function(data) return data.Stats.BestPower end },
}

local stores = {}
local nameCache = {}
local MAX_VALUE = 2 ^ 53

local function nameOf(userId)
	if nameCache[userId] then
		return nameCache[userId]
	end
	local online = Players:GetPlayerByUserId(userId)
	if online then
		nameCache[userId] = online.DisplayName
		return online.DisplayName
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nameCache[userId] = ok and name or ("Joueur " .. userId)
	return nameCache[userId]
end

local function setBoardText(key, text)
	local label = S.Map.Leaderboards[key]
	if label then
		label.Text = text
	end
end

local function refresh()
	if S.Data.isMemoryMode() then
		for _, board in ipairs(BOARDS) do
			setBoardText(board.Key, "Classement indisponible en Studio.\nActive l'accès API dans Game Settings > Security.")
		end
		return
	end
	for _, board in ipairs(BOARDS) do
		local store = stores[board.Key]
		if store then
			for _, player in ipairs(Players:GetPlayers()) do
				local data = S.Data.get(player)
				if data then
					local value = math.clamp(math.floor(board.Value(data) or 0), 0, MAX_VALUE)
					if value > 0 then
						pcall(function()
							store:SetAsync(tostring(player.UserId), value)
						end)
					end
				end
			end
			local ok, pages = pcall(function()
				return store:GetSortedAsync(false, Config.Leaderboards.Entries)
			end)
			if ok and pages then
				local okPage, page = pcall(function()
					return pages:GetCurrentPage()
				end)
				if okPage and page then
					local lines = {}
					for rank, entry in ipairs(page) do
						local userId = tonumber(entry.key)
						local medal = rank == 1 and "🥇" or rank == 2 and "🥈" or rank == 3 and "🥉" or (rank .. ".")
						table.insert(lines, string.format("%s %s  <font color=\"#ffd166\">%s</font>", medal, nameOf(userId), Economy.format(entry.value)))
					end
					if #lines == 0 then
						table.insert(lines, "Sois le premier au classement !")
					end
					setBoardText(board.Key, table.concat(lines, "\n"))
				end
			end
		end
	end
end

function LeaderboardService.init(services)
	S = services
	for _, board in ipairs(BOARDS) do
		local ok, store = pcall(function()
			return DataStoreService:GetOrderedDataStore(board.Store)
		end)
		if ok then
			stores[board.Key] = store
		end
	end
	task.spawn(function()
		task.wait(5)
		while true do
			local ok, err = pcall(refresh)
			if not ok then
				warn("[LeaderboardService] " .. tostring(err))
			end
			task.wait(Config.Leaderboards.RefreshSeconds)
		end
	end)
end

return LeaderboardService
