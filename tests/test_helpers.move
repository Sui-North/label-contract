/// Test helpers and utilities shared across all test modules
#[test_only]
module songsim::test_helpers;

// === Error Codes ===
const EInvalidBlobId: u64 = 1;
const EInsufficientBounty: u64 = 2;
const ETaskNotFound: u64 = 3;
const EUnauthorized: u64 = 4;
const EInvalidTaskStatus: u64 = 5;
const EConsensusThresholdNotMet: u64 = 6;
const EProfileNotFound: u64 = 7;
const EProfileAlreadyExists: u64 = 8;
const ENotAdmin: u64 = 9;
const EInvalidFeePercentage: u64 = 10;
const EPlatformPaused: u64 = 11;
const ETaskNotOpen: u64 = 12;
const ETaskNotCompleted: u64 = 13;
const ENoSubmissions: u64 = 14;
const EInvalidDeadline: u64 = 15;
const EDisputeNotFound: u64 = 16;
const EDisputeAlreadyResolved: u64 = 17;
const EAlreadyVoted: u64 = 18;
const EPrizePoolNotFound: u64 = 19;
const EPrizePoolNotEnded: u64 = 20;
const EInsufficientParticipants: u64 = 21;
const ESubmissionNotFound: u64 = 22;
const EInvalidLabelerAddress: u64 = 23;
const EBatchSizeTooLarge: u64 = 24;
const EInsufficientBalance: u64 = 25;
const EBatchIndexOutOfBounds: u64 = 26;
const EFeeExceedsPayout: u64 = 27;
const EDuplicateSubmission: u64 = 28;
const ESubmissionDeadlinePassed: u64 = 29;

// === Platform Constants ===
const DEFAULT_PLATFORM_FEE_BPS: u64 = 500; // 5% (500 basis points)
const MIN_BOUNTY: u64 = 1_000_000; // 0.001 SUI (1 million MIST)
const MAX_FEE_BPS: u64 = 1000; // 10% maximum
const MAX_BOUNTY: u64 = 1_000_000_000_000_000; // 1M SUI (prevent overflow)
const MAX_BATCH_SIZE: u64 = 50; // Maximum payouts per transaction
const REVIEW_BUFFER_MS: u64 = 86400000; // 24 hours in milliseconds
const MAX_DECAY_PERIODS: u64 = 6; // Maximum reputation decay (6 months)

// === Reputation Constants ===
const REPUTATION_DECAY_PERIOD: u64 = 2592000000; // 30 days in milliseconds
const REPUTATION_DECAY_AMOUNT: u64 = 10; // Decay per period
const INITIAL_REPUTATION_SCORE: u64 = 500; // Start at 50%
const MAX_REPUTATION_SCORE: u64 = 1000;
const MIN_REPUTATION_SCORE: u64 = 0;
const REPUTATION_INCREASE_ACCEPTED: u64 = 50;
const REPUTATION_DECREASE_REJECTED: u64 = 50;

// === Badge Constants ===
const BADGE_NOVICE: u8 = 1;
const BADGE_INTERMEDIATE: u8 = 2;
const BADGE_EXPERT: u8 = 3;
const BADGE_MASTER: u8 = 4;
const BADGE_CONSISTENT: u8 = 5; // 10 consecutive accepts
const BADGE_SPEED_DEMON: u8 = 6; // Fast submissions

// === Task Status ===
const STATUS_OPEN: u8 = 0;
const STATUS_IN_PROGRESS: u8 = 1;
const STATUS_COMPLETED: u8 = 2;
const STATUS_CANCELLED: u8 = 3;

// === User Type ===
const USER_TYPE_REQUESTER: u8 = 1;
const USER_TYPE_LABELER: u8 = 2;
const USER_TYPE_BOTH: u8 = 3;
const USER_TYPE_ADMIN: u8 = 4;

// === Prize Pool Status ===
const POOL_STATUS_ACTIVE: u8 = 0;
const POOL_STATUS_ENDED: u8 = 1;
const POOL_STATUS_DISTRIBUTED: u8 = 2;

// === Submission Status ===
const SUBMISSION_STATUS_PENDING: u8 = 0;
const SUBMISSION_STATUS_ACCEPTED: u8 = 1;
const SUBMISSION_STATUS_REJECTED: u8 = 2;

// === Public Error Accessors ===
public fun e_invalid_blob_id(): u64 { EInvalidBlobId }

public fun e_insufficient_bounty(): u64 { EInsufficientBounty }

public fun e_task_not_found(): u64 { ETaskNotFound }

public fun e_unauthorized(): u64 { EUnauthorized }

public fun e_invalid_task_status(): u64 { EInvalidTaskStatus }

public fun e_consensus_threshold_not_met(): u64 { EConsensusThresholdNotMet }

public fun e_profile_not_found(): u64 { EProfileNotFound }

public fun e_profile_already_exists(): u64 { EProfileAlreadyExists }

public fun e_not_admin(): u64 { ENotAdmin }

public fun e_invalid_fee_percentage(): u64 { EInvalidFeePercentage }

public fun e_platform_paused(): u64 { EPlatformPaused }

public fun e_task_not_open(): u64 { ETaskNotOpen }

public fun e_task_not_completed(): u64 { ETaskNotCompleted }

public fun e_no_submissions(): u64 { ENoSubmissions }

public fun e_invalid_deadline(): u64 { EInvalidDeadline }

public fun e_dispute_not_found(): u64 { EDisputeNotFound }

public fun e_dispute_already_resolved(): u64 { EDisputeAlreadyResolved }

public fun e_already_voted(): u64 { EAlreadyVoted }

public fun e_prize_pool_not_found(): u64 { EPrizePoolNotFound }

public fun e_prize_pool_not_ended(): u64 { EPrizePoolNotEnded }

