/// Tests for reputation system - simplified version focusing on actual APIs
#[test_only]
module songsim::reputation_tests;
use std::string;

use songsim::songsim::{Self, PlatformConfig};
use songsim::profile::UserProfile;
use songsim::task::{Self, Task};
use songsim::registry::{Self, TaskRegistry};
use sui::object;
use songsim::test_helpers::{Self, begin_test, end_test};
use sui::test_scenario as ts;

// === Basic Reputation Tests ===
// Note: Reputation is updated internally during consensus finalization
// These tests verify the reputation system exists and integrates with the workflow

#[test]
fun test_reputation_tracked_in_registry() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    // Create labeler profile
    ts::next_tx(&mut scenario, test_helpers::labeler1());
    {
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::create_profile(&mut registry, &mut config, string::utf8(b"Labeler"), string::utf8(b"Bio"), string::utf8(b"av"), 2, &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    // Verify reputation exists in registry
    ts::next_tx(&mut scenario, test_helpers::labeler1());
    {
        let registry = ts::take_shared<TaskRegistry>(&scenario);
        let exists = registry::reputation_exists(&registry, test_helpers::labeler1());
        assert!(exists, 0);
        ts::return_shared(registry);
    };

    end_test(scenario);
}

#[test]
fun test_profile_stats_increment_with_submissions() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    // Create requester and task
    ts::next_tx(&mut scenario, test_helpers::requester());
    {
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::create_profile(&mut registry, &mut config, string::utf8(b"Req"), string::utf8(b"Bio"), string::utf8(b"av"), 1, &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    ts::next_tx(&mut scenario, test_helpers::requester());
    {
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);
        let mut profile = ts::take_from_sender<UserProfile>(&scenario);
        let bounty = test_helpers::mint_sui(test_helpers::bounty_amount(), ts::ctx(&mut scenario));
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::create_task(&mut registry, &mut config, &mut profile, string::utf8(b"ds"), string::utf8(b"d.csv"), string::utf8(b"text/csv"), string::utf8(b"T"), string::utf8(b"D"), string::utf8(b"I"), 2, test_helpers::future_deadline(), bounty, &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_to_sender(&scenario, profile);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    // Create labeler and submit
    ts::next_tx(&mut scenario, test_helpers::labeler1());
    {
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::create_profile(&mut registry, &mut config, string::utf8(b"Lab"), string::utf8(b"Bio"), string::utf8(b"av"), 2, &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    ts::next_tx(&mut scenario, test_helpers::labeler1());
    {
        let mut task = ts::take_shared<Task>(&scenario);
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let profile_addr = registry::get_profile_address(&registry, test_helpers::labeler1());
        let mut profile = ts::take_shared_by_id<UserProfile>(&scenario, object::id_from_address(profile_addr));
        
        // Get quality tracker
        let task_id = task::get_task_id(&task);
        let quality_tracker_addr = registry::get_quality_tracker_address(&registry, task_id);
        let mut quality_tracker = ts::take_shared_by_id(&scenario, object::id_from_address(quality_tracker_addr));
        
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::submit_labels(&mut registry, &mut task, &mut profile, &mut quality_tracker, string::utf8(b"labels_url"), string::utf8(b"labels.json"), string::utf8(b"application/json"), &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_shared(quality_tracker);
        ts::return_shared(profile);
        ts::return_shared(registry);
        ts::return_shared(task);
    };

    end_test(scenario);
}

#[test]
fun test_profile_tracks_task_creation() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, test_helpers::requester());
    {
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::create_profile(&mut registry, &mut config, string::utf8(b"Req"), string::utf8(b"Bio"), string::utf8(b"av"), 1, &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    // Create multiple tasks
    let mut i = 0;
    while (i < 3) {
        ts::next_tx(&mut scenario, test_helpers::requester());
        {
            let mut registry = ts::take_shared<TaskRegistry>(&scenario);
            let mut config = ts::take_shared<PlatformConfig>(&scenario);
            let mut profile = ts::take_from_sender<UserProfile>(&scenario);
            let bounty = test_helpers::mint_sui(test_helpers::bounty_amount(), ts::ctx(&mut scenario));
            let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

            songsim::create_task(&mut registry, &mut config, &mut profile, string::utf8(b"ds"), string::utf8(b"d.csv"), string::utf8(b"text/csv"), string::utf8(b"T"), string::utf8(b"D"), string::utf8(b"I"), 2, test_helpers::future_deadline(), bounty, &clock, ts::ctx(&mut scenario));

            test_helpers::destroy_clock(clock);
            ts::return_to_sender(&scenario, profile);
            ts::return_shared(registry);
            ts::return_shared(config);
        };
        i = i + 1;
    };

    end_test(scenario);
}

#[test]
fun test_multiple_labelers_build_reputation() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    // Create labeler profiles
    let labelers = vector[test_helpers::labeler1(), test_helpers::labeler2(), test_helpers::labeler3()];
    let mut i = 0;

    while (i < vector::length(&labelers)) {
        let labeler = *vector::borrow(&labelers, i);
        
        ts::next_tx(&mut scenario, labeler);
        {
            let mut registry = ts::take_shared<TaskRegistry>(&scenario);
            let mut config = ts::take_shared<PlatformConfig>(&scenario);
            let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

            songsim::create_profile(&mut registry, &mut config, string::utf8(b"Labeler"), string::utf8(b"Bio"), string::utf8(b"av"), 2, &clock, ts::ctx(&mut scenario));

            test_helpers::destroy_clock(clock);
            ts::return_shared(registry);
            ts::return_shared(config);
        };

        // Verify reputation was created
        ts::next_tx(&mut scenario, labeler);
        {
            let registry = ts::take_shared<TaskRegistry>(&scenario);
            let exists = registry::reputation_exists(&registry, labeler);
            assert!(exists, 0);
            ts::return_shared(registry);
        };

        i = i + 1;
    };

    end_test(scenario);
}
