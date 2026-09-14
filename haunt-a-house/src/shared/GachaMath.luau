--!nonstrict
-- Tirage pondere avec chance. Module pur (aucune dependance).
-- entries : { { Id = string, Weight = number, Rank = number } }
-- La chance multiplie le poids des raretes de rang >= 3 (Rare et au-dela).
local GachaMath = {}

GachaMath.LuckMinRank = 3

function GachaMath.weighted(entries, luck)
	luck = math.max(1, luck or 1)
	local total = 0
	local result = {}
	for _, entry in ipairs(entries) do
		local weight = entry.Weight
		if entry.Rank >= GachaMath.LuckMinRank then
			weight = weight * luck
		end
		total += weight
		table.insert(result, { Id = entry.Id, Weight = weight, Rank = entry.Rank })
	end
	for _, entry in ipairs(result) do
		entry.Chance = total > 0 and entry.Weight / total or 0
	end
	return result, total
end

-- rng : fonction retournant un nombre dans [0, 1)
function GachaMath.roll(entries, luck, rng)
	local weighted, total = GachaMath.weighted(entries, luck)
	local r = (rng or math.random)() * total
	local acc = 0
	for _, entry in ipairs(weighted) do
		acc += entry.Weight
		if r < acc then
			return entry.Id
		end
	end
	return weighted[#weighted].Id
end

-- Pourcentage lisible (ex : 0.00123 -> "0.12%")
function GachaMath.formatChance(chance)
	local pct = chance * 100
	if pct >= 10 then
		return string.format("%.0f%%", pct)
	elseif pct >= 1 then
		return string.format("%.1f%%", pct)
	elseif pct >= 0.01 then
		return string.format("%.2f%%", pct)
	else
		return string.format("%.4f%%", pct)
	end
end

return GachaMath
