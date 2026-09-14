--!nonstrict
-- Catalogue des monstres. Power = coins par seconde (avant multiplicateurs).
-- Visual : recette utilisee par MonsterBuilder pour construire le modele 3D.
--   body : Ball | Block | Cylinder | Wedge
--   eyes : dots | angry | cute | cyclops | glow
--   mouth : smile | fangs | zigzag | o | none
--   hat : none | witch | top | horns | halo | crown | bolt | bandage | stem | hood | ears | helm | jester
--   aura : none | glow | fire | ice | void | sparkle
local MonsterData = {}

local function V(body, color, material, eyes, mouth, hat, aura, accent, scale, transparency)
	return {
		Body = body,
		Color = color,
		Material = material or "SmoothPlastic",
		Eyes = eyes or "dots",
		Mouth = mouth or "smile",
		Hat = hat or "none",
		Aura = aura or "none",
		Accent = accent or { 255, 255, 255 },
		Scale = scale or 1,
		Transparency = transparency or 0,
	}
end

MonsterData.List = {
	-- Cercueil en Bois
	{ Id = "ghosty", Name = "Ghosty", Rarity = "Common", Power = 1, Visual = V("Ball", { 245, 245, 255 }, "SmoothPlastic", "dots", "o", "none", "none", nil, 1, 0.15) },
	{ Id = "boo_bat", Name = "Chauve-Boo", Rarity = "Common", Power = 1.5, Visual = V("Ball", { 70, 50, 110 }, "SmoothPlastic", "glow", "fangs", "ears", "none", { 255, 230, 80 }, 0.85) },
	{ Id = "jack", Name = "Jack Citrouille", Rarity = "Uncommon", Power = 4, Visual = V("Ball", { 255, 140, 30 }, "SmoothPlastic", "angry", "zigzag", "stem", "glow", { 80, 140, 40 }, 1.05) },
	{ Id = "skelly", Name = "Skelly", Rarity = "Rare", Power = 12, Visual = V("Block", { 235, 230, 215 }, "SmoothPlastic", "dots", "zigzag", "none", "none", nil, 1) },
	{ Id = "mini_reaper", Name = "Mini Faucheuse", Rarity = "Epic", Power = 40, Visual = V("Cylinder", { 30, 30, 40 }, "Fabric", "glow", "none", "hood", "glow", { 120, 255, 160 }, 1.1) },

	-- Cercueil en Fer
	{ Id = "zombo", Name = "Zombo", Rarity = "Common", Power = 5, Visual = V("Block", { 110, 170, 90 }, "SmoothPlastic", "cute", "zigzag", "none", "none", nil, 1) },
	{ Id = "spidey", Name = "Araignette", Rarity = "Common", Power = 7, Visual = V("Ball", { 35, 35, 35 }, "SmoothPlastic", "glow", "fangs", "none", "none", { 255, 60, 60 }, 0.9) },
	{ Id = "frankie", Name = "Frankie", Rarity = "Uncommon", Power = 18, Visual = V("Block", { 90, 160, 140 }, "SmoothPlastic", "dots", "smile", "bolt", "none", { 200, 200, 210 }, 1.1) },
	{ Id = "vampy", Name = "Vampy", Rarity = "Rare", Power = 50, Visual = V("Block", { 230, 220, 235 }, "SmoothPlastic", "angry", "fangs", "top", "none", { 20, 20, 30 }, 1) },
	{ Id = "banshee", Name = "Banshee", Rarity = "Epic", Power = 160, Visual = V("Ball", { 200, 220, 255 }, "ForceField", "glow", "o", "none", "glow", { 160, 200, 255 }, 1.15, 0.2) },
	{ Id = "werewolf", Name = "Loup-Garou", Rarity = "Legendary", Power = 600, Visual = V("Block", { 110, 75, 45 }, "Fabric", "angry", "fangs", "ears", "none", { 80, 55, 30 }, 1.25) },

	-- Cercueil en Or
	{ Id = "mummy", Name = "Momie", Rarity = "Common", Power = 25, Visual = V("Block", { 220, 205, 170 }, "Fabric", "dots", "none", "bandage", "none", { 200, 185, 150 }, 1) },
	{ Id = "gargoyle", Name = "Gargouille", Rarity = "Common", Power = 35, Visual = V("Block", { 120, 120, 130 }, "Slate", "glow", "fangs", "horns", "none", { 90, 90, 100 }, 1.05) },
	{ Id = "witchy", Name = "Sorcierette", Rarity = "Uncommon", Power = 90, Visual = V("Ball", { 150, 200, 90 }, "SmoothPlastic", "cute", "smile", "witch", "sparkle", { 60, 30, 90 }, 1) },
	{ Id = "headless", Name = "Cavalier sans Tete", Rarity = "Rare", Power = 250, Visual = V("Block", { 50, 40, 60 }, "Fabric", "glow", "none", "jester", "fire", { 255, 140, 30 }, 1.1) },
	{ Id = "phantom_knight", Name = "Chevalier Fantome", Rarity = "Epic", Power = 800, Visual = V("Block", { 160, 170, 190 }, "Metal", "glow", "none", "helm", "glow", { 120, 180, 255 }, 1.15) },
	{ Id = "dracula", Name = "Dracula", Rarity = "Legendary", Power = 3000, Visual = V("Block", { 240, 235, 240 }, "SmoothPlastic", "angry", "fangs", "top", "glow", { 200, 20, 40 }, 1.2) },

	-- Cercueil Maudit
	{ Id = "poltergeist", Name = "Poltergeist", Rarity = "Common", Power = 120, Visual = V("Ball", { 180, 255, 200 }, "ForceField", "glow", "zigzag", "none", "sparkle", { 180, 255, 200 }, 1, 0.3) },
	{ Id = "scarecrow", Name = "Epouvantail", Rarity = "Common", Power = 170, Visual = V("Block", { 200, 160, 90 }, "Fabric", "angry", "zigzag", "top", "none", { 120, 80, 40 }, 1.05) },
	{ Id = "swampy", Name = "Chose du Marais", Rarity = "Uncommon", Power = 450, Visual = V("Ball", { 60, 110, 60 }, "Grass", "cute", "smile", "none", "none", nil, 1.15) },
	{ Id = "wendigo", Name = "Wendigo", Rarity = "Rare", Power = 1250, Visual = V("Block", { 200, 200, 210 }, "Ice", "glow", "fangs", "horns", "ice", { 150, 200, 255 }, 1.2) },
	{ Id = "lich", Name = "Liche", Rarity = "Epic", Power = 4000, Visual = V("Cylinder", { 80, 60, 120 }, "Fabric", "glow", "none", "crown", "glow", { 120, 255, 200 }, 1.15) },
	{ Id = "kraken", Name = "Rejeton du Kraken", Rarity = "Legendary", Power = 15000, Visual = V("Ball", { 90, 60, 150 }, "SmoothPlastic", "cyclops", "fangs", "none", "sparkle", { 200, 120, 255 }, 1.3) },
	{ Id = "nightmare_fox", Name = "Renard Cauchemar", Rarity = "Mythic", Power = 60000, Visual = V("Block", { 40, 20, 60 }, "SmoothPlastic", "glow", "fangs", "ears", "void", { 255, 60, 200 }, 1.2) },

	-- Cercueil de Cristal
	{ Id = "crystal_golem", Name = "Golem de Cristal", Rarity = "Common", Power = 600, Visual = V("Block", { 150, 220, 255 }, "Glass", "dots", "none", "none", "ice", { 200, 240, 255 }, 1.15, 0.1) },
	{ Id = "ice_wraith", Name = "Spectre de Glace", Rarity = "Common", Power = 850, Visual = V("Ball", { 200, 240, 255 }, "Ice", "glow", "o", "none", "ice", { 180, 230, 255 }, 1, 0.2) },
	{ Id = "storm_spirit", Name = "Esprit d'Orage", Rarity = "Uncommon", Power = 2250, Visual = V("Ball", { 120, 140, 255 }, "Neon", "angry", "zigzag", "bolt", "sparkle", { 255, 255, 120 }, 1) },
	{ Id = "void_cat", Name = "Chat du Vide", Rarity = "Rare", Power = 6250, Visual = V("Ball", { 20, 20, 30 }, "SmoothPlastic", "glow", "smile", "ears", "void", { 160, 60, 255 }, 1) },
	{ Id = "demon_lord", Name = "Seigneur Demon", Rarity = "Epic", Power = 20000, Visual = V("Block", { 170, 30, 40 }, "SmoothPlastic", "angry", "fangs", "horns", "fire", { 255, 120, 30 }, 1.3) },
	{ Id = "ancient_dragon", Name = "Dragon Ancien", Rarity = "Legendary", Power = 75000, Visual = V("Block", { 60, 140, 90 }, "Metal", "angry", "fangs", "horns", "fire", { 255, 200, 60 }, 1.4) },
	{ Id = "eclipse", Name = "Eclipse", Rarity = "Mythic", Power = 300000, Visual = V("Ball", { 10, 10, 15 }, "SmoothPlastic", "glow", "none", "halo", "glow", { 255, 200, 80 }, 1.25) },

	-- Cercueil du Neant
	{ Id = "void_walker", Name = "Marcheur du Neant", Rarity = "Common", Power = 3000, Visual = V("Block", { 30, 25, 45 }, "SmoothPlastic", "glow", "none", "none", "void", { 140, 80, 255 }, 1.1) },
	{ Id = "shadow_hound", Name = "Molosse d'Ombre", Rarity = "Common", Power = 4250, Visual = V("Block", { 20, 20, 25 }, "SmoothPlastic", "glow", "fangs", "ears", "none", { 255, 40, 40 }, 1.1) },
	{ Id = "star_eater", Name = "Mangeur d'Etoiles", Rarity = "Uncommon", Power = 11250, Visual = V("Ball", { 60, 30, 90 }, "Neon", "cyclops", "o", "none", "sparkle", { 255, 255, 200 }, 1.2) },
	{ Id = "chaos_jester", Name = "Bouffon du Chaos", Rarity = "Rare", Power = 31000, Visual = V("Cylinder", { 200, 50, 120 }, "SmoothPlastic", "cute", "smile", "jester", "sparkle", { 80, 200, 255 }, 1.1) },
	{ Id = "abyss_queen", Name = "Reine des Abysses", Rarity = "Epic", Power = 100000, Visual = V("Cylinder", { 40, 60, 120 }, "Glass", "glow", "none", "crown", "ice", { 120, 220, 255 }, 1.25, 0.1) },
	{ Id = "galaxy_titan", Name = "Titan Galactique", Rarity = "Legendary", Power = 375000, Visual = V("Block", { 30, 40, 90 }, "Neon", "glow", "zigzag", "helm", "sparkle", { 200, 160, 255 }, 1.5) },
	{ Id = "the_omen", Name = "L'Omen", Rarity = "Mythic", Power = 1500000, Visual = V("Ball", { 15, 0, 25 }, "SmoothPlastic", "cyclops", "none", "halo", "void", { 255, 0, 120 }, 1.35) },
	{ Id = "old_one", Name = "L'Ancien", Rarity = "Secret", Power = 10000000, Visual = V("Ball", { 5, 5, 5 }, "Neon", "glow", "fangs", "crown", "void", { 255, 255, 255 }, 1.6) },

	-- Cercueil Cauchemar (evenements, boss, serie quotidienne)
	{ Id = "pumpkin_king", Name = "Roi Citrouille", Rarity = "Epic", Power = 900, KeepOnRebirth = true, Visual = V("Ball", { 255, 120, 20 }, "SmoothPlastic", "angry", "zigzag", "crown", "fire", { 255, 220, 60 }, 1.3) },
	{ Id = "nightmare_clown", Name = "Clown Cauchemar", Rarity = "Legendary", Power = 3500, KeepOnRebirth = true, Visual = V("Ball", { 250, 250, 250 }, "SmoothPlastic", "angry", "smile", "jester", "none", { 255, 40, 40 }, 1.15) },
	{ Id = "hunter_ghost", Name = "Fantome du Chasseur", Rarity = "Legendary", Power = 4000, KeepOnRebirth = true, Visual = V("Ball", { 180, 200, 180 }, "ForceField", "glow", "none", "top", "glow", { 120, 255, 160 }, 1.15, 0.2) },
	{ Id = "skull_dragon", Name = "Dragon Squelette", Rarity = "Mythic", Power = 25000, KeepOnRebirth = true, Visual = V("Block", { 230, 225, 210 }, "SmoothPlastic", "glow", "fangs", "horns", "fire", { 120, 255, 120 }, 1.4) },
	{ Id = "midnight", Name = "Minuit", Rarity = "Secret", Power = 250000, KeepOnRebirth = true, Visual = V("Ball", { 0, 0, 10 }, "SmoothPlastic", "glow", "none", "halo", "void", { 120, 120, 255 }, 1.5) },

	-- Exclusifs (pack de demarrage, VIP, passe de saison)
	{ Id = "golden_ghosty", Name = "Ghosty Dore", Rarity = "Epic", Power = 60, KeepOnRebirth = true, Exclusive = "Pack de demarrage", Visual = V("Ball", { 255, 215, 80 }, "Foil", "cute", "smile", "none", "sparkle", { 255, 240, 160 }, 1.1) },
	{ Id = "vip_phantom", Name = "Phantom VIP", Rarity = "Legendary", Power = 150, KeepOnRebirth = true, Exclusive = "Pass VIP", Visual = V("Ball", { 255, 200, 255 }, "ForceField", "glow", "smile", "crown", "sparkle", { 255, 220, 100 }, 1.15, 0.15) },
	{ Id = "pass_phantom", Name = "Spectre Spooky", Rarity = "Epic", Power = 700, KeepOnRebirth = true, Exclusive = "Passe Spooky palier 10", Visual = V("Ball", { 255, 120, 40 }, "SmoothPlastic", "cute", "zigzag", "witch", "fire", { 80, 30, 100 }, 1.1) },
	{ Id = "season_reaper", Name = "Faucheuse de Saison", Rarity = "Mythic", Power = 8000, KeepOnRebirth = true, Exclusive = "Passe Spooky palier 20", Visual = V("Cylinder", { 20, 10, 30 }, "Fabric", "glow", "none", "hood", "void", { 255, 120, 40 }, 1.3) },
}

MonsterData.ById = {}
for _, def in ipairs(MonsterData.List) do
	MonsterData.ById[def.Id] = def
end

function MonsterData.get(id)
	return MonsterData.ById[id]
end

return MonsterData
