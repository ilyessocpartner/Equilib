#!/usr/bin/env python3
"""
Publication automatique de Haunt a House sur Roblox (Open Cloud).

Ce script, a partir de publish.config.json :
  1. cree (ou retrouve) les 8 Game Passes et les 12 Developer Products avec les bons prix ;
  2. inscrit leurs identifiants dans le jeu (fichier de place et source) ;
  3. regle le nom, la description et la taille des serveurs de l'experience ;
  4. publie le fichier de place ;
  5. rend l'experience publique ;
  6. lance un test de fumee dans le moteur Roblox et affiche le resultat.

Aucune dependance externe : Python 3.8+ suffit.
"""
import json
import os
import re
import sys
import time
import uuid
import urllib.error
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
CONFIG_PATH = os.path.join(HERE, "publish.config.json")
RBXLX_PATH = os.path.join(ROOT, "build", "HauntAHouse.rbxlx")
IDS_SOURCE_PATH = os.path.join(ROOT, "src", "shared", "MonetizationIds.luau")
SMOKE_PATH = os.path.join(HERE, "smoke_test.luau")

# Les noms doivent rester identiques a ceux de src/shared/MonetizationIds.luau
GAME_PASSES = [
    ("DoubleCoins", "2x Coins", 299, "Double tous tes gains, pour toujours."),
    ("AutoCollect", "Auto Collect", 199, "Tes coins vont directement dans ta poche."),
    ("TripleHatch", "Triple Cercueil", 249, "Ouvre 3 cercueils d'un coup."),
    ("ExtraRooms", "+3 Salles", 349, "3 salles de plus dans ton manoir."),
    ("Lucky", "Chance x2", 449, "Double tes chances de monstres rares."),
    ("VIP", "VIP", 599, "+25% coins, +1 salle, monstre exclusif, tag VIP."),
    ("Ultimate", "Pack Ultime", 1499, "TOUS les passes ci-dessus. Economise 30%."),
    ("SeasonPremium", "Passe Spooky Premium", 399, "Debloque la piste premium de la saison."),
]
PRODUCTS = [
    ("CoinsSmall", "Bourse de coins", 49, "5 000 coins (x ton multiplicateur de rebirth)."),
    ("CoinsMedium", "Sac de coins", 199, "30 000 coins (x ton multiplicateur de rebirth)."),
    ("CoinsLarge", "Coffre de coins", 499, "100 000 coins (x ton multiplicateur de rebirth). Meilleure valeur."),
    ("CoinsHuge", "Chambre forte", 1499, "400 000 coins (x ton multiplicateur de rebirth)."),
    ("BoostCoins", "Boost 2x Coins (30 min)", 79, "Double tes gains pendant 30 minutes."),
    ("BoostLuck", "Boost 2x Chance (30 min)", 99, "Double tes chances de monstres rares pendant 30 minutes."),
    ("ServerLuck", "Chance x2 pour tout le serveur (30 min)", 199, "Chance x2 pour tous les joueurs du serveur pendant 30 minutes."),
    ("InstantRebirth", "Rebirth instantane", 349, "Effectue un rebirth immediatement."),
    ("StarterPack", "Pack de demarrage", 99, "15 000 coins + Ghosty Dore exclusif + 2x Coins 30 min."),
    ("FlashCoinVault", "Offre flash : Coffre +50%", 399, "150 000 coins au lieu de 100 000."),
    ("FlashBoostBundle", "Offre flash : Pack Boosts", 149, "2x Coins 1h + 2x Chance 1h."),
    ("FlashRebirthRush", "Offre flash : Rebirth Express", 299, "Rebirth instantane + 2x Coins 1h."),
]

DESCRIPTION = """👻 Deviens le fantôme en chef du manoir le plus terrifiant de Roblox !

⚰️ Ouvre des cercueils et collectionne 48 monstres (Commun → Secret)
🏚️ Place-les dans tes salles : chaque visiteur effrayé te donne des coins
😱 Clique sur les visiteurs pour crier BOO ! et gagner encore plus
♻️ Rebirth pour multiplier tes gains et débloquer des cercueils légendaires
⚔️ Toutes les 10 min : raid de MINUIT contre le Capitaine Chasseur, en coop avec tout le serveur
🎁 Récompenses quotidiennes, passe de saison Halloween, classements mondiaux

Code de lancement : LAUNCH (2 500 coins gratuits)

Mise à jour chaque semaine jusqu'à Halloween 🎃"""


