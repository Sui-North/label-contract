/// Module: profile
/// User profile management for Songsim platform
module songsim::profile;

use std::string::String;
use songsim::constants;
use songsim::events;

/// User profile (SHARED OBJECT)
public struct UserProfile has key, store {
    id: UID,
    owner: address,
    display_name: String,
    bio: String,
    avatar_url: String,
    user_type: u8, // 1=requester, 2=labeler, 3=both, 4=admin
    created_at: u64,
    tasks_created: u64, // For requesters
    tasks_completed: u64, // Tasks finalized with consensus
    tasks_cancelled: u64, // Tasks cancelled
    submissions_count: u64, // For labelers - total submitted
    submissions_accepted: u64, // Accepted by requesters
    submissions_rejected: u64, // Rejected by requesters
    total_earned: u64, // Cumulative earnings in MIST (SUI * 10^9)
}

// === Profile Management Functions ===

/// Create user profile
public(package) fun create(
    owner: address,
    display_name: String,
    bio: String,
    avatar_url: String,
    user_type: u8,
    created_at: u64,
    ctx: &mut TxContext,
): UserProfile {
    UserProfile {
        id: object::new(ctx),
        owner,
        display_name,
        bio,
        avatar_url,
        user_type,
        created_at,
        tasks_created: 0,
        tasks_completed: 0,
        tasks_cancelled: 0,
        submissions_count: 0,
        submissions_accepted: 0,
        submissions_rejected: 0,
        total_earned: 0,
    }
}

/// Update profile information
public fun update(
    profile: &mut UserProfile,
    display_name: String,
    bio: String,
    avatar_url: String,
    ctx: &TxContext,
) {
    assert!(profile.owner == ctx.sender(), constants::e_unauthorized());

    profile.display_name = display_name;
    profile.bio = bio;
    profile.avatar_url = avatar_url;

    events::emit_profile_updated(object::id_address(profile), profile.owner);
}

/// Update user type preference
public fun update_user_type(profile: &mut UserProfile, new_user_type: u8, ctx: &TxContext) {
    assert!(profile.owner == ctx.sender(), constants::e_unauthorized());
    profile.user_type = new_user_type;

    events::emit_profile_updated(object::id_address(profile), profile.owner);
}

/// Increment tasks created count
public(package) fun increment_tasks_created(profile: &mut UserProfile) {
    profile.tasks_created = profile.tasks_created + 1;
}

/// Increment submissions count
public(package) fun increment_submissions_count(profile: &mut UserProfile) {
    profile.submissions_count = profile.submissions_count + 1;
}

/// Increment tasks completed count
public(package) fun increment_tasks_completed(profile: &mut UserProfile) {
    profile.tasks_completed = profile.tasks_completed + 1;
}

/// Increment tasks cancelled count
public(package) fun increment_tasks_cancelled(profile: &mut UserProfile) {
    profile.tasks_cancelled = profile.tasks_cancelled + 1;
}

/// Increment accepted submissions count and earnings
public(package) fun increment_accepted(profile: &mut UserProfile, earned_amount: u64) {
    profile.submissions_accepted = profile.submissions_accepted + 1;
    profile.total_earned = profile.total_earned + earned_amount;
}

/// Increment rejected submissions count
public(package) fun increment_rejected(profile: &mut UserProfile) {
    profile.submissions_rejected = profile.submissions_rejected + 1;
}

// === View Functions ===

public fun get_owner(profile: &UserProfile): address {
    profile.owner
}

public fun get_user_type(profile: &UserProfile): u8 {
    profile.user_type
}

public fun get_stats(profile: &UserProfile): (u64, u64, u64, u64, u64, u64, u64) {
    (
        profile.tasks_created,
        profile.tasks_completed,
        profile.tasks_cancelled,
        profile.submissions_count,
        profile.submissions_accepted,
        profile.submissions_rejected,
        profile.total_earned,
    )
}

public fun get_details(profile: &UserProfile): (
    address,
    String,
    String,
    String,
    u8,
    u64,
    u64,
    u64,
    u64,
    u64,
    u64,
    u64,
    u64,
) {
    (
        profile.owner,
        profile.display_name,
        profile.bio,
        profile.avatar_url,
        profile.user_type,
        profile.created_at,
        profile.tasks_created,
        profile.tasks_completed,
        profile.tasks_cancelled,
        profile.submissions_count,
        profile.submissions_accepted,
        profile.submissions_rejected,
        profile.total_earned,
    )
}
