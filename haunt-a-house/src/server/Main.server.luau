--!nonstrict
-- Point d'entree serveur : initialise tous les services dans le bon ordre.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)

-- Cree les objets distants avant que les clients ne les attendent
Net.request()
Net.serverEvent()
Net.clientEvent()

local ServicesFolder = script.Parent.Services

local S = { Config = Config }
S.Net = require(script.Parent.NetServer)
S.Data = require(ServicesFolder.DataService)
S.Player = require(ServicesFolder.PlayerService)
S.Map = require(ServicesFolder.MapBuilder)
S.Plot = require(ServicesFolder.PlotService)
S.Inventory = require(ServicesFolder.InventoryService)
S.Economy = require(ServicesFolder.EconomyService)
S.Reward = require(ServicesFolder.RewardService)
S.Shop = require(ServicesFolder.ShopService)
S.Coffin = require(ServicesFolder.CoffinService)
S.Rebirth = require(ServicesFolder.RebirthService)
S.Daily = require(ServicesFolder.DailyRewardService)
S.Playtime = require(ServicesFolder.PlaytimeService)
S.Season = require(ServicesFolder.SeasonPassService)
S.Codes = require(ServicesFolder.CodesService)
S.Leaderboard = require(ServicesFolder.LeaderboardService)
S.Boss = require(ServicesFolder.BossService)
S.Visitor = require(ServicesFolder.VisitorService)

S.Net.init(S)
S.Data.init(S)
S.Map.build(S)
S.Plot.init(S)
S.Inventory.init(S)
S.Economy.init(S)
S.Reward.init(S)
S.Shop.init(S)
S.Coffin.init(S)
S.Rebirth.init(S)
S.Daily.init(S)
S.Playtime.init(S)
S.Season.init(S)
S.Codes.init(S)
S.Leaderboard.init(S)
S.Boss.init(S)
S.Visitor.init(S)
S.Player.init(S)

print("[Haunt a House] Serveur prêt : " .. Config.Plot.Count .. " manoirs, " .. #require(ReplicatedStorage.Shared.MonsterData).List .. " monstres.")
