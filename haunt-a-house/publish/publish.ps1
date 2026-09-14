# Publication automatique de Haunt a House sur Roblox (Open Cloud), version Windows.
# Compatible Windows PowerShell 5.1 et PowerShell 7. Utilise curl.exe (fourni avec Windows 10 et 11).
# Lance-le en double-cliquant sur PUBLIER.cmd.
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $Here
$ConfigPath = Join-Path $Here "publish.config.json"
$RbxlxPath = Join-Path (Join-Path $Root "build") "HauntAHouse.rbxlx"
$IdsSourcePath = Join-Path (Join-Path (Join-Path $Root "src") "shared") "MonetizationIds.luau"
$SmokePath = Join-Path $Here "smoke_test.luau"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Les noms doivent rester identiques a ceux de src/shared/MonetizationIds.luau
$GamePasses = @(
    @{ Key = "DoubleCoins"; Name = "2x Coins"; Price = 299; Desc = "Double tous tes gains, pour toujours." },
    @{ Key = "AutoCollect"; Name = "Auto Collect"; Price = 199; Desc = "Tes coins vont directement dans ta poche." },
    @{ Key = "TripleHatch"; Name = "Triple Cercueil"; Price = 249; Desc = "Ouvre 3 cercueils d'un coup." },
    @{ Key = "ExtraRooms"; Name = "+3 Salles"; Price = 349; Desc = "3 salles de plus dans ton manoir." },
    @{ Key = "Lucky"; Name = "Chance x2"; Price = 449; Desc = "Double tes chances de monstres rares." },
    @{ Key = "VIP"; Name = "VIP"; Price = 599; Desc = "+25% coins, +1 salle, monstre exclusif, tag VIP." },
    @{ Key = "Ultimate"; Name = "Pack Ultime"; Price = 1499; Desc = "TOUS les passes ci-dessus. Economise 30%." },
    @{ Key = "SeasonPremium"; Name = "Passe Spooky Premium"; Price = 399; Desc = "Debloque la piste premium de la saison." }
)
$Products = @(
    @{ Key = "CoinsSmall"; Name = "Bourse de coins"; Price = 49; Desc = "5 000 coins (x ton multiplicateur de rebirth)." },
    @{ Key = "CoinsMedium"; Name = "Sac de coins"; Price = 199; Desc = "30 000 coins (x ton multiplicateur de rebirth)." },
    @{ Key = "CoinsLarge"; Name = "Coffre de coins"; Price = 499; Desc = "100 000 coins (x ton multiplicateur de rebirth). Meilleure valeur." },
    @{ Key = "CoinsHuge"; Name = "Chambre forte"; Price = 1499; Desc = "400 000 coins (x ton multiplicateur de rebirth)." },
    @{ Key = "BoostCoins"; Name = "Boost 2x Coins (30 min)"; Price = 79; Desc = "Double tes gains pendant 30 minutes." },
    @{ Key = "BoostLuck"; Name = "Boost 2x Chance (30 min)"; Price = 99; Desc = "Double tes chances de monstres rares pendant 30 minutes." },
    @{ Key = "ServerLuck"; Name = "Chance x2 pour tout le serveur (30 min)"; Price = 199; Desc = "Chance x2 pour tous les joueurs du serveur pendant 30 minutes." },
    @{ Key = "InstantRebirth"; Name = "Rebirth instantane"; Price = 349; Desc = "Effectue un rebirth immediatement." },
    @{ Key = "StarterPack"; Name = "Pack de demarrage"; Price = 99; Desc = "15 000 coins + Ghosty Dore exclusif + 2x Coins 30 min." },
    @{ Key = "FlashCoinVault"; Name = "Offre flash : Coffre +50%"; Price = 399; Desc = "150 000 coins au lieu de 100 000." },
    @{ Key = "FlashBoostBundle"; Name = "Offre flash : Pack Boosts"; Price = 149; Desc = "2x Coins 1h + 2x Chance 1h." },
    @{ Key = "FlashRebirthRush"; Name = "Offre flash : Rebirth Express"; Price = 299; Desc = "Rebirth instantane + 2x Coins 1h." }
)
$Description = @"
👻 Deviens le fantôme en chef du manoir le plus terrifiant de Roblox !

⚰️ Ouvre des cercueils et collectionne 48 monstres (Commun → Secret)
🏚️ Place-les dans tes salles : chaque visiteur effrayé te donne des coins
😱 Clique sur les visiteurs pour crier BOO ! et gagner encore plus
♻️ Rebirth pour multiplier tes gains et débloquer des cercueils légendaires
⚔️ Toutes les 10 min : raid de MINUIT contre le Capitaine Chasseur, en coop avec tout le serveur
🎁 Récompenses quotidiennes, passe de saison Halloween, classements mondiaux

