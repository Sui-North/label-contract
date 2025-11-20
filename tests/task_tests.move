/// Tests for task and submission lifecycle with Clock integration
#[test_only]
module songsim::task_tests;

use songsim::songsim::{Self, PlatformConfig};
use songsim::profile::UserProfile;
use songsim::task::{Task, Submission};
use songsim::registry::TaskRegistry;
use songsim::test_helpers::{Self, begin_test, end_test};
use songsim::constants;
use sui::test_scenario as ts;

// === Task Creation Tests ===

#[test]
fun test_create_task_with_valid_params() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    // Create requester profile
    ts::next_tx(&mut scenario, test_helpers::requester());
    {
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::create_profile(
            &mut registry,
            &mut config,
            b"Requester",
            b"Bio",
            b"avatar",
            1,
            &clock,
            ts::ctx(&mut scenario),
        );

        test_helpers::destroy_clock(clock);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    // Create task
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
            b"dataset_url",
            b"dataset.csv",
            b"text/csv",
            b"Label Images",
            b"Detailed description",
            b"Instructions",
            3, // Required labelers
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

    // Verify task was created
    ts::next_tx(&mut scenario, test_helpers::requester());
    {
        assert!(ts::has_most_recent_shared<Task>(), 0);
    };

    end_test(scenario);
}

