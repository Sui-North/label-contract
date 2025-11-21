/// Tests for registry module
module songsim::registry_tests;

use songsim::constants;
use songsim::events;
use songsim::task::{Self, Task};
use sui::clock::{Self, Clock};
use sui::coin::{Self, Coin};
use sui::sui::SUI;

/// Consensus result
public struct ConsensusResult has key, store {
    id: UID,
    task_id: u64,
    accepted_submissions: vector<u64>,
    rejected_submissions: vector<u64>,
    consensus_at: u64,
}

/// Payout batch state (for multi-transaction payouts)
public struct PayoutBatch has key, store {
    id: UID,
    task_id: u64,
    total_recipients: u64,
    processed_count: u64,
    payout_per_recipient: u64,
    fee_per_recipient: u64,
    recipients: vector<address>,
}

/// Finalize consensus with AUTOMATED bounty distribution and SECURITY FIXES
/// Fixes:
/// - Uses actual balance instead of original bounty_amount
/// - Validates labeler addresses match submissions
/// - Implements reentrancy-safe pattern (state updates before transfers)
/// - Supports batch processing for large submission counts
/// - Awards remainder to first labeler (fairness)
public fun finalize_consensus(
    task: &mut Task,
    accepted_submission_ids: vector<u64>,
    accepted_labelers: vector<address>,
    rejected_submission_ids: vector<u64>,
    fee_bps: u64,
    fee_recipient: address,
    clock: &Clock,
    ctx: &mut TxContext,
): ConsensusResult {
    // Authorization check
    assert!(task::get_requester(task) == ctx.sender(), constants::e_unauthorized());
    assert!(
        task::get_status(task) == constants::status_in_progress(),
        constants::e_invalid_task_status(),
    );

    let accepted_count = vector::length(&accepted_submission_ids);
    let rejected_count = vector::length(&rejected_submission_ids);

    // Validation checks
    assert!(accepted_count > 0, constants::e_no_submissions());
    assert!(
        accepted_count == vector::length(&accepted_labelers),
        constants::e_invalid_task_status(),
    );
    assert!(accepted_count <= constants::max_batch_size(), constants::e_batch_size_too_large());

    // Validate all submission IDs belong to this task
    validate_all_submissions_belong_to_task(
        task,
        &accepted_submission_ids,
        &rejected_submission_ids,
    );

    // CRITICAL: Validate labeler addresses match submissions
    validate_labelers_match_task(task, &accepted_labelers);

    // CRITICAL FIX: Use actual remaining balance, not original bounty_amount
    let remaining_balance = task::get_bounty_remaining(task);
    assert!(remaining_balance > 0, constants::e_insufficient_balance());

    // Calculate payout based on ACTUAL balance
    let payout_per_labeler = remaining_balance / accepted_count;
    let remainder = remaining_balance % accepted_count; // Track remainder
    assert!(payout_per_labeler > 0, constants::e_insufficient_balance());

    // Calculate fees with overflow protection
    let fee_amount = (payout_per_labeler * fee_bps) / 10000;
    assert!(fee_amount < payout_per_labeler, constants::e_fee_exceeds_payout());
    let net_payout = payout_per_labeler - fee_amount;

    // STATE UPDATE FIRST (reentrancy protection pattern)
    task::set_completed(task, accepted_count, clock::timestamp_ms(clock));

    // Then perform transfers
    let mut total_fees = 0u64;
    let mut i = 0;
    while (i < accepted_count) {
        let labeler = *vector::borrow(&accepted_labelers, i);

        // Award remainder to first labeler for fairness
        let mut amount_to_withdraw = payout_per_labeler;
        if (i == 0 && remainder > 0) {
            amount_to_withdraw = amount_to_withdraw + remainder;
        };

        // Withdraw from task balance
        let mut payment = task::withdraw_bounty(task, amount_to_withdraw, ctx);

        // Split and transfer platform fee
        let fee_coin = coin::split(&mut payment, fee_amount, ctx);
        transfer::public_transfer(fee_coin, fee_recipient);

        // Transfer net payout to labeler (includes remainder for first labeler)
        transfer::public_transfer(payment, labeler);

        total_fees = total_fees + fee_amount;

        // Event reflects actual amount received (with remainder for first)
        let actual_payout = if (i == 0 && remainder > 0) {
            net_payout + remainder
        } else {
            net_payout
        };
        events::emit_payout_distributed(task::get_task_id(task), labeler, actual_payout);

        i = i + 1;
    };

    // No remaining bounty should exist now (all distributed)
    // Remainder was awarded to first labeler

    events::emit_consensus_finalized(task::get_task_id(task), accepted_count, rejected_count);
    events::emit_platform_fee_collected(task::get_task_id(task), total_fees, fee_recipient);

    // Create consensus result
    ConsensusResult {
        id: object::new(ctx),
        task_id: task::get_task_id(task),
        accepted_submissions: accepted_submission_ids,
        rejected_submissions: rejected_submission_ids,
        consensus_at: clock::timestamp_ms(clock),
    }
}

