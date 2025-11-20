# Songsim Label - Smart Contract Development Tasks

## Overview

This document tracks the development of Move smart contracts for the Songsim Label decentralized data labeling marketplace on Sui.

## Core Architecture

### Data Structures

- **AdminCap**: Capability object for platform administration
- **UserProfile**: On-chain identity for platform users (requesters and labelers)
- **Task**: NFT representing a labeling task with Walrus blob ID references
- **Submission**: Labeler's work submission with Walrus blob ID
- **Reputation**: On-chain reputation scoring for labelers
- **Consensus**: Voting and validation logic for label quality

---

## M0 - Foundation & Setup ✓

- [x] Scaffold Move project structure
- [x] Define core data structures and types
- [x] Set up test framework

---

## M1 - Functional MVP

### Platform Initialization Module

- [x] Create `AdminCap` capability object
  - [x] Issue on module initialization
  - [x] Transfer to deployer address
- [x] Create platform configuration object

  - [x] Platform fee percentage (5-10%)
  - [x] Fee recipient address
  - [x] Minimum task bounty
  - [x] Other global parameters

- [x] Implement admin functions
  - [x] Update platform fee (requires AdminCap)
  - [x] Update fee recipient (requires AdminCap)
  - [x] Pause/unpause platform (requires AdminCap)
  - [x] Emergency withdrawal (requires AdminCap)

### User Profile Module

- [x] Create `UserProfile` object structure

  - [x] User address (owner)
  - [x] Display name (optional)
  - [x] Bio/description (optional)
  - [x] Avatar Walrus blob ID (optional)
  - [x] User type (requester, labeler, or both)
  - [x] Registration timestamp
  - [x] Total tasks created (for requesters)
  - [x] Total submissions (for labelers)
  - [x] Linked reputation object ID

- [x] Implement profile creation function

  - [x] Create new profile for user
  - [x] Initialize empty reputation
  - [x] Emit ProfileCreated event
  - [x] Return profile object

- [x] Implement profile update functions

  - [x] Update display name
  - [x] Update bio
  - [x] Update avatar blob ID
  - [x] Update user type preferences

- [x] Implement profile query functions
  - [x] Get profile by address
  - [x] Check if user has profile
  - [ ] List profiles (paginated) _(deferred to M2)_

### Task Management Module

- [x] Create `Task` object structure

  - [x] Task ID (unique identifier)
  - [x] Requester address
  - [x] Dataset Walrus blob ID
  - [x] Task metadata (type, instructions, requirements)
  - [x] Bounty amount (in SUI)
  - [x] Status (open, in_progress, completed, cancelled)
  - [x] Required number of labelers
  - [x] Deadline timestamp
  - [x] Created timestamp

- [x] Implement task creation function

  - [x] Accept bounty stake in SUI
  - [x] Validate blob ID format
  - [x] Emit task creation event
  - [x] Return Task NFT to requester

- [x] Implement task query functions
  - [x] Get task by ID
  - [ ] List open tasks _(deferred to M2)_
  - [ ] Get tasks by requester _(deferred to M2)_

### Submission Module

- [x] Create `Submission` object structure

  - [x] Submission ID
  - [x] Task ID reference
  - [x] Labeler address
  - [x] Result Walrus blob ID
  - [x] Submission timestamp
  - [x] Status (pending, accepted, rejected)

- [x] Implement submission function

  - [x] Validate task is open
  - [x] Verify labeler eligibility
  - [x] Store blob ID reference
  - [x] Update task status
  - [x] Emit submission event

- [x] Implement submission query functions
  - [x] Get submissions by task
  - [x] Get submissions by labeler

### Consensus Module

- [x] Create `ConsensusResult` object structure

  - [x] Task ID reference
  - [x] Accepted submissions list
  - [x] Rejected submissions list
  - [x] Consensus timestamp

- [x] Implement majority voting consensus

  - [x] Compare submission blob IDs
  - [x] Calculate majority threshold
  - [x] Determine winning submissions
  - [x] Handle tie-breaking logic

- [x] Implement consensus finalization
  - [x] Validate minimum submissions received
  - [x] Execute consensus algorithm
  - [x] Update task status to completed
  - [x] Emit consensus event

### Payout Module

- [x] Implement payout distribution function

  - [x] Validate consensus is finalized
  - [x] Calculate platform fee (5-10% of bounty)
  - [x] Deduct platform fee from total bounty
  - [x] Calculate per-labeler payout from remaining bounty
  - [x] Transfer platform fee to fee recipient
  - [x] Transfer SUI to accepted labelers
  - [x] Refund requester if task fails
  - [x] Emit payout events (including fee amount)

- [x] Implement bounty management
  - [x] Lock bounty on task creation
  - [x] Unlock bounty on completion/cancellation
  - [x] Handle partial payouts

### Reputation Module

- [x] Create `Reputation` object structure

  - [x] Labeler address
  - [x] Total tasks completed
  - [x] Acceptance rate
  - [x] Average quality score
  - [x] Reputation level

- [x] Implement reputation update functions

  - [x] Increment on successful submission
  - [x] Decrement on rejected submission
  - [x] Calculate weighted reputation score

- [x] Implement reputation query functions
  - [x] Get reputation by address
  - [ ] Get top labelers _(deferred to M2)_

### Events & Errors

- [x] Define event types

  - [x] ProfileCreated
  - [x] ProfileUpdated
  - [x] TaskCreated
  - [x] SubmissionReceived
  - [x] ConsensusFinalized
  - [x] PayoutDistributed
  - [x] PlatformFeeCollected
  - [x] ReputationUpdated
  - [x] PlatformConfigUpdated

