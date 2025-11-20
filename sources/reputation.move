/// Module: reputation
/// Reputation tracking and badge system for Songsim labelers
module songsim::reputation;

use songsim::constants;
use songsim::events;

/// Reputation tracking with weighted scoring and badges
public struct Reputation has key, store {
    id: UID,
    user: address,
    total_completed: u64,
    total_accepted: u64,
    total_rejected: u64,
    reputation_score: u64, // 0-1000 scale
    last_activity: u64, // Timestamp for decay calculation
    weighted_score: u64, // Weighted by task difficulty
    badges: vector<u8>, // Badge IDs earned
}

/// Badge/Achievement
public struct Badge has copy, drop, store {
    badge_id: u8,
    name: vector<u8>,
    description: vector<u8>,
    earned_at: u64,
}

// === Reputation Management Functions ===

/// Create initial reputation for a new user
public(package) fun create(user: address, created_at: u64, ctx: &mut TxContext): Reputation {
    Reputation {
        id: object::new(ctx),
        user,
        total_completed: 0,
        total_accepted: 0,
        total_rejected: 0,
        reputation_score: constants::initial_reputation_score(),
        last_activity: created_at,
        weighted_score: constants::initial_reputation_score(),
        badges: vector::empty(),
    }
}

/// Update reputation after submission review (simple version)
public fun update_simple(reputation: &mut Reputation, accepted: bool, ctx: &TxContext) {
    assert!(reputation.user == ctx.sender(), constants::e_unauthorized());
    update_internal(reputation, accepted, ctx.epoch_timestamp_ms());
}

/// Update reputation with weighted scoring
public fun update_weighted(
    reputation: &mut Reputation,
    accepted: bool,
    task_difficulty: u64, // 1-10 scale
    current_time: u64,
) {
    // Apply decay first
    apply_decay_internal(reputation, current_time);

    reputation.total_completed = reputation.total_completed + 1;
    reputation.last_activity = current_time;

    let score_change = constants::reputation_increase_accepted() + (task_difficulty * 2);

    if (accepted) {
        reputation.total_accepted = reputation.total_accepted + 1;

        // Increase reputation (cap at MAX)
        let max_score = constants::max_reputation_score();
        if (reputation.reputation_score < (max_score - score_change)) {
            reputation.reputation_score = reputation.reputation_score + score_change;
        } else {
            reputation.reputation_score = max_score;
        };

        // Update weighted score
        let weighted_increase = score_change * task_difficulty / 5;
        if (reputation.weighted_score < (max_score - weighted_increase)) {
            reputation.weighted_score = reputation.weighted_score + weighted_increase;
        } else {
            reputation.weighted_score = max_score;
        };

        // Check for badge eligibility
        check_and_award_badges(reputation, current_time);
    } else {
        reputation.total_rejected = reputation.total_rejected + 1;

        // Decrease reputation (floor at MIN)
        if (reputation.reputation_score > score_change) {
            reputation.reputation_score = reputation.reputation_score - score_change;
        } else {
            reputation.reputation_score = constants::min_reputation_score();
        };

        // Decrease weighted score
        if (reputation.weighted_score > score_change) {
            reputation.weighted_score = reputation.weighted_score - score_change;
        } else {
            reputation.weighted_score = constants::min_reputation_score();
        };
    };

    events::emit_reputation_updated(reputation.user, reputation.reputation_score);
}

/// Apply reputation decay based on inactivity
public fun apply_decay(reputation: &mut Reputation, current_time: u64) {
    apply_decay_internal(reputation, current_time);
}

