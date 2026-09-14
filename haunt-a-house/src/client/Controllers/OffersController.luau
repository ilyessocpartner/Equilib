--!nonstrict
-- Fenetre du pack de demarrage (affichee une fois par session tant que l'offre est active).
local OffersController = {}

function OffersController.init(ctx)
	local UI = ctx.UI
	local Config = ctx.Config
	local Economy = ctx.Economy
	local Offers = ctx.Offers
	local shown = false

	local function showStarter()
		if shown then
			return
		end
		shown = true
		local overlay = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, ZIndex = 60, Parent = UI.modalLayer() })
		local box = UI.new("Frame", { Size = UDim2.fromScale(0.5, 0.62), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(60, 25, 55), ZIndex = 61, Parent = overlay }, {
			UI.corner(20), UI.stroke(UI.Colors.Accent, 4), UI.padding(18, 14),
			UI.new("UISizeConstraint", { MaxSize = Vector2.new(560, 460), MinSize = Vector2.new(300, 300) }),
		})
		UI.label({ Text = "🎁 PACK DE DÉMARRAGE", Font = UI.Font, TextSize = 32, TextScaled = true, Size = UDim2.new(1, 0, 0.14, 0), TextColor3 = UI.Colors.Gold, ZIndex = 62, Parent = box })
		UI.label({ Text = "Offre unique pour les nouveaux hanteurs !", TextSize = 16, TextScaled = true, Size = UDim2.new(1, 0, 0.08, 0), Position = UDim2.fromScale(0, 0.14), TextColor3 = UI.Colors.Muted, ZIndex = 62, Parent = box })
		local contents = "🪙 " .. Economy.format(Config.StarterPack.Coins) .. " coins\n👻 Ghosty Doré (monstre EPIQUE exclusif, conservé au rebirth)\n⚡ 2x Coins pendant 30 min"
		UI.label({ Text = contents, TextSize = 18, TextScaled = true, Size = UDim2.new(1, 0, 0.36, 0), Position = UDim2.fromScale(0, 0.24), ZIndex = 62, Parent = box })
		local timer = UI.label({ Text = "", Font = UI.Font, TextSize = 18, TextScaled = true, Size = UDim2.new(1, 0, 0.1, 0), Position = UDim2.fromScale(0, 0.6), TextColor3 = UI.Colors.Red, ZIndex = 62, Parent = box })
		local price = ctx.MonetizationIds.Products.StarterPack.Price
		UI.label({ Text = "<s>Valeur R$ " .. Config.StarterPack.WorthRobux .. "</s>", TextSize = 16, TextScaled = true, Size = UDim2.new(1, 0, 0.07, 0), Position = UDim2.fromScale(0, 0.7), TextColor3 = UI.Colors.Muted, ZIndex = 62, Parent = box })
		UI.button({ Text = "ACHETER  R$ " .. price, Color = UI.Colors.Robux, Size = UDim2.new(0.6, 0, 0.13, 0), Position = UDim2.fromScale(0.2, 0.78), ZIndex = 62, MaxTextSize = 26, Parent = box, OnClick = function()
			ctx.prompt("Product", "StarterPack")
			overlay:Destroy()
		end })
		UI.button({ Text = "Plus tard", Color = Color3.fromRGB(90, 85, 110), Size = UDim2.new(0.3, 0, 0.09, 0), Position = UDim2.fromScale(0.35, 0.92), ZIndex = 62, MaxTextSize = 16, Parent = box, OnClick = function()
			overlay:Destroy()
		end })
		task.spawn(function()
			while overlay.Parent do
				local remaining = Offers.starterRemaining(tonumber(ctx.attr("StarterFirstJoin")) or 0, ctx.attr("StarterPurchased") == true, os.time())
				if remaining <= 0 then
					overlay:Destroy()
					break
				end
				timer.Text = "⏳ Expire dans " .. Economy.formatTime(remaining)
				task.wait(1)
			end
		end)
	end

	task.spawn(function()
		task.wait(Config.StarterPack.PopupDelay)
		while ctx.attr("DataLoaded") ~= true or ctx.state == nil do
			task.wait(1)
		end
		local configured = ctx.MonetizationIds.Products.StarterPack.Id > 0
		local remaining = Offers.starterRemaining(tonumber(ctx.attr("StarterFirstJoin")) or 0, ctx.attr("StarterPurchased") == true, os.time())
		if configured and remaining > 0 and not ctx.state.Restricted then
			showStarter()
		end
	end)
end

return OffersController
