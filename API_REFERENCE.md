# Songsim Smart Contract API Reference

## Quick Reference for New/Updated Functions

### 📝 Task Management (Updated)

#### `create_task`

```move
public fun create_task(
    registry: &mut TaskRegistry,
    config: &mut PlatformConfig,
    profile: &mut UserProfile,
    dataset_url: vector<u8>,
    dataset_filename: vector<u8>,        // NEW
    dataset_content_type: vector<u8>,    // NEW
    title: vector<u8>,
    description: vector<u8>,
    instructions: vector<u8>,
    required_labelers: u64,
    deadline: u64,
    mut bounty: Coin<SUI>,               // Changed: now stores as Balance
    ctx: &mut TxContext,
)
```

**Changes:**

- Added `dataset_filename` and `dataset_content_type` parameters
- Bounty is now stored internally as `Balance<SUI>`
- Task becomes a **shared object** (not owned)
- Validates bounty <= MAX_BOUNTY for overflow protection

#### `cancel_task`

```move
entry fun cancel_task(
    task: &mut Task,
    ctx: &mut TxContext,  // Changed: removed bounty parameter
)
```

**Changes:**

- Removed `bounty: Coin<SUI>` parameter
- Extracts bounty from task's stored balance
- Emits `TaskCancelled` event

#### `refund_failed_task`

```move
entry fun refund_failed_task(
    task: &mut Task,
    ctx: &mut TxContext,  // Changed: removed bounty parameter
)
```

**Changes:**

- Removed `bounty: Coin<SUI>` parameter
- Extracts bounty from task's stored balance
- Emits `TaskCancelled` event

### 📤 Submission Management (Updated)

#### `submit_labels`

```move
public fun submit_labels(
    registry: &mut TaskRegistry,
    task: &mut Task,
    profile: &mut UserProfile,
    result_url: vector<u8>,
    result_filename: vector<u8>,         // NEW
    result_content_type: vector<u8>,     // NEW
    ctx: &mut TxContext,
)
```

**Changes:**

- Added `result_filename` and `result_content_type` parameters
- Tracks submission IDs in task for validation
- Submission includes `reviewed_at` timestamp

### 💰 Payout Functions (Updated)

#### `distribute_payout`

```move
public fun distribute_payout(
    config: &PlatformConfig,
    task: &mut Task,                      // Changed: now mutable
    submission: &Submission,
    ctx: &mut TxContext,                  // Changed: removed payment parameter
)
```

**Changes:**

- Removed `payment: Coin<SUI>` parameter
- Extracts from task's stored bounty balance
- Calculates: `payout = bounty_amount / accepted_count`
- Includes overflow protection

#### `distribute_batch_payouts` (NEW)

```move
public fun distribute_batch_payouts(
    config: &PlatformConfig,
    task: &mut Task,
    submission_ids: vector<u64>,          // Submission IDs to pay
    submission_labelers: vector<address>, // Corresponding labeler addresses
    ctx: &mut TxContext,
)
```

**New Function:**

- Distributes payouts to multiple labelers in one transaction
- Validates all submission IDs belong to task
- Emits individual `PayoutDistributed` events
- Significantly more gas efficient for multiple payouts

### 🎯 Consensus Functions (Enhanced)

#### `finalize_consensus`

```move
public fun finalize_consensus(
    task: &mut Task,
    accepted_submission_ids: vector<u64>,
    rejected_submission_ids: vector<u64>,
    ctx: &mut TxContext,
)
```

**Enhancements:**

- Validates total reviewed == total submissions
- Validates all submission IDs exist in task
- Requires at least one accepted submission
- Tracks `accepted_count` for payout calculations

#### `update_submission_status`

```move
public fun update_submission_status(
    submission: &mut Submission,
    task: &Task,
    is_accepted: bool,
    ctx: &mut TxContext,               // Changed: now mutable
)
```

**Changes:**

- Sets `reviewed_at` timestamp
- Emits `SubmissionRejected` event for rejections
- Validates task is completed before allowing status update

### 📊 View Functions (NEW)

#### Task Query Functions

```move
// Get paginated task IDs
public fun get_all_task_ids(
    registry: &TaskRegistry,
    start_id: u64,
    limit: u64
): vector<u64>

// Check if task exists
public fun task_exists(registry: &TaskRegistry, task_id: u64): bool

// Get task object address
public fun get_task_address(registry: &TaskRegistry, task_id: u64): address

// Get all submission IDs for a task
public fun get_task_submission_ids(task: &Task): vector<u64>

// Get remaining bounty in task
public fun get_task_bounty_remaining(task: &Task): u64

// Get comprehensive task details
public fun get_task_details(task: &Task): (
    u64,      // task_id
    address,  // requester
    u64,      // bounty_amount
    u64,      // bounty_remaining
    u8,       // status
    u64,      // required_labelers
    u64,      // submission_count
    u64,      // accepted_count
    u64,      // deadline
    u64,      // created_at
    u64,      // completed_at
)
```

#### Submission Query Functions

```move
// Get submission address
public fun get_submission_address(
    registry: &TaskRegistry,
    submission_id: u64
): address

// Get detailed submission info
public fun get_submission_details(submission: &Submission): (
    u64,      // submission_id
    u64,      // task_id
    address,  // labeler
    u8,       // status
    u64,      // submitted_at
    u64,      // reviewed_at
)
```