class RobloxError(Exception):
    pass


def api_base(config):
    return (config.get("apiBase") or os.environ.get("ROBLOX_API_BASE") or "https://apis.roblox.com").rstrip("/")


def request(config, method, path, json_body=None, data=None, content_type=None, params=None, attempts=3):
    url = api_base(config) + "/" + path.lstrip("/")
    if params:
        url += "?" + urllib.parse.urlencode({k: v for k, v in params.items() if v is not None})
    body = None
    headers = {"x-api-key": config["apiKey"], "user-agent": "HauntAHouse-Publisher/1.0"}
    if json_body is not None:
        body = json.dumps(json_body, ensure_ascii=False).encode("utf-8")
        headers["Content-Type"] = "application/json"
    elif data is not None:
        body = data
        headers["Content-Type"] = content_type or "application/octet-stream"
    last_error = None
    for attempt in range(1, attempts + 1):
        req = urllib.request.Request(url, data=body, method=method, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=120) as response:
                raw = response.read()
                text = raw.decode("utf-8", errors="replace")
                try:
                    return json.loads(text) if text.strip() else {}
                except ValueError:
                    return {"raw": text}
        except urllib.error.HTTPError as error:
            text = error.read().decode("utf-8", errors="replace")
            last_error = RobloxError(f"{method} {path} -> HTTP {error.code} : {text[:600]}")
            if error.code in (429, 500, 502, 503, 504) and attempt < attempts:
                time.sleep(2 * attempt)
                continue
            raise last_error
        except urllib.error.URLError as error:
            last_error = RobloxError(f"{method} {path} -> connexion impossible : {error.reason}")
            if attempt < attempts:
                time.sleep(2 * attempt)
                continue
            raise last_error
    raise last_error


def multipart(fields):
    boundary = "----HauntAHouse" + uuid.uuid4().hex
    parts = []
    for name, value in fields.items():
        parts.append(f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"\r\n\r\n{value}\r\n".encode("utf-8"))
    parts.append(f"--{boundary}--\r\n".encode("utf-8"))
    return b"".join(parts), f"multipart/form-data; boundary={boundary}"


def list_all(config, path, key):
    items = []
    token = None
    while True:
        data = request(config, "GET", path, params={"pageSize": 50, "pageToken": token})
        items.extend(data.get(key) or [])
        token = data.get("nextPageToken")
        if not token:
            break
    return items


def ensure_items(config, label, catalog, list_path, create_path, list_key, id_key):
    universe = config["universeId"]
    existing = list_all(config, list_path.format(universe=universe), list_key)
    by_name = {}
    for item in existing:
        by_name.setdefault(item.get("name"), item)
    ids = {}
    for key, name, price, description in catalog:
        found = by_name.get(name)
        if found:
            ids[key] = int(found[id_key])
            print(f"   = {label} deja present : {name} (ID {ids[key]})")
            continue
        body, content_type = multipart({"name": name, "description": description, "price": str(price), "isForSale": "true"})
        created = request(config, "POST", create_path.format(universe=universe), data=body, content_type=content_type)
        ids[key] = int(created[id_key])
        print(f"   + {label} cree : {name} a {price} R$ (ID {ids[key]})")
        time.sleep(0.5)
    return ids


def patch_ids(path, pass_ids, product_ids, group_id):
    if not os.path.exists(path):
        return 0
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()
    replaced = 0
    for key, value in list(pass_ids.items()) + list(product_ids.items()):
        pattern = re.compile(r"(\b" + re.escape(key) + r" = \{ Id = )\d+")
        text, count = pattern.subn(lambda m: m.group(1) + str(value), text)
        replaced += count
    if group_id:
        text, count = re.subn(r"(\bIds\.GroupId = )\d+", lambda m: m.group(1) + str(group_id), text)
        replaced += count
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)
    return replaced


def update_place(config):
    universe, place = config["universeId"], config["placeId"]
    body = {"displayName": config.get("experienceName") or "Haunt a House 👻", "description": DESCRIPTION, "serverSize": int(config.get("serverSize") or 12)}
    request(config, "PATCH", f"cloud/v2/universes/{universe}/places/{place}", json_body=body, params={"updateMask": "displayName,description,serverSize"})


def publish_place(config):
    universe, place = config["universeId"], config["placeId"]
    with open(RBXLX_PATH, "rb") as handle:
        data = handle.read()
    result = request(config, "POST", f"universes/v1/{universe}/places/{place}/versions", data=data, content_type="application/xml", params={"versionType": "Published"})
    return result.get("versionNumber")


