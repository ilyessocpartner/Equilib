# Phase 1 : analyse du marché Roblox (septembre 2026)

Cette analyse s'appuie sur des recherches web menées le 14 septembre 2026 (sources en fin de document). Elle justifie chaque décision de design du jeu **Haunt a House**.

## 1. Le marché en chiffres

| Indicateur | Valeur | Ce que ça change pour nous |
|---|---|---|
| Joueurs actifs par jour | environ 132 millions (T1 2026) | L'audience est là, la difficulté est la découvrabilité. |
| Payeurs uniques par mois | 31 millions (+52 % sur un an) | La conversion est en forte hausse : les joueurs achètent plus qu'avant. |
| Répartition par âge | 35 % moins de 13 ans, 38 % de 13 à 17 ans, 27 % de 18 ans et plus | Cible principale : 9 à 17 ans, avec une interface simple et un thème « effrayant mais mignon ». |
| Segment 18 ans et plus | croissance de plus de 50 % par an, dépense environ 40 % de plus par session | Le jeu doit rester agréable pour un adulte (progression profonde, coop). |
| Pic de joueurs simultanés plateforme | 47,4 millions (août 2026) | Les vagues virales sont gigantesques, il faut un jeu « regardable » sur TikTok. |

## 2. Les jeux qui dominent et pourquoi

| Jeu | Genre | Chiffres clés | Boucle de gameplay | Monétisation observée |
|---|---|---|---|---|
| Steal a Brainrot | vol et défense, tycoon | record absolu de 25,8 M de joueurs simultanés (oct. 2025), environ 1,4 M$ de revenu mensuel estimé | Acheter des unités sur un tapis roulant, elles génèrent du cash, voler celles des autres, rebirth | Pack de démarrage 189 R$ (valeur 499), Chance serveur x2 249 R$, VIP 499 R$, 2x Money 299 R$, armes 749 R$, Admin 7 499 R$, bundles de cash, lucky blocks ; le rebirth ajoute des emplacements et un multiplicateur |
| Grow a Garden (et sa suite) | idle cozy, collection | 21,3 M simultanés (juin 2025), racheté par Do Big Studios | Planter, récolter, animaux qui boostent, évènements météo | Passe premium 749 R$, « Grow All » 375 R$, sauts de temps 49 R$, œufs premium en Robux, double monnaie (Sheckles ou Robux) |
| Steal An Egg | tycoon et collection de pets | sorti le 20 août 2026, 9,87 M simultanés le 5 septembre 2026, numéro 1 actuel | Voler des œufs dans des nids, les éclore, les pets génèrent un revenu, tapis d'entraînement, rebirth | 2x Money 399 R$, 2x Speed 467 R$, VIP (+20 % revenu), Lucky Hatch ; retiré quelques jours par Roblox pour un système de « reels » jugé contraire aux nouvelles règles anti-défilement passif |
| Pet Simulator 99 | simulateur de pets | référence historique du genre | Casser des objets, éclore des œufs, fusionner, énigmes | Ensemble de passes d'environ 8 075 R$ : Huge Hunter 3 250, +40 œufs 1 499, Magic Eggs 1 200, Ultra Lucky 800, VIP 400 ; œufs exclusifs 2 pour 240 R$ jusqu'à 169 pour 14 500 R$ ; « Forever Pack » hebdomadaire à prix croissants (50 à 2 400 R$) |
| 99 Nights in the Forest | survie coop | pic de 14,2 M simultanés, plus de 28 milliards de visites | Survivre la nuit, feu de camp, construction de base, coop | Passes et produits, forte viralité grâce aux jump scares « regardables » |
| Rivals | FPS | 8 à 15 M$ par mois, meilleur revenu de la plateforme | Matchs rapides | Skins d'armes, passe de combat |
| Blox Fruits | RPG anime | 8 à 14 M$ par mois | Progression longue, fruits rotatifs | Passes permanents + rotation de contenu qui relance les achats |
| Brookhaven RP | roleplay | 500 000 joueurs simultanés en moyenne, 6 à 12 M$ par mois | Vie sociale | Maisons et véhicules premium |
| Adopt Me | pets et trading | 5 à 10 M$ par mois | Élever, échanger | Œufs limités, économie d'échange |
| Dress to Impress | mode sociale | 2 à 5 M$ par mois | Concours de tenues | Cosmétiques, passes saisonniers |
| Fisch | pêche RPG | 3 à 6 M$ par mois | Pêcher, améliorer sa canne, explorer | Passes et cosmétiques ; preuve qu'un genre hybride récent peut atteindre le sommet |
| Animal Hospital | gestion et horreur | 1,2 M simultanés (mai 2026) | Gérer un hôpital pendant que des « anomalies » se cachent parmi les patients | Cosmétiques et classes ; preuve que l'hybride gestion + horreur marche |
| Murder Mystery 2 | social et deduction | record de 1,35 M simultanés en août 2026 grâce à un évènement saisonnier | Rounds courts | Skins, évènements saisonniers |

