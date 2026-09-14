# Guide de mise en ligne pour débutant total

Tu n'as rien à coder. Suis les étapes dans l'ordre. Compte environ 1 h 30 la première fois.

## Le plus simple : publication automatique (30 min)

Un outil publie tout à ta place : il crée les 8 passes et les 12 produits aux bons prix, inscrit leurs identifiants dans le jeu, règle le nom, la description et la taille des serveurs, publie la place, la rend publique et lance un test dans le moteur Roblox. Tu n'as que trois choses à faire une seule fois.

### A. Créer l'expérience vide (5 min)

1. Installe Roblox Studio (étape 1 ci-dessous), ouvre-le et clique sur **New** puis **Baseplate**.
2. **File > Publish to Roblox As...** Nom : `Haunt a House`. Clique **Create**. Ferme Studio.
3. Va sur https://create.roblox.com/dashboard/creations et clique sur l'expérience. L'adresse de la page ressemble à `https://create.roblox.com/dashboard/creations/experiences/1234567890/overview` : le nombre est ton **universeId**.
4. Dans le menu de gauche, **Places** puis clique sur la place : le nombre dans l'adresse est ton **placeId** (c'est aussi celui de `https://www.roblox.com/games/<placeId>`).

### B. Créer la clé API (5 min)

1. Va sur https://create.roblox.com/dashboard/credentials et clique **Create API Key**.
2. Nom : `Publication Haunt a House`.
3. Dans **Access Permissions**, ajoute chaque API dont le nom contient **Universe**, **Place**, **Developer Product**, **Game Pass** et **Luau Execution**. Pour chacune, sélectionne ton expérience et coche **Read** et **Write** (ou l'opération unique proposée).
4. Dans **Security**, laisse l'accès IP par défaut ou mets `0.0.0.0/0` si le script signale un refus.
5. Clique **Save & Generate Key**, puis **Copy Key**. La clé n'est affichée qu'une fois : colle-la tout de suite à l'étape C.

### C. Lancer la publication (2 min)

1. Récupère le dossier du dépôt (GitHub : bouton **Code > Download ZIP**, puis décompresse).
2. Dans le dossier `haunt-a-house/publish`, copie `publish.config.example.json` en `publish.config.json` et ouvre-le avec le Bloc-notes. Colle ta clé dans `apiKey`, tes nombres dans `universeId` et `placeId` (sans guillemets), puis enregistre. `groupId` reste à 0 sauf si tu as un groupe.
3. **Windows** : double-clique sur `PUBLIER.cmd`. **Mac** : ouvre le Terminal, tape `bash ` puis glisse le fichier `publier.sh` dans la fenêtre et appuie sur Entrée (installe Python 3 depuis python.org s'il te le demande).
4. Lis les lignes affichées : chaque étape indique ce qui a réussi. La dernière partie affiche le résultat du test dans le moteur Roblox (`RESULTAT : tous les tests passent`). En cas de ligne `!`, copie tout le texte et demande une correction.
5. Ton jeu est en ligne et public : `https://www.roblox.com/games/<placeId>`.

Relancer l'outil plus tard est sans danger : il retrouve les passes et produits déjà créés et republie simplement la dernière version.

### D. Finitions sur le site (10 min)

Sur create.roblox.com, ouvre l'expérience :
* **Basic Settings** : ajoute l'icône et les miniatures (briefs plus bas), coche tous les appareils.
* **Audience > Questionnaire** : réponds au questionnaire d'âge (obligatoire pour apparaître dans les recherches).
* **Places > ta place** : vérifie que le nom, la description et **Max Players = 12** sont bien appliqués.

Tu peux ensuite ignorer les étapes 3 à 7 ci-dessous, qui décrivent la méthode entièrement manuelle.

## Étape 1 : installer Roblox Studio (10 min)

1. Va sur https://create.roblox.com et connecte-toi avec ton compte Roblox (crée-en un si besoin).
2. Clique sur **Studio** en haut à droite puis **Download Studio**. Installe-le et ouvre-le.
3. Dans Studio, connecte-toi avec le même compte.

## Étape 2 : ouvrir le jeu (5 min)

1. Récupère le fichier **`haunt-a-house/build/HauntAHouse.rbxlx`** de ce dépôt (sur GitHub : ouvre le fichier, bouton **Download raw file**).
2. Dans Studio : menu **File > Open from File...** et choisis `HauntAHouse.rbxlx`.
3. Clique sur le bouton **Play** (triangle bleu). La carte se construit toute seule au démarrage : place centrale, crypte, boutique, autel, arène, 12 manoirs. Marche jusqu'à la Crypte (bâtiment violet au nord) et ouvre un cercueil.

À ce stade, un message rouge indique que les données ne sont pas sauvegardées en Studio : c'est normal, on active cela à l'étape 3.

## Étape 3 : publier et régler l'expérience (15 min)

1. **File > Publish to Roblox As...** Nom : `Haunt a House 👻`. Description : copie celle de la section « Lancement » plus bas. Clique **Create**.
2. Menu **Home > Game Settings** :
   - **Security** : active **Enable Studio Access to API Services** (sinon pas de sauvegarde ni de classements pendant tes tests).
   - **Places** : clique sur ta place, mets **Max Players = 12** (il y a 12 manoirs) et **Server Fill = Roblox optimized**.
   - **Basic Info** : coche tous les appareils (Computer, Phone, Tablet, Console, VR). Genre : **Simulator** (ou Tycoon).
   - **Avatar** : laisse par défaut.
   - **Options** : laisse par défaut.
3. **Save** puis **File > Publish to Roblox** (Alt+P) après chaque changement.

## Étape 4 : créer les Game Passes (20 min)

Sur https://create.roblox.com : **Creations > ton expérience > Monetization > Passes > Create a Pass**. Pour chacun, mets le nom et la description ci-dessous, une icône (voir idées plus bas), puis **Sales > Item for sale : On** et le prix. Une fois créé, l'**ID** est le nombre dans l'adresse de la page (ou visible dans la liste).

| Clé à remplir dans le jeu | Nom du pass | Prix conseillé | Description à copier |
|---|---|---|---|
| `DoubleCoins` | 2x Coins | 299 R$ | Double tous tes gains, pour toujours. |
| `AutoCollect` | Auto Collect | 199 R$ | Tes coins vont directement dans ta poche, plus besoin de vider la caisse. |
| `TripleHatch` | Triple Cercueil | 249 R$ | Ouvre 3 cercueils d'un coup. |
| `ExtraRooms` | +3 Salles | 349 R$ | 3 salles de plus dans ton manoir. |
| `Lucky` | Chance x2 | 449 R$ | Double tes chances de monstres rares et plus. |
| `VIP` | VIP | 599 R$ | +25 % coins, +1 salle, monstre exclusif Phantom VIP, tag VIP. |
| `Ultimate` | Pack Ultime | 1 499 R$ | TOUS les passes ci-dessus. Économise 30 %. |
| `SeasonPremium` | Passe Spooky Premium (Saison 1) | 399 R$ | Débloque les 20 récompenses premium de la saison. |

Pourquoi ces prix : 199 à 449 R$ est la zone « petit achat » où la conversion est la meilleure ; 599 et 1 499 servent d'ancrage et de gros paniers (voir `ANALYSE_MARCHE.md`).

## Étape 5 : créer les Developer Products (20 min)

Même page, onglet **Developer Products > Create a Developer Product**.

| Clé à remplir dans le jeu | Nom du produit | Prix conseillé |
|---|---|---|
| `CoinsSmall` | Bourse de coins | 49 R$ |
| `CoinsMedium` | Sac de coins | 199 R$ |
| `CoinsLarge` | Coffre de coins | 499 R$ |
| `CoinsHuge` | Chambre forte | 1 499 R$ |
| `BoostCoins` | Boost 2x Coins (30 min) | 79 R$ |
| `BoostLuck` | Boost 2x Chance (30 min) | 99 R$ |
| `ServerLuck` | Chance x2 pour tout le serveur (30 min) | 199 R$ |
| `InstantRebirth` | Rebirth instantané | 349 R$ |
| `StarterPack` | Pack de démarrage | 99 R$ |
| `FlashCoinVault` | Offre flash : Coffre +50 % | 399 R$ |
| `FlashBoostBundle` | Offre flash : Pack Boosts | 149 R$ |
| `FlashRebirthRush` | Offre flash : Rebirth Express | 299 R$ |

## Étape 6 : coller les identifiants (10 min)

1. Dans Studio, ouvre la fenêtre **Explorer** (View > Explorer) et déplie **ReplicatedStorage > Shared**.
2. Double-clique sur **MonetizationIds**. Un fichier de texte s'ouvre.
3. Pour chaque ligne, remplace le `0` après `Id =` par l'identifiant copié. Exemple :
   `DoubleCoins = { Id = 0, ...` devient `DoubleCoins = { Id = 123456789, ...`
   Ne touche à rien d'autre.
4. (Facultatif) Si tu as créé un groupe Roblox pour le jeu, colle son identifiant à la ligne `Ids.GroupId = 0` : les membres gagnent +10 % de coins, ce qui pousse à rejoindre le groupe.
5. **File > Publish to Roblox** (Alt+P).

Tant qu'un identifiant reste à 0, l'article correspondant apparaît en gris « Bientôt » dans la boutique. Rien ne casse.

## Étape 7 : tester (10 min)

1. Bouton **Play** dans Studio. Les achats en Studio sont simulés (aucun Robux dépensé) : teste un pass et un produit, vérifie que le bonus s'applique.
2. Sur le site de ton expérience, clique **Play** pour tester en vrai avec un ami. Vérifie : cercueil, placement automatique, caisse, rebirth, coffre quotidien, raid de Minuit (toutes les 10 minutes à l'arène au nord).

## Étape 8 : lancement

### Titre
`Haunt a House 👻 [HALLOWEEN]`

Le crochet en majuscules signale l'évènement (pratique courante des jeux du top) et l'emoji augmente le taux de clic dans les listes.

### Description (à copier)
```
👻 Deviens le fantôme en chef du manoir le plus terrifiant de Roblox !

⚰️ Ouvre des cercueils et collectionne 48 monstres (Commun → Secret)
🏚️ Place-les dans tes salles : chaque visiteur effrayé te donne des coins
😱 Clique sur les visiteurs pour crier BOO ! et gagner encore plus
♻️ Rebirth pour multiplier tes gains et débloquer des cercueils légendaires
⚔️ Toutes les 10 min : raid de MINUIT contre le Capitaine Chasseur, en coop avec tout le serveur
🎁 Récompenses quotidiennes, passe de saison Halloween, classements mondiaux

Code de lancement : LAUNCH (2 500 coins gratuits)

Mise à jour chaque semaine jusqu'à Halloween 🎃
```

### Icône (512 x 512) et miniature (1920 x 1080)
- **Icône** : gros plan sur un fantôme mignon violet-blanc aux yeux jaunes qui sort d'un cercueil doré, fond violet nuit, texte « HAUNT A HOUSE » en lettres épaisses orange avec contour noir. Contraste fort, un seul sujet.
- **Miniature** : à gauche, un manoir violet avec des fenêtres orange éclairées et de la brume ; au centre, trois monstres (fantôme, citrouille, dragon squelette) qui sautent vers l'écran ; à droite, un visiteur qui s'enfuit en criant avec des coins qui volent. Texte en haut : « FAIS PEUR. GAGNE DES COINS. » et un badge « NOUVEAU 🎃 ». Génère ces images avec un outil d'IA ou commande-les à un artiste sur les forums Roblox (budget habituel 500 à 2 000 R$).
- Ajoute 2 autres miniatures : une du raid de Minuit (boss géant, joueurs qui l'attaquent) et une de la crypte avec les cercueils.

### Paramètres de la page
- **Genre** : Simulator. **Sous-genre** : Tycoon. **Tags** : Horror, Pets, Collect.
- Coche **Phone** et **Tablet** : la majorité des joueurs de ce genre sont sur mobile.
- Active les **badges** plus tard (facultatif).

### Promotion (dans l'ordre d'efficacité)
1. **Clips courts TikTok / YouTube Shorts** de 10 à 20 s : un « BOO » sur un visiteur qui hurle, un Légendaire qui sort du cercueil avec l'annonce serveur, le boss qui tombe. Trois vidéos par jour la première semaine.
2. **Codes pour les créateurs** : donne un code unique à chaque YouTubeur (ajoute-le dans `Config.Codes`, voir plus bas), ils adorent en parler.
3. **Sponsoring Roblox** (Creator Hub > Ads) : commence avec 5 000 R$ ciblés « Simulator » et « Horror » le week-end, garde ce qui a le meilleur coût par visite.
4. **Groupe Roblox** : crée-le, mets son ID dans le jeu (+10 % coins pour les membres), publie les mises à jour dessus.
5. **Mises à jour hebdomadaires** avec un [NOUVEAU] dans le titre : nouveau cercueil, nouveaux monstres, évènement. C'est ce qui relance les vagues de joueurs sur les jeux du top.

## Réglages que tu peux modifier sans coder

Tout est dans **ReplicatedStorage > Shared > Config** (double-clic dans l'Explorer) :
- `Config.Codes` : ajoute des codes, exemple `NOEL = { Type = "Coins", Amount = 5000 },`
- `Config.Boss.IntervalSeconds` : fréquence du raid (600 = 10 min).
- `Config.Rebirth.Costs` : prix des rebirths.
- `Config.Season.EndsAt` : fin de saison (année, mois, jour).
- `Config.StarterPack.WindowSeconds` : durée de l'offre de démarrage (86400 = 24 h).
- `Config.FlashDeals.RotationSeconds` : rotation des offres flash (28800 = 8 h).

Après chaque modification : **File > Publish to Roblox**.

## Si quelque chose ne marche pas

- **« Mode Studio : les données ne sont pas sauvegardées »** : active l'accès API (étape 3).
- **Un article est gris « Bientôt »** : son identifiant est encore à 0 (étape 6) ou l'article n'est pas « for sale » sur le site.
- **Classements vides** : normal pendant la première minute, puis rafraîchis toutes les 2 min. En Studio ils exigent l'accès API.
- **Le jeu affiche « Tes données sont encore utilisées par un autre serveur »** : le joueur a quitté un serveur il y a moins de 3 minutes, il suffit de réessayer.
- **Fenêtre Output** (View > Output) : les messages qui commencent par `[ShopService]` listent les identifiants manquants.