public fun e_insufficient_participants(): u64 { EInsufficientParticipants }

public fun e_submission_not_found(): u64 { ESubmissionNotFound }

public fun e_invalid_labeler_address(): u64 { EInvalidLabelerAddress }

public fun e_batch_size_too_large(): u64 { EBatchSizeTooLarge }

public fun e_insufficient_balance(): u64 { EInsufficientBalance }

public fun e_batch_index_out_of_bounds(): u64 { EBatchIndexOutOfBounds }

public fun e_fee_exceeds_payout(): u64 { EFeeExceedsPayout }

public fun e_duplicate_submission(): u64 { EDuplicateSubmission }

public fun e_submission_deadline_passed(): u64 { ESubmissionDeadlinePassed }

// === Public Constant Accessors ===
public fun default_platform_fee_bps(): u64 { DEFAULT_PLATFORM_FEE_BPS }

public fun min_bounty(): u64 { MIN_BOUNTY }

public fun max_fee_bps(): u64 { MAX_FEE_BPS }

public fun max_bounty(): u64 { MAX_BOUNTY }

public fun max_batch_size(): u64 { MAX_BATCH_SIZE }

public fun review_buffer_ms(): u64 { REVIEW_BUFFER_MS }

public fun max_decay_periods(): u64 { MAX_DECAY_PERIODS }

public fun reputation_decay_period(): u64 { REPUTATION_DECAY_PERIOD }

public fun reputation_decay_amount(): u64 { REPUTATION_DECAY_AMOUNT }

public fun initial_reputation_score(): u64 { INITIAL_REPUTATION_SCORE }

public fun max_reputation_score(): u64 { MAX_REPUTATION_SCORE }

public fun min_reputation_score(): u64 { MIN_REPUTATION_SCORE }

public fun reputation_increase_accepted(): u64 { REPUTATION_INCREASE_ACCEPTED }

public fun reputation_decrease_rejected(): u64 { REPUTATION_DECREASE_REJECTED }

public fun badge_novice(): u8 { BADGE_NOVICE }

public fun badge_intermediate(): u8 { BADGE_INTERMEDIATE }

public fun badge_expert(): u8 { BADGE_EXPERT }

public fun badge_master(): u8 { BADGE_MASTER }

public fun badge_consistent(): u8 { BADGE_CONSISTENT }

public fun badge_speed_demon(): u8 { BADGE_SPEED_DEMON }

public fun status_open(): u8 { STATUS_OPEN }

public fun status_in_progress(): u8 { STATUS_IN_PROGRESS }

public fun status_completed(): u8 { STATUS_COMPLETED }

public fun status_cancelled(): u8 { STATUS_CANCELLED }

public fun user_type_requester(): u8 { USER_TYPE_REQUESTER }

public fun user_type_labeler(): u8 { USER_TYPE_LABELER }

public fun user_type_both(): u8 { USER_TYPE_BOTH }

public fun user_type_admin(): u8 { USER_TYPE_ADMIN }

public fun pool_status_active(): u8 { POOL_STATUS_ACTIVE }

public fun pool_status_ended(): u8 { POOL_STATUS_ENDED }

public fun pool_status_distributed(): u8 { POOL_STATUS_DISTRIBUTED }

public fun submission_status_pending(): u8 { SUBMISSION_STATUS_PENDING }

public fun submission_status_accepted(): u8 { SUBMISSION_STATUS_ACCEPTED }

public fun submission_status_rejected(): u8 { SUBMISSION_STATUS_REJECTED }

// === Test Addresses ===
use sui::test_scenario::{Self as ts};
use sui::clock::{Self, Clock};
use sui::coin::{Self, Coin};
use sui::sui::SUI;

/// Admin address for platform operations
public fun admin(): address {
    @0xAD1
}

/// Fee recipient address
public fun fee_recipient(): address {
    @0xFEE
}

/// Test requester address
public fun requester(): address {
    @0xA1
}

/// Test labeler addresses
public fun labeler1(): address {
    @0xB1
}

public fun labeler2(): address {
    @0xB2
}

public fun labeler3(): address {
    @0xB3
}

/// Test bounty amount (0.1 SUI)
public fun bounty_amount(): u64 {
    100_000_000 // 0.1 SUI in MIST
}

/// Large bounty amount (1 SUI)
public fun large_bounty(): u64 {
    1_000_000_000 // 1 SUI in MIST
}

/// Future deadline (1 year from now)
public fun future_deadline(): u64 {
    1735689600000 // January 1, 2025
}

/// Past deadline (for testing expiration)
public fun past_deadline(): u64 {
    1577836800000 // January 1, 2020
}

// === Test Scenario Helpers ===

/// Begin a test scenario with admin as the sender
public fun begin_test(): ts::Scenario {
    ts::begin(admin())
}

/// End a test scenario
public fun end_test(scenario: ts::Scenario) {
    ts::end(scenario);
}

// === Clock Helpers ===

/// Create a test clock
public fun create_clock(ctx: &mut TxContext): Clock {
    clock::create_for_testing(ctx)
}

/// Destroy a test clock
public fun destroy_clock(clock: Clock) {
    clock::destroy_for_testing(clock);
}

/// Set clock timestamp
public fun set_clock_timestamp(clock: &mut Clock, timestamp_ms: u64) {
    clock::set_for_testing(clock, timestamp_ms);
}

// === Coin Helpers ===

/// Mint test SUI coins
public fun mint_sui(amount: u64, ctx: &mut TxContext): Coin<SUI> {
    coin::mint_for_testing<SUI>(amount, ctx)
}

/// Burn test SUI coins
public fun burn_sui(coin: Coin<SUI>) {
    coin::burn_for_testing(coin);
}
