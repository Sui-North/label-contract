#!/bin/bash

# Songsim Platform - Testnet Deployment Script
# This script automates the deployment process and captures important IDs

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Songsim Platform - Testnet Deployment v1.0.0         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Navigate to contract directory
cd "$(dirname "$0")/.."
echo -e "${GREEN}✓${NC} Working directory: $(pwd)"

# Check Sui CLI installed
if ! command -v sui &> /dev/null; then
    echo -e "${RED}✗${NC} Sui CLI not found. Please install from https://docs.sui.io/build/install"
    exit 1
fi
echo -e "${GREEN}✓${NC} Sui CLI found: $(sui --version)"

# Check network configuration
NETWORK=$(sui client active-env)
echo -e "${YELLOW}!${NC} Active network: $NETWORK"

if [ "$NETWORK" != "testnet" ]; then
    echo -e "${YELLOW}!${NC} WARNING: Not on testnet. Continue? (y/n)"
    read -r response
    if [ "$response" != "y" ]; then
        echo "Deployment cancelled."
        exit 0
    fi
fi

# Get active address
DEPLOYER=$(sui client active-address)
echo -e "${GREEN}✓${NC} Deployer address: $DEPLOYER"

# Check balance
echo -e "${BLUE}[1/5]${NC} Checking balance..."
BALANCE=$(sui client gas --json | jq -r '.[] | select(.gasBalance) | .gasBalance' | head -1)
BALANCE_SUI=$(echo "scale=2; $BALANCE / 1000000000" | bc)
echo -e "${GREEN}✓${NC} Balance: $BALANCE_SUI SUI"

if (( $(echo "$BALANCE_SUI < 0.1" | bc -l) )); then
    echo -e "${RED}✗${NC} Insufficient balance. Need at least 0.1 SUI for deployment."
    echo -e "    Request tokens from: https://discord.com/channels/916379725201563759/971488439931392130"
    exit 1
fi

# Build package
echo -e "${BLUE}[2/5]${NC} Building package..."
if sui move build; then
    echo -e "${GREEN}✓${NC} Build successful"
else
    echo -e "${RED}✗${NC} Build failed. Check errors above."
    exit 1
fi

# Run tests
echo -e "${BLUE}[3/5]${NC} Running tests..."
if sui move test; then
    echo -e "${GREEN}✓${NC} All tests passed"
else
    echo -e "${RED}✗${NC} Tests failed. Check errors above."
    exit 1
fi

# Deploy package
echo -e "${BLUE}[4/5]${NC} Publishing to $NETWORK..."
echo -e "${YELLOW}!${NC} This will consume gas. Continue? (y/n)"
read -r response
if [ "$response" != "y" ]; then
    echo "Deployment cancelled."
    exit 0
fi

OUTPUT=$(sui client publish --gas-budget 100000000 --json)

# Check if deployment successful
if [ $? -ne 0 ]; then
    echo -e "${RED}✗${NC} Deployment failed"
    exit 1
fi

# Extract important IDs
PACKAGE_ID=$(echo "$OUTPUT" | jq -r '.objectChanges[] | select(.type == "published") | .packageId')
UPGRADE_CAP=$(echo "$OUTPUT" | jq -r '.objectChanges[] | select(.objectType | contains("UpgradeCap")) | .objectId')
PLATFORM_CONFIG=$(echo "$OUTPUT" | jq -r '.objectChanges[] | select(.objectType | contains("PlatformConfig")) | .objectId')
TASK_REGISTRY=$(echo "$OUTPUT" | jq -r '.objectChanges[] | select(.objectType | contains("TaskRegistry")) | .objectId')
MIGRATION_STATE=$(echo "$OUTPUT" | jq -r '.objectChanges[] | select(.objectType | contains("MigrationState")) | .objectId')
ADMIN_CAP=$(echo "$OUTPUT" | jq -r '.objectChanges[] | select(.objectType | contains("AdminCap")) | .objectId')
TX_DIGEST=$(echo "$OUTPUT" | jq -r '.digest')