Code de lancement : LAUNCH (2 500 coins gratuits)

Mise à jour chaque semaine jusqu'à Halloween 🎃
"@

if (Get-Command "curl.exe" -ErrorAction SilentlyContinue) { $Curl = "curl.exe" } else { $Curl = "curl" }

function Write-Step($text) { Write-Host ""; Write-Host $text -ForegroundColor Cyan }
function Write-Warn($text) { Write-Host ("   ! " + $text) -ForegroundColor Yellow }
function Write-Ok($text) { Write-Host ("   " + $text) -ForegroundColor Green }

function Read-Config {
    if (-not (Test-Path $ConfigPath)) {
        Write-Host "Fichier publish.config.json introuvable." -ForegroundColor Red
        Write-Host "Copie publish.config.example.json en publish.config.json et remplis apiKey, universeId et placeId (voir docs/GUIDE_DEBUTANT.md)."
        exit 1
    }
    $raw = [System.IO.File]::ReadAllText($ConfigPath, [System.Text.Encoding]::UTF8)
    $config = $raw | ConvertFrom-Json
    $problems = @()
    if (-not $config.apiKey -or $config.apiKey -like "*COLLE*") { $problems += "apiKey manquante" }
    if (-not $config.universeId -or [int64]$config.universeId -eq 0) { $problems += "universeId manquant" }
    if (-not $config.placeId -or [int64]$config.placeId -eq 0) { $problems += "placeId manquant" }
    if ($problems.Count -gt 0) {
        Write-Host ("Configuration incomplete : " + ($problems -join ", ") + ". Ouvre publish.config.json et complete-le.") -ForegroundColor Red
        exit 1
    }
    return $config
}

function Get-ApiBase($config) {
    $base = $config.apiBase
    if (-not $base) { $base = $env:ROBLOX_API_BASE }
    if (-not $base) { $base = "https://apis.roblox.com" }
    return $base.TrimEnd("/")
}

# Execute curl et retourne un objet { Status, Text, Json }
function Invoke-Roblox($config, $method, $path, $extraArgs) {
    $url = (Get-ApiBase $config) + "/" + $path.TrimStart("/")
    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()
    $args = @("-s", "-S", "-X", $method, $url, "-H", ("x-api-key: " + $config.apiKey), "-H", "user-agent: HauntAHouse-Publisher/1.0", "-o", $outFile, "--stderr", $errFile, "-w", "%{http_code}", "--max-time", "180")
    if ($extraArgs) { $args += $extraArgs }
    $status = & $Curl @args
    $text = ""
    if (Test-Path $outFile) { $text = [System.IO.File]::ReadAllText($outFile, [System.Text.Encoding]::UTF8) }
    $err = ""
    if (Test-Path $errFile) { $err = [System.IO.File]::ReadAllText($errFile, [System.Text.Encoding]::UTF8) }
    Remove-Item $outFile, $errFile -ErrorAction SilentlyContinue
    $statusCode = 0
    [void][int]::TryParse(("" + $status).Trim(), [ref]$statusCode)
    if ($statusCode -eq 0) { throw ($method + " " + $path + " -> connexion impossible : " + $err.Trim()) }
    if ($statusCode -lt 200 -or $statusCode -ge 300) {
        $snippet = $text
        if ($snippet.Length -gt 600) { $snippet = $snippet.Substring(0, 600) }
        throw ($method + " " + $path + " -> HTTP " + $statusCode + " : " + $snippet)
    }
    $json = $null
    if ($text.Trim().Length -gt 0) { try { $json = $text | ConvertFrom-Json } catch { $json = $null } }
    return @{ Status = $statusCode; Text = $text; Json = $json }
}

function Get-AllItems($config, $path, $key) {
    $items = @()
    $token = $null
    while ($true) {
        $query = $path + "?pageSize=50"
        if ($token) { $query += "&pageToken=" + [uri]::EscapeDataString($token) }
        $result = Invoke-Roblox $config "GET" $query @()
        if ($result.Json -and $result.Json.$key) { $items += @($result.Json.$key) }
        $token = $null
        if ($result.Json -and $result.Json.nextPageToken) { $token = $result.Json.nextPageToken }
        if (-not $token) { break }
    }
    return $items
}

