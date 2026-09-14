--!nonstrict
-- Boutique Robux : offres, passes, boosts, coins.
local ShopController = {}

function ShopController.init(ctx)
	local UI = ctx.UI
	local Economy = ctx.Economy
	local Config = ctx.Config
	local Offers = ctx.Offers

	local window = UI.window("Shop", "Boutique", { Icon = "🛒" })
	local body = window.Body
	local content = UI.new("Frame", { Name = "Content", Size = UDim2.new(1, 0, 1, -48), Position = UDim2.new(0, 0, 0, 48), BackgroundTransparency = 1, ZIndex = 22, Parent = body })
	local list = UI.scroll(content, {})
	local currentTab = "Offers"
	local refreshing = false

	local function priceText(entry)
		return "R$ " .. tostring(entry.Price)
	end

	local function findCatalog(kind, key)
		if not ctx.state or not ctx.state.Catalog then
			return nil
		end
		local items = kind == "Pass" and ctx.state.Catalog.Passes or ctx.state.Catalog.Products
		for _, entry in ipairs(items) do
			if entry.Key == key then
				return entry
			end
		end
		return nil
	end

	local function isHidden(entry)
		return entry.Random and ctx.state and ctx.state.Restricted
	end

	-- Carte d'article
	local function itemCard(options)
		local card = UI.card(list, { Size = UDim2.new(1, 0, 0, options.Height or 92), LayoutOrder = options.LayoutOrder, Color = options.Color, Stroke = options.Stroke })
		UI.label({ Text = options.Icon or "🛒", TextSize = 34, TextScaled = true, Size = UDim2.new(0, 56, 0, 56), Position = UDim2.new(0, 0, 0.5, -28), ZIndex = 24, Parent = card })
		UI.label({ Text = options.Title, Font = UI.Font, TextSize = 20, Size = UDim2.new(1, -220, 0, 26), Position = UDim2.new(0, 64, 0, 4), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 24, Parent = card })
		UI.label({ Text = options.Desc or "", TextSize = 14, Size = UDim2.new(1, -220, 1, -34), Position = UDim2.new(0, 64, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = UI.Colors.Muted, ZIndex = 24, Parent = card })
		if options.Badge then
			local badge = UI.new("Frame", { Size = UDim2.fromOffset(150, 24), Position = UDim2.new(1, -160, 0, -14), BackgroundColor3 = options.BadgeColor or UI.Colors.Red, ZIndex = 26, Parent = card }, { UI.corner(8) })
			UI.label({ Text = options.Badge, Font = UI.Font, TextSize = 13, TextScaled = true, ZIndex = 27, Parent = badge })
		end
		local buttonText = options.ButtonText
		local color = UI.Colors.Robux
		local enabled = true
		if options.Owned then
			buttonText = "✅ Possédé"
			color = Color3.fromRGB(70, 110, 80)
			enabled = false
		elseif not options.Configured then
			buttonText = "Bientôt"
			enabled = false
		end
		local button = UI.button({ Text = buttonText, Color = color, Size = UDim2.fromOffset(140, 48), Position = UDim2.new(1, -144, 0.5, -24), ZIndex = 25, Parent = card, OnClick = function()
			if enabled and options.OnBuy then
				options.OnBuy()
			end
		end })
		UI.setEnabled(button, enabled)
		if options.Worth and enabled then
			UI.label({ Text = "<s>R$ " .. options.Worth .. "</s>", TextSize = 13, Size = UDim2.fromOffset(140, 16), Position = UDim2.new(1, -144, 0.5, 26), TextColor3 = UI.Colors.Muted, ZIndex = 25, Parent = card })
		end
		return card
	end

	local function buildOffers()
		local order = 0
		local now = os.time()
		local starter = findCatalog("Product", "StarterPack")
		local remaining = Offers.starterRemaining(tonumber(ctx.attr("StarterFirstJoin")) or 0, ctx.attr("StarterPurchased") == true, now)
		if starter and remaining > 0 and not isHidden(starter) then
			order += 1
			itemCard({
				LayoutOrder = order, Icon = "🎁", Title = "Pack de démarrage : " .. priceText(starter), Height = 110,
				Desc = Economy.format(Config.StarterPack.Coins) .. " coins + Ghosty Doré (monstre exclusif, conservé au rebirth) + 2x Coins 30 min.\n⏳ Disponible encore " .. Economy.formatTime(remaining),
				ButtonText = priceText(starter), Configured = starter.Configured, Worth = Config.StarterPack.WorthRobux, Badge = "-75% · UNE SEULE FOIS", BadgeColor = UI.Colors.Red, Color = Color3.fromRGB(70, 30, 60), Stroke = UI.Colors.Accent,
				OnBuy = function() ctx.prompt("Product", "StarterPack") end,
			})
		end
		local _, deal, rotationLeft = Offers.getFlashDeal(now)
		local dealEntry = findCatalog("Product", deal.Key)
		if dealEntry and not isHidden(dealEntry) then
			order += 1
			itemCard({
				LayoutOrder = order, Icon = "⚡", Title = "Offre flash : " .. deal.Title, Height = 110,
				Desc = deal.Desc .. "\n⏳ Change dans " .. Economy.formatTime(rotationLeft),
				ButtonText = priceText(dealEntry), Configured = dealEntry.Configured, Worth = deal.WorthRobux, Badge = "TEMPS LIMITÉ", BadgeColor = Color3.fromRGB(200, 120, 20), Color = Color3.fromRGB(60, 40, 30), Stroke = Color3.fromRGB(255, 180, 60),
				OnBuy = function() ctx.prompt("Product", deal.Key) end,
			})
		end
		local ultimate = findCatalog("Pass", "Ultimate")
		if ultimate and not isHidden(ultimate) then
			order += 1
			itemCard({
				LayoutOrder = order, Icon = "🌟", Title = "Pack Ultime : tous les passes", Height = 100,
				Desc = "2x Coins + Auto Collect + Triple Cercueil + 3 Salles + Chance x2 + VIP. Le meilleur rapport qualité-prix du jeu.",
				ButtonText = priceText(ultimate), Configured = ultimate.Configured, Owned = ctx.ownsPass("Ultimate"), Worth = 2144, Badge = "-30% · MEILLEURE VALEUR", BadgeColor = UI.Colors.Accent2, Color = Color3.fromRGB(50, 30, 80), Stroke = UI.Colors.Gold,
				OnBuy = function() ctx.prompt("Pass", "Ultimate") end,
			})
		end
		local season = findCatalog("Pass", "SeasonPremium")
		if season then
			order += 1
			itemCard({
				LayoutOrder = order, Icon = "🎃", Title = "Passe Spooky Premium", Desc = "Débloque 20 récompenses premium : coins, boosts, 11 Cercueils Cauchemar et 2 monstres exclusifs.",
				ButtonText = priceText(season), Configured = season.Configured, Owned = ctx.ownsPass("SeasonPremium"),
				OnBuy = function() ctx.prompt("Pass", "SeasonPremium") end,
			})
		end
	end

	local function buildPasses()
		if not ctx.state or not ctx.state.Catalog then
			return
		end
		local order = 0
		for _, entry in ipairs(ctx.state.Catalog.Passes) do
			if entry.Key ~= "SeasonPremium" and not isHidden(entry) then
				order += 1
				local def = ctx.MonetizationIds.GamePasses[entry.Key]
				itemCard({
					LayoutOrder = entry.Key == "Ultimate" and 0 or order, Icon = def.Icon, Title = def.Name, Desc = def.Desc,
					ButtonText = priceText(entry), Configured = entry.Configured, Owned = ctx.ownsPass(entry.Key),
					Badge = entry.Key == "Ultimate" and "-30% · TOUT INCLUS" or (entry.Key == "DoubleCoins" and "LE PLUS POPULAIRE" or nil), BadgeColor = entry.Key == "Ultimate" and UI.Colors.Accent2 or UI.Colors.Red,
					Stroke = entry.Key == "Ultimate" and UI.Colors.Gold or nil,
					OnBuy = function() ctx.prompt("Pass", entry.Key) end,
				})
			end
		end
	end

	local function buildBoosts()
		local items = {
			{ Key = "BoostCoins", Icon = "⚡", Title = "Boost 2x Coins (30 min)", Desc = "Double tous tes gains pendant 30 minutes. Se cumule avec les passes." },
			{ Key = "BoostLuck", Icon = "🍀", Title = "Boost 2x Chance (30 min)", Desc = "Double tes chances de monstres rares pendant 30 minutes (odds affichées dans la Crypte)." },
			{ Key = "ServerLuck", Icon = "🌐", Title = "Chance x2 pour TOUT le serveur (30 min)", Desc = "Tout le monde en profite et ton nom est annoncé. Parfait pour jouer entre amis." },
			{ Key = "InstantRebirth", Icon = "♻️", Title = "Rebirth instantané", Desc = "Effectue un rebirth immédiatement, sans avoir les coins nécessaires (mêmes effets qu'un rebirth normal)." },
		}
		local order = 0
		for _, item in ipairs(items) do
			local entry = findCatalog("Product", item.Key)
			if entry and not isHidden(entry) then
				order += 1
				itemCard({ LayoutOrder = order, Icon = item.Icon, Title = item.Title, Desc = item.Desc, ButtonText = priceText(entry), Configured = entry.Configured, OnBuy = function()
					ctx.prompt("Product", item.Key)
				end })
			end
		end
	end

	local function buildCoins()
		local rebirths = tonumber(ctx.attr("Rebirths")) or 0
		local order = 0
		for _, bundle in ipairs(Config.CoinBundles) do
			local entry = findCatalog("Product", bundle.Key)
			if entry and not isHidden(entry) then
				order += 1
				local amount = Economy.bundleAmount(bundle.Coins, rebirths)
				itemCard({
					LayoutOrder = order, Icon = "🪙", Title = bundle.Title .. " : " .. Economy.format(amount) .. " coins",
					Desc = rebirths > 0 and ("Bonus rebirth inclus (x" .. Economy.rebirthMultiplier(rebirths) .. "). Plus tu as de rebirths, plus tu reçois de coins !") or "Le montant augmente avec tes rebirths.",
					ButtonText = priceText(entry), Configured = entry.Configured, Badge = bundle.BestValue and "MEILLEURE VALEUR" or nil, BadgeColor = UI.Colors.Green, Stroke = bundle.BestValue and UI.Colors.Green or nil,
					OnBuy = function() ctx.prompt("Product", bundle.Key) end,
				})
			end
		end
		if ctx.state and ctx.state.Restricted then
			order += 1
			local card = UI.card(list, { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 60) })
			UI.label({ Text = "Certains articles ne sont pas disponibles dans ta région.", TextSize = 14, TextColor3 = UI.Colors.Muted, ZIndex = 24, Parent = card })
		end
	end

	local function refresh()
		if refreshing then
			return
		end
		refreshing = true
		UI.clear(list)
		if currentTab == "Offers" then
			buildOffers()
		elseif currentTab == "Passes" then
			buildPasses()
		elseif currentTab == "Boosts" then
			buildBoosts()
		elseif currentTab == "Coins" then
			buildCoins()
		end
		refreshing = false
	end

	local tabs = UI.tabs(body, {
		{ Key = "Offers", Text = "⚡ Offres" },
		{ Key = "Passes", Text = "🎟️ Passes" },
		{ Key = "Boosts", Text = "🚀 Boosts" },
		{ Key = "Coins", Text = "🪙 Coins" },
	}, function(key)
		currentTab = key
		refresh()
	end)

	window.OnOpen = function(context)
		tabs.Select(context and context.Tab or "Offers")
	end
	ctx.onState(function()
		if window.Frame.Visible then
			refresh()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(30)
			if window.Frame.Visible and currentTab == "Offers" then
				refresh()
			end
		end
	end)
end

return ShopController
