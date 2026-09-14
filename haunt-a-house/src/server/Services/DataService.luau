--!nonstrict
-- Sauvegarde des joueurs : DataStore avec verrou de session, reessais, autosave et BindToClose.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(ReplicatedStorage.Shared.Util)

local DataService = {}

local LOCK_TIMEOUT = 180 -- secondes avant qu'un verrou d'une autre session soit considere mort
local AUTOSAVE_INTERVAL = 60
local LOAD_ATTEMPTS = 4
local MAX_RECEIPTS = 100

local TEMPLATE = {
	Version = Config.DataVersion,
	Coins = 300, -- coins de depart : deux Cercueils en Bois immediatement
	TotalCoins = 0,
	Rebirths = 0,
	RoomsPurchased = 0,
	Monsters = {}, -- { Uid = string, Id = string, Room = number (0 = inventaire) }
	Index = {}, -- [monsterId] = true
	Boosts = { Coins = 0, Luck = 0 }, -- timestamps de fin (os.time)
	Daily = { LastClaim = 0, Streak = 0 },
	Codes = {}, -- [code] = true
	Starter = { FirstJoin = 0, Purchased = false },
	Season = { Id = Config.Season.Id, Xp = 0, ClaimedFree = {}, ClaimedPremium = {} },
	NightmareCoffins = 0,
	VipMonsterGranted = false,
	Stats = { Hatches = 0, Scares = 0, BossKills = 0, PlayTime = 0, BestPower = 0 },
	Receipts = {},
	SessionLock = nil,
}

local profiles = {} -- [player] = { Data, Key, Loaded, Released, LastSave }
local store = nil
local memoryMode = false
local S

local function reconcile(data, template)
	for key, value in pairs(template) do
		if data[key] == nil then
			data[key] = Util.deepCopy(value)
		elseif type(value) == "table" and type(data[key]) == "table" then
			reconcile(data[key], value)
		end
	end
end

local function migrate(data)
	-- Point d'extension pour les versions futures : on ne fait que remonter la version.
	data.Version = Config.DataVersion
end

local function keyFor(player)
	return "Player_" .. player.UserId
end

-- Tente de charger et verrouiller. Retourne "ok", data | "locked" | "error", err
local function tryLoad(key)
	local loaded = nil
	local lockedByOther = false
	local ok, err = pcall(function()
		store:UpdateAsync(key, function(old)
			if type(old) ~= "table" then
				old = Util.deepCopy(TEMPLATE)
			end
			local lock = old.SessionLock
			if lock and lock.JobId ~= game.JobId and (os.time() - (tonumber(lock.Time) or 0)) < LOCK_TIMEOUT then
				lockedByOther = true
				return nil
			end
			old.SessionLock = { JobId = game.JobId, Time = os.time() }
			loaded = old
			return old
		end)
	end)
	if not ok then
		return "error", err
	end
	if lockedByOther then
		return "locked"
	end
	return "ok", loaded
end

local function writeProfile(profile, release)
	if memoryMode then
		return true
	end
	local data = profile.Data
	if release then
		data.SessionLock = nil
	else
		data.SessionLock = { JobId = game.JobId, Time = os.time() }
	end
	local ok, err = Util.retry(3, 1, function()
		store:UpdateAsync(profile.Key, function()
			return data
		end)
	end)
	if not ok then
		warn("[DataService] Échec de sauvegarde pour " .. profile.Key .. " : " .. tostring(err))
	end
	return ok
end

function DataService.init(services)
	S = services
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		memoryMode = true
		warn("[DataService] DataStore indisponible, mode mémoire : " .. tostring(result))
	end
	if store and RunService:IsStudio() then
		local okTest = pcall(function()
			store:GetAsync("__test_access")
		end)
		if not okTest then
			memoryMode = true
			warn("[DataService] Studio sans accès aux API : les données ne seront PAS sauvegardées. Active 'Enable Studio Access to API Services' dans Game Settings > Security.")
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		DataService.release(player)
	end)

	pcall(game.BindToClose, game, function()
		if memoryMode then
			return
		end
		local pending = 0
		for player, profile in pairs(profiles) do
			if profile.Loaded and not profile.Released then
				pending += 1
				task.spawn(function()
					profile.Released = true
					writeProfile(profile, true)
					pending -= 1
				end)
			end
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.2)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player, profile in pairs(profiles) do
				if profile.Loaded and not profile.Released and player.Parent then
					writeProfile(profile, false)
					profile.LastSave = os.clock()
				end
			end
		end
	end)
end

-- Charge le profil (bloquant). Retourne les donnees ou nil si le joueur a ete expulse.
function DataService.load(player)
	local profile = { Key = keyFor(player), Loaded = false, Released = false, LastSave = os.clock() }
	profiles[player] = profile

	local data = nil
	if memoryMode then
		data = Util.deepCopy(TEMPLATE)
	else
		for attempt = 1, LOAD_ATTEMPTS do
			local status, result = tryLoad(profile.Key)
			if status == "ok" then
				data = result
				break
			elseif status == "locked" then
				if attempt < LOAD_ATTEMPTS then
					task.wait(4)
				end
			else
				warn("[DataService] Erreur de chargement (" .. attempt .. ") : " .. tostring(result))
				if attempt < LOAD_ATTEMPTS then
					task.wait(2 * attempt)
				end
			end
			if not player.Parent then
				profiles[player] = nil
				return nil
			end
		end
	end

	if not data then
		profiles[player] = nil
		player:Kick("Tes données sont encore utilisées par un autre serveur ou indisponibles. Réessaie dans une minute !")
		return nil
	end

	reconcile(data, TEMPLATE)
	migrate(data)
	profile.Data = data
	profile.Loaded = true

	if not player.Parent then
		DataService.release(player)
		return nil
	end
	return data
end

function DataService.get(player)
	local profile = profiles[player]
	if profile and profile.Loaded and not profile.Released then
		return profile.Data
	end
	return nil
end

function DataService.isLoaded(player)
	return DataService.get(player) ~= nil
end

function DataService.isMemoryMode()
	return memoryMode
end

-- Sauvegarde immediate (ex : apres un achat Robux). Retourne true si ecrit.
function DataService.save(player)
	local profile = profiles[player]
	if not profile or not profile.Loaded or profile.Released then
		return false
	end
	local ok = writeProfile(profile, false)
	profile.LastSave = os.clock()
	return ok
end

function DataService.release(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	if profile.Loaded and not profile.Released then
		profile.Released = true
		writeProfile(profile, true)
	end
	profiles[player] = nil
end

-- Enregistre un recu d'achat (idempotence). Retourne false si deja traite.
function DataService.recordReceipt(data, purchaseId)
	for _, id in ipairs(data.Receipts) do
		if id == purchaseId then
			return false
		end
	end
	table.insert(data.Receipts, purchaseId)
	while #data.Receipts > MAX_RECEIPTS do
		table.remove(data.Receipts, 1)
	end
	return true
end

function DataService.hasReceipt(data, purchaseId)
	for _, id in ipairs(data.Receipts) do
		if id == purchaseId then
			return true
		end
	end
	return false
end

function DataService.template()
	return TEMPLATE
end

return DataService