- [x] Define error codes
  - [x] Invalid blob ID
  - [x] Insufficient bounty
  - [x] Task not found
  - [x] Unauthorized access
  - [x] Invalid task status
  - [x] Consensus threshold not met
  - [x] Profile not found
  - [x] Profile already exists
  - [x] Not admin (missing AdminCap)
  - [x] Invalid fee percentage
  - [x] Platform paused

### Testing

- [x] Unit tests for platform initialization
- [x] Unit tests for AdminCap operations
- [x] Unit tests for profile creation and updates
- [x] Unit tests for task creation
- [x] Unit tests for submission flow
- [x] Unit tests for consensus logic
- [x] Unit tests for payout distribution with platform fee
- [x] Unit tests for reputation updates
- [x] Integration tests for full task lifecycle
- [x] Edge case tests (ties, failures, timeouts)
- [x] Security tests for admin-only functions

**Test Coverage Summary:**

- ✅ 18 comprehensive test cases implemented in `tests/songsim_tests.move`
- ✅ All tests passing (18/18)
- ✅ Test coverage includes:
  - Platform initialization and admin operations
  - Profile management (creation, updates, authorization)
  - Task lifecycle (creation, validation, cancellation)
  - Submission workflow
  - Full consensus and payout integration
  - Reputation scoring (acceptance/rejection scenarios)
  - Error conditions and unauthorized access
- ⚠️ Note: `test_refund_failed_task` skipped (requires clock simulation for deadline testing)

### Documentation

- [ ] Contract API documentation
- [ ] Function parameter specifications
- [ ] Event schema documentation
- [ ] Deployment guide for testnet

---

## M2 - Quality & Advanced Features ✅

### Enhanced Reputation

- [x] Implement weighted reputation scoring
- [x] Add reputation decay over time
- [x] Badge/achievement system (on-chain)
  - [x] Novice badge (10 tasks)
  - [x] Intermediate badge (50 tasks)
  - [x] Expert badge (200 tasks)
  - [x] Master badge (500 tasks)
  - [x] Consistent badge (95%+ acceptance rate)

### Dispute Resolution

- [x] Create dispute object structure
- [x] Implement dispute creation
- [x] Add dispute voting mechanism
- [x] Implement dispute resolution payouts (admin-controlled)

### Advanced Consensus

- [x] Weighted voting by reputation
- [x] Multi-tier consensus implementation
  - [x] `finalize_consensus_weighted` function
  - [x] Reputation-based voting power (0-10 scale)
  - [x] 51% weighted majority threshold
- [ ] Nautilus TEE result verification hooks _(deferred to future)_

### Prize Pools

- [x] Create prize pool object
- [x] Implement pool funding mechanism
- [x] Implement winner selection logic
- [x] Distribute prizes based on leaderboard

**M2 Implementation Summary:**

- ✅ **Enhanced Reputation System**

  - Weighted scoring based on task difficulty (1-10 scale)
  - Automatic reputation decay after 30 days of inactivity
  - 5 on-chain badge types with automatic awarding
  - Tracks `last_activity`, `weighted_score`, and `badges` vector

- ✅ **Dispute Resolution Module**

  - Dispute creation with reason tracking
  - Community voting system (votes_for/votes_against)
  - Admin-controlled resolution with written resolution
  - Voter tracking to prevent double-voting
  - Full event emission for transparency

- ✅ **Advanced Consensus**

  - `finalize_consensus_weighted()` function
  - Reputation scores converted to voting power (0-10)
  - Minimum 1 vote per participant
  - 51% weighted majority for acceptance
  - Separate from basic consensus for task complexity tiers

- ✅ **Prize Pool System**
  - Prize pool creation with SUI funding
  - Participant tracking and eligibility
  - Time-based pool lifecycle (start_time, end_time)
  - Minimum submission requirements
  - Admin-controlled winner distribution
  - Equal prize distribution among winners

**New Data Structures:**

- `Badge` - Achievement tracking
- `Dispute` - Dispute resolution
- `PrizePool` - Competitive prize distributions
- Enhanced `Reputation` with decay and badges
- Extended `TaskRegistry` with disputes and prize pools

**New Constants:**

- `REPUTATION_DECAY_PERIOD` - 30 days
- `REPUTATION_DECAY_AMOUNT` - 10 points
- `BADGE_NOVICE`, `BADGE_INTERMEDIATE`, `BADGE_EXPERT`, `BADGE_MASTER`, `BADGE_CONSISTENT`

**New Events:**

- `BadgeEarned`, `DisputeCreated`, `DisputeVoted`, `DisputeResolved`
- `PrizePoolCreated`, `PrizePoolWinner`

---

## M3 - Tokenomics & DAO

### $SLT Token

- [ ] Design token economics
- [ ] Implement token minting
- [ ] Token-based payments
- [ ] Staking mechanisms

### Governance

- [ ] Proposal creation
- [ ] Voting mechanisms
- [ ] Treasury management
- [ ] Parameter updates via governance

---

## Notes

### Current Priorities

1. Complete M1 core modules
2. Establish comprehensive test coverage
3. Deploy to testnet and validate

### Dependencies

- Sui Move framework
- Walrus blob ID format specification
- Seal encryption integration (handled client-side)

### Security Considerations

- Blob ID validation to prevent manipulation
- Reentrancy protection on payouts
- Access control on admin functions
- Integer overflow/underflow checks
- Proper error handling throughout
