/// Module: batch_updates
/// Batch update functions for profile and reputation after consensus
module songsim::batch_updates;

use songsim::registry::{Self, TaskRegistry};
use songsim::profile::{Self, UserProfile};
use songsim::reputation::{Self, Reputation};
use songsim::task::{Self, Task, Submission};
use songsim::events;
use songsim::constants;

/// Update a single labeler's profile and reputation after acceptance
public fun update_accepted_labeler(
    profile: &mut UserProfile,
    reputation: &mut Reputation,
    earned_amount: u64,
    current_time: u64,
) {
    // Verify profile and reputation match
    assert!(profile::get_owner(profile) == reputation::get_user(reputation), constants::e_unauthorized());
    
    // Update profile stats
    profile::increment_accepted(profile, earned_amount);
    
    // Update reputation (accepted)
    reputation::update_from_consensus(reputation, true, current_time);
    
    // Emit event
    let (_, tasks_completed, _, _, submissions_accepted, _, total_earned) = profile::get_stats(profile);
    events::emit_profile_stats_updated(
        profile::get_owner(profile),
        tasks_completed,
        submissions_accepted,
        total_earned,
    );
}

/// Update a single labeler's profile and reputation after rejection
public fun update_rejected_labeler(
    profile: &mut UserProfile,
    reputation: &mut Reputation,
    current_time: u64,
) {
    // Verify profile and reputation match
    assert!(profile::get_owner(profile) == reputation::get_user(reputation), constants::e_unauthorized());
    
    // Update profile stats
    profile::increment_rejected(profile);
    
    // Update reputation (rejected)
    reputation::update_from_consensus(reputation, false, current_time);
    
    // Emit event
    let (_, tasks_completed, _, _, submissions_accepted, _, total_earned) = profile::get_stats(profile);
    events::emit_profile_stats_updated(
        profile::get_owner(profile),
        tasks_completed,
        submissions_accepted,
        total_earned,
    );
}

/// Update submission status after consensus (individual)
public fun update_submission_after_consensus(
    submission: &mut Submission,
    task: &Task,
    is_accepted: bool,
    current_time: u64,
) {
    // Update submission using internal function (no requester auth check)
    task::update_submission_status_internal(submission, task, is_accepted, current_time);
}

