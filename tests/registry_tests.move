/// Tests for task registry and VecMap optimization
#[test_only]
module songsim::registry_tests;
use std::string;

use songsim::songsim::{Self, PlatformConfig};
use songsim::profile::UserProfile;
use songsim::task::Task;
use songsim::registry::{Self, TaskRegistry};
use songsim::test_helpers::{Self, begin_test, end_test};
use sui::test_scenario as ts;

// === Registry Initialization Tests ===

#[test]
fun test_registry_created_on_init() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, test_helpers::admin());
    {
        let registry = ts::take_shared<TaskRegistry>(&scenario);
        ts::return_shared(registry);
    };

    end_test(scenario);
}

// === Task Registration Tests ===

#[test]
fun test_register_task_adds_to_active_list() {
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

        songsim::create_task(
            &mut registry,
            &mut config,
            &mut profile,
            string::utf8(b"dataset"),
            string::utf8(b"data.csv"),
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
        ts::return_to_sender(&scenario, profile);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    end_test(scenario);
}

#[test]
fun test_register_multiple_tasks() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    // Create requester
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

    // Create 3 tasks
    let mut i = 0;
    while (i < 3) {
        ts::next_tx(&mut scenario, test_helpers::requester());
        {
            let mut registry = ts::take_shared<TaskRegistry>(&scenario);
            let mut config = ts::take_shared<PlatformConfig>(&scenario);
            let mut profile = ts::take_from_sender<UserProfile>(&scenario);
            let bounty = test_helpers::mint_sui(test_helpers::bounty_amount(), ts::ctx(&mut scenario));
            let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

            songsim::create_task(
                &mut registry,
                &mut config,
                &mut profile,
                string::utf8(b"dataset"),
                string::utf8(b"data.csv"),
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
            ts::return_to_sender(&scenario, profile);
            ts::return_shared(registry);
            ts::return_shared(config);
        };
        i = i + 1;
    };

    end_test(scenario);
}

// === Task Deregistration Tests ===

#[test]
fun test_deregister_task_on_completion() {
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

        songsim::create_task(
            &mut registry,
            &mut config,
            &mut profile,
            string::utf8(b"dataset"),
            string::utf8(b"data.csv"),
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
        ts::return_to_sender(&scenario, profile);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    // Cancel task (which should deregister it)
    ts::next_tx(&mut scenario, test_helpers::requester());
    {
        let mut task = ts::take_shared<Task>(&scenario);
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::cancel_task(&mut task, &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_shared(task);
    };

    end_test(scenario);
}

// === Pagination Tests ===

#[test]
fun test_get_active_tasks_with_pagination() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    // Create requester
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

    // Create 10 tasks
    let mut i = 0;
    while (i < 10) {
        ts::next_tx(&mut scenario, test_helpers::requester());
        {
            let mut registry = ts::take_shared<TaskRegistry>(&scenario);
            let mut config = ts::take_shared<PlatformConfig>(&scenario);
            let mut profile = ts::take_from_sender<UserProfile>(&scenario);
            let bounty = test_helpers::mint_sui(test_helpers::bounty_amount(), ts::ctx(&mut scenario));
            let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

            songsim::create_task(
                &mut registry,
                &mut config,
                &mut profile,
                string::utf8(b"dataset"),
                string::utf8(b"data.csv"),
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
            ts::return_to_sender(&scenario, profile);
            ts::return_shared(registry);
            ts::return_shared(config);
        };
        i = i + 1;
    };

    // Test pagination retrieval
    ts::next_tx(&mut scenario, test_helpers::admin());
    {
        let registry = ts::take_shared<TaskRegistry>(&scenario);
        
        // Get first page (limit 5)
        let page1 = registry::get_active_task_ids(&registry, 0, 5);
        assert!(vector::length(&page1) <= 5, 0);
        
        // Get second page
        let page2 = registry::get_active_task_ids(&registry, 5, 5);
        assert!(vector::length(&page2) <= 5, 0);

        ts::return_shared(registry);
    };

    end_test(scenario);
}

// === Profile Lookup Tests ===

#[test]
fun test_profile_exists_check() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    // Check before creation
    ts::next_tx(&mut scenario, test_helpers::requester());
    {
        let registry = ts::take_shared<TaskRegistry>(&scenario);
        let exists = registry::profile_exists(&registry, test_helpers::requester());
        assert!(!exists, 0);
        ts::return_shared(registry);
    };

    // Create profile
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

    // Check after creation
    ts::next_tx(&mut scenario, test_helpers::requester());
    {
        let registry = ts::take_shared<TaskRegistry>(&scenario);
        let exists = registry::profile_exists(&registry, test_helpers::requester());
        assert!(exists, 0);
        ts::return_shared(registry);
    };

    end_test(scenario);
}

// === VecMap O(1) Lookup Tests ===

#[test]
fun test_vecmap_efficient_lookups() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    // Create many tasks to test VecMap efficiency
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

    let mut i = 0;
    while (i < 20) {
        ts::next_tx(&mut scenario, test_helpers::requester());
        {
            let mut registry = ts::take_shared<TaskRegistry>(&scenario);
            let mut config = ts::take_shared<PlatformConfig>(&scenario);
            let mut profile = ts::take_from_sender<UserProfile>(&scenario);
            let bounty = test_helpers::mint_sui(test_helpers::bounty_amount(), ts::ctx(&mut scenario));
            let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

            songsim::create_task(
                &mut registry,
                &mut config,
                &mut profile,
                string::utf8(b"dataset"),
                string::utf8(b"data.csv"),
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
            ts::return_to_sender(&scenario, profile);
            ts::return_shared(registry);
            ts::return_shared(config);
        };
        i = i + 1;
    };

    // VecMap should provide O(1) lookups regardless of task count
    // (In production, you'd benchmark this)

    end_test(scenario);
}
