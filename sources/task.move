/// Module: task
/// Task and submission management for Songsim platform
module songsim::task;

use std::string::{Self, String};
use sui::balance::{Self, Balance};
use sui::clock::{Self, Clock};
use sui::coin::{Self, Coin};
use sui::sui::SUI;
use sui::vec_set::{Self, VecSet};
use songsim::constants;
use songsim::events;

/// Task NFT
public struct Task has key, store {
    id: UID,
    task_id: u64,
    requester: address,
    dataset_url: String,
    dataset_filename: String, // Original filename for proper downloads
    dataset_content_type: String, // MIME type (e.g., "text/csv", "application/json")
    title: String,
    description: String,
    instructions: String,
    bounty: Balance<SUI>, // Store balance directly for safe management
    bounty_amount: u64, // Keep for reference/display
    status: u8,
    required_labelers: u64,
    submission_count: u64,
    accepted_count: u64, // Track accepted submissions
    deadline: u64,
    created_at: u64,
    completed_at: u64,
    submission_ids: vector<u64>, // Track all submission IDs for validation
    labeler_addresses: VecSet<address>, // Track unique labelers to prevent duplicates
}

/// Submission record (SHARED OBJECT)
public struct Submission has key, store {
    id: UID,
    submission_id: u64,
    task_id: u64,
    labeler: address,
    result_url: String,
    result_filename: String, // Original filename for proper downloads
    result_content_type: String, // MIME type
    submitted_at: u64,
    status: u8, // 0=pending, 1=accepted, 2=rejected
    reviewed_at: u64, // Timestamp when reviewed
}

// === Task Management Functions ===

/// Create new labeling task
public(package) fun create(
    task_id: u64,
    requester: address,
    dataset_url: String,
    dataset_filename: String,
    dataset_content_type: String,
    title: String,
    description: String,
    instructions: String,
    required_labelers: u64,
    deadline: u64,
    bounty: Coin<SUI>,
    created_at: u64,
    ctx: &mut TxContext,
): Task {
    let bounty_amount = coin::value(&bounty);
    let bounty_balance = coin::into_balance(bounty);

    Task {
        id: object::new(ctx),
        task_id,
        requester,
        dataset_url,
        dataset_filename,
        dataset_content_type,
        title,
        description,
        instructions,
        bounty: bounty_balance,
        bounty_amount,
        status: constants::status_open(),
        required_labelers,
        submission_count: 0,
        accepted_count: 0,
        deadline,
        created_at,
        completed_at: 0,
        submission_ids: vector::empty(),
        labeler_addresses: vec_set::empty(),
    }
}

/// Validate task creation parameters
public fun validate_task_creation(
    dataset_url: &String,
    required_labelers: u64,
    deadline: u64,
    bounty_amount: u64,
    min_bounty: u64,
    clock: &Clock,
) {
    assert!(string::length(dataset_url) > 0, constants::e_invalid_blob_id());
    assert!(required_labelers > 0, constants::e_invalid_task_status());
    assert!(bounty_amount >= min_bounty, constants::e_insufficient_bounty());
    assert!(bounty_amount <= constants::max_bounty(), constants::e_insufficient_bounty());
    assert!(deadline > clock::timestamp_ms(clock), constants::e_invalid_deadline());
}

/// Cancel task and refund bounty (only if no submissions)
public fun cancel_task(task: &mut Task, clock: &Clock, ctx: &mut TxContext): Coin<SUI> {
    assert!(task.requester == ctx.sender(), constants::e_unauthorized());
    assert!(task.status == constants::status_open(), constants::e_invalid_task_status());
    assert!(task.submission_count == 0, constants::e_invalid_task_status());

    // Extract bounty from task
    let bounty_value = balance::value(&task.bounty);
    let refund_balance = balance::withdraw_all(&mut task.bounty);
    let refund_coin = coin::from_balance(refund_balance, ctx);

    // Update task status
    task.status = constants::status_cancelled();
    task.completed_at = clock::timestamp_ms(clock);

    events::emit_task_cancelled(
        task.task_id,
        task.requester,
        bounty_value,
        clock::timestamp_ms(clock),
    );

    refund_coin
}

