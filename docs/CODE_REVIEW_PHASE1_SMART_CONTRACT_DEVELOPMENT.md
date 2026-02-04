# Phase 1: Smart Contract Development

> **Timeline**: Weeks 1-4  
> **Priority**: Critical  
> **Tech Stack**: Solidity ^0.8.x, Hardhat, OpenZeppelin, TypeScript

---

## Overview

This phase focuses on building the core smart contract infrastructure for the DeFi Yield Aggregator. All contracts will be developed using Solidity with Hardhat as the development framework, following security best practices and gas optimization patterns.

---

## Task Breakdown

### P1-SC-001: Initialize Hardhat Project
**Title**: Initialize Hardhat Project with TypeScript Configuration

| Field | Value |
|-------|-------|
| Priority | P0 - Critical |
| Estimated Hours | 2 |
| Dependencies | None |

**Description**:  
Set up the Hardhat development environment with TypeScript support, including all necessary dependencies and configuration files.

**Acceptance Criteria**:
- [ ] Hardhat project initialized with `npx hardhat init`
- [ ] TypeScript configured with strict mode
- [ ] Dependencies installed: `@openzeppelin/contracts`, `@nomiclabs/hardhat-ethers`, `ethers`
- [ ] `hardhat.config.ts` configured with network settings (localhost, Sepolia, mainnet)
- [ ] `.env.example` created with required environment variables
- [ ] Basic folder structure: `contracts/`, `scripts/`, `test/`, `deploy/`

**Files to Create**:
```
hardhat.config.ts
tsconfig.json
.env.example
package.json
```

---

### P1-SC-002: Implement Base Vault Contract
**Title**: Create Core Vault Contract with Deposit/Withdraw Logic

| Field | Value |
|-------|-------|
| Priority | P0 - Critical |
| Estimated Hours | 8 |
| Dependencies | P1-SC-001 |

**Description**:  
Develop the main Vault contract that handles user deposits, withdrawals, share calculations, and serves as the entry point for yield aggregation.

**Acceptance Criteria**:
- [ ] ERC-4626 compliant vault implementation
- [ ] Deposit function with share minting
- [ ] Withdraw function with share burning
- [ ] Preview deposit/withdraw calculations
- [ ] Total assets tracking
- [ ] Events: `Deposit`, `Withdraw`, `StrategyUpdated`
- [ ] Reentrancy protection via OpenZeppelin `ReentrancyGuard`
- [ ] Pausable functionality for emergencies

**Files to Create**:
```
contracts/core/Vault.sol
contracts/interfaces/IVault.sol
```

**Key Functions**:
```solidity
function deposit(uint256 assets, address receiver) external returns (uint256 shares);
function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
function totalAssets() public view returns (uint256);
function convertToShares(uint256 assets) public view returns (uint256);
function convertToAssets(uint256 shares) public view returns (uint256);
```

---

### P1-SC-003: Create Strategy Interface
**Title**: Define IStrategy Interface for Protocol Adapters

| Field | Value |
|-------|-------|
| Priority | P0 - Critical |
| Estimated Hours | 3 |
| Dependencies | P1-SC-001 |

**Description**:  
Create the standard interface that all protocol strategy adapters must implement, ensuring consistent interaction patterns across different DeFi protocols.

**Acceptance Criteria**:
- [ ] Interface defines `deposit()`, `withdraw()`, `harvest()` functions
- [ ] `estimatedTotalAssets()` for calculating strategy holdings
- [ ] `apr()` function for current yield estimation
- [ ] `want()` returns the token address the strategy accepts
- [ ] `vault()` returns the associated vault address
- [ ] Emergency withdrawal function signature

**Files to Create**:
```
contracts/interfaces/IStrategy.sol
```

**Interface Definition**:
```solidity
interface IStrategy {
    function vault() external view returns (address);
    function want() external view returns (address);
    function deposit() external;
    function withdraw(uint256 amount) external returns (uint256);
    function withdrawAll() external returns (uint256);
    function harvest() external;
    function estimatedTotalAssets() external view returns (uint256);
    function apr() external view returns (uint256);
    function emergencyWithdraw() external;
}
```

---

