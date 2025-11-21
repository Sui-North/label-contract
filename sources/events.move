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

public struct TaskDeadlineExtended has copy, drop {
    task_id: u64,
    requester: address,
    old_deadline: u64,
    new_deadline: u64,
    timestamp: u64,
}

public struct TaskStatusChanged has copy, drop {
    task_id: u64,
    old_status: u8,
    new_status: u8,
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

public struct SubmissionStatusChanged has copy, drop {
    submission_id: u64,
    task_id: u64,
    labeler: address,
    old_status: u8,
    new_status: u8,
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

public struct QualityMetricsRecorded has copy, drop {
    submission_id: u64,
    task_id: u64,
    labeler: address,
    agreement_score: u64,
    completion_time: u64,
}

// === Platform Config Events ===

public struct PlatformConfigUpdated has copy, drop {
    fee_bps: u64,
    fee_recipient: address,
}

public struct ProfileStatsUpdated has copy, drop {
    user: address,
    tasks_completed: u64,
    submissions_accepted: u64,
    total_earned: u64,
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

public(package) fun emit_task_deadline_extended(task_id: u64, requester: address, old_deadline: u64, new_deadline: u64, timestamp: u64) {
    event::emit(TaskDeadlineExtended { task_id, requester, old_deadline, new_deadline, timestamp });
}

public(package) fun emit_task_status_changed(task_id: u64, old_status: u8, new_status: u8, timestamp: u64) {
    event::emit(TaskStatusChanged { task_id, old_status, new_status, timestamp });
}

public(package) fun emit_submission_received(submission_id: u64, task_id: u64, labeler: address, timestamp: u64) {
    event::emit(SubmissionReceived { submission_id, task_id, labeler, timestamp });
}

public(package) fun emit_submission_rejected(submission_id: u64, task_id: u64, labeler: address, timestamp: u64) {
    event::emit(SubmissionRejected { submission_id, task_id, labeler, timestamp });
}

public(package) fun emit_submission_status_changed(submission_id: u64, task_id: u64, labeler: address, old_status: u8, new_status: u8, timestamp: u64) {
    event::emit(SubmissionStatusChanged { submission_id, task_id, labeler, old_status, new_status, timestamp });
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

public(package) fun emit_quality_metrics_recorded(submission_id: u64, task_id: u64, labeler: address, agreement_score: u64, completion_time: u64) {
    event::emit(QualityMetricsRecorded { submission_id, task_id, labeler, agreement_score, completion_time });
}

public(package) fun emit_platform_config_updated(fee_bps: u64, fee_recipient: address) {
    event::emit(PlatformConfigUpdated { fee_bps, fee_recipient });
}

public(package) fun emit_profile_stats_updated(user: address, tasks_completed: u64, submissions_accepted: u64, total_earned: u64) {
    event::emit(ProfileStatsUpdated { user, tasks_completed, submissions_accepted, total_earned });
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

// === Staking Events ===

public struct LabelerStaked has copy, drop {
    labeler: address,
    amount: u64,
    locked_until: u64,
}

public struct StakeSlashed has copy, drop {
    labeler: address,
    amount: u64,
    reason: vector<u8>,
}

public struct StakeWithdrawn has copy, drop {
    labeler: address,
    remaining_balance: u64,
}

// === Batch Payout Events ===

public struct BatchPayoutDistributed has copy, drop {
    task_id: u64,
    recipient_count: u64,
    total_amount: u64,
}

// === Emergency Events ===

public struct EmergencyPauseActivated has copy, drop {
    subsystem: u8,
    reason: vector<u8>,
    paused_at: u64,
}

public struct EmergencyPauseDeactivated has copy, drop {
    subsystem: u8,
    resumed_at: u64,
}

// === New Event Emission Functions ===

public(package) fun emit_labeler_staked(labeler: address, amount: u64, locked_until: u64) {
    event::emit(LabelerStaked { labeler, amount, locked_until });
}

public(package) fun emit_stake_slashed(labeler: address, amount: u64, reason: vector<u8>) {
    event::emit(StakeSlashed { labeler, amount, reason });
}

public(package) fun emit_stake_withdrawn(labeler: address, remaining_balance: u64) {
    event::emit(StakeWithdrawn { labeler, remaining_balance });
}

public(package) fun emit_batch_payout_distributed(task_id: u64, recipient_count: u64, total_amount: u64) {
    event::emit(BatchPayoutDistributed { task_id, recipient_count, total_amount });
}

public(package) fun emit_emergency_pause_activated(subsystem: u8, reason: vector<u8>, paused_at: u64) {
    event::emit(EmergencyPauseActivated { subsystem, reason, paused_at });
}

public(package) fun emit_emergency_pause_deactivated(subsystem: u8, resumed_at: u64) {
    event::emit(EmergencyPauseDeactivated { subsystem, resumed_at });
}