function Ensure-Items($config, $label, $catalog, $listPath, $createPath, $listKey, $idKey) {
    $universe = $config.universeId
    $existing = Get-AllItems $config ($listPath -replace "\{universe\}", $universe) $listKey
    $ids = @{}
    foreach ($entry in $catalog) {
        $found = $null
        foreach ($item in $existing) { if ($item.name -eq $entry.Name) { $found = $item; break } }
        if ($found) {
            $ids[$entry.Key] = [int64]$found.$idKey
            Write-Host ("   = " + $label + " deja present : " + $entry.Name + " (ID " + $ids[$entry.Key] + ")")
            continue
        }
        $formArgs = @("--form-string", ("name=" + $entry.Name), "--form-string", ("description=" + $entry.Desc), "--form-string", ("price=" + $entry.Price), "--form-string", "isForSale=true")
        $created = Invoke-Roblox $config "POST" ($createPath -replace "\{universe\}", $universe) $formArgs
        $ids[$entry.Key] = [int64]$created.Json.$idKey
        Write-Host ("   + " + $label + " cree : " + $entry.Name + " a " + $entry.Price + " R$ (ID " + $ids[$entry.Key] + ")")
        Start-Sleep -Milliseconds 500
    }
    return $ids
}

function Patch-Ids($path, $ids, $groupId) {
    if (-not (Test-Path $path)) { return 0 }
    $text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    $count = 0
    foreach ($key in $ids.Keys) {
        $pattern = "(\b" + [regex]::Escape($key) + " = \{ Id = )\d+"
        $matches = [regex]::Matches($text, $pattern)
        $count += $matches.Count
        $text = [regex]::Replace($text, $pattern, ('${1}' + $ids[$key]))
    }
    if ($groupId -and [int64]$groupId -ne 0) {
        $pattern = "(\bIds\.GroupId = )\d+"
        $count += [regex]::Matches($text, $pattern).Count
        $text = [regex]::Replace($text, $pattern, ('${1}' + [int64]$groupId))
    }
    [System.IO.File]::WriteAllText($path, $text, $Utf8NoBom)
    return $count
}

function Write-JsonFile($object) {
    $file = [System.IO.Path]::GetTempFileName()
    $json = $object | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($file, $json, $Utf8NoBom)
    return $file
}

# ---------------------------------------------------------------- Deroulement
$config = Read-Config
if (-not (Test-Path $RbxlxPath)) { Write-Host ("Fichier de place introuvable : " + $RbxlxPath) -ForegroundColor Red; exit 1 }
Write-Host "=== Haunt a House : publication sur Roblox ===" -ForegroundColor Magenta
Write-Host ("Experience (universe) " + $config.universeId + ", place " + $config.placeId)

$passIds = @{}
$productIds = @{}
Write-Step "[1/6] Game Passes"
try {
    $passIds = Ensure-Items $config "Pass" $GamePasses "game-passes/v1/universes/{universe}/game-passes/creator" "game-passes/v1/universes/{universe}/game-passes" "gamePasses" "gamePassId"
} catch {
    Write-Warn ("Impossible de creer les passes : " + $_.Exception.Message)
    Write-Warn "Verifie que la cle API a la permission Game Passes (lecture + ecriture) sur cette experience."
}
Write-Step "[2/6] Developer Products"
try {
    $productIds = Ensure-Items $config "Produit" $Products "developer-products/v2/universes/{universe}/developer-products/creator" "developer-products/v2/universes/{universe}/developer-products" "developerProducts" "productId"
} catch {
    Write-Warn ("Impossible de creer les produits : " + $_.Exception.Message)
    Write-Warn "Verifie que la cle API a la permission Developer Products (lecture + ecriture) sur cette experience."
}

Write-Step "[3/6] Inscription des identifiants dans le jeu"
$allIds = @{}
foreach ($k in $passIds.Keys) { $allIds[$k] = $passIds[$k] }
foreach ($k in $productIds.Keys) { $allIds[$k] = $productIds[$k] }
$groupId = 0
if ($config.groupId) { $groupId = [int64]$config.groupId }
$total = (Patch-Ids $RbxlxPath $allIds $groupId) + (Patch-Ids $IdsSourcePath $allIds $groupId)
Write-Ok ("" + $total + " identifiant(s) inscrit(s) (" + $passIds.Count + " passes, " + $productIds.Count + " produits)")

Write-Step "[4/6] Reglages de l'experience (nom, description, 12 joueurs par serveur)"
try {
    $name = $config.experienceName
    if (-not $name) { $name = "Haunt a House" }
    $serverSize = 12
    if ($config.serverSize) { $serverSize = [int]$config.serverSize }
    $bodyFile = Write-JsonFile @{ displayName = $name; description = $Description; serverSize = $serverSize }
    [void](Invoke-Roblox $config "PATCH" ("cloud/v2/universes/" + $config.universeId + "/places/" + $config.placeId + "?updateMask=displayName,description,serverSize") @("-H", "Content-Type: application/json", "--data-binary", ("@" + $bodyFile)))
    Remove-Item $bodyFile -ErrorAction SilentlyContinue
    Write-Ok "Reglages appliques."
} catch {
    Write-Warn ("Reglages non appliques : " + $_.Exception.Message)
    Write-Warn "Tu peux les faire a la main sur create.roblox.com (Configure > Places)."
}

