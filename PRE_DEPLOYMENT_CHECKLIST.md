# Pre-Deployment Checklist

Complete this checklist before deploying to testnet or mainnet.

---

## Version Information

- [ ] **Version Number**: _____________________ (e.g., 1.0.0)
- [ ] **Deployment Date**: _____________________ (YYYY-MM-DD)
- [ ] **Network**: ☐ Testnet ☐ Mainnet
- [ ] **Deployer**: _____________________ (Wallet address)

---

## Code Quality

### Build & Compilation

- [ ] `sui move build` completes without errors
- [ ] No compilation warnings (or documented exceptions)
- [ ] Move.toml version matches deployment version
- [ ] Move.toml dependencies are correct and locked

### Testing

- [ ] All unit tests passing (`sui move test`)
  - **Current Status**: 36/36 tests passing ✅
- [ ] Integration tests completed
- [ ] Edge cases tested (minimum bounty, zero stake, etc.)
- [ ] Error handling verified (all e_* constants tested)

### Code Review

- [ ] Peer review completed by ____________________
- [ ] Security-sensitive functions reviewed (AdminCap, staking, payouts)
- [ ] Gas optimization review completed
- [ ] Documentation updated (API_REFERENCE.md, comments)

---

## Security Verification

### Authentication & Authorization

- [ ] All admin functions require AdminCap
- [ ] No unauthorized access to sensitive operations
- [ ] Profile ownership validated in all user operations
- [ ] Task requester validation working correctly

### Economic Security

- [ ] Minimum bounty enforced (1_000_000 MIST = 0.001 SUI)
- [ ] Platform fee calculation correct (5% default)
- [ ] Staking requirements validated (0.01 SUI minimum)
- [ ] No integer overflow/underflow in balance operations

### Anti-Abuse Mechanisms

- [ ] Duplicate submission prevention tested
- [ ] Duplicate vote prevention tested
- [ ] Sybil resistance (staking) verified
- [ ] Emergency pause functionality working

### Data Integrity

- [ ] Consensus algorithm tested (quorum calculation)
- [ ] Reputation scoring validated (0-1000 scale)
- [ ] Quality metrics calculation correct
- [ ] Task lifecycle state transitions verified

---

## Smart Contract Verification

### Module Checklist

- [ ] **songsim.move** - Core platform initialization ✅
- [ ] **profile.move** - User profile management ✅
- [ ] **task.move** - Task creation and lifecycle ✅
- [ ] **consensus.move** - Submission consensus ✅
- [ ] **reputation.move** - Reputation tracking ✅
- [ ] **registry.move** - Task and profile registry ✅
- [ ] **dispute.move** - Dispute resolution ✅
- [ ] **prize_pool.move** - Prize pool mechanics ✅
- [ ] **staking.move** - Anti-Sybil staking ✅
- [ ] **quality.move** - Quality metrics ✅
- [ ] **emergency.move** - Circuit breaker ✅
- [ ] **migration.move** - Version tracking ✅
- [ ] **access_policy.move** - Seal encryption (optional) ✅
- [ ] **constants.move** - Error codes and constants ✅
- [ ] **events.move** - Event emissions ✅

### Shared Objects

- [ ] PlatformConfig properly initialized
- [ ] TaskRegistry properly initialized
- [ ] MigrationState properly initialized
- [ ] All shared objects have version fields

### Owned Objects

- [ ] AdminCap issued to deployer
- [ ] UpgradeCap management understood
- [ ] UserProfile creation working
- [ ] Reputation tracking per user

---

## Migration System

### Version Tracking

- [ ] MigrationState.current_version = 1
- [ ] PlatformConfig.version initialized correctly
- [ ] TaskRegistry.version initialized correctly
- [ ] Version constants defined (VERSION_1_0_0, CURRENT_VERSION)

### Upgrade Capabilities

- [ ] UpgradeCap will be issued on deployment
- [ ] Migration lock/unlock functions tested
- [ ] Rollback procedure documented
- [ ] Version validation logic working

### Documentation

