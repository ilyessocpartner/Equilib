# Haunt a House 👻

Jeu Roblox de type tycoon-collection horreur mignonne : ouvrir des cercueils, placer des monstres dans son manoir, faire peur aux visiteurs pour gagner des coins, rebirth, raid coop de Minuit, passe de saison, boutique complète.

- `docs/ANALYSE_MARCHE.md` : analyse de marché et justification du concept.
- `docs/GUIDE_DEBUTANT.md` : mise en ligne pas à pas (Studio, passes, produits, identifiants, lancement).
- `build/HauntAHouse.rbxlx` : fichier de place prêt à ouvrir dans Roblox Studio.

## Structure

```
default.project.json         projet Rojo (DataModel complet)
src/shared/                  ReplicatedStorage.Shared : config, données, logique pure, constructeur de monstres
src/server/Main.server.luau  point d'entrée serveur
src/server/Services/         data, joueur, carte, manoirs, inventaire, économie, cercueils, rebirth,
                             boutique, quotidien, temps de jeu, saison, codes, classements, boss, visiteurs
src/client/Main.client.luau  point d'entrée client
src/client/Controllers/      HUD, boutique, offres, cercueils, inventaire, bestiaire, rebirth,
                             quotidien, saison, codes, temps de jeu, boss, animations
tests/                       tests de logique pure (économie, gacha, offres, quotidien, saison)
```

## Construire

Prérequis : [Rojo 7.5+](https://rojo.space) (ou `rokit install` / `aftman install` dans ce dossier).

```
./build.sh        # Linux / macOS
build.cmd         # Windows
```

Le fichier `build/HauntAHouse.rbxlx` est produit. La carte est générée par script au lancement du serveur (aucun asset externe).

## Tester la logique

Prérequis : l'exécutable `luau` (https://github.com/luau-lang/luau/releases).

```
LUAU_BIN=/chemin/vers/luau tests/run_tests.sh
```

## Points techniques

- Sauvegarde : DataStore avec verrou de session, réessais exponentiels, autosave 60 s, `BindToClose`, reçus d'achat idempotents, mode mémoire automatique en Studio sans accès API.
- Anti-triche : toute l'économie est calculée côté serveur, limitation de débit par action, vérification des distances (crypte, caisse, visiteurs, boss), validation des types.
- Conformité : cercueils achetables uniquement en coins, probabilités affichées (somme 100 %) et recalculées avec la chance active, `PolicyService` pour masquer les articles liés au hasard dans les régions restreintes.
- Monétisation : 8 Game Passes, 12 Developer Products, pack de démarrage 24 h, offres flash tournantes (8 h), bundles de coins scalés par le rebirth, passe de saison à 20 paliers.
- Rétention : quotidien avec série, récompenses de temps de jeu, classements OrderedDataStore, bestiaire, rebirth, raid coop toutes les 10 minutes, codes.
