# Songsim V3 Deployment (Shared Object Architecture)

## Deployment Summary

**Date:** 2025-01-XX  
**Network:** Sui Testnet  
**Transaction Digest:** `97F1tghBCqbDuSk2zpCXaJzxqtApFdy799JV1YGp9M9Z`

## Key Object IDs

### Package
- **Package ID:** `0xe26690f7c4c45ee7ceedee6dceb2b269ab49581a2b9844ff1ca382fe8415757d`

### Owned Objects (sent to deployer)
- **Admin Cap:** `0xba868a6534fb40aa16b896c2b79382584f3c8f9a6d4a8232faf7285eeb139203`
- **Upgrade Cap:** `0x200264ee1adfbb72e9e33d5acea96f7e8037374fa0123ae52fd3f5c7f282a59d`

### Shared Objects
- **Platform Config:** `0x57377260251d300719d7423db4a290e323b4c6a5383a70ea2ae26e36390e9ff1`
- **Task Registry:** `0xb3d5c0cfdb4cc0894f3c5dbd15f3f2b1f9daa94cd333f84c8a027e5d2fab8470`
- **Access Registry:** `0xadfdc3da5595990615091002bcbe1bd9baff6a75b2f9b6f20794cad409b68c67`
- **Migration State:** `0xf35a64efef3f466da9d713f1c54272085d5dcd2c228c9b6f2909cf282699050c`

## Gas Costs

- **Storage Cost:** 344.865 SUI
- **Computation Cost:** 0.004 SUI
- **Storage Rebate:** -0.000978 SUI
- **Total Cost:** ~0.348 SUI

## Architecture Changes (V3)

### Shared Objects (key + store)
1. **Profile** - Per-user profile with completion statistics
2. **Reputation** - Per-user reputation score tracking
3. **Submission** - Individual task submissions
4. **QualityTracker** - Per-task quality metrics

### Registry Updates
- Added `quality_trackers` table mapping task_id → QualityTracker address
- All objects registered in central TaskRegistry

### Frontend Integration Requirements

Update `.env.local`:
```env
NEXT_PUBLIC_PACKAGE_ID=0xe26690f7c4c45ee7ceedee6dceb2b269ab49581a2b9844ff1ca382fe8415757d
NEXT_PUBLIC_PLATFORM_CONFIG_ID=0x57377260251d300719d7423db4a290e323b4c6a5383a70ea2ae26e36390e9ff1
NEXT_PUBLIC_TASK_REGISTRY_ID=0xb3d5c0cfdb4cc0894f3c5dbd15f3f2b1f9daa94cd333f84c8a027e5d2fab8470
NEXT_PUBLIC_ACCESS_REGISTRY_ID=0xadfdc3da5595990615091002bcbe1bd9baff6a75b2f9b6f20794cad409b68c67
```

## Modules Deployed

1. access_policy
2. batch_updates
3. consensus
4. constants
5. dispute
6. emergency
7. events
8. migration
9. prize_pool
10. profile
11. quality
12. registry
13. reputation
14. songsim (main)
15. staking
16. task