- [ ] UPGRADE_GUIDE.md reviewed
- [ ] Migration procedures understood
- [ ] Rollback plan documented
- [ ] Emergency procedures defined

---

## Frontend Integration Readiness

### Configuration Files

- [ ] `.env.local.example` exists in songsim-label/
- [ ] All required environment variables documented
- [ ] Walrus configuration correct (testnet/mainnet URLs)
- [ ] Seal encryption configuration (optional)

### Contract Constants

- [ ] `lib/contract-constants.ts` ready for IDs
- [ ] Type definitions match contract structs
- [ ] Event types match contract emissions
- [ ] Error codes documented

### Integration Points

- [ ] React Query hooks reviewed
- [ ] Transaction builders tested
- [ ] Decoding functions working (vector<u8> → string)
- [ ] Walrus upload/download tested

---

## Deployment Preparation

### Environment Setup

- [ ] Sui CLI installed and configured
  - **Version**: _________________ (run `sui --version`)
- [ ] Active wallet configured
  - **Address**: _________________
- [ ] Network set correctly (`sui client active-env`)
  - **Current**: _________________
- [ ] Gas balance sufficient (≥0.1 SUI for testnet, ≥1 SUI for mainnet)
  - **Current Balance**: _________________ SUI

### Backup & Recovery

- [ ] Wallet seed phrase backed up securely
- [ ] Deployer private key accessible
- [ ] Recovery procedure documented
- [ ] Team contacts for emergency available

### Deployment Scripts

- [ ] `scripts/deploy.ps1` (Windows) reviewed
- [ ] `scripts/deploy.sh` (Linux/Mac) reviewed
- [ ] Scripts have execute permissions (`chmod +x deploy.sh`)
- [ ] Dry-run completed (if applicable)

---

## Post-Deployment Actions

### Immediate (Within 1 Hour)

- [ ] Save deployment.json securely
- [ ] Record UpgradeCap ID: _______________________________
- [ ] Record AdminCap ID: _______________________________
- [ ] Record Package ID: _______________________________
- [ ] Record PlatformConfig ID: _______________________________
- [ ] Record TaskRegistry ID: _______________________________
- [ ] Record MigrationState ID: _______________________________
- [ ] Update Move.toml with `published-at`
- [ ] Create .env.local from template in songsim-label/
- [ ] Update contract-constants.ts with all IDs

### Within 24 Hours

- [ ] Update DEPLOYMENT_HISTORY.md with deployment details
- [ ] Test profile creation on frontend
- [ ] Test task creation on frontend
- [ ] Test submission workflow end-to-end
- [ ] Test consensus finalization
- [ ] Test emergency pause/resume
- [ ] Verify all React Query hooks working
- [ ] Check Walrus storage integration
- [ ] Monitor for any error events

### Within 1 Week

- [ ] Announce deployment to community
- [ ] Share explorer links (package, config, registry)
- [ ] Update documentation with live examples
- [ ] Monitor gas usage patterns
- [ ] Gather user feedback
- [ ] Track any bugs or issues
- [ ] Plan first upgrade (if needed)

---

## Risk Assessment

### Critical Risks (Must Address Before Deployment)

- [ ] **Loss of UpgradeCap**: Documented backup locations
- [ ] **Loss of AdminCap**: Documented recovery procedure
- [ ] **Smart Contract Bugs**: All tests passing, peer reviewed
- [ ] **Economic Exploits**: Staking and fee logic validated

### Medium Risks (Monitor & Mitigate)

- [ ] **Gas Price Spikes**: Budget for 2x current gas prices
- [ ] **Walrus Downtime**: Have fallback storage plan
- [ ] **Network Congestion**: Test during peak times
- [ ] **User Errors**: Clear UI/UX guidance provided

### Low Risks (Accept & Monitor)

- [ ] **Frontend Bugs**: Can be fixed without contract upgrade
- [ ] **UI/UX Issues**: Can be improved iteratively
- [ ] **Performance Issues**: Can optimize later

---

## Testnet-Specific Checks

*(Skip this section for mainnet)*

