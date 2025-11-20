# Songsim Smart Contract - Deployment Guide

## Prerequisites

- Sui CLI installed and configured
- Sui wallet with testnet SUI tokens
- Git (for version control)

---

## Environment Setup

### 1. Install Sui CLI

```bash
# macOS/Linux
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install --locked --git https://github.com/MystenLabs/sui.git --branch testnet sui

# Windows
# Download from: https://github.com/MystenLabs/sui/releases
```

### 2. Configure Sui Wallet

```bash
# Initialize wallet
sui client

# Get testnet tokens from faucet
sui client faucet

# Check balance
sui client gas
```

### 3. Verify Installation

```bash
sui --version
sui move --version
```

---

## Local Development

### Build Contract

```bash
cd songsim
sui move build
```

**Expected output:**

```
INCLUDING DEPENDENCY Bridge
INCLUDING DEPENDENCY SuiSystem
INCLUDING DEPENDENCY Sui
INCLUDING DEPENDENCY MoveStdlib
BUILDING songsim
```

### Run Tests

```bash
sui move test
```

**Expected output:**

```
Test result: OK. Total tests: 18; passed: 18; failed: 0
```

### Run Specific Test

```bash
sui move test test_create_profile
sui move test test_finalize_consensus_and_distribute_payout
```

---

## Testnet Deployment

### 1. Switch to Testnet

```bash
sui client switch --env testnet
```

### 2. Deploy Contract

```bash
cd songsim
sui client publish --gas-budget 100000000
```

**What happens:**

- Contract bytecode is uploaded to Sui testnet
- Module is published at a new package address
- Objects are created:
  - `AdminCap` (sent to deployer)
  - `PlatformConfig` (shared object)
  - `TaskRegistry` (shared object)

**Expected output:**

```
Transaction Digest: <digest>
Published Objects:
  - Package ID: 0x<package_id>
  - AdminCap: 0x<admin_cap_id>
  - PlatformConfig: 0x<config_id>
  - TaskRegistry: 0x<registry_id>
```

### 3. Save Deployment Info

Create a `deployment.json` file:

```json
{
  "network": "testnet",
  "package_id": "0x...",
  "admin_cap_id": "0x...",
  "config_id": "0x...",
  "registry_id": "0x...",
  "deployer": "0x...",
  "deployed_at": "2024-01-01T00:00:00Z"
}
```

---

## Post-Deployment Verification

### 1. Verify Package

```bash
sui client object <package_id>
```

### 2. Check AdminCap Ownership

```bash
sui client object <admin_cap_id>
```

### 3. Inspect PlatformConfig

```bash
sui client object <config_id>
```

**Expected fields:**

```
fee_bps: 500            // 5% platform fee
fee_recipient: 0x...    // Deployer address
min_bounty: 1000000     // 0.001 SUI
is_paused: false
```

---

## Example Transactions

### 1. Create User Profile

```bash
sui client call \
  --package <package_id> \
  --module songsim \
  --function create_profile \
  --args <registry_id> <config_id> \"Alice\" \"Data labeling expert\" \"avatar_blob_id\" 2 \
  --gas-budget 10000000
```

**Parameters:**

- `registry_id`: TaskRegistry object ID
- `config_id`: PlatformConfig object ID
- `"Alice"`: Display name
- `"Data labeling expert"`: Bio
- `"avatar_blob_id"`: Walrus blob ID for avatar
- `2`: User type (1=requester, 2=labeler, 3=both)

### 2. Create Task

```bash
sui client call \
  --package <package_id> \
  --module songsim \
  --function create_task \
  --args <registry_id> <config_id> <profile_id> \"dataset_blob_id\" \"Image Classification\" \"Label cats vs dogs\" \"instructions_blob_id\" 5 1735689600000 <bounty_coin_id> \
  --gas-budget 10000000
```

**Parameters:**

- `profile_id`: UserProfile object ID
- `"dataset_blob_id"`: Walrus blob ID for dataset
- `"Image Classification"`: Task title
- `"Label cats vs dogs"`: Task description
- `"instructions_blob_id"`: Walrus blob ID for instructions
- `5`: Required number of labelers
- `1735689600000`: Deadline (Unix timestamp in ms)
- `bounty_coin_id`: Coin object with sufficient SUI

### 3. Submit Labels

```bash
sui client call \
  --package <package_id> \
  --module songsim \
  --function submit_labels \
  --args <registry_id> <task_id> <profile_id> \"result_blob_id\" \
  --gas-budget 10000000
```

### 4. Admin: Update Platform Fee

```bash
sui client call \
  --package <package_id> \
  --module songsim \
  --function update_platform_fee \
  --args <admin_cap_id> <config_id> 750 \
  --gas-budget 10000000
```

**Note:** Requires AdminCap ownership. 750 = 7.5% fee.

---

## Object Ownership Model

### Owned Objects (sent to creator)

- **AdminCap**: Owned by deployer (admin)
- **UserProfile**: Owned by user
- **Task**: Owned by task creator (requester)
- **Submission**: Owned by labeler
- **Reputation**: Owned by labeler

### Shared Objects (accessible by all)

- **PlatformConfig**: Global platform settings
- **TaskRegistry**: Central registry of all tasks

### Object Lifecycle

```
User creates profile → receives UserProfile + Reputation (owned)
                    ↓
Requester creates task → receives Task NFT (owned)
                       ↓
Labelers submit work → receive Submission NFT (owned)
                     ↓
Consensus finalized → Task updated, payouts sent
                    ↓
Labelers receive SUI → Reputation updated
```

