# Contract Upgrade v2.0.0 - Deadline Extension Feature

**Date:** November 20, 2025  
**Transaction Digest:** `GbCpF6aBgqtmDLnAF8yBPyyoFV4tXbUXgv4h4jnMrpc7`  
**Network:** Sui Testnet  
**Upgrade Type:** Package Upgrade (preserves existing data)

## Upgrade Details

### Package Information

- **New Package ID:** `0x437f4dac58b0dd5daeaecc66d4cb3571ae6e379cfd6f3018447f0b8bbffcc19d`
- **Original Package ID:** `0xe92d9bf5a82568d6c994917c88606eedd97374c978367a233c3fe33955534dea` (preserved in Move.toml)
- **UpgradeCap ID:** `0xcf8a2af8ce073e32292d446c4fb356cddea0d66aaf5c112680f4f5a96322282a` (version updated to 2)

### Object IDs (Unchanged - Data Preserved)

All existing objects remain valid and accessible:

- **Platform Config:** `0x80ecfcccd12cfcfccb0436691d3cda735a02fc9d02a4f55bbea75cd8eb703385`
- **Task Registry:** `0x8d0aaa56bac53294a2c35220bc66dc2159043d67d12a6b31a2605644edb7c82a`
- **Migration State:** `0xa6b0753bc01a20116959c36bbce33243faabc2ed1b74f7ac7a0a76d2c2a956c7`
- **Access Registry:** `0x703b68cc81fd3e9e450a6f3861b14238014c8d80aebe5b94405828f78fbb2e48`
- **Admin Cap:** `0x361efdc205a526c6dfaf5ef7313bac1dc1b1f690c6d0c7ac826bcb02a057d429`

## New Features Added

### 1. Deadline Extension (task.move)

```move
public fun extend_deadline(
    task: &mut Task, 
    new_deadline: u64, 
    clock: &Clock, 
    ctx: &TxContext
)
```

**Validation:**
- Only requester can extend
- Task must be OPEN or IN_PROGRESS
- New deadline must be in the future
- New deadline must be > current deadline

**Event Emitted:**
```move
public struct TaskDeadlineExtended has copy, drop {
    task_id: ID,
    requester: address,
    old_deadline: u64,
    new_deadline: u64,
    timestamp: u64,
}
```

### 2. Public Entry Point (songsim.move)

```move
public fun extend_deadline(
    labeling_task: &mut Task, 
    new_deadline: u64, 
    clock: &Clock, 
    ctx: &TxContext
)
```

### 3. Frontend Integration

**Transaction Builder (lib/contracts/songsim.ts):**
```typescript
export function extendDeadlineTransaction(
  taskObjectId: string, 
  newDeadline: number
): Transaction
```

**UI Component (dashboard/tasks/[id]/page.tsx):**
- Dialog with date picker for selecting new deadline
- Client-side validation (25h minimum from now)
- Server-side validation (enforced by contract)
- Shows only for open/in-progress tasks

## Upgrade Command

```bash
sui client upgrade \
  --upgrade-capability 0xcf8a2af8ce073e32292d446c4fb356cddea0d66aaf5c112680f4f5a96322282a \
  --gas-budget 500000000
```

## Gas Costs

- **Storage Cost:** 304,174,800 MIST (~0.304 SUI)
- **Computation Cost:** 4,000,000 MIST (~0.004 SUI)
- **Storage Rebate:** 2,595,780 MIST (~0.0026 SUI)
- **Total Cost:** ~305,579,020 MIST (~0.306 SUI)

## Test Results

All tests passing before upgrade:
```
Test result: OK. Total tests: 36; passed: 36; failed: 0
```

Test coverage:
- ✅ Profile management (5 tests)
- ✅ Task lifecycle (8 tests)
- ✅ Consensus & payouts (6 tests)
- ✅ Reputation system (4 tests)
- ✅ Registry management (4 tests)
- ✅ Platform configuration (9 tests)

## Data Preservation

**Why This Upgrade Preserves Data:**

1. Used `sui client upgrade` instead of `publish` (keeps same Package ID in Move.toml)
2. All shared objects (PlatformConfig, TaskRegistry, Tasks) remain valid
3. No breaking changes to struct definitions
4. Only additive changes (new function, new event)

**Verified Data Intact:**
- All existing user profiles accessible
- All tasks (open, in-progress, completed) remain functional
- All submissions linked correctly
- Reputation scores preserved
- Registry dynamic fields unchanged

## Frontend Updates

Updated files to use new Package ID:

1. `.env.local`:
   ```env
   NEXT_PUBLIC_PACKAGE_ID=0x437f4dac58b0dd5daeaecc66d4cb3571ae6e379cfd6f3018447f0b8bbffcc19d
   ```

2. `lib/contract-constants.ts`:
   ```typescript
   PACKAGE_ID: "0x437f4dac58b0dd5daeaecc66d4cb3571ae6e379cfd6f3018447f0b8bbffcc19d"
   ```

3. `songsim/Move.toml`:
   ```toml
   version = "2.0.0"
   published-at = "0xe92d9bf5a82568d6c994917c88606eedd97374c978367a233c3fe33955534dea"
   ```

## Deployment Verification

To verify the upgrade:

```bash
# Check package version
sui client object 0xcf8a2af8ce073e32292d446c4fb356cddea0d66aaf5c112680f4f5a96322282a

# Should show version: 2 (was version: 1)

# Verify existing task still accessible
sui client object <task_object_id>

# Test new function
sui client call \
  --package 0x437f4dac58b0dd5daeaecc66d4cb3571ae6e379cfd6f3018447f0b8bbffcc19d \
  --module songsim \
  --function extend_deadline \
  --args <task_object_id> <new_deadline_ms> 0x6 \
  --gas-budget 10000000
```

## Rollback Plan

If issues arise, can revert to previous Package ID in frontend:
```env
NEXT_PUBLIC_PACKAGE_ID=0xe92d9bf5a82568d6c994917c88606eedd97374c978367a233c3fe33955534dea
```

All existing functionality will continue working (deadline extension simply won't be available).

## Next Steps (Phase 3)

With upgrade complete, ready to implement:

1. **Prize Pools** (contract exists, need UI)
   - Create pool transaction builder
   - Join pool functionality
   - Claim winnings UI

2. **Leaderboard** (need queries + page)
   - Top labelers by reputation
   - Top requesters by tasks posted
   - Weekly/monthly rankings

3. **Analytics Dashboard** (need charts)
   - Task completion rates
   - Earnings over time
   - Submission statistics
   - Platform metrics

4. **Reputation Badges** (need visualization)
   - Badge components with icons
   - Progress bars for next level
   - Achievement showcase

---

**Upgrade Status:** ✅ SUCCESS  
**Data Integrity:** ✅ VERIFIED  
**Frontend Updated:** ✅ COMPLETE  
**Ready for Testing:** ✅ YES