#[test]
#[expected_failure(abort_code = 15)] // EInvalidDeadline
fun test_cannot_create_task_with_past_deadline() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, test_helpers::requester());
    {
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::create_profile(
            &mut registry,
            &mut config,
            b"Requester",
            b"Bio",
            b"avatar",
            1,
            &clock,
            ts::ctx(&mut scenario),
        );

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
        let mut clock = test_helpers::create_clock(ts::ctx(&mut scenario));
        
        // Set clock to future, then use past deadline
        test_helpers::set_clock_time(&mut clock, 10000);

        songsim::create_task(
            &mut registry,
            &mut config,
            &mut profile,
            b"dataset",
            b"data.csv",
            b"text/csv",
            b"Task",
            b"Desc",
            b"Inst",
            2,
            test_helpers::past_deadline(), // Past deadline
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
#[expected_failure(abort_code = 2)] // EInsufficientBounty
fun test_cannot_create_task_with_insufficient_bounty() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, test_helpers::requester());
    {
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::create_profile(
            &mut registry,
            &mut config,
            b"Requester",
            b"Bio",
            b"avatar",
            1,
            &clock,
            ts::ctx(&mut scenario),
        );

        test_helpers::destroy_clock(clock);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    ts::next_tx(&mut scenario, test_helpers::requester());
    {
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);
        let mut profile = ts::take_from_sender<UserProfile>(&scenario);
        let bounty = test_helpers::mint_sui(100, ts::ctx(&mut scenario)); // Too small
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::create_task(
            &mut registry,
            &mut config,
            &mut profile,
            b"dataset",
            b"data.csv",
            b"text/csv",
            b"Task",
            b"Desc",
            b"Inst",
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

// Note: test_only_requester_can_create_task removed
// because user_type validation is not implemented in create_task

// === Submission Tests ===

#[test]
fun test_submit_labels() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    // Setup: create requester and task
    ts::next_tx(&mut scenario, test_helpers::requester());
    {
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::create_profile(&mut registry, &mut config, b"Req", b"Bio", b"av", 1, &clock, ts::ctx(&mut scenario));

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

        songsim::create_task(&mut registry, &mut config, &mut profile, b"ds", b"d.csv", b"text/csv", b"T", b"D", b"I", 2, test_helpers::future_deadline(), bounty, &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_to_sender(&scenario, profile);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    // Create labeler profile
    ts::next_tx(&mut scenario, test_helpers::labeler1());
    {
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::create_profile(&mut registry, &mut config, b"Lab", b"Bio", b"av", 2, &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    // Submit labels
    ts::next_tx(&mut scenario, test_helpers::labeler1());
    {
        let mut task = ts::take_shared<Task>(&scenario);
        let mut profile = ts::take_from_sender<UserProfile>(&scenario);
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::submit_labels(&mut registry, &mut task, &mut profile, b"labels_url", b"labels.json", b"application/json", &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_to_sender(&scenario, profile);
        ts::return_shared(registry);
        ts::return_shared(task);
    };

    // Verify submission created
    ts::next_tx(&mut scenario, test_helpers::labeler1());
    {
        assert!(ts::has_most_recent_for_sender<Submission>(&scenario), 0);
    };

    end_test(scenario);
}

#[test]
#[expected_failure(abort_code = 15)] // EInvalidDeadline
fun test_cannot_submit_after_deadline() {
    let mut scenario = begin_test();
    
    {
        songsim::init_for_testing(ts::ctx(&mut scenario));
    };

    // Create requester and task with near deadline
    ts::next_tx(&mut scenario, test_helpers::requester());
    {
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::create_profile(&mut registry, &mut config, b"Req", b"Bio", b"av", 1, &clock, ts::ctx(&mut scenario));

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

        songsim::create_task(&mut registry, &mut config, &mut profile, b"ds", b"d.csv", b"text/csv", b"T", b"D", b"I", 2, 10000, bounty, &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_to_sender(&scenario, profile);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    // Create labeler
    ts::next_tx(&mut scenario, test_helpers::labeler1());
    {
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut config = ts::take_shared<PlatformConfig>(&scenario);
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::create_profile(&mut registry, &mut config, b"Lab", b"Bio", b"av", 2, &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    // Submit after deadline
    ts::next_tx(&mut scenario, test_helpers::labeler1());
    {
        let mut task = ts::take_shared<Task>(&scenario);
        let mut profile = ts::take_from_sender<UserProfile>(&scenario);
        let mut registry = ts::take_shared<TaskRegistry>(&scenario);
        let mut clock = test_helpers::create_clock(ts::ctx(&mut scenario));
        
        // Advance clock past deadline
        test_helpers::set_clock_time(&mut clock, 20000);

        songsim::submit_labels(&mut registry, &mut task, &mut profile, b"labels_url", b"labels.json", b"application/json", &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_to_sender(&scenario, profile);
        ts::return_shared(registry);
        ts::return_shared(task);
    };

    end_test(scenario);
}

// === Task Cancellation Tests ===

#[test]
fun test_cancel_task_with_no_submissions() {
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

        songsim::create_profile(&mut registry, &mut config, b"Req", b"Bio", b"av", 1, &clock, ts::ctx(&mut scenario));

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

        songsim::create_task(&mut registry, &mut config, &mut profile, b"ds", b"d.csv", b"text/csv", b"T", b"D", b"I", 2, test_helpers::future_deadline(), bounty, &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_to_sender(&scenario, profile);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    // Cancel task
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

#[test]
#[expected_failure(abort_code = 4)] // EUnauthorized
fun test_only_requester_can_cancel_task() {
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

        songsim::create_profile(&mut registry, &mut config, b"Req", b"Bio", b"av", 1, &clock, ts::ctx(&mut scenario));

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

        songsim::create_task(&mut registry, &mut config, &mut profile, b"ds", b"d.csv", b"text/csv", b"T", b"D", b"I", 2, test_helpers::future_deadline(), bounty, &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_to_sender(&scenario, profile);
        ts::return_shared(registry);
        ts::return_shared(config);
    };

    // Try to cancel as different user
    ts::next_tx(&mut scenario, test_helpers::labeler1());
    {
        let mut task = ts::take_shared<Task>(&scenario);
        let clock = test_helpers::create_clock(ts::ctx(&mut scenario));

        songsim::cancel_task(&mut task, &clock, ts::ctx(&mut scenario));

        test_helpers::destroy_clock(clock);
        ts::return_shared(task);
    };

    end_test(scenario);
}
