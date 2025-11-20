/// Module: registry
/// Global registry for object lookups and ID management
module songsim::registry;

use sui::table::{Self, Table};
use sui::vec_map::{Self, VecMap};
use songsim::constants;

/// Global registry for lookups (shared object)
public struct TaskRegistry has key {
    id: UID,
    tasks: Table<u64, address>, // task_id -> Task object address
    submissions: Table<u64, address>, // submission_id -> Submission object address
    profiles: Table<address, address>, // user address -> UserProfile object address
    reputations: Table<address, address>, // user address -> Reputation object address
    disputes: Table<u64, address>, // dispute_id -> Dispute object address
    prize_pools: Table<u64, address>, // pool_id -> PrizePool object address
    
    // Optimized lookup: active task IDs for efficient iteration
    active_task_ids: VecMap<u64, bool>, // task_id -> is_active
    
    // ID counters
    next_task_id: u64,
    next_submission_id: u64,
    next_dispute_id: u64,
    next_pool_id: u64,
}

// === Registry Creation ===

public fun create(ctx: &mut TxContext): TaskRegistry {
    TaskRegistry {
        id: object::new(ctx),
        tasks: table::new(ctx),
        submissions: table::new(ctx),
        profiles: table::new(ctx),
        reputations: table::new(ctx),
        disputes: table::new(ctx),
        prize_pools: table::new(ctx),
        active_task_ids: vec_map::empty(),
        next_task_id: 1,
        next_submission_id: 1,
        next_dispute_id: 1,
        next_pool_id: 1,
    }
}

/// Create and share registry (called from main init)
public fun create_and_share(ctx: &mut TxContext) {
    let registry = create(ctx);
    transfer::share_object(registry);
}

// === Task Registration ===

public(package) fun register_task(registry: &mut TaskRegistry, task_addr: address): u64 {
    let task_id = registry.next_task_id;
    table::add(&mut registry.tasks, task_id, task_addr);
    vec_map::insert(&mut registry.active_task_ids, task_id, true);
    registry.next_task_id = task_id + 1;
    task_id
}

/// Get next task ID without incrementing (for pre-allocation)
public(package) fun get_next_task_id(registry: &TaskRegistry): u64 {
    registry.next_task_id
}

/// Confirm task registration with pre-allocated ID
public(package) fun confirm_task_registration(registry: &mut TaskRegistry, task_id: u64, task_addr: address) {
    table::add(&mut registry.tasks, task_id, task_addr);
    vec_map::insert(&mut registry.active_task_ids, task_id, true);
    registry.next_task_id = task_id + 1;
}

public(package) fun mark_task_inactive(registry: &mut TaskRegistry, task_id: u64) {
    if (vec_map::contains(&registry.active_task_ids, &task_id)) {
        let (_key, _val) = vec_map::remove(&mut registry.active_task_ids, &task_id);
    };
}

// === Submission Registration ===

public(package) fun register_submission(registry: &mut TaskRegistry, submission_addr: address): u64 {
    let submission_id = registry.next_submission_id;
    table::add(&mut registry.submissions, submission_id, submission_addr);
    registry.next_submission_id = submission_id + 1;
    submission_id
}

// === Task Query Functions ===

/// Get tasks with cursor-based pagination
public fun get_tasks_paginated(
    registry: &TaskRegistry,
    cursor: u64,
    limit: u64,
): (vector<address>, u64) {
    assert!(limit > 0 && limit <= constants::pagination_max_limit(), constants::e_pagination_error());
    
    let mut results = vector::empty();
    let task_count = registry.next_task_id;
    let mut current = cursor;
    
    while (current < task_count && vector::length(&results) < limit) {
        if (table::contains(&registry.tasks, current)) {
            let task_addr = *table::borrow(&registry.tasks, current);
            vector::push_back(&mut results, task_addr);
        };
        current = current + 1;
    };
    
    let next_cursor = if (current < task_count) { current } else { 0 }; // 0 = no more
    (results, next_cursor)
}

/// Get active tasks with pagination
public fun get_active_tasks_paginated(
    registry: &TaskRegistry,
    cursor: u64,
    limit: u64,
): (vector<address>, u64) {
    assert!(limit > 0 && limit <= constants::pagination_max_limit(), constants::e_pagination_error());
    
    let mut results = vector::empty();
    let (active_keys, _) = vec_map::into_keys_values(registry.active_task_ids);
    let total = vector::length(&active_keys);
    let mut i = cursor;
    
    while (i < total && vector::length(&results) < limit) {
        let task_id = *vector::borrow(&active_keys, i);
        if (vec_map::contains(&registry.active_task_ids, &task_id)) {
            if (table::contains(&registry.tasks, task_id)) {
                let task_addr = *table::borrow(&registry.tasks, task_id);
                vector::push_back(&mut results, task_addr);
            };
        };
        i = i + 1;
    };
    
    let next_cursor = if (i < total) { i } else { 0 };
    (results, next_cursor)
}

// === Profile Registration ===

public(package) fun register_profile(registry: &mut TaskRegistry, user: address, profile_addr: address) {
    assert!(!table::contains(&registry.profiles, user), constants::e_profile_already_exists());
    table::add(&mut registry.profiles, user, profile_addr);
}

