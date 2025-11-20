/// Module: songsim
/// Main orchestrator for decentralized data-labeling marketplace on Sui
/// This module coordinates all sub-modules and provides the public API
module songsim::songsim;

use std::string::String;
use sui::clock::{Self, Clock};
use sui::coin::{Self, Coin};
use sui::sui::SUI;
use songsim::constants;
use songsim::consensus;
use songsim::dispute::{Self, Dispute};
use songsim::events;
use songsim::prize_pool::{Self, PrizePool};
use songsim::profile::{Self, UserProfile};
use songsim::registry::{Self, TaskRegistry};
use songsim::reputation::{Self, Reputation};
use songsim::task::{Self, Task, Submission};
use songsim::consensus::{ConsensusResult, PayoutBatch};
use songsim::migration::{Self, MigrationState};

// === Platform Core Structs ===

/// Admin capability - non-transferable
public struct AdminCap has key {
    id: UID,
}

/// Platform configuration (shared object)
public struct PlatformConfig has key {
    id: UID,
    version: u64, // Schema version for migrations
    fee_bps: u64, // Platform fee in basis points (1 bps = 0.01%)
    fee_recipient: address, // Address receiving platform fees
    min_bounty: u64, // Minimum task bounty
    paused: bool, // Emergency pause flag
    total_tasks: u64, // Total tasks created
    total_profiles: u64, // Total profiles created
}

// === Init Function ===

/// Module initializer - creates AdminCap, PlatformConfig, and TaskRegistry
fun init(ctx: &mut TxContext) {
    // Create and transfer AdminCap to deployer
    let admin_cap = AdminCap {
        id: object::new(ctx),
    };
    transfer::transfer(admin_cap, ctx.sender());

    // Create and share PlatformConfig
    let config = PlatformConfig {
        id: object::new(ctx),
        version: migration::current_version(),
        fee_bps: constants::default_platform_fee_bps(),
        fee_recipient: ctx.sender(),
        min_bounty: constants::min_bounty(),
        paused: false,
        total_tasks: 0,
        total_profiles: 0,
    };
    transfer::share_object(config);

    // Create and share TaskRegistry
    registry::create_and_share(ctx);

    // Create and share MigrationState
    migration::create_and_share(ctx);
}

// === Admin Functions ===

/// Update platform fee (requires AdminCap)
public fun update_platform_fee(_: &AdminCap, config: &mut PlatformConfig, new_fee_bps: u64) {
    assert!(new_fee_bps <= constants::max_fee_bps(), constants::e_invalid_fee_percentage());
    config.fee_bps = new_fee_bps;

    events::emit_platform_config_updated(new_fee_bps, config.fee_recipient);
}

/// Update fee recipient (requires AdminCap)
public fun update_fee_recipient(_: &AdminCap, config: &mut PlatformConfig, new_recipient: address) {
    config.fee_recipient = new_recipient;

    events::emit_platform_config_updated(config.fee_bps, new_recipient);
}

/// Pause/unpause platform (requires AdminCap)
public fun set_platform_paused(_: &AdminCap, config: &mut PlatformConfig, paused: bool) {
    config.paused = paused;
}

/// Update minimum bounty (requires AdminCap)
public fun update_min_bounty(_: &AdminCap, config: &mut PlatformConfig, new_min_bounty: u64) {
    config.min_bounty = new_min_bounty;
}

/// Emergency withdrawal of platform fees (requires AdminCap)
entry fun emergency_withdraw(
    _: &AdminCap,
    amount: u64,
    recipient: address,
    mut payment: Coin<SUI>,
    ctx: &mut TxContext,
) {
    let withdraw_coin = coin::split(&mut payment, amount, ctx);
    transfer::public_transfer(withdraw_coin, recipient);

    // Return remaining coins to sender
    if (coin::value(&payment) > 0) {
        transfer::public_transfer(payment, ctx.sender());
    } else {
        coin::destroy_zero(payment);
    };
}

/// Resolve a dispute (requires AdminCap)
public fun admin_resolve_dispute(_: &AdminCap, dispute: &mut Dispute, resolution: String) {
    dispute::resolve(dispute, resolution);
}

