--!nonstrict
-- ===============================================================
--  IDENTIFIANTS DE MONETISATION
--  Remplacez chaque 0 par l'identifiant cree sur create.roblox.com
--  (voir docs/GUIDE_DEBUTANT.md, etape 3). Un identifiant laisse a 0
--  desactive proprement l'article correspondant dans la boutique.
-- ===============================================================
local Ids = {}

-- Game Passes (achat unique, permanent). Prix recommandes en Robux.
Ids.GamePasses = {
	DoubleCoins = { Id = 0, Price = 299, Name = "2x Coins", Desc = "Double tous tes gains, pour toujours.", Icon = "💰" },
	AutoCollect = { Id = 0, Price = 199, Name = "Auto Collect", Desc = "Tes coins vont directement dans ta poche.", Icon = "🧲" },
	TripleHatch = { Id = 0, Price = 249, Name = "Triple Cercueil", Desc = "Ouvre 3 cercueils d'un coup.", Icon = "⚰️" },
	ExtraRooms = { Id = 0, Price = 349, Name = "+3 Salles", Desc = "3 salles de plus dans ton manoir.", Icon = "🏚️" },
	Lucky = { Id = 0, Price = 449, Name = "Chance x2", Desc = "Double tes chances de monstres rares.", Icon = "🍀" },
	VIP = { Id = 0, Price = 599, Name = "VIP", Desc = "+25% coins, +1 salle, monstre exclusif, tag VIP.", Icon = "👑" },
	Ultimate = { Id = 0, Price = 1499, Name = "Pack Ultime", Desc = "TOUS les passes ci-dessus. Economise 30%.", Icon = "🌟" },
	SeasonPremium = { Id = 0, Price = 399, Name = "Passe Spooky Premium", Desc = "Debloque la piste premium de la saison.", Icon = "🎃" },
}

-- Developer Products (achats repetables). Prix recommandes en Robux.
Ids.Products = {
	CoinsSmall = { Id = 0, Price = 49, Name = "Bourse de coins" },
	CoinsMedium = { Id = 0, Price = 199, Name = "Sac de coins" },
	CoinsLarge = { Id = 0, Price = 499, Name = "Coffre de coins" },
	CoinsHuge = { Id = 0, Price = 1499, Name = "Chambre forte" },
	BoostCoins = { Id = 0, Price = 79, Name = "Boost 2x Coins (30 min)" },
	BoostLuck = { Id = 0, Price = 99, Name = "Boost 2x Chance (30 min)" },
	ServerLuck = { Id = 0, Price = 199, Name = "Chance x2 pour tout le serveur (30 min)" },
	InstantRebirth = { Id = 0, Price = 349, Name = "Rebirth instantane" },
	StarterPack = { Id = 0, Price = 99, Name = "Pack de demarrage" },
	FlashCoinVault = { Id = 0, Price = 399, Name = "Offre flash : Coffre +50%" },
	FlashBoostBundle = { Id = 0, Price = 149, Name = "Offre flash : Pack Boosts" },
	FlashRebirthRush = { Id = 0, Price = 299, Name = "Offre flash : Rebirth Express" },
}

-- Groupe Roblox (facultatif) : +10% de coins pour les membres. 0 = desactive.
Ids.GroupId = 0

return Ids