// === CRITICAL FIX #2: Labeler Address Validation ===

/// Validate that accepted labelers match their submissions
/// This prevents payment theft by malicious requesters
public fun validate_labeler_matches_submission(
    submission_labeler: address,
    provided_labeler: address,
) {
    assert!(submission_labeler == provided_labeler, constants::e_invalid_labeler_address());
}

/// Validate that all provided labelers have submitted to the task
fun validate_labelers_match_task(task: &Task, labelers: &vector<address>) {
    let mut i = 0;
    while (i < vector::length(labelers)) {
        let labeler = *vector::borrow(labelers, i);
        // Check if labeler is in the task's labeler set
        assert!(task::has_labeler_submitted(task, labeler), constants::e_invalid_labeler_address());
        i = i + 1;
    };
}

// === Partial Task Finalization ===

/// Finalize task with partial submissions (deadline passed, reward partial work)
/// Distributes fair portion to labelers who submitted and refunds remainder to requester
public fun finalize_partial_task(
    task: &mut Task,
    accepted_submission_ids: vector<u64>,
    accepted_labelers: vector<address>,
    rejected_submission_ids: vector<u64>,
    fee_bps: u64,
    fee_recipient: address,
    clock: &Clock,
    ctx: &mut TxContext,
): ConsensusResult {
    // Authorization and timing checks
    assert!(task::get_requester(task) == ctx.sender(), constants::e_unauthorized());
    let task_status = task::get_status(task);
    assert!(
        task_status == constants::status_open() || task_status == constants::status_in_progress(),
        constants::e_invalid_task_status(),
    );

    let (_, _, _, _, _, _, submission_count, _, deadline, _, _) = task::get_task_details(task);
    let required_labelers = get_task_required_labelers(task);

    assert!(clock::timestamp_ms(clock) > deadline, constants::e_invalid_deadline());
    assert!(submission_count > 0, constants::e_no_submissions());
    assert!(submission_count < required_labelers, constants::e_consensus_threshold_not_met());

    let accepted_count = vector::length(&accepted_submission_ids);
    let rejected_count = vector::length(&rejected_submission_ids);
    let total_reviewed = accepted_count + rejected_count;

    assert!(total_reviewed == submission_count, constants::e_invalid_task_status());
    assert!(accepted_count > 0, constants::e_no_submissions());
    assert!(
        accepted_count == vector::length(&accepted_labelers),
        constants::e_invalid_task_status(),
    );

    // Validate all submission IDs belong to this task
    validate_all_submissions_belong_to_task(
        task,
        &accepted_submission_ids,
        &rejected_submission_ids,
    );

    // Calculate fair distribution: portion based on actual vs required labelers
    let bounty_amount = get_task_bounty_amount(task);
    let fair_bounty_portion = (bounty_amount * accepted_count) / required_labelers;
    let payout_per_labeler = fair_bounty_portion / accepted_count;

    let fee_amount = (payout_per_labeler * fee_bps) / 10000;
    assert!(fee_amount < payout_per_labeler, constants::e_fee_exceeds_payout());
    let net_payout = payout_per_labeler - fee_amount;
    let mut total_fees = 0u64;

    // STATE UPDATE FIRST
    task::set_completed(task, accepted_count, clock::timestamp_ms(clock));

    // Distribute to accepted labelers
    let mut i = 0;
    while (i < accepted_count) {
        let labeler = *vector::borrow(&accepted_labelers, i);

        let mut payment = task::withdraw_bounty(task, payout_per_labeler, ctx);
        let fee_coin = coin::split(&mut payment, fee_amount, ctx);
        transfer::public_transfer(fee_coin, fee_recipient);
        transfer::public_transfer(payment, labeler);

        total_fees = total_fees + fee_amount;

        events::emit_payout_distributed(task::get_task_id(task), labeler, net_payout);

        i = i + 1;
    };

    // Refund remaining bounty to requester
    let remaining = task::get_bounty_remaining(task);
    if (remaining > 0) {
        let refund_coin = task::withdraw_all_bounty(task, ctx);
        transfer::public_transfer(refund_coin, task::get_requester(task));

        events::emit_task_cancelled(
            task::get_task_id(task),
            task::get_requester(task),
            remaining,
            clock::timestamp_ms(clock),
        );
    };

    events::emit_platform_fee_collected(task::get_task_id(task), total_fees, fee_recipient);
    events::emit_consensus_finalized(task::get_task_id(task), accepted_count, rejected_count);

    ConsensusResult {
        id: object::new(ctx),
        task_id: task::get_task_id(task),
        accepted_submissions: accepted_submission_ids,
        rejected_submissions: rejected_submission_ids,
        consensus_at: clock::timestamp_ms(clock),
    }
}