/// Distribute prize pool (requires AdminCap)
public fun admin_distribute_prize_pool(
    _: &AdminCap,
    pool: &mut PrizePool,
    winners: vector<address>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    prize_pool::distribute(pool, winners, clock, ctx);
}

// === Migration Management (AdminCap required) ===

/// Begin platform migration - locks platform during upgrade
public fun begin_platform_migration(
    _: &AdminCap,
    migration_state: &mut MigrationState,
    clock: &Clock,
) {
    migration::begin_migration(migration_state, clock);
}

/// Complete platform migration - unlocks with new version
public fun complete_platform_migration(
    _: &AdminCap,
    migration_state: &mut MigrationState,
    new_version: u64,
) {
    migration::complete_migration(migration_state, new_version);
}

/// Rollback failed migration
public fun rollback_platform_migration(
    _: &AdminCap,
    migration_state: &mut MigrationState,
) {
    migration::rollback_migration(migration_state);
}

// === Profile Management ===

/// Create user profile
#[allow(lint(self_transfer))]
public fun create_profile(
    registry: &mut TaskRegistry,
    config: &mut PlatformConfig,
    display_name: String,
    bio: String,
    avatar_url: String,
    user_type: u8,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let sender = ctx.sender();
    assert!(!registry::has_profile(registry, sender), constants::e_profile_already_exists());

    let created_at = clock::timestamp_ms(clock);

    // Create profile
    let user_profile = profile::create(
        sender,
        display_name,
        bio,
        avatar_url,
        user_type,
        created_at,
        ctx,
    );
    let profile_addr = object::id_address(&user_profile);

    // Create initial reputation
    let user_reputation = reputation::create(sender, created_at, ctx);
    let rep_addr = object::id_address(&user_reputation);

    // Register in tables
    registry::register_profile(registry, sender, profile_addr);
    registry::register_reputation(registry, sender, rep_addr);
    config.total_profiles = config.total_profiles + 1;

    events::emit_profile_created(profile_addr, sender, user_type, created_at);

    // Transfer objects to owner
    transfer::public_transfer(user_profile, sender);
    transfer::public_transfer(user_reputation, sender);
}

// === Task Management ===

/// Create new labeling task
public fun create_task(
    registry: &mut TaskRegistry,
    config: &mut PlatformConfig,
    user_profile: &mut UserProfile,
    dataset_url: String,
    dataset_filename: String,
    dataset_content_type: String,
    title: String,
    description: String,
    instructions: String,
    required_labelers: u64,
    deadline: u64,
    bounty: Coin<SUI>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert!(!config.paused, constants::e_platform_paused());
    assert!(profile::get_owner(user_profile) == ctx.sender(), constants::e_unauthorized());

    let bounty_amount = coin::value(&bounty);
    
    // Validate task parameters
    task::validate_task_creation(
        &dataset_url,
        required_labelers,
        deadline,
        bounty_amount,
        config.min_bounty,
        clock,
    );

    // Pre-allocate task ID to avoid race condition
    let task_id = registry::get_next_task_id(registry);
    
    // Register task and get ID
    let created_at = clock::timestamp_ms(clock);
    let new_task = task::create(
        task_id, // Use pre-allocated ID
        ctx.sender(),
        dataset_url,
        dataset_filename,
        dataset_content_type,
        title,
        description,
        instructions,
        required_labelers,
        deadline,
        bounty,
        created_at,
        ctx,
    );
    
    let task_addr = object::id_address(&new_task);
    registry::confirm_task_registration(registry, task_id, task_addr);
    
    // Update profile stats
    profile::increment_tasks_created(user_profile);
    config.total_tasks = config.total_tasks + 1;

    events::emit_task_created(task_id, ctx.sender(), bounty_amount, deadline);

    // Make task a shared object so labelers can submit to it
    transfer::public_share_object(new_task);
}

