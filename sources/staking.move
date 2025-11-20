/// Module: staking
/// Anti-Sybil staking mechanism for labelers
module songsim::staking;

use sui::balance::{Self, Balance};
use sui::clock::{Self, Clock};
use sui::coin::{Self, Coin};
use sui::sui::SUI;
use songsim::constants;
use songsim::events;

/// Labeler stake for anti-Sybil protection
public struct LabelerStake has key, store {
    id: UID,
    labeler: address,
    staked_amount: Balance<SUI>,
    stake_value: u64, // Track original value
    locked_until: u64,
    slashed_amount: u64,
}

// === Staking Functions ===

/// Stake SUI to become eligible labeler
public(package) fun create_stake(
    labeler: address,
    stake_coin: Coin<SUI>,
    clock: &Clock,
    ctx: &mut TxContext,
): LabelerStake {
    let stake_value = coin::value(&stake_coin);
    assert!(stake_value >= constants::min_labeler_stake(), constants::e_insufficient_stake());
    
    let locked_until = clock::timestamp_ms(clock) + constants::stake_lock_duration();
    let stake_balance = coin::into_balance(stake_coin);
    
    events::emit_labeler_staked(labeler, stake_value, locked_until);
    
    LabelerStake {
        id: object::new(ctx),
        labeler,
        staked_amount: stake_balance,
        stake_value,
        locked_until,
        slashed_amount: 0,
    }
}

/// Withdraw stake after lock period
public fun withdraw_stake(
    stake: LabelerStake,
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<SUI> {
    let LabelerStake {
        id,
        labeler,
        staked_amount,
        stake_value: _,
        locked_until,
        slashed_amount: _,
    } = stake;
    
    assert!(clock::timestamp_ms(clock) >= locked_until, constants::e_stake_locked());
    assert!(labeler == ctx.sender(), constants::e_unauthorized());
    
    let remaining_balance = balance::value(&staked_amount);
    events::emit_stake_withdrawn(labeler, remaining_balance);
    
    object::delete(id);
    coin::from_balance(staked_amount, ctx)
}

/// Slash stake for malicious behavior (admin only)
public(package) fun slash_stake(
    stake: &mut LabelerStake,
    slash_amount: u64,
    reason: vector<u8>,
    fee_recipient: address,
    ctx: &mut TxContext,
) {
    let current_balance = balance::value(&stake.staked_amount);
    let actual_slash = if (slash_amount > current_balance) {
        current_balance
    } else {
        slash_amount
    };
    
    let slashed = balance::split(&mut stake.staked_amount, actual_slash);
    let slashed_coin = coin::from_balance(slashed, ctx);
    transfer::public_transfer(slashed_coin, fee_recipient); // Transfer to platform treasury
    
    stake.slashed_amount = stake.slashed_amount + actual_slash;
    
    events::emit_stake_slashed(stake.labeler, actual_slash, reason);
}

/// Extend stake lock period
public fun extend_lock(
    stake: &mut LabelerStake,
    additional_duration: u64,
    clock: &Clock,
    ctx: &TxContext,
) {
    assert!(stake.labeler == ctx.sender(), constants::e_unauthorized());
    
    let current_time = clock::timestamp_ms(clock);
    stake.locked_until = if (stake.locked_until > current_time) {
        stake.locked_until + additional_duration
    } else {
        current_time + additional_duration
    };
}

// === Query Functions ===

public fun get_labeler(stake: &LabelerStake): address {
    stake.labeler
}

public fun get_stake_value(stake: &LabelerStake): u64 {
    stake.stake_value
}

public fun get_remaining_balance(stake: &LabelerStake): u64 {
    balance::value(&stake.staked_amount)
}

public fun get_locked_until(stake: &LabelerStake): u64 {
    stake.locked_until
}

public fun get_slashed_amount(stake: &LabelerStake): u64 {
    stake.slashed_amount
}

public fun is_locked(stake: &LabelerStake, clock: &Clock): bool {
    clock::timestamp_ms(clock) < stake.locked_until
}