def make_public(config):
    universe = config["universeId"]
    request(config, "PATCH", f"cloud/v2/universes/{universe}", json_body={"visibility": "PUBLIC"}, params={"updateMask": "visibility"})


def smoke_test(config):
    universe, place = config["universeId"], config["placeId"]
    with open(SMOKE_PATH, "r", encoding="utf-8") as handle:
        script = handle.read()
    task = request(config, "POST", f"cloud/v2/universes/{universe}/places/{place}/luau-execution-session-tasks", json_body={"script": script, "timeout": "240s"})
    path = task["path"]
    state = task.get("state")
    deadline = time.time() + 400
    while state in (None, "STATE_UNSPECIFIED", "QUEUED", "PROCESSING") and time.time() < deadline:
        time.sleep(4)
        task = request(config, "GET", f"cloud/v2/{path}")
        state = task.get("state")
    logs = request(config, "GET", f"cloud/v2/{path}/logs", params={"view": "FLAT", "maxPageSize": 10000})
    messages = []
    for chunk in logs.get("luauExecutionSessionTaskLogs") or []:
        messages.extend(chunk.get("messages") or [])
    return state, task.get("error"), messages


def extract_ids(text):
    """Retourne (universeId, placeId) trouves dans une adresse ou un nombre colle par l'utilisateur."""
    text = (text or "").strip()
    universe = None
    place = None
    m = re.search(r"experiences/(\d+)", text)
    if m:
        universe = int(m.group(1))
    m = re.search(r"places/(\d+)", text)
    if m:
        place = int(m.group(1))
    m = re.search(r"games/(\d+)", text)
    if m:
        place = int(m.group(1))
    if universe is None and place is None:
        m = re.fullmatch(r"\d{4,}", text)
        if m:
            universe = int(text)
    return universe, place


def ask(prompt):
    try:
        return input(prompt).strip()
    except EOFError:
        return ""


def interactive_config(config):
    """Demande les trois informations manquantes et enregistre publish.config.json."""
    print("Configuration en 3 questions (une seule fois). Colle chaque valeur puis appuie sur Entree.\n")
    universe = int(config.get("universeId") or 0) or None
    place = int(config.get("placeId") or 0) or None
    while not universe:
        answer = ask("1/3  Adresse de la page de ton experience sur create.roblox.com (ou l'universeId) : ")
        u, pl = extract_ids(answer)
        universe = u
        if pl and not place:
            place = pl
        if not universe:
            print("     Je n'ai pas trouve de nombre. Exemple attendu : https://create.roblox.com/dashboard/creations/experiences/1234567890/overview")
    while not place:
        answer = ask("2/3  Adresse de la page du jeu (https://www.roblox.com/games/...) ou le placeId : ")
        _, pl = extract_ids(answer)
        if pl is None:
            m = re.fullmatch(r"\d{4,}", answer.strip())
            if m:
                pl = int(answer.strip())
        place = pl
        if not place:
            print("     Je n'ai pas trouve de nombre. Exemple attendu : https://www.roblox.com/games/123456789/Haunt-a-House")
    api_key = config.get("apiKey") if config.get("apiKey") and "COLLE" not in config.get("apiKey", "") else None
    while not api_key:
        api_key = ask("3/3  Cle API Open Cloud (create.roblox.com/dashboard/credentials) : ")
        if len(api_key) < 20:
            print("     La cle semble trop courte, reessaie (bouton Copy Key sur la page de la cle).")
            api_key = None
    config.update({"apiKey": api_key, "universeId": universe, "placeId": place})
    config.setdefault("groupId", 0)
    config.setdefault("experienceName", "Haunt a House 👻 [HALLOWEEN]")
    config.setdefault("serverSize", 12)
    config.setdefault("makePublic", True)
    config.setdefault("runSmokeTest", True)
    with open(CONFIG_PATH, "w", encoding="utf-8") as handle:
        json.dump(config, handle, ensure_ascii=False, indent=2)
    print("     Enregistre dans publish.config.json. La prochaine fois, aucune question ne sera posee.\n")
    return config


def load_config():
    config = {}
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "r", encoding="utf-8") as handle:
            config = json.load(handle)
    incomplete = (not config.get("apiKey") or "COLLE" in config.get("apiKey", "") or not int(config.get("universeId") or 0) or not int(config.get("placeId") or 0))
    if incomplete:
        config = interactive_config(config)
    config["universeId"] = int(config["universeId"])
    config["placeId"] = int(config["placeId"])
    return config


