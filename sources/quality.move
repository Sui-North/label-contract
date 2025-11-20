/// Module: quality
/// Quality metrics and validation for submissions
module songsim::quality;

use sui::vec_map::{Self, VecMap};
use songsim::task::{Self, Submission};

/// Quality metrics for a submission
public struct QualityMetrics has store, drop, copy {
    inter_labeler_agreement: u64, // Percentage 0-100
    completion_time: u64, // Milliseconds
    revision_count: u64,
    flagged_by_peers: u64,
}

/// Submission quality tracking
public struct QualityTracker has key, store {
    id: UID,
    task_id: u64,
    metrics: VecMap<u64, QualityMetrics>, // submission_id -> metrics
}

// === Quality Functions ===

/// Create quality tracker for a task
public(package) fun create_tracker(
    task_id: u64,
    ctx: &mut TxContext,
): QualityTracker {
    QualityTracker {
        id: object::new(ctx),
        task_id,
        metrics: vec_map::empty(),
    }
}

/// Record quality metrics for a submission
public(package) fun record_metrics(
    tracker: &mut QualityTracker,
    submission_id: u64,
    completion_time: u64,
) {
    let metrics = QualityMetrics {
        inter_labeler_agreement: 0, // Will be calculated during consensus
        completion_time,
        revision_count: 0,
        flagged_by_peers: 0,
    };
    
    vec_map::insert(&mut tracker.metrics, submission_id, metrics);
}

/// Calculate inter-labeler agreement score
public fun calculate_agreement_score(
    submissions: &vector<Submission>,
): u64 {
    let count = vector::length(submissions);
    if (count < 2) {
        return 100 // Single submission = 100% agreement
    };
    
    // Compare blob IDs for similarity (simplified version)
    let first_result = task::get_submission_result_url(vector::borrow(submissions, 0));
    let mut matches = 0;
    let mut i = 1;
    
    while (i < count) {
        let submission = vector::borrow(submissions, i);
        if (task::get_submission_result_url(submission) == first_result) {
            matches = matches + 1;
        };
        i = i + 1;
    };
    
    // Calculate percentage (matches / total comparisons)
    (matches * 100) / (count - 1)
}

/// Update agreement score after consensus
public(package) fun update_agreement_score(
    tracker: &mut QualityTracker,
    submission_id: u64,
    agreement_score: u64,
) {
    if (vec_map::contains(&tracker.metrics, &submission_id)) {
        let metrics = vec_map::get_mut(&mut tracker.metrics, &submission_id);
        metrics.inter_labeler_agreement = agreement_score;
    };
}

/// Flag submission by peer
public fun flag_submission(
    tracker: &mut QualityTracker,
    submission_id: u64,
    ctx: &TxContext,
) {
    if (vec_map::contains(&tracker.metrics, &submission_id)) {
        let metrics = vec_map::get_mut(&mut tracker.metrics, &submission_id);
        metrics.flagged_by_peers = metrics.flagged_by_peers + 1;
    };
}

// === Query Functions ===

public fun get_metrics(
    tracker: &QualityTracker,
    submission_id: u64,
): QualityMetrics {
    *vec_map::get(&tracker.metrics, &submission_id)
}

public fun get_completion_time(metrics: &QualityMetrics): u64 {
    metrics.completion_time
}

public fun get_agreement_score(metrics: &QualityMetrics): u64 {
    metrics.inter_labeler_agreement
}

public fun get_flag_count(metrics: &QualityMetrics): u64 {
    metrics.flagged_by_peers
}

public fun has_metrics(tracker: &QualityTracker, submission_id: u64): bool {
    vec_map::contains(&tracker.metrics, &submission_id)
}
