--!nonstrict
-- Reglages globaux du jeu. Toutes les valeurs d'equilibrage sont ici.
local Config = {}

Config.GameName = "Haunt a House"
Config.CurrencyName = "Coins"
Config.CurrencyIcon = "🪙"
Config.DataStoreName = "HauntAHouse_Player_v1"
Config.DataVersion = 1

-- Terrain et parcelles (manoirs)
Config.Plot = {
	Count = 12, -- nombre de manoirs (= taille de serveur recommandee)
	RingRadius = 220,
	Width = 60,
	Length = 120,
	BaseRooms = 3, -- salles disponibles des le debut
	MaxRebirthRooms = 5, -- +1 salle par rebirth, jusqu'a 5
	MaxPurchasedRooms = 6, -- salles achetables avec des coins
	VipRooms = 1, -- pass VIP
	ExtraRoomsPass = 3, -- pass "+3 salles"
	TotalPads = 18, -- 3 + 5 + 6 + 1 + 3
}

-- Prix des salles achetables (1re, 2e, ... 6e salle achetee)
Config.RoomCosts = { 1000, 6000, 30000, 150000, 750000, 4000000 }

-- Rebirth
Config.Rebirth = {
	Costs = { 25000, 150000, 750000, 3000000, 12000000, 50000000 }, -- au-dela : x3 par rebirth
	CostGrowthAfterTable = 3,
	MultiplierPerRebirth = 0.5, -- x1.5 au 1er rebirth, x2 au 2e, ...
}

-- Revenus
Config.Income = {
	TickSeconds = 1,
	ScareBaseCoins = 5, -- coins minimum par effroi actif
	ScareIncomeSeconds = 2, -- un effroi rapporte l'equivalent de N secondes de revenu passif
	ScareCooldown = 0.45,
	ScareRange = 14,
	VisitorScareCooldown = 3,
	IndexBonusPerMonster = 0.01, -- +1% de coins par monstre decouvert
	GroupBonus = 0.10, -- +10% pour les membres du groupe
	VipBonus = 0.25,
	MaxUncollectedSeconds = 7200, -- la caisse du manoir stocke au maximum 2h de revenus
}

-- Visiteurs (PNJ qui traversent les manoirs)
Config.Visitors = {
	PerPlot = 4,
	Speed = 7,
	SpawnDelay = 2,
}

-- Boss cooperatif "Minuit"
Config.Boss = {
	IntervalSeconds = 600,
	DurationSeconds = 120,
	WarningSeconds = 20,
	BaseHealth = 1500,
	HealthPerPower = 60, -- PV = base + (somme des puissances du serveur) * ce facteur
	MinClickDamage = 10,
	ClickCooldown = 0.4,
	Range = 30,
	CoinsPerDamage = 40, -- recompense = degats infliges * 40 * multiplicateurs
	NightmareCoffinTopCount = 3, -- les 3 meilleurs recoivent un Cercueil Cauchemar garanti
	NightmareCoffinChanceOthers = 0.2,
	XpReward = 100,
	Name = "Capitaine Chasseur",
}

-- Boosts (secondes)
Config.Boosts = {
	CoinsBoostSeconds = 1800,
	LuckBoostSeconds = 1800,
	ServerLuckSeconds = 1800,
	CoinsBoostMultiplier = 2,
	LuckBoostMultiplier = 2,
	ServerLuckMultiplier = 2,
}

-- Inventaire
Config.Inventory = {
	MaxMonsters = 120,
}

-- Recompenses de temps de jeu (par session)
Config.Playtime = {
	{ Minutes = 2, Type = "Coins", Amount = 300 },
	{ Minutes = 5, Type = "Coins", Amount = 1200 },
	{ Minutes = 10, Type = "CoinsBoost", Minutes2 = 10 },
	{ Minutes = 20, Type = "Coins", Amount = 6000 },
	{ Minutes = 30, Type = "NightmareCoffin", Amount = 1 },
	{ Minutes = 45, Type = "LuckBoost", Minutes2 = 15 },
	{ Minutes = 60, Type = "Coins", Amount = 30000 },
}

-- Codes promo (majuscules). Chaque code est utilisable une seule fois par joueur.
Config.Codes = {
	LAUNCH = { Type = "Coins", Amount = 2500 },
	SPOOKY = { Type = "Coins", Amount = 1000 },
	HAUNT = { Type = "CoinsBoost", Minutes = 15 },
	BOO = { Type = "LuckBoost", Minutes = 15 },
}

-- Pack de demarrage : disponible 24h apres la premiere connexion
Config.StarterPack = {
	WindowSeconds = 24 * 3600,
	Coins = 15000,
	MonsterId = "golden_ghosty",
	CoinsBoostSeconds = 1800,
	PopupDelay = 45, -- secondes apres l'arrivee avant d'afficher la fenetre
	WorthRobux = 400,
}

-- Offres flash tournantes (toutes les 8h)
Config.FlashDeals = {
	RotationSeconds = 8 * 3600,
	Deals = {
		{ Key = "FlashCoinVault", Title = "Coffre +50%", Desc = "150 000 coins au lieu de 100 000", Coins = 150000, WorthRobux = 749 },
		{ Key = "FlashBoostBundle", Title = "Pack Boosts", Desc = "2x Coins 1h + 2x Chance 1h", CoinsBoostSeconds = 3600, LuckBoostSeconds = 3600, WorthRobux = 356 },
		{ Key = "FlashRebirthRush", Title = "Rebirth Express", Desc = "Rebirth instantane + 2x Coins 1h", InstantRebirth = true, CoinsBoostSeconds = 3600, WorthRobux = 428 },
	},
}

-- Bundles de coins (montant de base, multiplie par le multiplicateur de rebirth)
Config.CoinBundles = {
	{ Key = "CoinsSmall", Title = "Bourse", Coins = 5000, BestValue = false },
	{ Key = "CoinsMedium", Title = "Sac", Coins = 30000, BestValue = false },
	{ Key = "CoinsLarge", Title = "Coffre", Coins = 100000, BestValue = true },
	{ Key = "CoinsHuge", Title = "Chambre forte", Coins = 400000, BestValue = false },
}

-- Saison en cours (Passe Spooky)
Config.Season = {
	Id = 1,
	Name = "Saison 1 : Nuit d'Halloween",
	EndsAt = os.time({ year = 2026, month = 10, day = 31, hour = 23, min = 59, sec = 59 }),
	Tiers = 20,
	XpHatch = 10,
	XpScare = 2,
	XpBoss = 100,
	XpDaily = 150,
}

-- Anti-triche : nombre maximal d'appels distants par seconde et par joueur
Config.RateLimits = {
	Default = 8,
	Scare = 4,
	Hatch = 3,
	Shop = 2,
}

-- Classements
Config.Leaderboards = {
	RefreshSeconds = 120,
	Entries = 10,
}

return Config