#### Profile & Reputation Query Functions

```move
// Get profile address
public fun get_profile_address(
    registry: &TaskRegistry,
    user: address
): address

// Get reputation address
public fun get_reputation_address(
    registry: &TaskRegistry,
    user: address
): address

// Get reputation details
public fun get_reputation_details(reputation: &Reputation): (
    address,        // user
    u64,           // total_completed
    u64,           // total_accepted
    u64,           // total_rejected
    u64,           // reputation_score
    u64,           // weighted_score
    vector<u8>,    // badges
)
```

### 🏆 Prize Pool Functions (Enhanced)

#### `distribute_prize_pool`

```move
public fun distribute_prize_pool(
    _: &AdminCap,
    pool: &mut PrizePool,
    winners: vector<address>,
    ctx: &mut TxContext,
)
```

**Enhancement:**

- Now handles integer division remainder
- First winner receives: `prize_per_winner + remainder`
- Ensures all funds are distributed

#### `join_prize_pool`

```move
public fun join_prize_pool(
    pool: &mut PrizePool,
    ctx: &mut TxContext,
)
```

**Enhancement:**

- Emits `PrizePoolJoined` event for tracking

### 🔐 Reputation Functions (Secured)

#### `update_reputation_internal` (NEW)

```move
public(package) fun update_reputation_internal(
    reputation: &mut Reputation,
    user_addr: address,
    accepted: bool
)
```

**New Function:**

- Package-internal only (cannot be called externally)
- Prevents self-manipulation of reputation
- Used internally for secure reputation updates

#### `update_reputation`

```move
public fun update_reputation(
    reputation: &mut Reputation,
    accepted: bool,
    ctx: &TxContext,
)
```

**Note:** Public wrapper maintained for backward compatibility

## 🔄 Migration Guide

### For Frontend Integration

#### Old Code (Before)

```typescript
// Creating a task
await contract.create_task(
  registry,
  config,
  profile,
  datasetUrl,
  title, // Wrong: no filename/content_type
  description,
  instructions,
  requiredLabelers,
  deadline,
  bounty
);
```

#### New Code (After)

```typescript
// Creating a task
await contract.create_task(
  registry,
  config,
  profile,
  datasetUrl,
  "dataset.csv", // NEW: filename
  "text/csv", // NEW: content type
  title,
  description,
  instructions,
  requiredLabelers,
  deadline,
  bounty
);
```

#### Old Code (Before)

```typescript
// Distributing payout
await contract.distribute_payout(
  config,
  task,
  submission,
  paymentCoin // No longer needed!
);
```

#### New Code (After)

```typescript
// Single payout
await contract.distribute_payout(
  config,
  task,
  submission
  // payment automatically extracted from task
);

// Or batch payout (more efficient)
await contract.distribute_batch_payouts(
  config,
  task,
  [subId1, subId2, subId3],
  [labeler1, labeler2, labeler3]
);
```

### For Task Object Handling

#### Important Change: Task is Now a Shared Object

**Old Code (Before):**

```move
// Task was owned by requester
let task = ts::take_from_sender<Task>(&scenario);
// ... use task ...
ts::return_to_sender(&scenario, task);
```

**New Code (After):**

```move
// Task is now shared
let mut task = ts::take_shared<Task>(&scenario);
// ... use task ...
ts::return_shared(task);
```

## 📋 Constants Reference

### New Constants

```move
const MAX_BOUNTY: u64 = 1_000_000_000_000_000;  // 1M SUI (overflow protection)
const ESubmissionNotFound: u64 = 22;            // New error code
```

### Task Status

```move
const STATUS_OPEN: u8 = 0;
const STATUS_IN_PROGRESS: u8 = 1;
const STATUS_COMPLETED: u8 = 2;
const STATUS_CANCELLED: u8 = 3;
```

### Submission Status

```move
// 0 = pending
// 1 = accepted
// 2 = rejected
```

## 🎯 Best Practices

### For Task Creation

1. Always include proper filename and content type
2. Ensure bounty < MAX_BOUNTY
3. Set reasonable deadline (> current timestamp)
4. Validate dataset_url is not empty

### For Payouts

1. Use `distribute_batch_payouts()` for multiple labelers
2. Finalize consensus before distributing
3. Update submission status after consensus
4. Check task is completed before payout

### For Queries

1. Use paginated functions for large datasets
2. Cache view function results when possible
3. Query `task_exists()` before fetching details
4. Use `get_task_bounty_remaining()` to verify funds

## ⚠️ Breaking Changes Summary

1. **Task object is now shared** - Change all `take_from_sender/address` to `take_shared`
2. **create_task requires filename/content_type** - Add 2 new parameters
3. **submit_labels requires filename/content_type** - Add 2 new parameters
4. **distribute_payout no longer needs payment** - Remove payment parameter
5. **cancel_task/refund_failed_task no longer need payment** - Remove payment parameter
6. **get_task_info renamed** - Use `get_task_details` with 11 return values
7. **get_submission_info renamed** - Use `get_submission_details` with 6 return values

## 📞 Support

For questions or issues:

- Check the test files for usage examples
- Review SMART_CONTRACT_FIXES_SUMMARY.md for detailed changes
- All tests pass: `sui move test` in songsim directory
