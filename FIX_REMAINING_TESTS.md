# Remaining Test Fixes Required

## Status: 5 finalize_consensus calls need updating in consensus_tests.move

### Pattern for Fixes

All `finalize_consensus` calls need to be updated from OLD signature to NEW signature:

#### OLD Signature (Current - WRONG):
```move
songsim::finalize_consensus(
    &config,
    &mut task,
    accepted_ids,
    accepted_labelers,
    rejected_ids,
    &clock,
    ts::ctx(&mut scenario),
);
```

#### NEW Signature (Required - CORRECT):
```move
// 1. Before the finalize call, add these lines to get registry, profile, quality_tracker:
let mut registry = ts::take_shared<TaskRegistry>(&scenario);

// Get requester profile
let profile_addr = registry::get_profile_address(&registry, test_helpers::requester());
let mut requester_profile = ts::take_shared_by_id<UserProfile>(&scenario, object::id_from_address(profile_addr));

// Get quality tracker
let task_id = task::get_task_id(&task);
let quality_tracker_addr = registry::get_quality_tracker_address(&registry, task_id);
let mut quality_tracker = ts::take_shared_by_id(&scenario, object::id_from_address(quality_tracker_addr));

// 2. Add rejected_labelers vector:
let rejected_labelers = vector::empty<address>(); // OR populate with actual addresses if rejecting

// 3. Call with NEW signature:
songsim::finalize_consensus(
    &config,
    &mut registry,
    &mut task,
    &mut requester_profile,
    &mut quality_tracker,
    accepted_ids,
    accepted_labelers,
    rejected_ids,
    rejected_labelers, // NEW PARAMETER
    &clock,
    ts::ctx(&mut scenario),
);

// 4. Return shared objects after call:
ts::return_shared(quality_tracker);
ts::return_shared(requester_profile);
ts::return_shared(registry);
```

### Locations to Fix (Line numbers approximate after previous edits):

1. **Line ~302**: `test_finalize_consensus_with_mixed_results`
   - Has 1 accepted, 1 rejected
   - Need to add `rejected_labelers = vector[test_helpers::labeler2()]`

2. **Line ~342**: `test_only_requester_can_finalize`
   - Has 2 accepted, 0 rejected
   - Need to add `rejected_labelers = vector::empty<address>()`

3. **Line ~484**: `test_consensus_with_custom_platform_fee`
   - Has 2 accepted, 0 rejected
   - Need to add `rejected_labelers = vector::empty<address>()`

4. **Line ~524**: `test_cannot_finalize_twice` (first finalize)
   - Has 2 accepted, 0 rejected
   - Need to add `rejected_labelers = vector::empty<address>()`

5. **Line ~550**: `test_cannot_finalize_twice` (second finalize - should fail)
   - Has 2 accepted, 0 rejected
   - Need to add `rejected_labelers = vector::empty<address>()`

### Test Compilation Errors Fixed So Far:

✅ profile_tests.move - All profiles accessed via registry as shared objects
✅ task_tests.move - All task creation/submission/cancel calls updated
✅ consensus_tests.move - setup functions updated (submit_labels with quality_tracker)
✅ consensus_tests.move - First finalize_consensus call updated (test_finalize_consensus_with_accepted_submissions)
✅ reputation_tests.move - submit_labels updated with quality_tracker
✅ registry_tests.move - cancel_task updated with registry and requester_profile

### Remaining Errors:

❌ consensus_tests.move - 5 finalize_consensus calls (lines 302, 342, 484, 524, 550)

### Command to Test After Fixes:

```bash
cd songsim
sui move test
```

Expected result after all fixes: All tests should compile and many should pass.

Note: Some tests may still fail functionally (not compile errors) due to logic changes in the new architecture (e.g., submission IDs may be different, timing issues). Those can be debugged individually after compilation succeeds.
