/// Seal Access Policy for Songsim Label
/// Controls who can decrypt encrypted datasets and submissions
module songsim::access_policy;

use sui::table::{Self, Table};
use sui::vec_set::{Self, VecSet};
use songsim::constants;

// === Error Codes ===
const ENotAuthorized: u64 = 1;
const ETaskNotFound: u64 = 2;
const ESubmissionNotFound: u64 = 3;
const EMaxSubmittersReached: u64 = 4;

// === Constants ===
const MAX_SUBMITTERS_PER_TASK: u64 = 1000; // Prevent unbounded vector growth

// === Structs ===

/// Global registry for access control
public struct AccessRegistry has key {
    id: UID,
    // Map task ID to requester (who can decrypt the dataset)
    task_requesters: Table<vector<u8>, address>,
    // Map submission ID to labeler (who can decrypt their submission)
    submission_labelers: Table<vector<u8>, address>,
    // Map task ID to set of authorized labelers (who submitted) - using VecSet to prevent duplicates
    task_submitters: Table<vector<u8>, VecSet<address>>,
}

// === Init Function ===

fun init(ctx: &mut TxContext) {
    let registry = AccessRegistry {
        id: object::new(ctx),
        task_requesters: table::new(ctx),
        submission_labelers: table::new(ctx),
        task_submitters: table::new(ctx),
    };
    transfer::share_object(registry);
}

// === Access Management Functions ===

/// Register a task with its requester (called when task is created)
public(package) fun register_task(registry: &mut AccessRegistry, task_id: vector<u8>, requester: address) {
    table::add(&mut registry.task_requesters, task_id, requester);
    table::add(&mut registry.task_submitters, task_id, vec_set::empty());
}

/// Register a submission (called when labeler submits)
public(package) fun register_submission(
    registry: &mut AccessRegistry,
    submission_id: vector<u8>,
    task_id: vector<u8>,
    labeler: address,
) {
    // Add submission
    table::add(&mut registry.submission_labelers, submission_id, labeler);

    // Add labeler to task's authorized set (prevents duplicates and is bounded)
    if (table::contains(&registry.task_submitters, task_id)) {
        let submitters = table::borrow_mut(&mut registry.task_submitters, task_id);
        
        // Check if already added
        if (!vec_set::contains(submitters, &labeler)) {
            // Enforce max submitters to prevent unbounded growth
            assert!(vec_set::length(submitters) < MAX_SUBMITTERS_PER_TASK, EMaxSubmittersReached);
            vec_set::insert(submitters, labeler);
        };
    };
}

// === Seal Approve Functions ===

/// Approve decryption for task datasets
/// Only the task requester can decrypt the dataset
/// Returns true if authorized, false otherwise
public fun seal_approve_task(id: vector<u8>, registry: &AccessRegistry, ctx: &TxContext): bool {
    let sender = ctx.sender();

    // Check if this task exists and sender is the requester
    if (!table::contains(&registry.task_requesters, id)) {
        return false
    };
    
    let requester = table::borrow(&registry.task_requesters, id);
    sender == *requester
}

/// Approve decryption for task datasets by authorized labelers
/// Allows labelers who have submitted to a task to decrypt the dataset
/// Returns true if authorized, false otherwise
public fun seal_approve_task_for_labeler(
    id: vector<u8>,
    registry: &AccessRegistry,
    ctx: &TxContext,
): bool {
    let sender = ctx.sender();

    // Check if this task exists
    if (!table::contains(&registry.task_submitters, id)) {
        return false
    };
    
    let submitters = table::borrow(&registry.task_submitters, id);

    // Check if sender has submitted to this task
    vec_set::contains(submitters, &sender)
}

/// Approve decryption for submissions
/// Only the labeler who created the submission or the task requester can decrypt
/// Returns true if authorized, false otherwise
public fun seal_approve_submission(
    id: vector<u8>,
    task_id: vector<u8>,
    registry: &AccessRegistry,
    ctx: &TxContext,
): bool {
    let sender = ctx.sender();

    // Check if submission exists
    if (!table::contains(&registry.submission_labelers, id)) {
        return false
    };
    
    let labeler = table::borrow(&registry.submission_labelers, id);

    // Check if sender is the labeler
    if (sender == *labeler) {
        return true
    };

    // Or check if sender is the task requester
    if (table::contains(&registry.task_requesters, task_id)) {
        let requester = table::borrow(&registry.task_requesters, task_id);
        return sender == *requester
    };
    
    false
}

/// Approve decryption for anyone (public access)
/// Use this for non-sensitive data or after a certain time period
public fun seal_approve_public(_id: vector<u8>, _ctx: &TxContext): bool {
    true
}

// === Cleanup Functions ===

/// Remove old task entries (admin/governance function)
public(package) fun cleanup_task(registry: &mut AccessRegistry, task_id: vector<u8>) {
    if (table::contains(&registry.task_requesters, task_id)) {
        table::remove(&mut registry.task_requesters, task_id);
    };
    if (table::contains(&registry.task_submitters, task_id)) {
        table::remove(&mut registry.task_submitters, task_id);
    };
}

/// Check if a task has access control entries
public fun has_task_access_control(registry: &AccessRegistry, task_id: vector<u8>): bool {
    table::contains(&registry.task_requesters, task_id)
}

/// Get number of submitters for a task
public fun get_submitter_count(registry: &AccessRegistry, task_id: vector<u8>): u64 {
    if (!table::contains(&registry.task_submitters, task_id)) {
        return 0
    };
    let submitters = table::borrow(&registry.task_submitters, task_id);
    vec_set::length(submitters)
}

// === Test-only Functions ===

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}
