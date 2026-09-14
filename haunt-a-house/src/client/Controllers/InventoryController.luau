--!nonstrict
-- Inventaire : placement, retrait, vente, auto-placement, achat de salles.
local InventoryController = {}

function InventoryController.init(ctx)
	local UI = ctx.UI
	local Economy = ctx.Economy
	local MonsterData = ctx.MonsterData
	local CoffinData = ctx.CoffinData
	local Rarity = ctx.Rarity

	local window = UI.window("Inventory", "Mes monstres", { Icon = "👻" })
	local body = window.Body
	local header = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 84), BackgroundColor3 = UI.Colors.Panel, ZIndex = 22, Parent = body }, { UI.corner(12), UI.padding(10, 8) })
	local info = UI.label({ Text = "", Font = UI.Font, TextSize = 18, Size = UDim2.new(1, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 23, Parent = header })
	local actions = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 30), BackgroundTransparency = 1, ZIndex = 23, Parent = header }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	UI.button({ Text = "⭐ Auto-placer les meilleurs", Color = UI.Colors.Accent2, Size = UDim2.new(0.34, -8, 1, 0), LayoutOrder = 1, ZIndex = 24, MaxTextSize = 16, Parent = actions, OnClick = function()
		ctx.request("AutoEquip")
	end })
	UI.button({ Text = "💸 Vendre non-placés (≤ Rare)", Color = Color3.fromRGB(160, 70, 60), Size = UDim2.new(0.33, -8, 1, 0), LayoutOrder = 2, ZIndex = 24, MaxTextSize = 16, Parent = actions, OnClick = function()
		UI.confirm("Vendre les non-placés ?", "Tous tes monstres NON placés de rareté Commun, Peu commun ou Rare seront vendus. Les Epiques et plus rares, ainsi que les exclusifs, sont conservés.", function()
			ctx.request("SellUnplaced")
		end, "Vendre")
	end })
	local roomButton = UI.button({ Text = "🏚️ Acheter une salle", Color = UI.Colors.Green, Size = UDim2.new(0.33, -8, 1, 0), LayoutOrder = 3, ZIndex = 24, MaxTextSize = 16, Parent = actions, OnClick = function()
		ctx.request("BuyRoom")
	end })
	local grid = UI.scroll(body, { Size = UDim2.new(1, 0, 1, -92), Position = UDim2.new(0, 0, 0, 92), Grid = true, CellSize = UDim2.fromOffset(172, 150) })

	local function refresh()
		local state = ctx.state
		if not state then
			return
		end
		local rooms = state.Rooms or { Count = 0, Total = 18 }
		local placed = 0
		for _, entry in ipairs(state.Monsters) do
			if entry.Room > 0 then
				placed += 1
			end
		end
		info.Text = string.format("Salles : %d/%d occupées (%d au total)  ·  Monstres : %d/%d  ·  ⚡ %s/s", placed, rooms.Count, rooms.Total, #state.Monsters, ctx.Config.Inventory.MaxMonsters, Economy.format(tonumber(ctx.attr("Income")) or 0))
		if rooms.NextCost then
			roomButton.Text = "🏚️ Salle : " .. Economy.format(rooms.NextCost) .. " 🪙"
			UI.setEnabled(roomButton, true)
		else
			roomButton.Text = "🏚️ Salles : rebirth / passes"
			UI.setEnabled(roomButton, false)
		end
		UI.clear(grid)
		local sorted = table.clone(state.Monsters)
		table.sort(sorted, function(a, b)
			local pa = MonsterData.get(a.Id).Power
			local pb = MonsterData.get(b.Id).Power
			if (a.Room > 0) ~= (b.Room > 0) then
				return a.Room > 0
			end
			if pa == pb then
				return a.Uid < b.Uid
			end
			return pa > pb
		end)
		for index, entry in ipairs(sorted) do
			local def = MonsterData.get(entry.Id)
			local r, g, b = Rarity.color(def.Rarity)
			local rarityColor = Color3.fromRGB(r, g, b)
			local card = UI.new("Frame", { BackgroundColor3 = entry.Room > 0 and UI.Colors.Panel2 or UI.Colors.Bg, LayoutOrder = index, ZIndex = 23, Parent = grid }, { UI.corner(12), UI.stroke(rarityColor, 2, 0.2), UI.padding(8, 6) })
			local face = UI.new("Frame", { Size = UDim2.fromOffset(40, 40), BackgroundColor3 = Color3.fromRGB(def.Visual.Color[1], def.Visual.Color[2], def.Visual.Color[3]), ZIndex = 24, Parent = card }, { UI.corner(20), UI.stroke(rarityColor, 3) })
			UI.label({ Text = "👀", TextSize = 18, ZIndex = 25, Parent = face })
			UI.label({ Text = def.Name, Font = UI.Font, TextSize = 15, Size = UDim2.new(1, -46, 0, 20), Position = UDim2.new(0, 46, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, ZIndex = 24, Parent = card })
			UI.label({ Text = Rarity.label(def.Rarity) .. "  ⚡" .. Economy.format(def.Power) .. "/s", TextSize = 12, Size = UDim2.new(1, -46, 0, 18), Position = UDim2.new(0, 46, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = rarityColor, ZIndex = 24, Parent = card })
			UI.label({ Text = entry.Room > 0 and ("🏚️ Salle " .. entry.Room) or "🎒 Inventaire", TextSize = 12, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0, 46), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.Colors.Muted, ZIndex = 24, Parent = card })
			local mainButton = UI.button({
				Text = entry.Room > 0 and "Retirer" or "Placer",
				Color = entry.Room > 0 and Color3.fromRGB(110, 60, 190) or UI.Colors.Green,
				Size = UDim2.new(0.55, -4, 0, 34), Position = UDim2.new(0, 0, 1, -36), ZIndex = 24, MaxTextSize = 15, Parent = card,
				OnClick = function()
					ctx.request(entry.Room > 0 and "Unequip" or "Equip", { Uid = entry.Uid })
				end,
			})
			mainButton.Name = "Main"
			local sellValue = Economy.sellPrice(def.Rarity, CoffinData.referenceCost(entry.Id))
			local sellButton = UI.button({
				Text = "💸 " .. Economy.format(sellValue),
				Color = Color3.fromRGB(150, 70, 60),
				Size = UDim2.new(0.45, -4, 0, 34), Position = UDim2.new(0.55, 4, 1, -36), ZIndex = 24, MaxTextSize = 14, Parent = card,
				OnClick = function()
					if Rarity.rank(def.Rarity) >= Rarity.rank("Epic") then
						UI.confirm("Vendre " .. def.Name .. " ?", "Ce monstre est " .. Rarity.label(def.Rarity) .. ". Tu recevras " .. Economy.format(sellValue) .. " coins. Cette action est définitive.", function()
							ctx.request("Sell", { Uid = entry.Uid })
						end, "Vendre")
					else
						ctx.request("Sell", { Uid = entry.Uid })
					end
				end,
			})
			if def.Exclusive then
				UI.setEnabled(sellButton, false)
				sellButton.Text = "Exclusif"
			end
		end
		if #sorted == 0 then
			local empty = UI.new("Frame", { Size = UDim2.fromOffset(340, 120), BackgroundTransparency = 1, ZIndex = 23, Parent = grid })
			UI.label({ Text = "Aucun monstre pour l'instant.\nVa à la Crypte pour ouvrir ton premier cercueil !", TextSize = 16, TextColor3 = UI.Colors.Muted, ZIndex = 24, Parent = empty })
		end
	end

	window.OnOpen = refresh
	ctx.onState(function()
		if window.Frame.Visible then
			refresh()
		end
	end)
	ctx.onAttr("Income", function()
		if window.Frame.Visible then
			refresh()
		end
	end)
end

return InventoryController