### P1-SC-004: Implement Strategy Manager
**Title**: Build Strategy Manager for Multi-Protocol Orchestration

| Field | Value |
|-------|-------|
| Priority | P0 - Critical |
| Estimated Hours | 10 |
| Dependencies | P1-SC-002, P1-SC-003 |

**Description**:  
Develop the Strategy Manager contract that handles strategy registration, allocation, rebalancing, and yield optimization across multiple protocols.

**Acceptance Criteria**:
- [ ] Strategy registration with whitelist
- [ ] Allocation percentages per strategy (basis points)
- [ ] Rebalance function to redistribute assets
- [ ] Harvest all strategies function
- [ ] Strategy performance tracking
- [ ] Maximum strategy limit (e.g., 10 strategies)
- [ ] Admin controls for strategy management
- [ ] Events: `StrategyAdded`, `StrategyRemoved`, `Rebalanced`, `Harvested`

**Files to Create**:
```
contracts/core/StrategyManager.sol
contracts/interfaces/IStrategyManager.sol
```

**Key Functions**:
```solidity
function addStrategy(address strategy, uint256 allocationBps) external;
function removeStrategy(address strategy) external;
function rebalance() external;
function harvestAll() external;
function getStrategyAllocation(address strategy) external view returns (uint256);
function totalStrategies() external view returns (uint256);
```

---

### P1-SC-005: Build Protocol Router
**Title**: Create Router Contract for Optimal Protocol Routing

| Field | Value |
|-------|-------|
| Priority | P1 - High |
| Estimated Hours | 6 |
| Dependencies | P1-SC-003 |

**Description**:  
Implement a Router contract that handles optimal token swaps and protocol interactions, minimizing gas costs and slippage.

**Acceptance Criteria**:
- [ ] Token approval management
- [ ] Batch transaction support
- [ ] Slippage protection parameters
- [ ] Deadline enforcement
- [ ] Gas-efficient multi-call patterns
- [ ] Integration with DEX aggregators (optional)

**Files to Create**:
```
contracts/core/Router.sol
contracts/interfaces/IRouter.sol
```

---

### P1-SC-006: Implement Aave Strategy
**Title**: Develop Aave V3 Protocol Strategy Adapter

| Field | Value |
|-------|-------|
| Priority | P0 - Critical |
| Estimated Hours | 8 |
| Dependencies | P1-SC-003 |

**Description**:  
Create the Aave V3 strategy adapter that deposits assets into Aave lending pools and harvests interest rewards.

**Acceptance Criteria**:
- [ ] Implements `IStrategy` interface
- [ ] Deposits to Aave lending pool
- [ ] Withdraws from Aave lending pool
- [ ] Harvests accrued interest
- [ ] Handles aToken balance tracking
- [ ] Calculates real-time APY from Aave
- [ ] Emergency withdrawal to vault

**Files to Create**:
```
contracts/strategies/AaveStrategy.sol
contracts/interfaces/external/IAavePool.sol
contracts/interfaces/external/IAToken.sol
```

**External Integrations**:
- Aave Pool: `0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2` (Mainnet)
- Aave Pool Data Provider

---

### P1-SC-007: Implement Compound Strategy
**Title**: Develop Compound V3 Protocol Strategy Adapter

| Field | Value |
|-------|-------|
| Priority | P0 - Critical |
| Estimated Hours | 8 |
| Dependencies | P1-SC-003 |

**Description**:  
Create the Compound V3 strategy adapter for supplying assets to Compound markets.

**Acceptance Criteria**:
- [ ] Implements `IStrategy` interface
- [ ] Supply to Compound V3 Comet
- [ ] Withdraw from Compound V3
- [ ] Claim COMP rewards
- [ ] Calculate supply APY
- [ ] Handle cToken/Comet balance tracking
- [ ] Emergency withdrawal mechanism

**Files to Create**:
```
contracts/strategies/CompoundStrategy.sol
contracts/interfaces/external/IComet.sol
contracts/interfaces/external/ICometRewards.sol
```

---

### P1-SC-008: Implement Curve Strategy
**Title**: Develop Curve Finance Protocol Strategy Adapter

