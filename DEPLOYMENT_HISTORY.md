# Deployment History & Upgrade Tracking

**Network:** Sui Testnet  
**Current Version:** 1.0.0

---

## Version 1.0.0 (Current - Initial Release)

**Deployment Date:** Not yet deployed  
**Status:** ✅ Ready for deployment

### Package Information
- **Package ID:** `<PENDING DEPLOYMENT>`
- **UpgradeCap ID:** `<PENDING DEPLOYMENT>`
- **Transaction Digest:** `<PENDING DEPLOYMENT>`

### Shared Objects Created
- **PlatformConfig ID:** `<PENDING>`
- **TaskRegistry ID:** `<PENDING>`
- **MigrationState ID:** `<PENDING>`
- **AdminCap Owner:** `<DEPLOYER ADDRESS>`

### Features Included
- ✅ Core platform (songsim.move)
- ✅ User profiles (profile.move)
- ✅ Task management (task.move)
- ✅ Consensus system (consensus.move)
- ✅ Reputation tracking (reputation.move)
- ✅ Registry system (registry.move)
- ✅ Dispute resolution (dispute.move)
- ✅ Prize pools (prize_pool.move)
- ✅ **Security:** Anti-Sybil staking (staking.move)
- ✅ **Security:** Quality metrics (quality.move)
- ✅ **Security:** Emergency circuit breaker (emergency.move)
- ✅ **Migration:** Version tracking and upgrade support (migration.move)
- ✅ **Optional:** Seal encryption (access_policy.move)

### Test Results
- **Total Tests:** 36
- **Passed:** 36
- **Failed:** 0
- **Test Command:** `sui move test`

### Deployment Instructions

1. **Build Package:**
   ```bash
   cd songsim
   sui move build
   ```

2. **Deploy to Testnet:**
   ```bash
   sui client publish --gas-budget 100000000
   ```

3. **Save Important IDs:**
   After deployment, look for these in the output:
   - Package ID (store in Move.toml `published-at`)
   - UpgradeCap ID (needed for future upgrades)
   - PlatformConfig ID (shared object)
   - TaskRegistry ID (shared object)
   - MigrationState ID (shared object)
   - AdminCap ID (owned by deployer)

4. **Update Configuration:**
   - Update `Move.toml` with `published-at = "<PACKAGE-ID>"`
   - Update `songsim-label/lib/contract-constants.ts` with all IDs
   - Update this file with deployment details

### Migration Notes
- **Schema Version:** 1
- **Migration Required:** N/A (initial deployment)
- **Backwards Compatible:** N/A (first version)

### Known Issues
- None

### Configuration
```move
// Default Platform Settings
DEFAULT_PLATFORM_FEE_BPS = 500      // 5%
MIN_BOUNTY = 1_000_000              // 0.001 SUI
MAX_FEE_BPS = 1000                  // 10%
MIN_LABELER_STAKE = 10_000_000      // 0.01 SUI
HIGH_VALUE_THRESHOLD = 100_000_000   // 0.1 SUI
MIN_REPUTATION_HIGH_VALUE = 700     // 70% score
```

---

## Future Versions (Planned)

### Version 1.1.0 (Security Hardening)
**Planned Date:** TBD  
**Status:** 📋 Planning

**Proposed Changes:**
- Integrate staking requirement enforcement in submit_labels
- Add quality tracking to task lifecycle
- Enable emergency pause validation in main functions
- Add batch processing for large payouts

**Migration Required:** No (additive changes only)

---

### Version 2.0.0 (Nautilus TEE Integration)
**Planned Date:** TBD  
**Status:** 📋 Research

**Proposed Changes:**
- Multi-party consensus using Nautilus TEEs
- Enhanced Seal encryption integration
- Advanced dispute resolution

**Migration Required:** Yes (may require data structure changes)

---

## Upgrade Template

Use this template when deploying upgrades:

```markdown
## Version X.Y.Z

**Upgrade Date:** YYYY-MM-DD  
**Status:** ✅ Deployed / 🚧 In Progress / 📋 Planned

### Package Information
- **Package ID:** 0x...
- **UpgradeCap ID:** 0x... (same as v1.0.0)
- **Transaction Digest:** ...
- **Upgraded From:** Version X.Y.Z-1

### Changes
- Feature 1
- Bug fix 2
- Enhancement 3

### Migration
- **Schema Version:** X
- **Migration Required:** Yes/No
- **Migration Steps:** 
  1. Step 1
  2. Step 2
- **Downtime:** X minutes

### Backwards Compatibility
- Compatible with: vX.Y.Z and later
- Breaking changes: Yes/No
- Deprecated features: None

### Testing
- **Tests Passed:** XX/XX
- **New Tests Added:** X
- **Integration Tests:** Pass/Fail

### Deployment Command
```bash
# Before upgrade
sui move build
sui move test

# Upgrade (if migration needed)
sui client call \
  --package <PACKAGE-ID> \
  --module songsim \
  --function begin_platform_migration \
  --args <ADMIN-CAP> <MIGRATION-STATE> <CLOCK> \
  --gas-budget 10000000

# Execute upgrade
sui client upgrade --upgrade-capability <UPGRADE-CAP-ID>

# After upgrade (if migration needed)
sui client call \
  --package <NEW-PACKAGE-ID> \
  --module songsim \
  --function complete_platform_migration \
  --args <ADMIN-CAP> <MIGRATION-STATE> 2 \
  --gas-budget 10000000
```

### Rollback Plan
- Backup package ID: 0x...
- Rollback steps: ...
- Data recovery: ...
```

---

## Critical Information

### UpgradeCap Management

**⚠️ CRITICAL:** The UpgradeCap is required for ALL future upgrades. Loss of UpgradeCap means the package becomes permanently immutable.

**Best Practices:**
1. Store UpgradeCap ID in multiple secure locations:
   - This file
   - Deployment scripts
   - Team password manager
   - Project documentation

2. Consider multi-sig wallet for UpgradeCap ownership (future enhancement)

3. NEVER transfer UpgradeCap to untrusted addresses

4. Before making package immutable, ensure:
   - Platform is stable and battle-tested
   - All planned features are implemented
   - Community consensus achieved

### AdminCap Management

**⚠️ IMPORTANT:** AdminCap controls all privileged operations:
- Platform configuration updates
- Emergency pause/unpause
- Migration operations
- Dispute resolution

**Security:**
- Keep AdminCap in secure wallet
- Consider multi-sig for production
- Document all admin operations
- Implement time-locks for critical changes (future enhancement)

---

## Monitoring & Health Checks

### Post-Deployment Checks

After each deployment/upgrade:

- [ ] Verify all shared objects created
- [ ] Test profile creation
- [ ] Test task creation and submission
- [ ] Test consensus finalization
- [ ] Test emergency pause/resume
- [ ] Verify version numbers match
- [ ] Check frontend can query all objects
- [ ] Monitor for any error events

### Ongoing Monitoring

- Platform version: `MigrationState.current_version`
- Total tasks: `PlatformConfig.total_tasks`
- Total profiles: `PlatformConfig.total_profiles`
- Platform paused: `PlatformConfig.paused`
- Migration status: `MigrationState.is_migrating`

---

## Contact & Support

**Development Team:**
- GitHub: [Repository URL]
- Discord: [Server Link]
- Email: [Support Email]

**Emergency Contact:**
- For critical bugs: [Emergency Contact]
- For upgrade assistance: [Tech Lead]

---

**Last Updated:** November 20, 2025  
**Next Review:** After first deployment  
**Maintained By:** Songsim Core Team