/// Extend task deadline (only by requester, for open/in-progress tasks)
public fun extend_deadline(task: &mut Task, new_deadline: u64, clock: &Clock, ctx: &TxContext) {
    // Only requester can extend deadline
    assert!(task.requester == ctx.sender(), constants::e_unauthorized());
    
    // Can only extend for open or in-progress tasks
    assert!(
        task.status == constants::status_open() || task.status == constants::status_in_progress(),
        constants::e_invalid_task_status()
    );
    
    // New deadline must be in the future
    assert!(new_deadline > clock::timestamp_ms(clock), constants::e_invalid_deadline());
    
    // New deadline must be greater than current deadline (can't shorten)
    assert!(new_deadline > task.deadline, constants::e_invalid_deadline());
    
    let old_deadline = task.deadline;
    task.deadline = new_deadline;
    
    events::emit_task_deadline_extended(
        task.task_id,
        task.requester,
        old_deadline,
        new_deadline,
        clock::timestamp_ms(clock),
    );
}

/// Update task status to in-progress
public(package) fun set_in_progress(task: &mut Task) {
    task.status = constants::status_in_progress();
}

/// Update task status to completed
public(package) fun set_completed(task: &mut Task, accepted_count: u64, completed_at: u64) {
    task.status = constants::status_completed();
    task.accepted_count = accepted_count;
    task.completed_at = completed_at;
}

/// Add submission ID to task
public(package) fun add_submission(task: &mut Task, submission_id: u64, labeler: address) {
    // Check for duplicate submission
    assert!(
        !vec_set::contains(&task.labeler_addresses, &labeler),
        constants::e_duplicate_submission()
    );
    
    // Add labeler to set
    vec_set::insert(&mut task.labeler_addresses, labeler);
    
    vector::push_back(&mut task.submission_ids, submission_id);
    task.submission_count = task.submission_count + 1;
    
    // Auto-transition to in-progress when enough submissions
    if (task.submission_count >= task.required_labelers && task.status == constants::status_open()) {
        task.status = constants::status_in_progress();
    };
}

/// Withdraw bounty (for consensus payouts)
public(package) fun withdraw_bounty(task: &mut Task, amount: u64, ctx: &mut TxContext): Coin<SUI> {
    let balance_available = balance::value(&task.bounty);
    assert!(amount <= balance_available, constants::e_insufficient_balance());
    
    let withdrawn = balance::split(&mut task.bounty, amount);
    coin::from_balance(withdrawn, ctx)
}

/// Withdraw all remaining bounty
public(package) fun withdraw_all_bounty(task: &mut Task, ctx: &mut TxContext): Coin<SUI> {
    let balance_available = balance::value(&task.bounty);
    if (balance_available == 0) {
        coin::zero(ctx)
    } else {
        let withdrawn = balance::withdraw_all(&mut task.bounty);
        coin::from_balance(withdrawn, ctx)
    }
}

// === Submission Management Functions ===

/// Create submission
public(package) fun create_submission(
    submission_id: u64,
    task_id: u64,
    labeler: address,
    result_url: String,
    result_filename: String,
    result_content_type: String,
    submitted_at: u64,
    ctx: &mut TxContext,
): Submission {
    Submission {
        id: object::new(ctx),
        submission_id,
        task_id,
        labeler,
        result_url,
        result_filename,
        result_content_type,
        submitted_at,
        status: constants::submission_status_pending(),
        reviewed_at: 0,
    }
}

/// Validate submission parameters
public fun validate_submission(
    result_url: &String,
    task_status: u8,
    task_deadline: u64,
    clock: &Clock,
) {
    assert!(string::length(result_url) > 0, constants::e_invalid_blob_id());
    assert!(task_status == constants::status_open(), constants::e_task_not_open());
    
    // Apply 24-hour review buffer before deadline (prevent underflow for short deadlines)
    let buffer = constants::review_buffer_ms();
    assert!(task_deadline > buffer, constants::e_invalid_deadline());
    
    let submission_deadline = task_deadline - buffer;
    assert!(
        clock::timestamp_ms(clock) < submission_deadline,
        constants::e_submission_deadline_passed()
    );
}

