# Songsim Smart Contracts

The core smart contracts for the Songsim Label decentralized data labeling marketplace, built on the Sui blockchain.

## Overview

This package (`songsim`) contains the Move smart contracts that power the Songsim Label platform. It handles the entire lifecycle of data labeling tasks, from creation and funding to submission, consensus, and payout distribution.

**Key Features:**
- **Automated Escrow**: Bounties are locked on-chain and distributed automatically upon consensus.
- **Multi-Labeler Consensus**: Supports multiple labelers per task with quorum-based validation.
- **Reputation System**: Tracks labeler performance and quality scores.
- **Anti-Sybil Staking**: Requires staking for participation to prevent spam.
- **Walrus Integration**: Stores large datasets and label submissions off-chain.
- **Seal Encryption**: Optional end-to-end encryption for sensitive data.

---

## Project Structure

```
songsim/
├── sources/               # Move contract modules
│   ├── songsim.move      # Platform initialization & admin
│   ├── profile.move      # User profiles
│   ├── task.move         # Task management
│   ├── consensus.move    # Consensus logic
│   ├── reputation.move   # Reputation system
│   ├── staking.move      # Staking mechanics
│   └── ...               # (15 modules total)
├── tests/                 # Unit and integration tests
├── scripts/               # Deployment and upgrade scripts
├── Move.toml             # Package manifest
└── deployment.json       # Generated deployment addresses
```

---

## Prerequisites

- **Sui CLI**: [Install Guide](https://docs.sui.io/build/install)
- **Git**: Version control

---

## Build & Test

### Build Contracts

```bash
sui move build
```

### Run Tests

The test suite covers all core functionality, including happy paths and edge cases.

```bash
sui move test
```

**Current Status**: 36/36 tests passing.

---

## Deployment

We provide automated scripts for deployment and upgrades.

### Deploy to Testnet

**Windows:**
```powershell
.\scripts\deploy.ps1
```

**Linux/Mac:**
```bash
chmod +x ./scripts/deploy.sh
./scripts/deploy.sh
```

**What the script does:**
1. Builds and tests the contracts.
2. Deploys the package to the configured environment (default: testnet).
3. Initializes the platform configuration.
4. Saves the deployment addresses to `deployment.json`.
5. Generates a `.env.local.template` for the frontend.

### Upgrades

To upgrade the package (e.g., to add new features or fix bugs):

```powershell
.\scripts\upgrade.ps1 -NewVersion "1.1.0"
```

---

## Architecture

### Core Modules

| Module | Description |
|--------|-------------|
| `songsim` | Entry point for platform initialization and admin controls. |
| `profile` | Manages user identities, avatars (Walrus), and roles. |
| `task` | Handles task creation, bounty escrow, and state transitions. |
| `consensus` | Implements the logic for validating submissions and determining the "truth". |
| `reputation` | Updates user scores based on consensus results. |
| `registry` | Indexer-friendly storage for discovering tasks and profiles. |

### Data Flow

1.  **Task Creation**: Requester calls `create_task`, locking SUI bounty in the `Task` object. Dataset is stored on Walrus.
2.  **Submission**: Labelers submit results (stored on Walrus) via `submit_labels`.
3.  **Consensus**: Requester triggers `finalize_consensus`. The contract compares submissions.
4.  **Payout**:
    -   **Consensus Reached**: Matching labelers are paid; reputation increases.
    -   **No Consensus**: Bounty may be refunded or held for dispute (future).

---

## Security

-   **AdminCap**: Critical administrative functions (pausing, upgrading) are protected by an `AdminCap`.
-   **Escrow**: Funds are held in a shared object (`Task`) and can only be released by the contract logic.
-   **Circuit Breaker**: Emergency pause functionality is available in case of critical bugs.
-   **Staking**: Labelers must stake SUI to participate, disincentivizing malicious behavior.

---

## Integration

For frontend integration details, see the [Frontend README](../songsim-label/README.md).
