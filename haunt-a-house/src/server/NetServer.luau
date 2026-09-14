--!nonstrict
-- Reception des requetes clients : validation, limitation de debit, dispatch.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)

local NetServer = {}

local handlers = {} -- [action] = { Fn = function, Limit = string }
local eventHandlers = {} -- [name] = function
local buckets = {} -- [player] = { [limitKey] = { Count, Window } }
local S

local function allowed(player, limitKey)
	local limit = Config.RateLimits[limitKey] or Config.RateLimits.Default
	local playerBuckets = buckets[player]
	if not playerBuckets then
		playerBuckets = {}
		buckets[player] = playerBuckets
	end
	local now = os.clock()
	local bucket = playerBuckets[limitKey]
	if not bucket or now - bucket.Window >= 1 then
		bucket = { Count = 0, Window = now }
		playerBuckets[limitKey] = bucket
	end
	bucket.Count += 1
	return bucket.Count <= limit
end

function NetServer.register(action, limitKey, fn)
	handlers[action] = { Fn = fn, Limit = limitKey or "Default" }
end

function NetServer.onEvent(name, fn)
	eventHandlers[name] = fn
end

function NetServer.fire(player, name, payload)
	if player and player.Parent then
		Net.serverEvent():FireClient(player, name, payload)
	end
end

function NetServer.fireAll(name, payload)
	Net.serverEvent():FireAllClients(name, payload)
end

function NetServer.notify(player, text, kind)
	NetServer.fire(player, "Notify", { Text = text, Kind = kind or "info" })
end

function NetServer.announce(text, kind)
	NetServer.fireAll("Announce", { Text = text, Kind = kind or "info" })
end

function NetServer.init(services)
	S = services
	Net.request().OnServerInvoke = function(player, action, payload)
		if type(action) ~= "string" then
			return { ok = false, message = "Requête invalide." }
		end
		local handler = handlers[action]
		if not handler then
			return { ok = false, message = "Action inconnue." }
		end
		if not allowed(player, handler.Limit) then
			return { ok = false, message = "Trop rapide ! Patiente une seconde." }
		end
		if not S.Data.isLoaded(player) then
			return { ok = false, message = "Tes données se chargent encore..." }
		end
		if payload ~= nil and type(payload) ~= "table" then
			return { ok = false, message = "Requête invalide." }
		end
		local ok, result = pcall(handler.Fn, player, payload or {})
		if not ok then
			warn("[NetServer] Erreur dans l'action " .. action .. " : " .. tostring(result))
			return { ok = false, message = "Erreur serveur, réessaie." }
		end
		if type(result) ~= "table" then
			return { ok = true }
		end
		return result
	end

	Net.clientEvent().OnServerEvent:Connect(function(player, name, payload)
		if type(name) ~= "string" then
			return
		end
		local handler = eventHandlers[name]
		if not handler then
			return
		end
		if not allowed(player, name) then
			return
		end
		if not S.Data.isLoaded(player) then
			return
		end
		if payload ~= nil and type(payload) ~= "table" then
			return
		end
		local ok, err = pcall(handler, player, payload or {})
		if not ok then
			warn("[NetServer] Erreur dans l'évènement " .. name .. " : " .. tostring(err))
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
	end)
end

return NetServer