/// Update submission status after consensus
public fun update_submission_status(
    submission: &mut Submission,
    task: &Task,
    is_accepted: bool,
    reviewed_at: u64,
    requester: address,
) {
    assert!(task.requester == requester, constants::e_unauthorized());
    assert!(submission.task_id == task.task_id, constants::e_task_not_found());
    assert!(task.status == constants::status_completed(), constants::e_task_not_completed());

    submission.status = if (is_accepted) {
        constants::submission_status_accepted()
    } else {
        constants::submission_status_rejected()
    };
    submission.reviewed_at = reviewed_at;

    if (!is_accepted) {
        events::emit_submission_rejected(
            submission.submission_id,
            submission.task_id,
            submission.labeler,
            reviewed_at,
        );
    };
}

/// Update submission status from consensus (no authorization check - package internal)
public(package) fun update_submission_status_internal(
    submission: &mut Submission,
    task: &Task,
    is_accepted: bool,
    reviewed_at: u64,
) {
    assert!(submission.task_id == task.task_id, constants::e_task_not_found());
    assert!(task.status == constants::status_completed(), constants::e_task_not_completed());

    submission.status = if (is_accepted) {
        constants::submission_status_accepted()
    } else {
        constants::submission_status_rejected()
    };
    submission.reviewed_at = reviewed_at;

    events::emit_submission_status_changed(
        submission.submission_id,
        submission.task_id,
        submission.labeler,
        constants::submission_status_pending(),
        submission.status,
        reviewed_at,
    );

    if (!is_accepted) {
        events::emit_submission_rejected(
            submission.submission_id,
            submission.task_id,
            submission.labeler,
            reviewed_at,
        );
    };
}

// === View Functions ===

public fun get_task_id(task: &Task): u64 {
    task.task_id
}

public fun get_created_at(task: &Task): u64 {
    task.created_at
}

public fun get_requester(task: &Task): address {
    task.requester
}

public fun get_status(task: &Task): u8 {
    task.status
}

public fun get_bounty_remaining(task: &Task): u64 {
    balance::value(&task.bounty)
}

public fun get_submission_ids(task: &Task): vector<u64> {
    task.submission_ids
}

public fun get_task_info(task: &Task): (u64, address, u64, u8, u64, u64) {
    (
        task.task_id,
        task.requester,
        task.bounty_amount,
        task.status,
        task.submission_count,
        task.deadline,
    )
}

public fun get_task_details(task: &Task): (
    u64, // task_id
    address, // requester
    u64, // bounty_amount
    u64, // bounty_remaining
    u8, // status
    u64, // required_labelers
    u64, // submission_count
    u64, // accepted_count
    u64, // deadline
    u64, // created_at
    u64, // completed_at
) {
    (
        task.task_id,
        task.requester,
        task.bounty_amount,
        balance::value(&task.bounty),
        task.status,
        task.required_labelers,
        task.submission_count,
        task.accepted_count,
        task.deadline,
        task.created_at,
        task.completed_at,
    )
}

public fun get_submission_info(submission: &Submission): (u64, u64, address, u8) {
    (submission.submission_id, submission.task_id, submission.labeler, submission.status)
}

public fun get_submission_details(submission: &Submission): (
    u64, // submission_id
    u64, // task_id
    address, // labeler
    u8, // status
    u64, // submitted_at
    u64, // reviewed_at
) {
    (
        submission.submission_id,
        submission.task_id,
        submission.labeler,
        submission.status,
        submission.submitted_at,
        submission.reviewed_at,
    )
}

public fun get_submission_labeler(submission: &Submission): address {
    submission.labeler
}

public fun get_submission_id(submission: &Submission): u64 {
    submission.submission_id
}

public fun get_submission_task_id(submission: &Submission): u64 {
    submission.task_id
}

public fun get_submission_result_url(submission: &Submission): String {
    submission.result_url
}

/// Validate that submission belongs to task
public fun validate_submission_belongs_to_task(task: &Task, submission_id: u64) {
    assert!(vector::contains(&task.submission_ids, &submission_id), constants::e_task_not_found());
}

/// Check if a labeler has already submitted to this task
public fun has_labeler_submitted(task: &Task, labeler: address): bool {
    vec_set::contains(&task.labeler_addresses, &labeler)
}

/// Validate labeler eligibility based on reputation and task value
public fun validate_labeler_eligibility(
    bounty_amount: u64,
    reputation_score: u64,
) {
    // High-value tasks require minimum reputation
    if (bounty_amount >= constants::high_value_threshold()) {
        assert!(
            reputation_score >= constants::min_reputation_high_value(),
            constants::e_insufficient_reputation()
        );
    };
}
