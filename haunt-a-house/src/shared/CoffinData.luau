--!nonstrict
-- Cercueils (oeufs) : cout, condition de rebirth et contenus ponderes.
local CoffinData = {}

CoffinData.List = {
	{
		Id = "wooden", Name = "Cercueil en Bois", Cost = 150, RebirthRequired = 0, Color = { 120, 80, 40 }, Accent = { 90, 60, 30 },
		Contents = { { Id = "ghosty", Weight = 60 }, { Id = "boo_bat", Weight = 25 }, { Id = "jack", Weight = 10 }, { Id = "skelly", Weight = 4.5 }, { Id = "mini_reaper", Weight = 0.5 } },
	},
	{
		Id = "iron", Name = "Cercueil en Fer", Cost = 1200, RebirthRequired = 0, Color = { 110, 115, 125 }, Accent = { 70, 75, 85 },
		Contents = { { Id = "zombo", Weight = 50 }, { Id = "spidey", Weight = 30 }, { Id = "frankie", Weight = 12 }, { Id = "vampy", Weight = 6 }, { Id = "banshee", Weight = 1.9 }, { Id = "werewolf", Weight = 0.1 } },
	},
	{
		Id = "golden", Name = "Cercueil en Or", Cost = 10000, RebirthRequired = 1, Color = { 230, 185, 60 }, Accent = { 180, 130, 30 },
		Contents = { { Id = "mummy", Weight = 48 }, { Id = "gargoyle", Weight = 30 }, { Id = "witchy", Weight = 14 }, { Id = "headless", Weight = 6 }, { Id = "phantom_knight", Weight = 1.8 }, { Id = "dracula", Weight = 0.2 } },
	},
	{
		Id = "cursed", Name = "Cercueil Maudit", Cost = 100000, RebirthRequired = 2, Color = { 90, 40, 120 }, Accent = { 160, 80, 220 },
		Contents = { { Id = "poltergeist", Weight = 45 }, { Id = "scarecrow", Weight = 30 }, { Id = "swampy", Weight = 15 }, { Id = "wendigo", Weight = 7 }, { Id = "lich", Weight = 2.5 }, { Id = "kraken", Weight = 0.48 }, { Id = "nightmare_fox", Weight = 0.02 } },
	},
	{
		Id = "crystal", Name = "Cercueil de Cristal", Cost = 1000000, RebirthRequired = 4, Color = { 140, 210, 255 }, Accent = { 220, 245, 255 },
		Contents = { { Id = "crystal_golem", Weight = 45 }, { Id = "ice_wraith", Weight = 30 }, { Id = "storm_spirit", Weight = 15 }, { Id = "void_cat", Weight = 7 }, { Id = "demon_lord", Weight = 2.5 }, { Id = "ancient_dragon", Weight = 0.48 }, { Id = "eclipse", Weight = 0.02 } },
	},
	{
		Id = "void", Name = "Cercueil du Neant", Cost = 12000000, RebirthRequired = 6, Color = { 25, 15, 45 }, Accent = { 140, 60, 255 },
		Contents = { { Id = "void_walker", Weight = 45 }, { Id = "shadow_hound", Weight = 30 }, { Id = "star_eater", Weight = 15 }, { Id = "chaos_jester", Weight = 7 }, { Id = "abyss_queen", Weight = 2.5 }, { Id = "galaxy_titan", Weight = 0.48 }, { Id = "the_omen", Weight = 0.019 }, { Id = "old_one", Weight = 0.001 } },
	},
	{
		Id = "nightmare", Name = "Cercueil Cauchemar", Cost = 0, RebirthRequired = 0, EventOnly = true, Color = { 20, 5, 30 }, Accent = { 255, 80, 40 },
		Contents = { { Id = "pumpkin_king", Weight = 55 }, { Id = "nightmare_clown", Weight = 25 }, { Id = "hunter_ghost", Weight = 15 }, { Id = "skull_dragon", Weight = 4.5 }, { Id = "midnight", Weight = 0.5 } },
	},
}

CoffinData.ById = {}
for _, coffin in ipairs(CoffinData.List) do
	CoffinData.ById[coffin.Id] = coffin
end

function CoffinData.get(id)
	return CoffinData.ById[id]
end

-- Cercueil d'origine d'un monstre (pour le prix de revente)
CoffinData.CoffinOfMonster = {}
for _, coffin in ipairs(CoffinData.List) do
	for _, entry in ipairs(coffin.Contents) do
		CoffinData.CoffinOfMonster[entry.Id] = coffin.Id
	end
end

-- Valeur de reference des monstres exclusifs (hors cercueil) pour la revente
CoffinData.ExclusiveReferenceCost = {
	golden_ghosty = 1200,
	vip_phantom = 10000,
	pass_phantom = 10000,
	season_reaper = 100000,
}

-- Valeur de reference du cercueil Cauchemar (non achetable) pour la revente
CoffinData.NightmareReferenceCost = 20000

function CoffinData.referenceCost(monsterId)
	local coffinId = CoffinData.CoffinOfMonster[monsterId]
	if coffinId == "nightmare" then
		return CoffinData.NightmareReferenceCost
	end
	if coffinId then
		return CoffinData.ById[coffinId].Cost
	end
	return CoffinData.ExclusiveReferenceCost[monsterId] or 1000
end

return CoffinData
