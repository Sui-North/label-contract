# Songsim Platform - Testnet Deployment Script (PowerShell)
# This script automates the deployment process and captures important IDs

$ErrorActionPreference = "Stop"

Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║     Songsim Platform - Testnet Deployment v1.0.0       ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# Navigate to contract directory
Set-Location $PSScriptRoot\..
Write-Host "✓ Working directory: $(Get-Location)" -ForegroundColor Green

# Check Sui CLI installed
try {
    $suiVersion = sui --version
    Write-Host "✓ Sui CLI found: $suiVersion" -ForegroundColor Green
}
catch {
    Write-Host "✗ Sui CLI not found. Please install from https://docs.sui.io/build/install" -ForegroundColor Red
    exit 1
}

# Check network configuration
$network = sui client active-env | Out-String
$network = $network.Trim()
Write-Host "! Active network: $network" -ForegroundColor Yellow

if ($network -ne "testnet") {
    $response = Read-Host "WARNING: Not on testnet. Continue? (y/n)"
    if ($response -ne "y") {
        Write-Host "Deployment cancelled."
        exit 0
    }
}

# Get active address
$deployer = sui client active-address | Out-String
$deployer = $deployer.Trim()
Write-Host "✓ Deployer address: $deployer" -ForegroundColor Green

# Check balance
Write-Host "[1/5] Checking balance..." -ForegroundColor Blue
$gasObjects = sui client gas --json | ConvertFrom-Json
$balance = ($gasObjects | Where-Object { $_.gasBalance } | Select-Object -First 1).gasBalance
$balanceSui = [math]::Round($balance / 1000000000, 2)
Write-Host "✓ Balance: $balanceSui SUI" -ForegroundColor Green

if ($balanceSui -lt 0.1) {
    Write-Host "✗ Insufficient balance. Need at least 0.1 SUI for deployment." -ForegroundColor Red
    Write-Host "    Request tokens from: https://discord.com/channels/916379725201563759/971488439931392130"
    exit 1
}

# Build package
Write-Host "[2/5] Building package..." -ForegroundColor Blue
try {
    sui move build
    Write-Host "✓ Build successful" -ForegroundColor Green
}
catch {
    Write-Host "✗ Build failed. Check errors above." -ForegroundColor Red
    exit 1
}

# Run tests
Write-Host "[3/5] Running tests..." -ForegroundColor Blue
try {
    sui move test
    Write-Host "✓ All tests passed" -ForegroundColor Green
}
catch {
    Write-Host "✗ Tests failed. Check errors above." -ForegroundColor Red
    exit 1
}

# Deploy package
Write-Host "[4/5] Publishing to $network..." -ForegroundColor Blue
$response = Read-Host "! This will consume gas. Continue? (y/n)"
if ($response -ne "y") {
    Write-Host "Deployment cancelled."
    exit 0
}

try {
    $output = sui client publish --gas-budget 100000000 --json | ConvertFrom-Json
}
catch {
    Write-Host "✗ Deployment failed" -ForegroundColor Red
    exit 1
}

# Extract important IDs
$packageId = ($output.objectChanges | Where-Object { $_.type -eq "published" }).packageId
$upgradeCap = ($output.objectChanges | Where-Object { $_.objectType -like "*UpgradeCap*" }).objectId
$platformConfig = ($output.objectChanges | Where-Object { $_.objectType -like "*PlatformConfig*" }).objectId
$taskRegistry = ($output.objectChanges | Where-Object { $_.objectType -like "*TaskRegistry*" }).objectId
$migrationState = ($output.objectChanges | Where-Object { $_.objectType -like "*MigrationState*" }).objectId
$adminCap = ($output.objectChanges | Where-Object { $_.objectType -like "*AdminCap*" }).objectId
$txDigest = $output.digest