| Field | Value |
|-------|-------|
| Priority | P1 - High |
| Estimated Hours | 10 |
| Dependencies | P1-SC-003 |

**Description**:  
Create the Curve strategy adapter for providing liquidity to Curve pools and staking in Curve gauges.

**Acceptance Criteria**:
- [ ] Implements `IStrategy` interface
- [ ] Add liquidity to Curve pools
- [ ] Remove liquidity from Curve pools
- [ ] Stake LP tokens in Curve gauges
- [ ] Claim CRV and CVX rewards
- [ ] Calculate pool APY + gauge rewards
- [ ] Handle impermanent loss considerations
- [ ] Emergency withdrawal from gauge and pool

**Files to Create**:
```
contracts/strategies/CurveStrategy.sol
contracts/interfaces/external/ICurvePool.sol
contracts/interfaces/external/ICurveGauge.sol
```

---

### P1-SC-009: Implement Security Controls
**Title**: Add Multi-Sig, Timelock, and Access Control Mechanisms

| Field | Value |
|-------|-------|
| Priority | P0 - Critical |
| Estimated Hours | 6 |
| Dependencies | P1-SC-002, P1-SC-004 |

**Description**:  
Implement comprehensive security controls including role-based access, timelocks for sensitive operations, and emergency mechanisms.

**Acceptance Criteria**:
- [ ] OpenZeppelin `AccessControl` integration
- [ ] Roles: `DEFAULT_ADMIN_ROLE`, `STRATEGIST_ROLE`, `GUARDIAN_ROLE`
- [ ] Timelock for strategy changes (48 hours)
- [ ] Emergency pause functionality
- [ ] Guardian emergency withdrawal
- [ ] Rate limiting for large withdrawals
- [ ] Reentrancy guards on all external functions

**Files to Create**:
```
contracts/security/TimelockController.sol
contracts/security/Guardian.sol
```

**Roles Definition**:
| Role | Permissions |
|------|-------------|
| Admin | Full control, role management |
| Strategist | Add/remove strategies, rebalance |
| Guardian | Emergency pause, emergency withdraw |

---

### P1-SC-010: Create Utility Libraries
**Title**: Develop Math and Helper Libraries

| Field | Value |
|-------|-------|
| Priority | P1 - High |
| Estimated Hours | 4 |
| Dependencies | P1-SC-001 |

**Description**:  
Create reusable utility libraries for mathematical operations, safe calculations, and common helper functions.

**Acceptance Criteria**:
- [ ] Basis points calculation library
- [ ] Share/asset conversion helpers
- [ ] Safe math for percentage calculations
- [ ] Price oracle helpers
- [ ] Gas-optimized operations

**Files to Create**:
```
contracts/libraries/MathUtils.sol
contracts/libraries/BasisPoints.sol
contracts/libraries/TokenUtils.sol
```

---

### P1-SC-011: Write Unit Tests - Core
**Title**: Comprehensive Unit Tests for Core Contracts

| Field | Value |
|-------|-------|
| Priority | P0 - Critical |
| Estimated Hours | 12 |
| Dependencies | P1-SC-002, P1-SC-004, P1-SC-005 |

**Description**:  
Write thorough unit tests for all core contracts using Hardhat and Chai.

**Acceptance Criteria**:
- [ ] Vault deposit/withdraw tests
- [ ] Share calculation accuracy tests
- [ ] Strategy manager allocation tests
- [ ] Rebalancing logic tests
- [ ] Edge cases: zero amounts, max amounts
- [ ] Access control tests
- [ ] Event emission verification
- [ ] Gas consumption benchmarks
- [ ] **Target: >90% code coverage**

**Files to Create**:
```
test/core/Vault.test.ts
test/core/StrategyManager.test.ts
test/core/Router.test.ts
test/helpers/fixtures.ts
```

---

### P1-SC-012: Write Unit Tests - Strategies
**Title**: Unit Tests for Protocol Strategy Adapters

| Field | Value |
|-------|-------|
| Priority | P0 - Critical |
| Estimated Hours | 10 |
| Dependencies | P1-SC-006, P1-SC-007, P1-SC-008 |

**Description**:  
Write unit tests for each protocol strategy using mainnet forking.

