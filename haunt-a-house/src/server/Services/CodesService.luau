--!nonstrict
-- Codes promotionnels (usage unique par joueur).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local CodesService = {}
local S

function CodesService.redeem(player, code)
	if type(code) ~= "string" then
		return { ok = false, message = "Code invalide." }
	end
	code = string.upper((string.gsub(code, "%s", "")))
	if #code == 0 or #code > 24 then
		return { ok = false, message = "Code invalide." }
	end
	local data = S.Data.get(player)
	local reward = Config.Codes[code]
	if not reward then
		return { ok = false, message = "Ce code n'existe pas." }
	end
	if data.Codes[code] then
		return { ok = false, message = "Code déjà utilisé." }
	end
	local text = S.Reward.grant(player, reward, true)
	data.Codes[code] = true
	S.Player.sendState(player)
	return { ok = true, message = "Code accepté : " .. tostring(text) }
end

function CodesService.init(services)
	S = services
	S.Net.register("RedeemCode", "Shop", function(player, payload)
		return CodesService.redeem(player, payload.Code)
	end)
end

return CodesService