### Les mécaniques qui reviennent partout
1. **Unité qui produit de l'argent passivement** (brainrot, pet, plante) : le joueur voit son revenu par seconde monter, ce qui rend la progression lisible et addictive.
2. **Gacha en monnaie du jeu** (œufs, cercueils, lucky blocks) avec raretés colorées et annonces serveur quand quelqu'un obtient un objet rare (preuve sociale).
3. **Rebirth** : remise à zéro contre un multiplicateur permanent, plus d'emplacements et de nouveaux paliers de contenu.
4. **Emplacements limités** (slots, pens, salles) : la contrainte crée le besoin d'améliorer ses unités et vend des passes « +slots ».
5. **Moment « regardable »** : les vidéos d'enfants qui pleurent après un vol (Steal a Brainrot) ou les jump scares (99 Nights) ont servi de publicité gratuite sur TikTok et YouTube.
6. **Évènements récurrents dans la session** (Taco Tuesday, Yin Yang Drops, évènements météo) pour garder les joueurs connectés.

## 3. Comment les gros jeux poussent à l'achat

| Levier | Exemple observé | Mise en œuvre dans Haunt a House |
|---|---|---|
| Pack de démarrage à prix cassé | Steal a Brainrot : 189 R$ affiché « valeur 499 » | Pack à 99 R$ (valeur affichée 400), fenêtre de 24 h, popup 45 s après l'arrivée |
| Ancrage par un pass cher | RoLearn : un pass à 999 R$ rend les autres « abordables » | Pack Ultime à 1 499 R$ affiché en premier avec « -30 % » |
| Échelle de 4 à 6 passes | les jeux avec 5 passes ou plus gagnent 2,3 fois plus | 8 passes de 199 à 1 499 R$ |
| Prix juste sous les ronds | 149, 299, 799 apparaissent partout | 99, 199, 249, 299, 349, 449, 599, 1 499 |
| Passes qui résolvent une frustration | conversion 2 à 3 fois supérieure aux cosmétiques | Auto Collect, 2x Coins, +3 Salles, Triple Cercueil |
| Achats répétables scalés | bundles de cash multipliés par le rebirth (Steal a Brainrot) | Bundles de coins multipliés par le multiplicateur de rebirth |
| Achat social | « Server Luck » annoncé à tout le serveur | Chance x2 pour tout le serveur, avec annonce du nom de l'acheteur |
| Offres à durée limitée | Forever Pack hebdomadaire de PS99 | 3 offres flash qui tournent toutes les 8 h avec compte à rebours |
| Passe de combat | Rivals, Dress to Impress | Passe Spooky : 20 paliers, piste gratuite et piste premium à 399 R$ |
| Gacha conforme | politique « Paid Random Items » de Roblox | Cercueils achetables uniquement en coins, probabilités affichées à 100 %, chance affichée dynamiquement, articles liés au hasard masqués dans les régions restreintes via PolicyService |

