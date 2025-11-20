/// Module: events
/// Event definitions for Songsim platform
module songsim::events;

use sui::event;

// === Profile Events ===

public struct ProfileCreated has copy, drop {
    profile_id: address,
    owner: address,
    user_type: u8,
    timestamp: u64,
}

public struct ProfileUpdated has copy, drop {
    profile_id: address,
    owner: address,
}

// === Task Events ===

public struct TaskCreated has copy, drop {
    task_id: u64,
    requester: address,
    bounty_amount: u64,
    deadline: u64,
}

public struct TaskCancelled has copy, drop {
    task_id: u64,
    requester: address,
    refund_amount: u64,
    timestamp: u64,
}

// === Submission Events ===

public struct SubmissionReceived has copy, drop {
    submission_id: u64,
    task_id: u64,
    labeler: address,
    timestamp: u64,
}

public struct SubmissionRejected has copy, drop {
    submission_id: u64,
    task_id: u64,
    labeler: address,
    timestamp: u64,
}

// === Consensus Events ===

public struct ConsensusFinalized has copy, drop {
    task_id: u64,
    accepted_count: u64,
    rejected_count: u64,
}

// === Payout Events ===

public struct PayoutDistributed has copy, drop {
    task_id: u64,
    recipient: address,
    amount: u64,
}

public struct PlatformFeeCollected has copy, drop {
    task_id: u64,
    amount: u64,
    recipient: address,
}

// === Reputation Events ===

public struct ReputationUpdated has copy, drop {
    user: address,
    new_score: u64,
}

public struct BadgeEarned has copy, drop {
    user: address,
    badge_id: u8,
    badge_name: vector<u8>,
    timestamp: u64,
}

// === Platform Config Events ===

public struct PlatformConfigUpdated has copy, drop {
    fee_bps: u64,
    fee_recipient: address,
}

// === Dispute Events ===

public struct DisputeCreated has copy, drop {
    dispute_id: u64,
    task_id: u64,
    submission_id: u64,
    disputer: address,
    timestamp: u64,
}

public struct DisputeVoted has copy, drop {
    dispute_id: u64,
    voter: address,
    vote_for: bool,
}

public struct DisputeResolved has copy, drop {
    dispute_id: u64,
    resolved_in_favor: bool,
    votes_for: u64,
    votes_against: u64,
}

// === Prize Pool Events ===

public struct PrizePoolCreated has copy, drop {
    pool_id: u64,
    total_amount: u64,
    winners_count: u64,
    end_time: u64,
}

public struct PrizePoolJoined has copy, drop {
    pool_id: u64,
    participant: address,
    timestamp: u64,
}

public struct PrizePoolWinner has copy, drop {
    pool_id: u64,
    winner: address,
    prize_amount: u64,
}

// === Event Emission Functions ===

public(package) fun emit_profile_created(profile_id: address, owner: address, user_type: u8, timestamp: u64) {
    event::emit(ProfileCreated { profile_id, owner, user_type, timestamp });
}

public(package) fun emit_profile_updated(profile_id: address, owner: address) {
    event::emit(ProfileUpdated { profile_id, owner });
}

public(package) fun emit_task_created(task_id: u64, requester: address, bounty_amount: u64, deadline: u64) {
    event::emit(TaskCreated { task_id, requester, bounty_amount, deadline });
}

public(package) fun emit_task_cancelled(task_id: u64, requester: address, refund_amount: u64, timestamp: u64) {
    event::emit(TaskCancelled { task_id, requester, refund_amount, timestamp });
}

public(package) fun emit_submission_received(submission_id: u64, task_id: u64, labeler: address, timestamp: u64) {
    event::emit(SubmissionReceived { submission_id, task_id, labeler, timestamp });
}

public(package) fun emit_submission_rejected(submission_id: u64, task_id: u64, labeler: address, timestamp: u64) {
    event::emit(SubmissionRejected { submission_id, task_id, labeler, timestamp });
}

public(package) fun emit_consensus_finalized(task_id: u64, accepted_count: u64, rejected_count: u64) {
    event::emit(ConsensusFinalized { task_id, accepted_count, rejected_count });
}

public(package) fun emit_payout_distributed(task_id: u64, recipient: address, amount: u64) {
    event::emit(PayoutDistributed { task_id, recipient, amount });
}

public(package) fun emit_platform_fee_collected(task_id: u64, amount: u64, recipient: address) {
    event::emit(PlatformFeeCollected { task_id, amount, recipient });
}

public(package) fun emit_reputation_updated(user: address, new_score: u64) {
    event::emit(ReputationUpdated { user, new_score });
}

public(package) fun emit_badge_earned(user: address, badge_id: u8, badge_name: vector<u8>, timestamp: u64) {
    event::emit(BadgeEarned { user, badge_id, badge_name, timestamp });
}

public(package) fun emit_platform_config_updated(fee_bps: u64, fee_recipient: address) {
    event::emit(PlatformConfigUpdated { fee_bps, fee_recipient });
}

public(package) fun emit_dispute_created(dispute_id: u64, task_id: u64, submission_id: u64, disputer: address, timestamp: u64) {
    event::emit(DisputeCreated { dispute_id, task_id, submission_id, disputer, timestamp });
}

public(package) fun emit_dispute_voted(dispute_id: u64, voter: address, vote_for: bool) {
    event::emit(DisputeVoted { dispute_id, voter, vote_for });
}

public(package) fun emit_dispute_resolved(dispute_id: u64, resolved_in_favor: bool, votes_for: u64, votes_against: u64) {
    event::emit(DisputeResolved { dispute_id, resolved_in_favor, votes_for, votes_against });
}

public(package) fun emit_prize_pool_created(pool_id: u64, total_amount: u64, winners_count: u64, end_time: u64) {
    event::emit(PrizePoolCreated { pool_id, total_amount, winners_count, end_time });
}

public(package) fun emit_prize_pool_joined(pool_id: u64, participant: address, timestamp: u64) {
    event::emit(PrizePoolJoined { pool_id, participant, timestamp });
}

public(package) fun emit_prize_pool_winner(pool_id: u64, winner: address, prize_amount: u64) {
    event::emit(PrizePoolWinner { pool_id, winner, prize_amount });
}
