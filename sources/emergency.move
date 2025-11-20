/// Module: emergency
/// Emergency pause circuit breaker for platform safety
module songsim::emergency;

use std::string::String;
use sui::clock::{Self, Clock};
use songsim::constants;
use songsim::events;
use songsim::songsim::AdminCap;

/// Subsystem identifiers
const SUBSYSTEM_TASKS: u8 = 0;
const SUBSYSTEM_SUBMISSIONS: u8 = 1;
const SUBSYSTEM_PAYOUTS: u8 = 2;

/// Emergency pause state
public struct EmergencyState has key {
    id: UID,
    task_creation_paused: bool,
    submissions_paused: bool,
    payouts_paused: bool,
    pause_reason: String,
    paused_at: u64,
}

// === Initialization ===

/// Create emergency state (called during platform init)
public(package) fun create_emergency_state(ctx: &mut TxContext): EmergencyState {
    EmergencyState {
        id: object::new(ctx),
        task_creation_paused: false,
        submissions_paused: false,
        payouts_paused: false,
        pause_reason: std::string::utf8(b""),
        paused_at: 0,
    }
}

// === Emergency Functions ===

/// Pause a specific subsystem
public fun emergency_pause_subsystem(
    emergency_state: &mut EmergencyState,
    subsystem: u8,
    reason: String,
    _admin_cap: &AdminCap,
    clock: &Clock,
) {
    assert!(subsystem <= SUBSYSTEM_PAYOUTS, constants::e_invalid_subsystem());
    
    let paused_at = clock::timestamp_ms(clock);
    
    if (subsystem == SUBSYSTEM_TASKS) {
        emergency_state.task_creation_paused = true;
    } else if (subsystem == SUBSYSTEM_SUBMISSIONS) {
        emergency_state.submissions_paused = true;
    } else if (subsystem == SUBSYSTEM_PAYOUTS) {
        emergency_state.payouts_paused = true;
    };
    
    emergency_state.pause_reason = reason;
    emergency_state.paused_at = paused_at;
    
    events::emit_emergency_pause_activated(subsystem, *std::string::bytes(&reason), paused_at);
}

/// Resume a specific subsystem
public fun emergency_resume_subsystem(
    emergency_state: &mut EmergencyState,
    subsystem: u8,
    _admin_cap: &AdminCap,
    clock: &Clock,
) {
    assert!(subsystem <= SUBSYSTEM_PAYOUTS, constants::e_invalid_subsystem());
    
    let resumed_at = clock::timestamp_ms(clock);
    
    if (subsystem == SUBSYSTEM_TASKS) {
        emergency_state.task_creation_paused = false;
    } else if (subsystem == SUBSYSTEM_SUBMISSIONS) {
        emergency_state.submissions_paused = false;
    } else if (subsystem == SUBSYSTEM_PAYOUTS) {
        emergency_state.payouts_paused = false;
    };
    
    // Clear reason if all systems resumed
    if (!emergency_state.task_creation_paused && 
        !emergency_state.submissions_paused && 
        !emergency_state.payouts_paused) {
        emergency_state.pause_reason = std::string::utf8(b"");
        emergency_state.paused_at = 0;
    };
    
    events::emit_emergency_pause_deactivated(subsystem, resumed_at);
}

/// Pause all subsystems
public fun emergency_pause_all(
    emergency_state: &mut EmergencyState,
    reason: String,
    admin_cap: &AdminCap,
    clock: &Clock,
) {
    emergency_pause_subsystem(emergency_state, SUBSYSTEM_TASKS, reason, admin_cap, clock);
    emergency_pause_subsystem(emergency_state, SUBSYSTEM_SUBMISSIONS, reason, admin_cap, clock);
    emergency_pause_subsystem(emergency_state, SUBSYSTEM_PAYOUTS, reason, admin_cap, clock);
}

/// Resume all subsystems
public fun emergency_resume_all(
    emergency_state: &mut EmergencyState,
    admin_cap: &AdminCap,
    clock: &Clock,
) {
    emergency_resume_subsystem(emergency_state, SUBSYSTEM_TASKS, admin_cap, clock);
    emergency_resume_subsystem(emergency_state, SUBSYSTEM_SUBMISSIONS, admin_cap, clock);
    emergency_resume_subsystem(emergency_state, SUBSYSTEM_PAYOUTS, admin_cap, clock);
}

// === Validation Functions ===

/// Check if task creation is paused
public fun assert_tasks_not_paused(emergency_state: &EmergencyState) {
    assert!(!emergency_state.task_creation_paused, constants::e_subsystem_paused());
}

/// Check if submissions are paused
public fun assert_submissions_not_paused(emergency_state: &EmergencyState) {
    assert!(!emergency_state.submissions_paused, constants::e_subsystem_paused());
}

/// Check if payouts are paused
public fun assert_payouts_not_paused(emergency_state: &EmergencyState) {
    assert!(!emergency_state.payouts_paused, constants::e_subsystem_paused());
}

// === Query Functions ===

public fun is_task_creation_paused(emergency_state: &EmergencyState): bool {
    emergency_state.task_creation_paused
}

public fun is_submissions_paused(emergency_state: &EmergencyState): bool {
    emergency_state.submissions_paused
}

public fun is_payouts_paused(emergency_state: &EmergencyState): bool {
    emergency_state.payouts_paused
}

public fun get_pause_reason(emergency_state: &EmergencyState): &String {
    &emergency_state.pause_reason
}

public fun get_paused_at(emergency_state: &EmergencyState): u64 {
    emergency_state.paused_at
}

public fun subsystem_tasks(): u8 { SUBSYSTEM_TASKS }

public fun subsystem_submissions(): u8 { SUBSYSTEM_SUBMISSIONS }

public fun subsystem_payouts(): u8 { SUBSYSTEM_PAYOUTS }

