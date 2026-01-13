# ============================================
# Node-RED Node: Full Release Automation Script
# ============================================

# CONFIGURATIE
$npmPackage = "@eltenlogisticsystems/node-red-contrib-s7"
$gitRepo = "https://github.com/EltenLogisticSystems/node-red-contrib-s7.git"

# -----------------------------
# 1️⃣ Controleer project root
# -----------------------------
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
cd $scriptPath
Write-Host "📂 Project root: $PWD"

# Check of package.json bestaat
if (-not (Test-Path "package.json")) {
    Write-Error "❌ package.json niet gevonden in deze map. Run dit script vanuit je node map."
    exit 1
}

# -----------------------------
# 2️⃣ Init Git indien nodig
# -----------------------------
if (-not (Test-Path ".git")) {
    Write-Host "🔹 Initialiseer nieuwe Git repository..."
    git init
    git remote add origin $gitRepo
    git branch -M main
    Write-Host "✅ Git init voltooid"
} else {
    Write-Host "🔹 Git repository bestaat al"
}

# -----------------------------
# 3️⃣ Pull remote indien eerste push
# -----------------------------
try {
    git fetch origin main 2>$null
    $hasRemote = $LASTEXITCODE -eq 0
} catch {
    $hasRemote = $false
}

if ($hasRemote) {
    Write-Host "🔹 Pull remote changes..."
    git pull origin main --allow-unrelated-histories
}

# -----------------------------
# 4️⃣ Bump versie patch
# -----------------------------
Write-Host "🔹 Bump versie patch..."
npm version patch | Out-Null

# Haal nieuwe versie uit package.json
$pkg = Get-Content package.json | ConvertFrom-Json
$version = $pkg.version
Write-Host "🔹 Nieuwe versie: $version"

# -----------------------------
# 5️⃣ Commit changes
# -----------------------------
git add .
git commit -m "Release v$version" 2>$null

# -----------------------------
# 6️⃣ Push commit + tag
# -----------------------------
git push origin main
git push origin "v$version"

# -----------------------------
# 7️⃣ Publish naar npm
# -----------------------------
Write-Host "🔹 Publish naar npm..."
npm publish --access public

# -----------------------------
# 8️⃣ GitHub release via CLI
# -----------------------------
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host "🔹 Maak GitHub release..."
    gh release create "v$version" -t "v$version" -n "Release Node-RED S7 node v$version"
} else {
    Write-Warning "⚠️ GitHub CLI (gh) niet gevonden. Release handmatig aanmaken."
}

Write-Host "🎉 Alles klaar! v$version is gepubliceerd naar NPM en GitHub"