def main():
    config = load_config()
    if not os.path.exists(RBXLX_PATH):
        print("Fichier de place introuvable : " + RBXLX_PATH)
        sys.exit(1)
    print("=== Haunt a House : publication sur Roblox ===")
    print(f"Experience (universe) {config['universeId']}, place {config['placeId']}")

    pass_ids, product_ids = {}, {}
    print("\n[1/6] Game Passes")
    try:
        pass_ids = ensure_items(config, "Pass", GAME_PASSES, "game-passes/v1/universes/{universe}/game-passes/creator", "game-passes/v1/universes/{universe}/game-passes", "gamePasses", "gamePassId")
    except RobloxError as error:
        if "HTTP 401" in str(error):
            print("   ! Cle API refusee par Roblox (401). Elle est peut-etre mal copiee, expiree, ou limitee a une autre adresse IP.")
            print("   ! Cree une nouvelle cle (create.roblox.com/dashboard/credentials), puis relance : la cle te sera redemandee.")
            config["apiKey"] = ""
            with open(CONFIG_PATH, "w", encoding="utf-8") as handle:
                json.dump(config, handle, ensure_ascii=False, indent=2)
            sys.exit(3)
        print("   ! Impossible de creer les passes : " + str(error))
        print("   ! Verifie que la cle API a la permission Game Passes (lecture + ecriture) sur cette experience.")
    print("\n[2/6] Developer Products")
    try:
        product_ids = ensure_items(config, "Produit", PRODUCTS, "developer-products/v2/universes/{universe}/developer-products/creator", "developer-products/v2/universes/{universe}/developer-products", "developerProducts", "productId")
    except RobloxError as error:
        print("   ! Impossible de creer les produits : " + str(error))
        print("   ! Verifie que la cle API a la permission Developer Products (lecture + ecriture) sur cette experience.")

    print("\n[3/6] Inscription des identifiants dans le jeu")
    group_id = int(config.get("groupId") or 0)
    total = patch_ids(RBXLX_PATH, pass_ids, product_ids, group_id) + patch_ids(IDS_SOURCE_PATH, pass_ids, product_ids, group_id)
    print(f"   {total} identifiant(s) inscrit(s) ({len(pass_ids)} passes, {len(product_ids)} produits" + (", groupe" if group_id else "") + ")")

    print("\n[4/6] Reglages de l'experience (nom, description, 12 joueurs par serveur)")
    try:
        update_place(config)
        print("   Reglages appliques.")
    except RobloxError as error:
        print("   ! Reglages non appliques : " + str(error))
        print("   ! Tu peux les faire a la main sur create.roblox.com (Configure > Places).")

    print("\n[5/6] Publication du fichier de place")
    try:
        version = publish_place(config)
        print(f"   Publie ! Version {version}.")
    except RobloxError as error:
        print("   ! Publication echouee : " + str(error))
        print("   ! Verifie la cle API (permission Universe Places, ecriture) et les identifiants universeId / placeId.")
        sys.exit(2)

    if config.get("makePublic", True):
        try:
            make_public(config)
            print("   Experience rendue PUBLIQUE.")
        except RobloxError as error:
            print("   ! Visibilite non modifiee : " + str(error))
            print("   ! Rends l'experience publique sur create.roblox.com (bouton Make Public).")

    if config.get("runSmokeTest", True):
        print("\n[6/6] Test dans le moteur Roblox (1 a 3 minutes)")
        try:
            state, error, messages = smoke_test(config)
            for message in messages:
                print("   " + message)
            if error:
                print("   ! Erreur du test : " + json.dumps(error, ensure_ascii=False))
            print("   Etat final : " + str(state))
            if state == "COMPLETE" and any("RESULTAT : tous les tests passent" in m for m in messages):
                print("   Tout fonctionne dans le moteur Roblox.")
            else:
                print("   ! Le test signale un probleme : copie ce journal et demande une correction.")
        except RobloxError as error:
            print("   ! Test non execute : " + str(error))
            print("   ! Ajoute la permission Luau Execution Sessions a la cle API pour activer ce test (facultatif).")

    print("\n=== Termine ===")
    print(f"Page du jeu : https://www.roblox.com/games/{config['placeId']}")
    print("Reste a faire a la main : icone, miniatures et questionnaire d'age sur create.roblox.com (voir docs/GUIDE_DEBUTANT.md).")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrompu.")
        sys.exit(130)