- [ ] Network set to `testnet` (not devnet or mainnet)
- [ ] Using testnet RPC: https://fullnode.testnet.sui.io:443
- [ ] Walrus testnet URLs configured:
  - Publisher: https://publisher.walrus-testnet.walrus.space
  - Aggregator: https://aggregator.walrus-testnet.walrus.space
- [ ] Test tokens acquired from faucet
- [ ] Willing to reset if needed (testnet data is ephemeral)

---

## Mainnet-Specific Checks

*(Future - DO NOT deploy to mainnet yet)*

### Additional Requirements

- [ ] **Security Audit**: Completed by ≥2 professional firms
  - Auditor 1: _________________ (Date: _______)
  - Auditor 2: _________________ (Date: _______)
- [ ] **Bug Bounty**: Program active for ≥30 days
- [ ] **Multi-Sig**: AdminCap in multi-sig wallet (3-of-5 or better)
- [ ] **Governance**: Community approval via governance vote
- [ ] **Insurance**: Smart contract insurance purchased
- [ ] **Legal Review**: Terms of service and compliance reviewed
- [ ] **Monitoring**: 24/7 monitoring and alerting configured
- [ ] **Incident Response**: Team trained on emergency procedures
- [ ] **Gas Budget**: ≥10 SUI for deployment and operations
- [ ] **User Testing**: Beta program completed (≥100 users)

### Compliance

- [ ] KYC/AML requirements reviewed (if applicable)
- [ ] Data privacy compliance (GDPR, CCPA, etc.)
- [ ] Smart contract registration (if required by jurisdiction)
- [ ] Tax implications understood

---

## Team Sign-Off

### Required Approvals

- [ ] **Lead Developer**: _____________ (Signature) Date: _______
- [ ] **Security Lead**: _____________ (Signature) Date: _______
- [ ] **Product Manager**: _____________ (Signature) Date: _______

### Optional (Mainnet Only)

- [ ] **Legal Counsel**: _____________ (Signature) Date: _______
- [ ] **Community Representative**: _____________ (Signature) Date: _______

---

## Final Go/No-Go Decision

### Checklist Summary

- **Total Items**: _______
- **Completed**: _______
- **Pending**: _______
- **Blockers**: _______

### Decision

- [ ] ✅ **GO** - Ready for deployment
- [ ] ⏸️ **HOLD** - Minor issues to address (estimated time: ________)
- [ ] ❌ **NO-GO** - Critical issues, abort deployment

### Blockers (If NO-GO)

1. _________________________________________________________________
2. _________________________________________________________________
3. _________________________________________________________________

### Notes

_______________________________________________________________________
_______________________________________________________________________
_______________________________________________________________________

---

## Deployment Execution

### Deployment Command (Record Time)

```bash
# Start Time: ______________

# Windows
cd songsim/scripts
.\deploy.ps1

# Linux/Mac
cd songsim/scripts
./deploy.sh

# End Time: ______________
# Duration: ______________
```

### Deployment Results

- **Status**: ☐ Success ☐ Failed
- **Transaction Digest**: _______________________________
- **Package ID**: _______________________________
- **Explorer Link**: _______________________________

### Issues Encountered

_______________________________________________________________________
_______________________________________________________________________
_______________________________________________________________________

---

## Post-Deployment Verification

### Health Checks (Within 1 Hour)

- [ ] Package visible on Sui Explorer
- [ ] PlatformConfig object queryable
- [ ] TaskRegistry object queryable
- [ ] MigrationState object queryable
- [ ] Frontend can connect to package
- [ ] Can create user profile
- [ ] Can create task
- [ ] Walrus storage working

### Status: ☐ All Checks Passed ☐ Issues Found

### Issues:

_______________________________________________________________________
_______________________________________________________________________
_______________________________________________________________________

---

**Deployment Completed By**: _____________________  
**Date**: _____________________  
**Time**: _____________________  
**Network**: _____________________

---

**For emergency rollback or support, contact:**
- Discord: [Server Link]
- Email: [Support Email]
- On-Call: [Phone/Telegram]

---

**Document Version**: 1.0.0  
**Last Updated**: November 20, 2025  
**Template Maintained By**: Songsim Core Team