Write-Step "[5/6] Publication du fichier de place"
try {
    $result = Invoke-Roblox $config "POST" ("universes/v1/" + $config.universeId + "/places/" + $config.placeId + "/versions?versionType=Published") @("-H", "Content-Type: application/xml", "--data-binary", ("@" + $RbxlxPath))
    Write-Ok ("Publie ! Version " + $result.Json.versionNumber + ".")
} catch {
    Write-Host ("   ! Publication echouee : " + $_.Exception.Message) -ForegroundColor Red
    Write-Host "   ! Verifie la cle API (permission Universe Places, ecriture) et les identifiants universeId / placeId." -ForegroundColor Red
    exit 2
}

$makePublic = $true
if ($null -ne $config.makePublic) { $makePublic = [bool]$config.makePublic }
if ($makePublic) {
    try {
        $bodyFile = Write-JsonFile @{ visibility = "PUBLIC" }
        [void](Invoke-Roblox $config "PATCH" ("cloud/v2/universes/" + $config.universeId + "?updateMask=visibility") @("-H", "Content-Type: application/json", "--data-binary", ("@" + $bodyFile)))
        Remove-Item $bodyFile -ErrorAction SilentlyContinue
        Write-Ok "Experience rendue PUBLIQUE."
    } catch {
        Write-Warn ("Visibilite non modifiee : " + $_.Exception.Message)
        Write-Warn "Rends l'experience publique sur create.roblox.com (bouton Make Public)."
    }
}

$runSmoke = $true
if ($null -ne $config.runSmokeTest) { $runSmoke = [bool]$config.runSmokeTest }
if ($runSmoke) {
    Write-Step "[6/6] Test dans le moteur Roblox (1 a 3 minutes)"
    try {
        $script = [System.IO.File]::ReadAllText($SmokePath, [System.Text.Encoding]::UTF8)
        $bodyFile = Write-JsonFile @{ script = $script; timeout = "240s" }
        $task = Invoke-Roblox $config "POST" ("cloud/v2/universes/" + $config.universeId + "/places/" + $config.placeId + "/luau-execution-session-tasks") @("-H", "Content-Type: application/json", "--data-binary", ("@" + $bodyFile))
        Remove-Item $bodyFile -ErrorAction SilentlyContinue
        $taskPath = $task.Json.path
        $state = $task.Json.state
        $deadline = (Get-Date).AddSeconds(400)
        while (($state -eq $null -or $state -eq "STATE_UNSPECIFIED" -or $state -eq "QUEUED" -or $state -eq "PROCESSING") -and (Get-Date) -lt $deadline) {
            Start-Sleep -Seconds 4
            $task = Invoke-Roblox $config "GET" ("cloud/v2/" + $taskPath) @()
            $state = $task.Json.state
        }
        $logs = Invoke-Roblox $config "GET" ("cloud/v2/" + $taskPath + "/logs?view=FLAT&maxPageSize=10000") @()
        $messages = @()
        if ($logs.Json -and $logs.Json.luauExecutionSessionTaskLogs) {
            foreach ($chunk in $logs.Json.luauExecutionSessionTaskLogs) { if ($chunk.messages) { $messages += @($chunk.messages) } }
        }
        foreach ($message in $messages) { Write-Host ("   " + $message) }
        if ($task.Json.error) { Write-Warn ("Erreur du test : " + ($task.Json.error | ConvertTo-Json -Compress)) }
        Write-Host ("   Etat final : " + $state)
        $passed = $false
        foreach ($message in $messages) { if ($message -like "*RESULTAT : tous les tests passent*") { $passed = $true } }
        if ($state -eq "COMPLETE" -and $passed) { Write-Ok "Tout fonctionne dans le moteur Roblox." }
        else { Write-Warn "Le test signale un probleme : copie ce journal et demande une correction." }
    } catch {
        Write-Warn ("Test non execute : " + $_.Exception.Message)
        Write-Warn "Ajoute la permission Luau Execution Sessions a la cle API pour activer ce test (facultatif)."
    }
}

Write-Host ""
Write-Host "=== Termine ===" -ForegroundColor Magenta
Write-Host ("Page du jeu : https://www.roblox.com/games/" + $config.placeId)
Write-Host "Reste a faire a la main : icone, miniatures et questionnaire d'age sur create.roblox.com (voir docs/GUIDE_DEBUTANT.md)."
