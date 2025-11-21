/// Tests for platform initialization and admin functions
#[test_only]
module songsim::platform_tests;
use std::string;

use songsim::songsim::{Self, AdminCap, PlatformConfig};
use songsim::registry::{Self as registry, TaskRegistry};
use songsim::profile::UserProfile;
use songsim::test_helpers::{Self, begin_test, end_test};
use songsim::constants;
use sui::test_scenario as ts;
use sui::object;

// === Platform Initialization Tests ===

#[test]
fun test_init_creates_admin_cap_and_config() {
    let mut scenario = begin_test();
    
    // Initialize platform
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    // Admin should receive AdminCap
    ts::next_tx(&mut scenario, test_helpers::admin());
    {
        assert!(ts::has_most_recent_for_sender<AdminCap>(&scenario), 0);
    };

    // PlatformConfig should be shared
    ts::next_tx(&mut scenario, test_helpers::admin());
    {
        let config = ts::take_shared<PlatformConfig>(&scenario);
        ts::return_shared(config);
    };

    // TaskRegistry should be shared
    ts::next_tx(&mut scenario, test_helpers::admin());
    {
        let registry = ts::take_shared<TaskRegistry>(&scenario);
        ts::return_shared(registry);
    };

    end_test(scenario);
}

// === Admin Functions Tests ===

#[test]
fun test_update_platform_fee() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, test_helpers::admin());
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);

        songsim::update_platform_fee(&admin_cap, &mut config, 750);

        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };

    end_test(scenario);
}

#[test]
#[expected_failure(abort_code = 10)] // EInvalidFeePercentage
fun test_update_platform_fee_fails_if_too_high() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, test_helpers::admin());
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);

        // Try to set fee above 10%
        songsim::update_platform_fee(&admin_cap, &mut config, 1500);

        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };

    end_test(scenario);
}

#[test]
fun test_update_fee_recipient() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, test_helpers::admin());
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);

        songsim::update_fee_recipient(&admin_cap, &mut config, test_helpers::fee_recipient());

        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };

    end_test(scenario);
}

#[test]
fun test_pause_unpause_platform() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, test_helpers::admin());
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);

        // Pause platform
        songsim::set_platform_paused(&admin_cap, &mut config, true);

        // Unpause platform
        songsim::set_platform_paused(&admin_cap, &mut config, false);

        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };

    end_test(scenario);
}

#[test]
fun test_update_min_bounty() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, test_helpers::admin());
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);

        songsim::update_min_bounty(&admin_cap, &mut config, 2_000_000);

        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };

    end_test(scenario);
}

#[test]
#[expected_failure(abort_code = 11)] // EPlatformPaused
fun test_platform_paused_prevents_task_creation() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    // Create profile first
    ts::next_tx(&mut scenario, test_helpers::requester());
    {
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::create_profile(
            &mut registry,
            &mut config,
            string::utf8(b"Requester"),
            string::utf8(b"Bio"),
            string::utf8(b"avatar"),
            1,
            &clock,
            ts::ctx(&mut scenario),
        );

        test_helpers::destroy_clock(clock);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    // Pause platform
    ts::next_tx(&mut scenario, test_helpers::admin());
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);

        songsim::set_platform_paused(&admin_cap, &mut config, true);

        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };

    // Try to create task while paused
    ts::next_tx(&mut scenario, test_helpers::requester());
    {
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);
        let profile_addr = registry::get_profile_address(&registry, test_helpers::requester());
        let mut profile = ts::take_shared_by_id<UserProfile>(&scenario, object::id_from_address(profile_addr));
        let bounty = test_helpers::mint_sui(test_helpers::bounty_amount(), ts::ctx(&mut scenario));
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::create_task(
            &mut registry,
            &mut config,
            &mut profile,
            string::utf8(b"dataset"),
            string::utf8(b"dataset.csv"),
            string::utf8(b"text/csv"),
            string::utf8(b"Task"),
            string::utf8(b"Desc"),
            string::utf8(b"Inst"),
            2,
            test_helpers::future_deadline(),
            bounty,
            &clock,
            ts::ctx(&mut scenario),
        );

        test_helpers::destroy_clock(clock);
        ts::return_shared(profile);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    end_test(scenario);
}
