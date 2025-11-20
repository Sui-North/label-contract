/// Test helpers and utilities shared across all test modules
#[test_only]
module songsim::test_helpers;

use sui::coin::{Self, Coin};
use sui::clock::{Self, Clock};
use sui::sui::SUI;
use sui::test_scenario::{Self as ts, Scenario};

// === Test Constants ===

const ADMIN: address = @0xAD;
const REQUESTER: address = @0xA1;
const LABELER1: address = @0xB1;
const LABELER2: address = @0xB2;
const LABELER3: address = @0xB3;
const FEE_RECIPIENT: address = @0xFEE;

const MIN_BOUNTY: u64 = 1_000_000; // 0.001 SUI
const BOUNTY_AMOUNT: u64 = 10_000_000; // 0.01 SUI
const LARGE_BOUNTY: u64 = 100_000_000; // 0.1 SUI
const PLATFORM_FEE_BPS: u64 = 500; // 5%

const FUTURE_DEADLINE: u64 = 9999999999999; // Far future timestamp
const PAST_DEADLINE: u64 = 1000; // Past timestamp

// === Public Accessors ===

public fun admin(): address { ADMIN }
public fun requester(): address { REQUESTER }
public fun labeler1(): address { LABELER1 }
public fun labeler2(): address { LABELER2 }
public fun labeler3(): address { LABELER3 }
public fun fee_recipient(): address { FEE_RECIPIENT }

public fun min_bounty(): u64 { MIN_BOUNTY }
public fun bounty_amount(): u64 { BOUNTY_AMOUNT }
public fun large_bounty(): u64 { LARGE_BOUNTY }
public fun platform_fee_bps(): u64 { PLATFORM_FEE_BPS }

public fun future_deadline(): u64 { FUTURE_DEADLINE }
public fun past_deadline(): u64 { PAST_DEADLINE }

// === Helper Functions ===

/// Mint SUI coins for testing
public fun mint_sui(amount: u64, ctx: &mut TxContext): Coin<SUI> {
    coin::mint_for_testing<SUI>(amount, ctx)
}

/// Create a mock clock for testing
public fun create_clock(ctx: &mut TxContext): Clock {
    clock::create_for_testing(ctx)
}

/// Set clock timestamp
public fun set_clock_time(clock: &mut Clock, timestamp_ms: u64) {
    clock::set_for_testing(clock, timestamp_ms);
}

/// Increment clock by duration
public fun increment_clock(clock: &mut Clock, duration_ms: u64) {
    let current = clock::timestamp_ms(clock);
    clock::set_for_testing(clock, current + duration_ms);
}

/// Destroy clock after testing
public fun destroy_clock(clock: Clock) {
    clock::destroy_for_testing(clock);
}

/// Begin test scenario with admin
public fun begin_test(): Scenario {
    ts::begin(ADMIN)
}

/// End test scenario
public fun end_test(scenario: Scenario) {
    ts::end(scenario);
}