/// Internal function for updating reputation (package-internal)
public(package) fun update_internal(reputation: &mut Reputation, accepted: bool, current_time: u64) {
    reputation.total_completed = reputation.total_completed + 1;
    reputation.last_activity = current_time;

    if (accepted) {
        reputation.total_accepted = reputation.total_accepted + 1;
        
        // Increase reputation (cap at 1000)
        let increase = constants::reputation_increase_accepted();
        let max_score = constants::max_reputation_score();
        if (reputation.reputation_score < (max_score - increase)) {
            reputation.reputation_score = reputation.reputation_score + increase;
        } else {
            reputation.reputation_score = max_score;
        };
    } else {
        reputation.total_rejected = reputation.total_rejected + 1;
        
        // Decrease reputation (floor at 0)
        let decrease = constants::reputation_decrease_rejected();
        if (reputation.reputation_score > decrease) {
            reputation.reputation_score = reputation.reputation_score - decrease;
        } else {
            reputation.reputation_score = constants::min_reputation_score();
        };
    };

    events::emit_reputation_updated(reputation.user, reputation.reputation_score);
}

// === Internal Helper Functions ===

fun apply_decay_internal(reputation: &mut Reputation, current_time: u64) {
    let time_diff = current_time - reputation.last_activity;
    let decay_period = constants::reputation_decay_period();
    let periods_passed = time_diff / decay_period;

    if (periods_passed > 0) {
        let decay_amount = periods_passed * constants::reputation_decay_amount();
        if (reputation.reputation_score > decay_amount) {
            reputation.reputation_score = reputation.reputation_score - decay_amount;
        } else {
            reputation.reputation_score = constants::min_reputation_score();
        };

        reputation.last_activity = current_time;

        events::emit_reputation_updated(reputation.user, reputation.reputation_score);
    };
}

fun check_and_award_badges(reputation: &mut Reputation, current_time: u64) {
    let badges = &mut reputation.badges;

    // Novice badge: 10 completed tasks
    if (reputation.total_completed >= 10 && !vector::contains(badges, &constants::badge_novice())) {
        vector::push_back(badges, constants::badge_novice());
        events::emit_badge_earned(reputation.user, constants::badge_novice(), b"Novice", current_time);
    };

    // Intermediate badge: 50 completed tasks
    if (reputation.total_completed >= 50 && !vector::contains(badges, &constants::badge_intermediate())) {
        vector::push_back(badges, constants::badge_intermediate());
        events::emit_badge_earned(reputation.user, constants::badge_intermediate(), b"Intermediate", current_time);
    };

    // Expert badge: 200 completed tasks
    if (reputation.total_completed >= 200 && !vector::contains(badges, &constants::badge_expert())) {
        vector::push_back(badges, constants::badge_expert());
        events::emit_badge_earned(reputation.user, constants::badge_expert(), b"Expert", current_time);
    };

    // Master badge: 500 completed tasks
    if (reputation.total_completed >= 500 && !vector::contains(badges, &constants::badge_master())) {
        vector::push_back(badges, constants::badge_master());
        events::emit_badge_earned(reputation.user, constants::badge_master(), b"Master", current_time);
    };

    // Consistent badge: 95%+ acceptance rate with 20+ tasks
    if (reputation.total_completed >= 20) {
        let acceptance_rate = (reputation.total_accepted * 100) / reputation.total_completed;
        if (acceptance_rate >= 95 && !vector::contains(badges, &constants::badge_consistent())) {
            vector::push_back(badges, constants::badge_consistent());
            events::emit_badge_earned(reputation.user, constants::badge_consistent(), b"Consistent", current_time);
        };
    };
}

// === View Functions ===

public fun get_score(reputation: &Reputation): u64 {
    reputation.reputation_score
}

public fun get_user(reputation: &Reputation): address {
    reputation.user
}

public fun get_details(reputation: &Reputation): (
    address, // user
    u64, // total_completed
    u64, // total_accepted
    u64, // total_rejected
    u64, // reputation_score
    u64, // weighted_score
    vector<u8>, // badges
) {
    (
        reputation.user,
        reputation.total_completed,
        reputation.total_accepted,
        reputation.total_rejected,
        reputation.reputation_score,
        reputation.weighted_score,
        reputation.badges,
    )
}

public fun has_badge(reputation: &Reputation, badge_id: u8): bool {
    vector::contains(&reputation.badges, &badge_id)
}