## 4. Rétention : ce qui fait revenir

- Récompenses quotidiennes avec série (le jour 7 donne un objet rare), présentes dans tous les leaders.
- Récompenses de temps de jeu en session (2, 5, 10, 20, 30, 45, 60 min).
- Classements globaux (coins, rebirths, puissance).
- Bestiaire avec cases « ??? » qui indiquent où trouver le monstre manquant.
- Contenu verrouillé visible (cercueils grisés « Rebirth 2 », salles cadenassées).
- Évènement coop toutes les 10 minutes (raid de Minuit) : une raison de rester encore un peu.
- Le seuil rappelé par les guides : ajouter des passes seulement quand la rétention à 7 jours dépasse 15 %. Le jeu est livré avec ces systèmes dès le premier jour pour ne pas avoir à les rajouter après.

## 5. Tendances et niches (opportunités et pièges)

**Saturé, à éviter** : les clones « Steal a X » et « Grow a X » (Bloomberg rapporte au moins quatre procès des créateurs de Steal a Brainrot contre des imitateurs ; les listes de tendances parlent de « clones IA »), les simulateurs génériques, les copies d'indés Steam.

**Sous-exploité, en croissance** :
- L'hybride **horreur + tycoon** est cité par RoLearn comme l'opportunité au potentiel le plus élevé du genre horreur, et Animal Hospital (1,2 M simultanés) prouve que « gestion + horreur » convertit.
- La coop horreur avec progression (99 Nights) et les évènements saisonniers (Murder Mystery 2 a battu son record en août 2026 avec un évènement).
- Le calendrier : nous sommes à six semaines d'Halloween, la période où le contenu effrayant explose sur Roblox.
- Les alternatives « douces » aux jeux de vol : parents et presse critiquent les vols entre joueurs (enfants qui pleurent), et Roblox a retiré Steal An Egg quelques jours pour ses mécaniques de défilement passif. Un jeu où l'on ne perd jamais sa progression au profit d'un autre joueur garde l'émotion sans la frustration.

# Phase 2 : le concept retenu

## Haunt a House 👻

**Pitch** : tu es le fantôme en chef d'un manoir hanté. Tu ouvres des cercueils pour obtenir des monstres, tu les places dans les salles du manoir, des visiteurs entrent et repartent en hurlant en laissant leurs coins. Plus tes monstres sont rares, plus tu gagnes. Toutes les 10 minutes, à Minuit, le Capitaine Chasseur attaque l'arène et tout le serveur doit coopérer pour le vaincre.

**Pourquoi un joueur choisirait ce jeu plutôt qu'un autre**
1. **Inversion du point de vue** : dans DOORS ou 99 Nights on subit la peur ; ici, on la provoque. Le « BOO » actif sur les visiteurs est un moment regardable et drôle, filmable en clips courts.
2. **Zéro perte face aux autres joueurs** : pas de vol de monstres, donc pas de rage-quit ni d'inquiétude des parents, tout en gardant l'économie éprouvée de Steal a Brainrot (unités, emplacements, rebirth).
3. **Coop au lieu de PvP** : le raid de Minuit récompense tout le monde selon sa participation, ce qui rend le serveur social sans griefing.
4. **Timing** : lancement fin septembre, montée naturelle avec Halloween, saison 1 « Nuit d'Halloween » jusqu'au 31 octobre 2026.
5. **Nom qui suit la formule qui marche** (« Verbe a Nom ») pour la recherche et la reconnaissance immédiate, sans copier une marque existante.

**Public cible** : 9 à 17 ans en priorité (mignon-effrayant, interface simple, mobile compatible), sans exclure les 18 ans et plus (progression longue, économie à optimiser, coop).

