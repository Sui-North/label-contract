/// Module: prize_pool
/// Prize pool competitions for Songsim labelers
module songsim::prize_pool;

use std::string::String;
use sui::balance::{Self, Balance};
use sui::clock::{Self, Clock};
use sui::coin::{Self, Coin};
use sui::sui::SUI;
use songsim::constants;
use songsim::events;

/// Prize Pool for competitions
public struct PrizePool has key, store {
    id: UID,
    pool_id: u64,
    name: String,
    description: String,
    total_amount: u64,
    funds: Balance<SUI>,
    start_time: u64,
    end_time: u64,
    min_submissions: u64,
    winners_count: u64,
    status: u8, // 0=active, 1=ended, 2=distributed
    participants: vector<address>,
}

// === Prize Pool Management Functions ===

/// Create a new prize pool
public(package) fun create(
    pool_id: u64,
    name: String,
    description: String,
    funds: Coin<SUI>,
    start_time: u64,
    end_time: u64,
    min_submissions: u64,
    winners_count: u64,
    ctx: &mut TxContext,
): PrizePool {
    let total_amount = coin::value(&funds);
    let funds_balance = coin::into_balance(funds);

    let pool = PrizePool {
        id: object::new(ctx),
        pool_id,
        name,
        description,
        total_amount,
        funds: funds_balance,
        start_time,
        end_time,
        min_submissions,
        winners_count,
        status: constants::pool_status_active(),
        participants: vector::empty(),
    };

    events::emit_prize_pool_created(pool_id, total_amount, winners_count, end_time);

    pool
}

/// Join a prize pool
public fun join(pool: &mut PrizePool, clock: &Clock, ctx: &TxContext) {
    let participant = ctx.sender();
    assert!(!vector::contains(&pool.participants, &participant), constants::e_profile_already_exists());
    assert!(pool.status == constants::pool_status_active(), constants::e_prize_pool_not_found());
    assert!(clock::timestamp_ms(clock) < pool.end_time, constants::e_prize_pool_not_ended());

    vector::push_back(&mut pool.participants, participant);

    events::emit_prize_pool_joined(pool.pool_id, participant, clock::timestamp_ms(clock));
}

/// Distribute prize pool to winners (admin/governance function)
public(package) fun distribute(
    pool: &mut PrizePool,
    winners: vector<address>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert!(pool.status == constants::pool_status_active(), constants::e_prize_pool_not_found());
    assert!(clock::timestamp_ms(clock) >= pool.end_time, constants::e_prize_pool_not_ended());
    assert!(
        vector::length(&pool.participants) >= pool.min_submissions,
        constants::e_insufficient_participants()
    );

    let winners_len = vector::length(&winners);
    assert!(winners_len > 0, constants::e_insufficient_participants());
    assert!(winners_len <= pool.winners_count, constants::e_consensus_threshold_not_met());

    let prize_per_winner = pool.total_amount / winners_len;
    let remainder = pool.total_amount % winners_len; // Calculate remainder
    let mut i = 0;

    while (i < winners_len) {
        let winner = *vector::borrow(&winners, i);

        // First winner gets remainder to avoid dust
        let prize_amount = if (i == 0) {
            prize_per_winner + remainder
        } else {
            prize_per_winner
        };

        let prize_balance = balance::split(&mut pool.funds, prize_amount);
        let prize_coin = coin::from_balance(prize_balance, ctx);
        transfer::public_transfer(prize_coin, winner);

        events::emit_prize_pool_winner(pool.pool_id, winner, prize_amount);

        i = i + 1;
    };

    pool.status = constants::pool_status_distributed();
}

/// End prize pool without distribution (admin function)
public(package) fun end_pool(pool: &mut PrizePool) {
    assert!(pool.status == constants::pool_status_active(), constants::e_prize_pool_not_found());
    pool.status = constants::pool_status_ended();
}

// === View Functions ===

public fun get_pool_id(pool: &PrizePool): u64 {
    pool.pool_id
}

public fun get_status(pool: &PrizePool): u8 {
    pool.status
}

public fun get_participant_count(pool: &PrizePool): u64 {
    vector::length(&pool.participants)
}

public fun is_participant(pool: &PrizePool, address: address): bool {
    vector::contains(&pool.participants, &address)
}

public fun get_details(pool: &PrizePool): (
    u64, // pool_id
    u64, // total_amount
    u64, // start_time
    u64, // end_time
    u64, // min_submissions
    u64, // winners_count
    u8, // status
    u64, // participant_count
) {
    (
        pool.pool_id,
        pool.total_amount,
        pool.start_time,
        pool.end_time,
        pool.min_submissions,
        pool.winners_count,
        pool.status,
        vector::length(&pool.participants),
    )
}