/// Submit labels for a task
#[allow(lint(self_transfer))]
public fun submit_labels(
    registry: &mut TaskRegistry,
    labeling_task: &mut Task,
    user_profile: &mut UserProfile,
    result_url: String,
    result_filename: String,
    result_content_type: String,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert!(profile::get_owner(user_profile) == ctx.sender(), constants::e_unauthorized());
    
    // Validate submission
    let (_, _, _, _, status, _, _, _, deadline, _, _) = task::get_task_details(labeling_task);
    task::validate_submission(&result_url, status, deadline, clock);

    let submitted_at = clock::timestamp_ms(clock);
    
    // Create submission
    let new_submission = task::create_submission(
        0, // Temporary, will be set by registry
        task::get_task_id(labeling_task),
        ctx.sender(),
        result_url,
        result_filename,
        result_content_type,
        submitted_at,
        ctx,
    );
    
    let submission_addr = object::id_address(&new_submission);
    let submission_id = registry::register_submission(registry, submission_addr);

    // Update task and profile (checks for duplicates internally)
    task::add_submission(labeling_task, submission_id, ctx.sender());
    profile::increment_submissions_count(user_profile);

    events::emit_submission_received(submission_id, task::get_task_id(labeling_task), ctx.sender(), submitted_at);

    // Transfer submission to labeler
    transfer::public_transfer(new_submission, ctx.sender());
}

/// Cancel task and refund bounty (only if no submissions)
entry fun cancel_task(labeling_task: &mut Task, clock: &Clock, ctx: &mut TxContext) {
    let refund_coin = task::cancel_task(labeling_task, clock, ctx);
    transfer::public_transfer(refund_coin, ctx.sender());
}

// === Consensus & Payout ===

/// Execute consensus with AUTOMATED bounty distribution (ESCROW PROTECTION)
#[allow(lint(self_transfer))]
public fun finalize_consensus(
    config: &PlatformConfig,
    labeling_task: &mut Task,
    accepted_submission_ids: vector<u64>,
    accepted_labelers: vector<address>,
    rejected_submission_ids: vector<u64>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let consensus_result = consensus::finalize_consensus(
        labeling_task,
        accepted_submission_ids,
        accepted_labelers,
        rejected_submission_ids,
        config.fee_bps,
        config.fee_recipient,
        clock,
        ctx,
    );

    // Transfer consensus result to requester
    transfer::public_transfer(consensus_result, ctx.sender());
}

/// Finalize task with partial submissions (deadline passed, reward partial work)
#[allow(lint(self_transfer))]
public fun finalize_partial_task(
    config: &PlatformConfig,
    labeling_task: &mut Task,
    accepted_submission_ids: vector<u64>,
    accepted_labelers: vector<address>,
    rejected_submission_ids: vector<u64>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let consensus_result = consensus::finalize_partial_task(
        labeling_task,
        accepted_submission_ids,
        accepted_labelers,
        rejected_submission_ids,
        config.fee_bps,
        config.fee_recipient,
        clock,
        ctx,
    );

    transfer::public_transfer(consensus_result, ctx.sender());
}

/// Update submission status after consensus
public fun update_submission_status(
    submission: &mut Submission,
    labeling_task: &Task,
    is_accepted: bool,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    task::update_submission_status(
        submission,
        labeling_task,
        is_accepted,
        clock::timestamp_ms(clock),
        ctx.sender(),
    );
}

// === Batch Processing for Large Tasks ===

/// Create payout batch for tasks with >50 labelers
#[allow(lint(self_transfer))]
public fun create_payout_batch(
    config: &PlatformConfig,
    labeling_task: &mut Task,
    accepted_labelers: vector<address>,
    ctx: &mut TxContext,
): PayoutBatch {
    consensus::create_payout_batch(labeling_task, accepted_labelers, config.fee_bps, ctx)
}

/// Process a batch of payouts
public fun process_payout_batch(
    config: &PlatformConfig,
    batch: &mut PayoutBatch,
    labeling_task: &mut Task,
    count: u64,
    ctx: &mut TxContext,
) {
    consensus::process_payout_batch(batch, labeling_task, count, config.fee_recipient, ctx);
}

// === Reputation Management ===

/// Update reputation after submission review
public fun update_reputation(user_reputation: &mut Reputation, accepted: bool, ctx: &TxContext) {
    reputation::update_simple(user_reputation, accepted, ctx);
}

/// Update reputation with weighted scoring
public fun update_reputation_weighted(
    user_reputation: &mut Reputation,
    accepted: bool,
    task_difficulty: u64,
    clock: &Clock,
) {
    reputation::update_weighted(user_reputation, accepted, task_difficulty, clock::timestamp_ms(clock));
}