public(package) fun has_profile(registry: &TaskRegistry, user: address): bool {
    table::contains(&registry.profiles, user)
}

// === Reputation Registration ===

public(package) fun register_reputation(registry: &mut TaskRegistry, user: address, reputation_addr: address) {
    table::add(&mut registry.reputations, user, reputation_addr);
}

// === Dispute Registration ===

public(package) fun register_dispute(registry: &mut TaskRegistry, dispute_addr: address): u64 {
    let dispute_id = registry.next_dispute_id;
    table::add(&mut registry.disputes, dispute_id, dispute_addr);
    registry.next_dispute_id = dispute_id + 1;
    dispute_id
}

// === Prize Pool Registration ===

public(package) fun register_prize_pool(registry: &mut TaskRegistry, pool_addr: address): u64 {
    let pool_id = registry.next_pool_id;
    table::add(&mut registry.prize_pools, pool_id, pool_addr);
    registry.next_pool_id = pool_id + 1;
    pool_id
}

// === View Functions ===

/// Get active task IDs (much more efficient than iterating all tasks)
public fun get_active_task_ids(registry: &TaskRegistry, start_index: u64, limit: u64): vector<u64> {
    let mut task_ids = vector::empty<u64>();
    let total_active = vec_map::length(&registry.active_task_ids);
    
    if (start_index >= total_active) {
        return task_ids
    };
    
    let mut count = 0;
    let mut i = 0;
    let keys = vec_map::keys(&registry.active_task_ids);
    
    while (i < vector::length(&keys) && count < limit) {
        if (i >= start_index) {
            let task_id = *vector::borrow(&keys, i);
            vector::push_back(&mut task_ids, task_id);
            count = count + 1;
        };
        i = i + 1;
    };
    
    task_ids
}

/// Get all task IDs (legacy, less efficient)
public fun get_all_task_ids(registry: &TaskRegistry, start_id: u64, limit: u64): vector<u64> {
    let mut task_ids = vector::empty<u64>();
    let mut current_id = start_id;
    let max_id = registry.next_task_id;
    let mut count = 0;

    while (current_id < max_id && count < limit) {
        if (table::contains(&registry.tasks, current_id)) {
            vector::push_back(&mut task_ids, current_id);
            count = count + 1;
        };
        current_id = current_id + 1;
    };

    task_ids
}

/// Check if entities exist
public fun task_exists(registry: &TaskRegistry, task_id: u64): bool {
    table::contains(&registry.tasks, task_id)
}

public fun submission_exists(registry: &TaskRegistry, submission_id: u64): bool {
    table::contains(&registry.submissions, submission_id)
}

public fun profile_exists(registry: &TaskRegistry, user: address): bool {
    table::contains(&registry.profiles, user)
}

public fun reputation_exists(registry: &TaskRegistry, user: address): bool {
    table::contains(&registry.reputations, user)
}

public fun dispute_exists(registry: &TaskRegistry, dispute_id: u64): bool {
    table::contains(&registry.disputes, dispute_id)
}

public fun prize_pool_exists(registry: &TaskRegistry, pool_id: u64): bool {
    table::contains(&registry.prize_pools, pool_id)
}

/// Get addresses from registry
public fun get_task_address(registry: &TaskRegistry, task_id: u64): address {
    assert!(table::contains(&registry.tasks, task_id), constants::e_task_not_found());
    *table::borrow(&registry.tasks, task_id)
}

public fun get_submission_address(registry: &TaskRegistry, submission_id: u64): address {
    assert!(table::contains(&registry.submissions, submission_id), constants::e_submission_not_found());
    *table::borrow(&registry.submissions, submission_id)
}

public fun get_profile_address(registry: &TaskRegistry, user: address): address {
    assert!(table::contains(&registry.profiles, user), constants::e_profile_not_found());
    *table::borrow(&registry.profiles, user)
}

public fun get_reputation_address(registry: &TaskRegistry, user: address): address {
    assert!(table::contains(&registry.reputations, user), constants::e_profile_not_found());
    *table::borrow(&registry.reputations, user)
}

public fun get_dispute_address(registry: &TaskRegistry, dispute_id: u64): address {
    assert!(table::contains(&registry.disputes, dispute_id), constants::e_dispute_not_found());
    *table::borrow(&registry.disputes, dispute_id)
}

public fun get_prize_pool_address(registry: &TaskRegistry, pool_id: u64): address {
    assert!(table::contains(&registry.prize_pools, pool_id), constants::e_prize_pool_not_found());
    *table::borrow(&registry.prize_pools, pool_id)
}

/// Get next IDs
public fun get_next_task_id_view(registry: &TaskRegistry): u64 {
    registry.next_task_id
}

public fun get_next_submission_id(registry: &TaskRegistry): u64 {
    registry.next_submission_id
}

public fun get_next_dispute_id(registry: &TaskRegistry): u64 {
    registry.next_dispute_id
}

public fun get_next_pool_id(registry: &TaskRegistry): u64 {
    registry.next_pool_id
}

/// Get total counts
public fun get_active_task_count(registry: &TaskRegistry): u64 {
    vec_map::length(&registry.active_task_ids)
}
