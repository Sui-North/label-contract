# Songsim Platform - Package Upgrade Script (PowerShell)
# This script automates safe package upgrades with migration support

param(
    [Parameter(Mandatory=$false)]
    [switch]$RequiresMigration = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$NewVersion = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests = $false
)

$ErrorActionPreference = "Stop"

Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║         Songsim Platform - Package Upgrade Tool          ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# Load existing deployment
if (-not (Test-Path "deployment.json")) {
    Write-Host "✗ deployment.json not found. Deploy first using deploy.ps1" -ForegroundColor Red
    exit 1
}

$deployment = Get-Content "deployment.json" | ConvertFrom-Json
Write-Host "✓ Loaded deployment v$($deployment.version)" -ForegroundColor Green
Write-Host "  Package:    $($deployment.packageId)" -ForegroundColor Gray
Write-Host "  UpgradeCap: $($deployment.upgradeCap)" -ForegroundColor Gray
Write-Host ""

# Check Sui CLI
$network = sui client active-env | Out-String
$network = $network.Trim()
Write-Host "✓ Active network: $network" -ForegroundColor Green

if ($network -ne $deployment.network) {
    Write-Host "✗ Network mismatch! Deployment was on $($deployment.network)" -ForegroundColor Red
    exit 1
}

# Get version info
if ($NewVersion -eq "") {
    Write-Host "Enter new version number (current: $($deployment.version)): " -NoNewline
    $NewVersion = Read-Host
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║                 Upgrade Configuration                    ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""
Write-Host "Current Version:    $($deployment.version)"
Write-Host "New Version:        $NewVersion"
Write-Host "Requires Migration: $RequiresMigration"
Write-Host ""

$response = Read-Host "Proceed with upgrade? (y/n)"
if ($response -ne "y") {
    Write-Host "Upgrade cancelled."
    exit 0
}
Write-Host ""

# Build package
Write-Host "[1/6] Building package..." -ForegroundColor Blue
try {
    sui move build
    Write-Host "✓ Build successful" -ForegroundColor Green
}
catch {
    Write-Host "✗ Build failed" -ForegroundColor Red
    exit 1
}

# Run tests
if (-not $SkipTests) {
    Write-Host "[2/6] Running tests..." -ForegroundColor Blue
    try {
        sui move test
        Write-Host "✓ All tests passed" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Tests failed" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[2/6] Tests skipped (--SkipTests flag)" -ForegroundColor Yellow
}

# Begin migration if needed
if ($RequiresMigration) {
    Write-Host "[3/6] Locking platform for migration..." -ForegroundColor Blue
    Write-Host "⚠️  Platform will be locked during upgrade!" -ForegroundColor Yellow
    $response = Read-Host "Continue? (y/n)"
    if ($response -ne "y") {
        Write-Host "Upgrade cancelled."
        exit 0
    }
    
    try {
        $adminCap = $deployment.adminCap
        $migrationState = $deployment.sharedObjects.migrationState
        $clock = "0x0000000000000000000000000000000000000000000000000000000000000006"
        
        sui client call `
            --package $($deployment.packageId) `
            --module songsim `
            --function begin_platform_migration `
            --args $adminCap $migrationState $clock `
            --gas-budget 10000000
        
        Write-Host "✓ Platform locked (version = U64_MAX)" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to lock platform" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[3/6] No migration required (skipping lock)" -ForegroundColor Green
}

# Execute upgrade
Write-Host "[4/6] Upgrading package..." -ForegroundColor Blue
Write-Host "! This will consume gas and publish new package version" -ForegroundColor Yellow
Write-Host ""

try {
    $upgradeOutput = sui client upgrade `
        --upgrade-capability $($deployment.upgradeCap) `
        --gas-budget 100000000 `
        --json | ConvertFrom-Json
    
    $newPackageId = ($upgradeOutput.objectChanges | Where-Object { $_.type -eq "published" }).packageId
    $txDigest = $upgradeOutput.digest
    
    Write-Host "✓ Upgrade successful!" -ForegroundColor Green
    Write-Host "  New Package: $newPackageId" -ForegroundColor Gray
    Write-Host "  Transaction: $txDigest" -ForegroundColor Gray
}
catch {
    Write-Host "✗ Upgrade failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    
    if ($RequiresMigration) {
        Write-Host ""
        Write-Host "⚠️  Platform is LOCKED! Need to rollback:" -ForegroundColor Red
        Write-Host ""
        Write-Host "sui client call \\" 
        Write-Host "  --package $($deployment.packageId) \\"
        Write-Host "  --module songsim \\"
        Write-Host "  --function rollback_platform_migration \\"
        Write-Host "  --args $($deployment.adminCap) $($deployment.sharedObjects.migrationState) \\"
        Write-Host "  --gas-budget 10000000"
    }
    exit 1
}

# Complete migration if needed
if ($RequiresMigration) {
    Write-Host "[5/6] Unlocking platform with new version..." -ForegroundColor Blue
    
    # Calculate version number (assuming semantic versioning)
    $versionParts = $NewVersion.Split(".")
    $versionNum = [int]$versionParts[0] * 1000000 + [int]$versionParts[1] * 1000 + [int]$versionParts[2]
    
    Write-Host "  Version number: $versionNum" -ForegroundColor Gray
    
    try {
        sui client call `
            --package $newPackageId `
            --module songsim `
            --function complete_platform_migration `
            --args $($deployment.adminCap) $($deployment.sharedObjects.migrationState) $versionNum `
            --gas-budget 10000000
        
        Write-Host "✓ Platform unlocked with version $NewVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to unlock platform!" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "⚠️  CRITICAL: Platform is locked but upgraded!" -ForegroundColor Red
        Write-Host "   Manually complete migration or rollback" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[5/6] No migration unlock needed" -ForegroundColor Green
}

# Update deployment.json
Write-Host "[6/6] Updating deployment records..." -ForegroundColor Blue

$deployment.version = $NewVersion
$deployment.packageId = $newPackageId
$deployment.previousVersions += @{
    version = $deployment.version
    packageId = $deployment.packageId
    upgradedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    transaction = @{
        digest = $txDigest
        explorerUrl = "https://suiscan.xyz/$network/tx/$txDigest"
    }
}

$deployment | ConvertTo-Json -Depth 10 | Out-File -FilePath "deployment.json" -Encoding UTF8
Write-Host "✓ Updated deployment.json" -ForegroundColor Green

# Create backup
$backupFile = "deployment_backup_$($deployment.version).json"
$deployment | ConvertTo-Json -Depth 10 | Out-File -FilePath $backupFile -Encoding UTF8
Write-Host "✓ Created backup: $backupFile" -ForegroundColor Green

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║              Upgrade Complete!                           ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""
Write-Host "Version:       $($deployment.version) → $NewVersion" -ForegroundColor Green
Write-Host "Package ID:    $newPackageId"
Write-Host "Transaction:   https://suiscan.xyz/$network/tx/$txDigest"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Update Move.toml with new published-at"
Write-Host "2. Update frontend .env.local with new Package ID"
Write-Host "3. Update DEPLOYMENT_HISTORY.md with upgrade details"
Write-Host "4. Test all functionality on frontend"
Write-Host "5. Monitor for any issues"
Write-Host ""

if ($RequiresMigration) {
    Write-Host "⚠️  Data migration completed. Verify all objects:" -ForegroundColor Yellow
    Write-Host "   - Check MigrationState.current_version = $versionNum"
    Write-Host "   - Test profile operations"
    Write-Host "   - Test task operations"
    Write-Host "   - Check consensus still works"
    Write-Host ""
}

Write-Host "✓ Upgrade successful!" -ForegroundColor Green
