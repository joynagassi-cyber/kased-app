# Script PowerShell pour Configurer le Logo Kased-app
# Auteur : Kiro AI Assistant
# Date : 3 mai 2026

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuration du Logo Kased-app" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Étape 1 : Vérifier si le logo existe
Write-Host "[1/6] Vérification du logo..." -ForegroundColor Yellow

$logoPath = "assets/images/kased_logo.png"

if (-Not (Test-Path $logoPath)) {
    Write-Host "❌ ERREUR : Le logo n'a pas été trouvé à : $logoPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Veuillez copier votre logo dans ce dossier :" -ForegroundColor Yellow
    Write-Host "  $PWD\assets\images\kased_logo.png" -ForegroundColor White
    Write-Host ""
    Write-Host "Commande pour copier (remplacez [nom-du-logo] par le vrai nom) :" -ForegroundColor Yellow
    Write-Host '  Copy-Item "C:/Users/joyda/Downloads/[nom-du-logo].png" "assets/images/kased_logo.png"' -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "✅ Logo trouvé : $logoPath" -ForegroundColor Green
Write-Host ""

# Étape 2 : Créer le dossier assets/images s'il n'existe pas
Write-Host "[2/6] Création du dossier assets/images..." -ForegroundColor Yellow

if (-Not (Test-Path "assets/images")) {
    New-Item -ItemType Directory -Force -Path "assets/images" | Out-Null
    Write-Host "✅ Dossier créé : assets/images" -ForegroundColor Green
} else {
    Write-Host "✅ Dossier existe déjà : assets/images" -ForegroundColor Green
}
Write-Host ""

# Étape 3 : Installer flutter_launcher_icons
Write-Host "[3/6] Installation de flutter_launcher_icons..." -ForegroundColor Yellow

flutter pub add --dev flutter_launcher_icons

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Package installé avec succès" -ForegroundColor Green
} else {
    Write-Host "❌ ERREUR lors de l'installation du package" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Étape 4 : Vérifier le fichier de configuration
Write-Host "[4/6] Vérification de la configuration..." -ForegroundColor Yellow

if (Test-Path "flutter_launcher_icons.yaml") {
    Write-Host "✅ Fichier de configuration trouvé : flutter_launcher_icons.yaml" -ForegroundColor Green
} else {
    Write-Host "❌ ERREUR : Fichier de configuration manquant" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Étape 5 : Générer les icônes
Write-Host "[5/6] Génération des icônes pour Android et iOS..." -ForegroundColor Yellow
Write-Host "    Cela peut prendre quelques secondes..." -ForegroundColor Gray

flutter pub run flutter_launcher_icons

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Icônes générées avec succès" -ForegroundColor Green
} else {
    Write-Host "❌ ERREUR lors de la génération des icônes" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Étape 6 : Vérifier les icônes générées
Write-Host "[6/6] Vérification des icônes générées..." -ForegroundColor Yellow

$androidIconsExist = Test-Path "android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
$iosIconsExist = Test-Path "ios/Runner/Assets.xcassets/AppIcon.appiconset"

if ($androidIconsExist) {
    Write-Host "✅ Icônes Android générées" -ForegroundColor Green
} else {
    Write-Host "⚠️  Icônes Android non trouvées" -ForegroundColor Yellow
}

if ($iosIconsExist) {
    Write-Host "✅ Icônes iOS générées" -ForegroundColor Green
} else {
    Write-Host "⚠️  Icônes iOS non trouvées" -ForegroundColor Yellow
}
Write-Host ""

# Résumé
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuration Terminée !" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Prochaines étapes :" -ForegroundColor Yellow
Write-Host "  1. Vérifiez que le logo apparaît dans les écrans Signup et Login" -ForegroundColor White
Write-Host "  2. Lancez l'application : flutter run" -ForegroundColor White
Write-Host "  3. Vérifiez l'icône de l'application sur votre appareil" -ForegroundColor White
Write-Host ""
Write-Host "Pour nettoyer et relancer :" -ForegroundColor Yellow
Write-Host "  flutter clean" -ForegroundColor White
Write-Host "  flutter pub get" -ForegroundColor White
Write-Host "  flutter run" -ForegroundColor White
Write-Host ""