Write-Host ""
Write-Host "✓ Deployment successful!" -ForegroundColor Green
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║              Deployment Summary                          ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""
Write-Host "CRITICAL IDs (Save these securely):" -ForegroundColor Yellow
Write-Host ""
Write-Host "Package ID:       $packageId"
Write-Host "UpgradeCap ID:    $upgradeCap"
Write-Host "AdminCap ID:      $adminCap"
Write-Host ""
Write-Host "Shared Objects:" -ForegroundColor Yellow
Write-Host ""
Write-Host "PlatformConfig:   $platformConfig"
Write-Host "TaskRegistry:     $taskRegistry"
Write-Host "MigrationState:   $migrationState"
Write-Host ""
Write-Host "Transaction:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Digest:           $txDigest"
Write-Host "Explorer:         https://suiscan.xyz/testnet/tx/$txDigest"
Write-Host ""

# Save to deployment.json
Write-Host "[5/5] Saving deployment information..." -ForegroundColor Blue

$deploymentInfo = @{
    network = $network
    version = "1.0.0"
    deployedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    deployer = $deployer
    packageId = $packageId
    upgradeCap = $upgradeCap
    adminCap = $adminCap
    sharedObjects = @{
        platformConfig = $platformConfig
        taskRegistry = $taskRegistry
        migrationState = $migrationState
    }
    transaction = @{
        digest = $txDigest
        explorerUrl = "https://suiscan.xyz/testnet/tx/$txDigest"
    }
} | ConvertTo-Json -Depth 10

$deploymentInfo | Out-File -FilePath "deployment.json" -Encoding UTF8
Write-Host "✓ Saved to deployment.json" -ForegroundColor Green

# Update Move.toml message
Write-Host ""
Write-Host "! Update Move.toml with published-at field:" -ForegroundColor Yellow
Write-Host "   published-at = `"$packageId`""
Write-Host ""

# Create frontend env template
$envTemplate = @"
# Songsim Platform - Frontend Configuration
# Generated: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")

# Sui Network
NEXT_PUBLIC_SUI_NETWORK=$network

# Deployed Package (v1.0.0)
NEXT_PUBLIC_PACKAGE_ID=$packageId

# Shared Objects
NEXT_PUBLIC_PLATFORM_CONFIG_ID=$platformConfig
NEXT_PUBLIC_TASK_REGISTRY_ID=$taskRegistry
NEXT_PUBLIC_MIGRATION_STATE_ID=$migrationState

# Walrus Storage (Testnet)
NEXT_PUBLIC_WALRUS_PUBLISHER=https://publisher.walrus-testnet.walrus.space
NEXT_PUBLIC_WALRUS_AGGREGATOR=https://aggregator.walrus-testnet.walrus.space

# Seal Encryption (Optional - Leave empty to disable)
NEXT_PUBLIC_SEAL_PACKAGE_ID=

# Feature Flags
NEXT_PUBLIC_ENABLE_ENCRYPTION=false
NEXT_PUBLIC_ENABLE_ANALYTICS=true
"@

$envTemplate | Out-File -FilePath "..\songsim-label\.env.local.template" -Encoding UTF8
Write-Host "✓ Created .env.local.template in songsim-label/" -ForegroundColor Green
Write-Host ""

# Next steps
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║                   Next Steps                             ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""
Write-Host "1. Update Move.toml with published-at field"
Write-Host "2. Copy .env.local.template to .env.local in songsim-label/"
Write-Host "3. Update DEPLOYMENT_HISTORY.md with deployment details"
Write-Host "4. Update contract-constants.ts with new IDs"
Write-Host "5. Test frontend connection: cd songsim-label && pnpm dev"
Write-Host ""
Write-Host "⚠️  CRITICAL: Backup UpgradeCap ID securely!" -ForegroundColor Red
Write-Host "    UpgradeCap: $upgradeCap"
Write-Host "    (Required for all future upgrades)"
Write-Host ""
Write-Host "✓ Deployment complete!" -ForegroundColor Green
