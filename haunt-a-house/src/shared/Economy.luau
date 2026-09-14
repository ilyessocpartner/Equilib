--!nonstrict
-- Fonctions pures d'economie : couts, multiplicateurs, formatage.
local Config = require(script.Parent.Config)
local Rarity = require(script.Parent.Rarity)

local Economy = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Economy.format(n)
	n = tonumber(n) or 0
	if n ~= n or n == math.huge then
		return "∞"
	end
	local negative = n < 0
	n = math.abs(n)
	if n < 1000 then
		return (negative and "-" or "") .. tostring(math.floor(n))
	end
	local index = 1
	while n >= 1000 and index < #SUFFIXES do
		n = n / 1000
		index += 1
	end
	local text
	if n >= 100 then
		text = string.format("%.0f", n)
	elseif n >= 10 then
		text = string.format("%.1f", n)
	else
		text = string.format("%.2f", n)
	end
	text = text:gsub("%.?0+$", "")
	return (negative and "-" or "") .. text .. SUFFIXES[index]
end

function Economy.formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

-- Cout de la N-ieme salle achetee (1 = premiere)
function Economy.roomCost(purchasedIndex)
	return Config.RoomCosts[purchasedIndex]
end

-- Nombre total de salles disponibles pour un etat de joueur
function Economy.roomCount(rebirths, roomsPurchased, hasVip, hasExtraRooms)
	local rooms = Config.Plot.BaseRooms
	rooms += math.min(rebirths, Config.Plot.MaxRebirthRooms)
	rooms += math.min(roomsPurchased, Config.Plot.MaxPurchasedRooms)
	if hasVip then
		rooms += Config.Plot.VipRooms
	end
	if hasExtraRooms then
		rooms += Config.Plot.ExtraRoomsPass
	end
	return math.min(rooms, Config.Plot.TotalPads)
end

-- Cout du prochain rebirth quand on en a deja `rebirths`
function Economy.rebirthCost(rebirths)
	local costs = Config.Rebirth.Costs
	local index = rebirths + 1
	if costs[index] then
		return costs[index]
	end
	local last = costs[#costs]
	local extra = index - #costs
	return last * (Config.Rebirth.CostGrowthAfterTable ^ extra)
end

function Economy.rebirthMultiplier(rebirths)
	return 1 + Config.Rebirth.MultiplierPerRebirth * rebirths
end

-- Prix de revente d'un monstre
function Economy.sellPrice(rarityName, coffinCost)
	local info = Rarity.Info[rarityName]
	local factor = info and info.SellFactor or 0.1
	return math.floor(coffinCost * factor)
end

-- Montant d'un bundle de coins selon le rebirth du joueur
function Economy.bundleAmount(baseCoins, rebirths)
	return math.floor(baseCoins * Economy.rebirthMultiplier(rebirths))
end

-- Multiplicateur final applique aux gains.
-- flags : { Rebirths, DoubleCoins, VIP, CoinsBoost, IndexCount, InGroup }
function Economy.incomeMultiplier(flags)
	local mult = Economy.rebirthMultiplier(flags.Rebirths or 0)
	if flags.DoubleCoins then
		mult *= 2
	end
	if flags.VIP then
		mult *= 1 + Config.Income.VipBonus
	end
	if flags.CoinsBoost then
		mult *= Config.Boosts.CoinsBoostMultiplier
	end
	mult *= 1 + Config.Income.IndexBonusPerMonster * (flags.IndexCount or 0)
	if flags.InGroup then
		mult *= 1 + Config.Income.GroupBonus
	end
	return mult
end

-- Multiplicateur de chance final (affiche dans les odds)
function Economy.luckMultiplier(flags)
	local luck = 1
	if flags.LuckyPass then
		luck *= 2
	end
	if flags.LuckBoost then
		luck *= Config.Boosts.LuckBoostMultiplier
	end
	if flags.ServerLuck then
		luck *= Config.Boosts.ServerLuckMultiplier
	end
	return luck
end

return Economy
