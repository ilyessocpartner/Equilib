--!nonstrict
-- Raretes des monstres : ordre, couleurs et multiplicateurs de revente.
local Rarity = {}

Rarity.Order = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

Rarity.Info = {
	Common = { Rank = 1, Label = "Commun", Color = { 190, 190, 200 }, SellFactor = 0.15, Announce = false },
	Uncommon = { Rank = 2, Label = "Peu commun", Color = { 90, 220, 110 }, SellFactor = 0.4, Announce = false },
	Rare = { Rank = 3, Label = "Rare", Color = { 70, 150, 255 }, SellFactor = 1.2, Announce = false },
	Epic = { Rank = 4, Label = "Epique", Color = { 190, 90, 255 }, SellFactor = 4, Announce = false },
	Legendary = { Rank = 5, Label = "Legendaire", Color = { 255, 170, 40 }, SellFactor = 15, Announce = true },
	Mythic = { Rank = 6, Label = "Mythique", Color = { 255, 70, 120 }, SellFactor = 60, Announce = true },
	Secret = { Rank = 7, Label = "Secret", Color = { 40, 40, 50 }, SellFactor = 300, Announce = true },
}

function Rarity.rank(name)
	local info = Rarity.Info[name]
	return info and info.Rank or 1
end

function Rarity.label(name)
	local info = Rarity.Info[name]
	return info and info.Label or name
end

function Rarity.color(name)
	local info = Rarity.Info[name]
	if not info then
		return 200, 200, 200
	end
	return info.Color[1], info.Color[2], info.Color[3]
end

return Rarity