/// Apply reputation decay based on inactivity
public fun apply_reputation_decay(user_reputation: &mut Reputation, clock: &Clock) {
    reputation::apply_decay(user_reputation, clock::timestamp_ms(clock));
}

// === Dispute Resolution ===

/// Create a dispute for a submission
public fun create_dispute(
    registry: &mut TaskRegistry,
    task_id: u64,
    submission_id: u64,
    reason: String,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let new_dispute = dispute::create(
        0, // Temporary, will be set by registry
        task_id,
        submission_id,
        ctx.sender(),
        reason,
        clock,
        ctx,
    );

    let dispute_addr = object::id_address(&new_dispute);
    let _dispute_id = registry::register_dispute(registry, dispute_addr);

    transfer::public_share_object(new_dispute);
}

/// Vote on a dispute
public fun vote_on_dispute(user_dispute: &mut Dispute, vote_for: bool, ctx: &TxContext) {
    dispute::vote(user_dispute, vote_for, ctx);
}

// === Prize Pool Functions ===

/// Create a new prize pool
public fun create_prize_pool(
    registry: &mut TaskRegistry,
    name: String,
    description: String,
    funds: Coin<SUI>,
    start_time: u64,
    end_time: u64,
    min_submissions: u64,
    winners_count: u64,
    ctx: &mut TxContext,
) {
    let new_pool = prize_pool::create(
        0, // Temporary, will be set by registry
        name,
        description,
        funds,
        start_time,
        end_time,
        min_submissions,
        winners_count,
        ctx,
    );

    let pool_addr = object::id_address(&new_pool);
    let _pool_id = registry::register_prize_pool(registry, pool_addr);

    transfer::public_share_object(new_pool);
}

/// Join a prize pool
public fun join_prize_pool(pool: &mut PrizePool, clock: &Clock, ctx: &TxContext) {
    prize_pool::join(pool, clock, ctx);
}

// === View Functions (delegate to sub-modules) ===

// Profile
public fun get_profile_stats(user_profile: &UserProfile): (u64, u64) {
    profile::get_stats(user_profile)
}

// Reputation
public fun get_reputation_score(user_reputation: &Reputation): u64 {
    reputation::get_score(user_reputation)
}

public fun get_reputation_details(user_reputation: &Reputation): (address, u64, u64, u64, u64, u64, vector<u8>) {
    reputation::get_details(user_reputation)
}

// Task
public fun get_task_info(labeling_task: &Task): (u64, address, u64, u8, u64, u64) {
    task::get_task_info(labeling_task)
}

public fun get_task_details(labeling_task: &Task): (u64, address, u64, u64, u8, u64, u64, u64, u64, u64, u64) {
    task::get_task_details(labeling_task)
}

public fun get_task_submission_ids(labeling_task: &Task): vector<u64> {
    task::get_submission_ids(labeling_task)
}

public fun get_task_bounty_remaining(labeling_task: &Task): u64 {
    task::get_bounty_remaining(labeling_task)
}

// Submission
public fun get_submission_info(submission: &Submission): (u64, u64, address, u8) {
    task::get_submission_info(submission)
}

public fun get_submission_details(submission: &Submission): (u64, u64, address, u8, u64, u64) {
    task::get_submission_details(submission)
}

// Registry
public fun task_exists(registry: &TaskRegistry, task_id: u64): bool {
    registry::task_exists(registry, task_id)
}

public fun get_task_address(registry: &TaskRegistry, task_id: u64): address {
    registry::get_task_address(registry, task_id)
}

public fun get_submission_address(registry: &TaskRegistry, submission_id: u64): address {
    registry::get_submission_address(registry, submission_id)
}

public fun get_profile_address(registry: &TaskRegistry, user: address): address {
    registry::get_profile_address(registry, user)
}

public fun get_reputation_address(registry: &TaskRegistry, user: address): address {
    registry::get_reputation_address(registry, user)
}

public fun get_active_task_ids(registry: &TaskRegistry, start_index: u64, limit: u64): vector<u64> {
    registry::get_active_task_ids(registry, start_index, limit)
}

public fun get_all_task_ids(registry: &TaskRegistry, start_id: u64, limit: u64): vector<u64> {
    registry::get_all_task_ids(registry, start_id, limit)
}

// === Test-only Functions ===

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}