echo ""
echo -e "${GREEN}✓${NC} Deployment successful!"
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Deployment Summary                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}CRITICAL IDs (Save these securely):${NC}"
echo ""
echo "Package ID:       $PACKAGE_ID"
echo "UpgradeCap ID:    $UPGRADE_CAP"
echo "AdminCap ID:      $ADMIN_CAP"
echo ""
echo -e "${YELLOW}Shared Objects:${NC}"
echo ""
echo "PlatformConfig:   $PLATFORM_CONFIG"
echo "TaskRegistry:     $TASK_REGISTRY"
echo "MigrationState:   $MIGRATION_STATE"
echo ""
echo -e "${YELLOW}Transaction:${NC}"
echo ""
echo "Digest:           $TX_DIGEST"
echo "Explorer:         https://suiscan.xyz/testnet/tx/$TX_DIGEST"
echo ""

# Save to deployment.json
echo -e "${BLUE}[5/5]${NC} Saving deployment information..."

cat > deployment.json << EOF
{
  "network": "$NETWORK",
  "version": "1.0.0",
  "deployedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "deployer": "$DEPLOYER",
  "packageId": "$PACKAGE_ID",
  "upgradeCap": "$UPGRADE_CAP",
  "adminCap": "$ADMIN_CAP",
  "sharedObjects": {
    "platformConfig": "$PLATFORM_CONFIG",
    "taskRegistry": "$TASK_REGISTRY",
    "migrationState": "$MIGRATION_STATE"
  },
  "transaction": {
    "digest": "$TX_DIGEST",
    "explorerUrl": "https://suiscan.xyz/testnet/tx/$TX_DIGEST"
  }
}
EOF

echo -e "${GREEN}✓${NC} Saved to deployment.json"

# Update Move.toml
echo ""
echo -e "${YELLOW}!${NC} Update Move.toml with published-at field:"
echo "   published-at = \"$PACKAGE_ID\""
echo ""

# Create frontend env template
cat > ../songsim-label/.env.local.template << EOF
# Songsim Platform - Frontend Configuration
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Sui Network
NEXT_PUBLIC_SUI_NETWORK=$NETWORK

# Deployed Package (v1.0.0)
NEXT_PUBLIC_PACKAGE_ID=$PACKAGE_ID

# Shared Objects
NEXT_PUBLIC_PLATFORM_CONFIG_ID=$PLATFORM_CONFIG
NEXT_PUBLIC_TASK_REGISTRY_ID=$TASK_REGISTRY
NEXT_PUBLIC_MIGRATION_STATE_ID=$MIGRATION_STATE

# Walrus Storage (Testnet)
NEXT_PUBLIC_WALRUS_PUBLISHER=https://publisher.walrus-testnet.walrus.space
NEXT_PUBLIC_WALRUS_AGGREGATOR=https://aggregator.walrus-testnet.walrus.space

# Seal Encryption (Optional - Leave empty to disable)
NEXT_PUBLIC_SEAL_PACKAGE_ID=

# Feature Flags
NEXT_PUBLIC_ENABLE_ENCRYPTION=false
NEXT_PUBLIC_ENABLE_ANALYTICS=true
EOF

echo -e "${GREEN}✓${NC} Created .env.local.template in songsim-label/"
echo ""

# Next steps
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   Next Steps                             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "1. Update Move.toml with published-at field"
echo "2. Copy .env.local.template to .env.local in songsim-label/"
echo "3. Update DEPLOYMENT_HISTORY.md with deployment details"
echo "4. Update contract-constants.ts with new IDs"
echo "5. Test frontend connection: cd songsim-label && pnpm dev"
echo ""
echo -e "${RED}⚠️  CRITICAL:${NC} Backup UpgradeCap ID securely!"
echo "    UpgradeCap: $UPGRADE_CAP"
echo "    (Required for all future upgrades)"
echo ""
echo -e "${GREEN}✓${NC} Deployment complete!"
