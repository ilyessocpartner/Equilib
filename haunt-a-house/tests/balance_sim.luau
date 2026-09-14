-- Simulation d'equilibrage : temps estime pour atteindre le premier rebirth en jeu actif.
-- Usage : luau tests/balance_sim.luau (via run_tests.sh, les requires relatifs sont reecrits)
local Config = require("./shared/Config")
local Economy = require("./shared/Economy")
local CoffinData = require("./shared/CoffinData")
local MonsterData = require("./shared/MonsterData")
local GachaMath = require("./shared/GachaMath")
local Rarity = require("./shared/Rarity")

local seed = 7
local function rng()
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648
end

local function entries(coffin)
	local list = {}
	for _, e in ipairs(coffin.Contents) do
		table.insert(list, { Id = e.Id, Weight = e.Weight, Rank = Rarity.rank(MonsterData.ById[e.Id].Rarity) })
	end
	return list
end

local function simulate(startCoins, scaresPerSecond, targetRebirths)
	local coins = startCoins
	local rebirths = 0
	local roomsPurchased = 0
	local placed = {} -- powers
	local t = 0
	local log = {}
	local function rooms()
		return Economy.roomCount(rebirths, roomsPurchased, false, false)
	end
	local function income()
		local base = 0
		for _, p in ipairs(placed) do
			base += p
		end
		return base * Economy.rebirthMultiplier(rebirths), base
	end
	local function addMonster(power)
		if #placed < rooms() then
			table.insert(placed, power)
		else
			local minIndex, minPower = nil, math.huge
			for i, p in ipairs(placed) do
				if p < minPower then
					minIndex, minPower = i, p
				end
			end
			if power > minPower then
				placed[minIndex] = power
			end
		end
	end
	while rebirths < targetRebirths and t < 6 * 3600 do
		t += 1
		local inc, base = income()
		coins += inc
		local scare = math.max(Config.Income.ScareBaseCoins * Economy.rebirthMultiplier(rebirths), inc * Config.Income.ScareIncomeSeconds)
		coins += scare * scaresPerSecond
		-- decisions
		local rebirthCost = Economy.rebirthCost(rebirths)
		if coins >= rebirthCost then
			table.insert(log, string.format("  t=%s rebirth %d (base %.0f/s, %d salles)", Economy.formatTime(t), rebirths + 1, base, rooms()))
			rebirths += 1
			coins = 0
			placed = {}
		else
			local nextRoom = Economy.roomCost(roomsPurchased + 1)
			local best = nil
			for _, coffin in ipairs(CoffinData.List) do
				if not coffin.EventOnly and rebirths >= coffin.RebirthRequired and coins >= coffin.Cost then
					best = coffin
				end
			end
			if nextRoom and coins >= nextRoom and (#placed >= rooms()) and nextRoom < rebirthCost * 0.5 then
				coins -= nextRoom
				roomsPurchased += 1
			elseif best and coins >= best.Cost and (#placed < rooms() or coins < rebirthCost * 0.8) then
				coins -= best.Cost
				local id = GachaMath.roll(entries(best), 1, rng)
				addMonster(MonsterData.ById[id].Power)
			end
		end
	end
	return t, log
end

for _, scenario in ipairs({ { 300, 0.5, "actif (0.5 effroi/s)" }, { 300, 0.15, "moyen (0.15 effroi/s)" }, { 300, 0, "passif (0 effroi)" } }) do
	local t, log = simulate(scenario[1], scenario[2], 3)
	print("Scenario " .. scenario[3] .. " : 3 rebirths en " .. Economy.formatTime(t))
	for _, line in ipairs(log) do
		print(line)
	end
end