**Potentiel de revenus** : les tycoons Roblox convertissent 2 à 5 % des joueurs avec un panier moyen de 100 à 300 R$. Avec la grille de 8 passes, 12 produits, le pack de démarrage, les offres flash et le passe de saison, l'objectif de ce design est un panier moyen dans le haut de cette fourchette. Le chiffre réel dépendra de l'acquisition (voir le guide de lancement).

**Stratégie de monétisation détaillée** : voir le tableau des prix dans `GUIDE_DEBUTANT.md` et la section 3 ci-dessus. Résumé de l'entonnoir :
- Minute 0 à 5 : premier cercueil gratuit grâce aux coins de départ, code LAUNCH, premier « BOO ». Popup du pack de démarrage à 45 s.
- Minute 5 à 30 : les salles se remplissent, frustration « salles pleines » → pass +3 Salles, Auto Collect (la caisse se remplit et il faut revenir la vider), 2x Coins.
- Après le premier rebirth (25 000 coins, environ 30 à 45 min de jeu actif) : bundles de coins scalés, Chance x2 pour viser les Légendaires du Cercueil en Or, offres flash.
- En continu : passe de saison, raid de Minuit (Cercueils Cauchemar), série quotidienne.

## Sources consultées

- [Roblox Charts 2026 : top 10 (ejaw.net)](https://ejaw.net/roblox-charts/)
- [The 10 Highest-Earning Roblox Games in 2026 (RoWatcher)](https://rowatcher.com/news/the-10-highest-earning-roblox-games-in-2026-and-what-they-mean-for-the-platform)
- [10 Most Popular Roblox Games in 2026 by Concurrent Players (MaxLevelGG)](https://www.maxlevelgg.com/news/ten-most-popular-roblox-games-in-twenty-twenty-six-based-on-concurrent-players/)
- [Roblox Statistics 2026 (ShaneTheGamer)](https://www.shanethegamer.com/research/roblox-statistics/)
- [Roblox Statistics 2026 (SQ Magazine)](https://sqmagazine.co.uk/roblox-statistics/)
- [Who actually plays Roblox in 2026 (ZehnStudio)](https://zehn-studio26.com/news/roblox-audience-2026-age-breakdown/)
- [Roblox achieves record 47.4 million concurrent players (Notebookcheck)](https://www.notebookcheck.net/Roblox-achieves-record-breaking-47-4-million-concurrent-players-in-August-despite-recent-legal-controversies.1096346.0.html)
- [Steal a Brainrot (Wikipedia)](https://en.wikipedia.org/wiki/Steal_a_Brainrot)
- [Steal a Brainrot Monetization (RoMonitor Stats)](https://romonitorstats.com/experience/109983668079237/monetization/)
- [The Algorithm Behind Steal a Brainrot (Andy Hall)](https://freesystems.substack.com/p/the-algorithm-behind-steal-a-brainrot)
- [Steal a Brainrot Player Count and Revenue (RoWatcher)](https://rowatcher.com/games/7709344486/steal-a-brainrot)
- [Gamepasses and Dev Products, Steal a Brainrot Wiki](https://stealabrainrot.fandom.com/wiki/Gamepasses_and_Dev_Products)
- [Steal a Brainrot Rebirth Guide (GameRant)](https://gamerant.com/roblox-steal-a-brainrot-rebirth-guide/)
- [Roblox's Hit Game Steal A Brainrot Battles Its Many Imitators (Bloomberg)](https://www.bloomberg.com/news/articles/2026-03-24/roblox-s-hit-game-steal-a-brainrot-battles-its-many-imitators)
- [Roblox's AI Slop Clones (Windows Central)](https://www.windowscentral.com/gaming/how-roblox-theft-is-becoming-a-big-problem)
- [Grow a Garden (Wikipedia)](https://en.wikipedia.org/wiki/Grow_a_Garden)
- [Do Big Studios and Grow a Garden (TheSpike)](https://www.thespike.gg/roblox/beginner-guides/big-studios-grow-a-garden-roblox)
- [Grow a Garden Mechanics (Fandom)](https://growagarden.fandom.com/wiki/Mechanics)
- [Steal An Egg Live Player Count (RoVitals)](https://rovitals.com/game/107778070777162)
- [Steal An Egg (Roblox Wiki)](https://roblox.fandom.com/wiki/And_Collect_Rare_Pets/Steal_An_Egg)
- [Steal An Egg Gamepasses (Fandom)](https://stealanegg.fandom.com/wiki/Gamepasses)
- [Steal an Egg Beginner Guide (games.gg)](https://games.gg/roblox/guides/steal-an-egg-beginner-guide/)
- [Steal An Egg pulled hours after reaching the top (EGamers)](https://egamers.io/robloxs-no-1-game-steal-an-egg-was-pulled-hours-after-reaching-the-top/)
- [Gamepasses, Pet Simulator 99 Wiki](https://pet-simulator.fandom.com/wiki/Gamepasses_(Pet_Simulator_99))
- [Exclusive Pets Egg, Pet Simulator 99 Wiki](https://pet-simulator.fandom.com/wiki/Exclusive_Pets_Egg_(Pet_Simulator_99))
- [Pet Simulator 99 Economy Explained (RoWatcher)](https://rowatcher.com/news/pet-simulator-99-economy-explained-gems-enchants-and-the-true-cost-of-progress)
- [99 Nights in the Forest hits 14.2 million players (games.gg)](https://games.gg/news/99-nights-forest-14-million-roblox/)
- [99 Nights in the Forest interview (PCGamesN)](https://www.pcgamesn.com/roblox/99-nights-in-the-forest-interview)
- [Top Roblox Games August 2026 (StudioKrew)](https://studiokrew.com/blog/top-roblox-games-august-2026/)
- [Animal Hospital hits 1.2 million CCU (GosuGamers)](https://www.gosugamers.net/entertainment/news/78773-roblox-animal-hospital-hits-1-2-million-ccu-with-major-update-featuring-new-character-and-items)
- [The Roblox Horror Genre: Market Report 2026 (RoLearn)](https://rolearn.dev/trend-reports/roblox-horror-genre-market-report-2026/)
- [Most Popular Roblox Game Genres in 2026 (KitsBlox)](https://kitsblox.com/blog/popular-roblox-game-genres-2026)
- [Roblox Tycoon Games 2026 (Endsights)](https://endsights.com/roblox-tycoon-games)
- [Gamepass Pricing Strategy (RoLearn)](https://rolearn.dev/guidance/roblox-gamepass-pricing-strategy-guide/)
- [The Gamepass Pricing Ladder (RoLearn)](https://rolearn.dev/insights/gamepass-pricing-ladder/)
- [Roblox Game Pass Pricing Guide 2026 (Generalist Programmer)](https://generalistprogrammer.com/tutorials/roblox-game-pass-pricing-guide)
- [Roblox Game Monetization 2026 (Generalist Programmer)](https://generalistprogrammer.com/tutorials/roblox-game-monetization-complete-revenue-strategy-guide)
- [Monetization foundations (Roblox Creator Hub)](https://create.roblox.com/docs/production/game-design/monetization-foundations)
- [Paid random items policy guidelines (Roblox Creator Hub)](https://create.roblox.com/docs/production/monetization/paid-random-items)
- [Clarifying Requirements for Paid Random Items (Roblox DevForum)](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622)
- [Korea's loot box rules push Roblox to disclose odds worldwide (TechTimes)](https://www.techtimes.com/articles/319148/20260626/koreas-loot-box-rules-push-roblox-disclose-item-odds-worldwide.htm)
- [Roblox Monetization Guide (Obby)](https://www.obby.fun/blog/roblox-monetization-guide)
- [September's top grossing mobile games (MobileGamer.biz)](https://mobilegamer.biz/septembers-top-grossing-mobile-games-2/)