---

## Integration with Frontend

### TypeScript SDK Usage

```typescript
import { SuiClient, TransactionBlock } from "@mysten/sui.js";

const client = new SuiClient({ url: "https://fullnode.testnet.sui.io" });

// Create profile
const tx = new TransactionBlock();
tx.moveCall({
  target: `${packageId}::songsim::create_profile`,
  arguments: [
    tx.object(registryId),
    tx.object(configId),
    tx.pure("Alice"),
    tx.pure("Data labeling expert"),
    tx.pure("avatar_blob_id"),
    tx.pure(2), // user_type
  ],
});

const result = await client.signAndExecuteTransactionBlock({
  signer: keypair,
  transactionBlock: tx,
});
```

### Query Objects

```typescript
// Get user profile
const profile = await client.getObject({
  id: profileId,
  options: { showContent: true },
});

// Get all tasks (from registry)
const tasks = await client.getDynamicFields({
  parentId: registryId,
});
```

---

## Monitoring & Events

### Listen to Events

```bash
sui client events --package <package_id>
```

**Event Types:**

- `ProfileCreated`
- `ProfileUpdated`
- `TaskCreated`
- `SubmissionReceived`
- `ConsensusFinalized`
- `PayoutDistributed`
- `PlatformFeeCollected`
- `ReputationUpdated`
- `PlatformConfigUpdated`

### Example: Query Specific Event

```bash
sui client events --package <package_id> --transaction-digest <tx_digest>
```

---

## Upgrading Contract

### 1. Update Code

Make changes to `sources/songsim.move`

### 2. Build New Version

```bash
sui move build
```

### 3. Publish Upgrade

```bash
sui client upgrade --package <package_id> --upgrade-capability <cap_id> --gas-budget 100000000
```

**Important:** Sui Move has limited upgrade capabilities. Plan for immutability or use capability-based upgrades.

---

## Troubleshooting

### Build Errors

**Issue:** `unable to resolve package`

```bash
# Update Move.toml dependencies
[dependencies.Sui]
git = "https://github.com/MystenLabs/sui.git"
subdir = "crates/sui-framework/packages/sui-framework"
rev = "testnet"
```

**Issue:** `type mismatch`

- Check function signatures in contract
- Verify argument types match expected parameters

### Deployment Errors

**Issue:** `insufficient gas`

```bash
# Increase gas budget
sui client publish --gas-budget 200000000
```

**Issue:** `invalid transaction`

- Check wallet has sufficient SUI
- Verify network connection
- Confirm correct environment (testnet)

### Transaction Errors

**Issue:** `object not found`

- Verify object IDs are correct
- Check object ownership (owned vs shared)
- Confirm object hasn't been consumed in previous tx

**Issue:** `unauthorized`

- Verify AdminCap ownership for admin functions
- Check profile ownership for profile updates
- Confirm sender matches expected address

---

## Security Best Practices

### 1. AdminCap Management

- **Never share** the AdminCap object ID publicly
- Store admin private key in secure hardware wallet
- Consider multi-sig for admin operations (M2)

### 2. Bounty Handling

- Always validate bounty amount ≥ min_bounty
- Use coin splitting for precise payments
- Test payout calculations thoroughly

### 3. Blob ID Validation

- Validate Walrus blob IDs on client side
- Store blob ID format specification
- Consider blob ID length/format constraints

### 4. Rate Limiting

- Implement rate limiting on frontend
- Monitor for spam task creation
- Consider reputation-based throttling (M2)

---

## Mainnet Deployment (Future)

### Prerequisites

- Comprehensive security audit
- Testnet validation (minimum 1000 transactions)
- Bug bounty program completion
- Governance mechanism active

### Checklist

- [ ] Security audit passed
- [ ] Testnet stress testing completed
- [ ] Frontend integration validated
- [ ] Documentation finalized
- [ ] Community testing phase completed
- [ ] Emergency procedures documented
- [ ] Admin key management plan finalized

---

## Support & Resources

### Official Documentation

- Sui Move Book: https://move-book.com
- Sui Documentation: https://docs.sui.io
- Sui Examples: https://github.com/MystenLabs/sui/tree/main/examples

### Community

- Sui Discord: https://discord.gg/sui
- Sui Forum: https://forums.sui.io

### Project Resources

- Contract source: `songsim/sources/songsim.move`
- Tests: `songsim/tests/songsim_tests.move`
- Task tracking: `songsim/TASKS.md`
- Test results: `songsim/TEST_RESULTS.md`

---

## Changelog

### Version 0.1.0 (M1)

**Released:** 2024

**Features:**

- ✅ Platform initialization with AdminCap
- ✅ User profile management
- ✅ Task creation with bounty locking
- ✅ Submission workflow
- ✅ Consensus algorithm (majority voting)
- ✅ Payout distribution with 5% platform fee
- ✅ Reputation scoring system
- ✅ Task cancellation and refunds
- ✅ Emergency withdrawal
- ✅ Comprehensive event system

**Test Coverage:** 18/18 tests passing (100%)

**Known Limitations:**

- No pagination for queries (M2)
- No leaderboard queries (M2)
- Basic reputation scoring (M2 will add decay/weighting)
- No dispute resolution (M2)

---

**Status:** ✅ Ready for Testnet Deployment