**Acceptance Criteria**:
- [ ] Aave strategy deposit/withdraw tests
- [ ] Compound strategy supply/withdraw tests
- [ ] Curve strategy LP/gauge tests
- [ ] Harvest and reward claim tests
- [ ] APY calculation verification
- [ ] Emergency withdrawal tests
- [ ] Mainnet fork integration tests

**Files to Create**:
```
test/strategies/AaveStrategy.test.ts
test/strategies/CompoundStrategy.test.ts
test/strategies/CurveStrategy.test.ts
test/helpers/fork.ts
```

---

### P1-SC-013: Write Integration Tests
**Title**: End-to-End Integration Tests

| Field | Value |
|-------|-------|
| Priority | P0 - Critical |
| Estimated Hours | 8 |
| Dependencies | P1-SC-011, P1-SC-012 |

**Description**:  
Create integration tests that verify the complete flow from deposit to yield generation.

**Acceptance Criteria**:
- [ ] Full deposit → strategy allocation → harvest → withdraw flow
- [ ] Multi-strategy rebalancing scenarios
- [ ] Emergency scenario simulations
- [ ] Gas optimization verification
- [ ] Time-based yield accrual tests

**Files to Create**:
```
test/integration/FullFlow.test.ts
test/integration/EmergencyScenarios.test.ts
```

---

### P1-SC-014: Gas Optimization Pass
**Title**: Optimize Gas Consumption Across All Contracts

| Field | Value |
|-------|-------|
| Priority | P1 - High |
| Estimated Hours | 6 |
| Dependencies | P1-SC-011, P1-SC-012 |

**Description**:  
Review and optimize all contracts for gas efficiency.

**Acceptance Criteria**:
- [ ] Storage slot packing optimization
- [ ] Calldata vs memory usage review
- [ ] Loop optimization
- [ ] External vs public function visibility
- [ ] Immutable variable usage
- [ ] Custom errors instead of require strings
- [ ] Unchecked blocks where safe
- [ ] Gas benchmark report generated

**Deliverables**:
```
docs/GAS_OPTIMIZATION_REPORT.md
```

---

### P1-SC-015: Create Deployment Scripts
**Title**: Write Automated Deployment Scripts

| Field | Value |
|-------|-------|
| Priority | P1 - High |
| Estimated Hours | 5 |
| Dependencies | P1-SC-009 |

**Description**:  
Create deployment scripts for testnet and mainnet deployments.

**Acceptance Criteria**:
- [ ] Deployment script with constructor arguments
- [ ] Verification script for Etherscan
- [ ] Post-deployment configuration script
- [ ] Role assignment automation
- [ ] Deployment address logging
- [ ] Multi-chain support (Mainnet, Sepolia, Arbitrum)

**Files to Create**:
```
scripts/deploy.ts
scripts/verify.ts
scripts/configure.ts
scripts/utils/deploymentLog.ts
```

---

## Phase 1 Completion Checklist

| Task ID | Title | Status |
|---------|-------|--------|
| P1-SC-001 | Initialize Hardhat Project | ⬜ |
| P1-SC-002 | Base Vault Contract | ⬜ |
| P1-SC-003 | Strategy Interface | ⬜ |
| P1-SC-004 | Strategy Manager | ⬜ |
| P1-SC-005 | Protocol Router | ⬜ |
| P1-SC-006 | Aave Strategy | ⬜ |
| P1-SC-007 | Compound Strategy | ⬜ |
| P1-SC-008 | Curve Strategy | ⬜ |
| P1-SC-009 | Security Controls | ⬜ |
| P1-SC-010 | Utility Libraries | ⬜ |
| P1-SC-011 | Unit Tests - Core | ⬜ |
| P1-SC-012 | Unit Tests - Strategies | ⬜ |
| P1-SC-013 | Integration Tests | ⬜ |
| P1-SC-014 | Gas Optimization | ⬜ |
| P1-SC-015 | Deployment Scripts | ⬜ |

---

## Success Criteria

- [ ] All 15 tasks completed
- [ ] Test coverage ≥ 90%
- [ ] Gas per rebalance < 200,000
- [ ] All contracts compile without warnings
- [ ] Slither static analysis passes
- [ ] Ready for security audit review
