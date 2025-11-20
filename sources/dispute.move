/// Module: dispute
/// Dispute resolution system for Songsim
module songsim::dispute;

use sui::clock::{Self, Clock};
use songsim::constants;
use songsim::events;

/// Dispute object
public struct Dispute has key, store {
    id: UID,
    dispute_id: u64,
    task_id: u64,
    submission_id: u64,
    disputer: address, // Who raised the dispute
    reason: vector<u8>,
    created_at: u64,
    resolved: bool,
    resolution: vector<u8>,
    votes_for: u64,
    votes_against: u64,
    voters: vector<address>,
}

// === Dispute Management Functions ===

/// Create a dispute for a submission
public(package) fun create(
    dispute_id: u64,
    task_id: u64,
    submission_id: u64,
    disputer: address,
    reason: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext,
): Dispute {
    let dispute = Dispute {
        id: object::new(ctx),
        dispute_id,
        task_id,
        submission_id,
        disputer,
        reason,
        created_at: clock::timestamp_ms(clock),
        resolved: false,
        resolution: vector::empty(),
        votes_for: 0,
        votes_against: 0,
        voters: vector::empty(),
    };

    events::emit_dispute_created(
        dispute_id,
        task_id,
        submission_id,
        disputer,
        clock::timestamp_ms(clock),
    );

    dispute
}

/// Vote on a dispute
public fun vote(dispute: &mut Dispute, vote_for: bool, ctx: &TxContext) {
    assert!(!dispute.resolved, constants::e_dispute_already_resolved());

    let voter = ctx.sender();
    assert!(!vector::contains(&dispute.voters, &voter), constants::e_already_voted());

    vector::push_back(&mut dispute.voters, voter);

    if (vote_for) {
        dispute.votes_for = dispute.votes_for + 1;
    } else {
        dispute.votes_against = dispute.votes_against + 1;
    };

    events::emit_dispute_voted(dispute.dispute_id, voter, vote_for);
}

/// Resolve a dispute (admin/governance function)
public(package) fun resolve(dispute: &mut Dispute, resolution: vector<u8>) {
    assert!(!dispute.resolved, constants::e_dispute_already_resolved());

    dispute.resolved = true;
    dispute.resolution = resolution;

    let resolved_in_favor = dispute.votes_for > dispute.votes_against;

    events::emit_dispute_resolved(
        dispute.dispute_id,
        resolved_in_favor,
        dispute.votes_for,
        dispute.votes_against,
    );
}

// === View Functions ===

public fun get_dispute_id(dispute: &Dispute): u64 {
    dispute.dispute_id
}

public fun is_resolved(dispute: &Dispute): bool {
    dispute.resolved
}

public fun get_details(dispute: &Dispute): (
    u64, // dispute_id
    u64, // task_id
    u64, // submission_id
    address, // disputer
    bool, // resolved
    u64, // votes_for
    u64, // votes_against
) {
    (
        dispute.dispute_id,
        dispute.task_id,
        dispute.submission_id,
        dispute.disputer,
        dispute.resolved,
        dispute.votes_for,
        dispute.votes_against,
    )
}

public fun get_vote_count(dispute: &Dispute): (u64, u64) {
    (dispute.votes_for, dispute.votes_against)
}

public fun has_voted(dispute: &Dispute, voter: address): bool {
    vector::contains(&dispute.voters, &voter)
}