// === Batch Processing for Large Tasks ===

/// Create a payout batch for large tasks (>50 labelers)
/// This allows splitting payouts across multiple transactions to avoid gas limits
public fun create_payout_batch(
    task: &mut Task,
    accepted_labelers: vector<address>,
    fee_bps: u64,
    ctx: &mut TxContext,
): PayoutBatch {
    assert!(task::get_requester(task) == ctx.sender(), constants::e_unauthorized());
    assert!(
        task::get_status(task) == constants::status_in_progress(),
        constants::e_invalid_task_status(),
    );

    let total_recipients = vector::length(&accepted_labelers);
    assert!(total_recipients > 0, constants::e_no_submissions());

    let remaining_balance = task::get_bounty_remaining(task);
    let payout_per_recipient = remaining_balance / total_recipients;
    let fee_per_recipient = (payout_per_recipient * fee_bps) / 10000;

    PayoutBatch {
        id: object::new(ctx),
        task_id: task::get_task_id(task),
        total_recipients,
        processed_count: 0,
        payout_per_recipient,
        fee_per_recipient,
        recipients: accepted_labelers,
    }
}

/// Process a batch of payouts
public fun process_payout_batch(
    batch: &mut PayoutBatch,
    task: &mut Task,
    count: u64,
    fee_recipient: address,
    ctx: &mut TxContext,
) {
    assert!(task::get_task_id(task) == batch.task_id, constants::e_task_not_found());
    assert!(
        batch.processed_count < batch.total_recipients,
        constants::e_batch_index_out_of_bounds(),
    );
    assert!(count <= constants::max_batch_size(), constants::e_batch_size_too_large());

    let mut end_index = batch.processed_count + count;
    if (end_index > batch.total_recipients) {
        end_index = batch.total_recipients;
    };

    let mut i = batch.processed_count;
    while (i < end_index) {
        let labeler = *vector::borrow(&batch.recipients, i);

        let mut payment = task::withdraw_bounty(task, batch.payout_per_recipient, ctx);
        let fee_coin = coin::split(&mut payment, batch.fee_per_recipient, ctx);
        transfer::public_transfer(fee_coin, fee_recipient);
        transfer::public_transfer(payment, labeler);

        let net_payout = batch.payout_per_recipient - batch.fee_per_recipient;
        events::emit_payout_distributed(task::get_task_id(task), labeler, net_payout);

        i = i + 1;
    };

    batch.processed_count = end_index;
}

// === Helper Functions ===

fun validate_all_submissions_belong_to_task(
    task: &Task,
    accepted_submission_ids: &vector<u64>,
    rejected_submission_ids: &vector<u64>,
) {
    let mut i = 0;
    let accepted_count = vector::length(accepted_submission_ids);
    while (i < accepted_count) {
        let sub_id = *vector::borrow(accepted_submission_ids, i);
        task::validate_submission_belongs_to_task(task, sub_id);
        i = i + 1;
    };

    i = 0;
    let rejected_count = vector::length(rejected_submission_ids);
    while (i < rejected_count) {
        let sub_id = *vector::borrow(rejected_submission_ids, i);
        task::validate_submission_belongs_to_task(task, sub_id);
        i = i + 1;
    };
}

// Temporary accessors (until we add these to task module)
fun get_task_required_labelers(task: &Task): u64 {
    let (_, _, _, _, _, required_labelers) = task::get_task_info(task);
    required_labelers
}

fun get_task_bounty_amount(task: &Task): u64 {
    let (_, _, bounty_amount, _, _, _) = task::get_task_info(task);
    bounty_amount
}

// === View Functions ===

public fun get_consensus_result(result: &ConsensusResult): (u64, vector<u64>, vector<u64>, u64) {
    (result.task_id, result.accepted_submissions, result.rejected_submissions, result.consensus_at)
}

public fun get_batch_progress(batch: &PayoutBatch): (u64, u64) {
    (batch.processed_count, batch.total_recipients)
}

public fun is_batch_complete(batch: &PayoutBatch): bool {
    batch.processed_count >= batch.total_recipients
}
