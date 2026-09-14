--!nonstrict
-- Logique pure des offres : pack de demarrage et offres flash tournantes.
local Config = require(script.Parent.Config)

local Offers = {}

-- Retourne l'index de l'offre flash active et le temps restant avant rotation.
function Offers.getFlashDeal(now)
	local deals = Config.FlashDeals.Deals
	local rotation = Config.FlashDeals.RotationSeconds
	local slot = math.floor(now / rotation)
	local index = (slot % #deals) + 1
	local remaining = rotation - (now % rotation)
	return index, deals[index], remaining
end

-- Temps restant (secondes) du pack de demarrage, 0 si expire ou deja achete.
function Offers.starterRemaining(firstJoin, purchased, now)
	if purchased then
		return 0
	end
	if not firstJoin or firstJoin <= 0 then
		return Config.StarterPack.WindowSeconds
	end
	local remaining = (firstJoin + Config.StarterPack.WindowSeconds) - now
	return math.max(0, remaining)
end

return Offers
