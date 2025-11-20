/// Module: migration
/// Handles package upgrades and data migration without losing user data
/// Uses Sui's versioning pattern with u64 version tracking
module songsim::migration;

use sui::clock::{Self, Clock};
use sui::package::{Self, UpgradeCap};
use songsim::constants;

/// Migration state tracker (shared object)
public struct MigrationState has key {
    id: UID,
    current_version: u64,
    last_migration_at: u64,
    migration_count: u64,
    is_migrating: bool, // Lock during multi-tx migrations
}

/// Version compatibility info
public struct VersionInfo has copy, drop, store {
    version: u64,
    compatible_from: u64, // Minimum compatible version
    description: vector<u8>,
}

// === Version Constants ===

const VERSION_1_0_0: u64 = 1;
const CURRENT_VERSION: u64 = 1;
const MIGRATION_SENTINEL: u64 = 18446744073709551615; // U64_MAX

// === Initialization ===

/// Create migration state during platform init
public(package) fun create_migration_state(ctx: &mut TxContext): MigrationState {
    MigrationState {
        id: object::new(ctx),
        current_version: CURRENT_VERSION,
        last_migration_at: 0,
        migration_count: 0,
        is_migrating: false,
    }
}

/// Create and share migration state (called from main init)
public fun create_and_share(ctx: &mut TxContext) {
    let state = create_migration_state(ctx);
    transfer::share_object(state);
}

// === Version Management ===

/// Get current platform version
public fun get_current_version(state: &MigrationState): u64 {
    state.current_version
}

/// Check if platform is currently migrating
public fun is_migrating(state: &MigrationState): bool {
    state.is_migrating
}

/// Validate version compatibility
public fun validate_version(state: &MigrationState, min_version: u64) {
    assert!(
        state.current_version >= min_version,
        constants::e_invalid_upgrade()
    );
    assert!(!state.is_migrating, constants::e_subsystem_paused());
}

// === Migration Functions (Package Only) ===

/// Start migration process - locks platform
/// Called from main module with AdminCap check
public(package) fun begin_migration(
    state: &mut MigrationState,
    clock: &Clock,
) {
    assert!(!state.is_migrating, constants::e_subsystem_paused());
    
    state.is_migrating = true;
    state.last_migration_at = clock::timestamp_ms(clock);
    state.current_version = MIGRATION_SENTINEL; // Lock version
}

/// Complete migration - unlocks platform with new version
public(package) fun complete_migration(
    state: &mut MigrationState,
    new_version: u64,
) {
    assert!(state.is_migrating, constants::e_invalid_upgrade());
    assert!(new_version > CURRENT_VERSION, constants::e_invalid_upgrade());
    
    state.current_version = new_version;
    state.is_migrating = false;
    state.migration_count = state.migration_count + 1;
}

/// Rollback migration on failure
public(package) fun rollback_migration(
    state: &mut MigrationState,
) {
    assert!(state.is_migrating, constants::e_invalid_upgrade());
    
    state.current_version = CURRENT_VERSION;
    state.is_migrating = false;
}

// === Upgrade Policy Management ===

/// Make package immutable (disallow further upgrades)
/// WARNING: This is irreversible!
public(package) fun make_package_immutable(
    upgrade_cap: UpgradeCap,
) {
    package::make_immutable(upgrade_cap);
}

// === Migration Helpers ===

/// Check if version is sentinel (migration in progress)
public fun is_sentinel_version(state: &MigrationState): bool {
    state.current_version == MIGRATION_SENTINEL
}

/// Get migration history info
public fun get_migration_info(state: &MigrationState): (u64, u64, u64) {
    (
        state.current_version,
        state.last_migration_at,
        state.migration_count
    )
}

// === Version Info Helpers ===

/// Create version info for documentation
public fun create_version_info(
    version: u64,
    compatible_from: u64,
    description: vector<u8>,
): VersionInfo {
    VersionInfo {
        version,
        compatible_from,
        description,
    }
}

/// Get version info details
public fun get_version_details(info: &VersionInfo): (u64, u64, vector<u8>) {
    (info.version, info.compatible_from, info.description)
}

// === Constants Accessors ===

public fun version_1_0_0(): u64 { VERSION_1_0_0 }
public fun current_version(): u64 { CURRENT_VERSION }
public fun migration_sentinel(): u64 { MIGRATION_SENTINEL }
