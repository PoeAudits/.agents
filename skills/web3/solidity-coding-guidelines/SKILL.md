---
name: solidity-coding-guidelines
description: Must be read if not already read before writing any Solidity code.
license: MIT
---

# General Coding Guidelines

## Structure
Order matters for readability (even if it doesn't affect semantics). On the first read, a file is read top-down, so put important things near the top. The main function goes first.

## Control Flow
Use only very simple, explicit control flow for clarity. Do not use recursion to ensure that all executions that should be bounded are bounded. Use only a minimum of excellent abstractions but only if they make the best sense of the domain. Abstractions are never zero cost. Every abstraction introduces the risk of a leaky abstraction.

## Data Structures
All loops and all queues must have a fixed upper bound to prevent infinite loops or tail latency spikes. This follows the “fail-fast” principle so that violations are detected sooner rather than later. Where a loop cannot terminate (e.g. an event loop), this must be asserted.

## Error Handling
All errors must be handled. An analysis of production failures in distributed data-intensive systems found that the majority of catastrophic failures could have been prevented by simple testing of error handling code.

## Naming
Add units or qualifiers to variable names, and put the units or qualifiers last, sorted by descending significance, so that the variable starts with the most significant word, and ends with the least significant word. For example, latency_ms_max rather than max_latency_ms. This will then line up nicely when latency_ms_min is added, as well as group all variables that relate to latency.

When choosing related names, try hard to find names with the same number of characters so that related variables all line up in the source. For example, source and target are better than src and dest because they have the second-order effect that any related variables such as source_offset and target_offset will all line up in calculations and slices. This makes the code symmetrical, with clean blocks that are easier for the eye to parse and for the reader to check.

When a single function calls out to a helper function or callback, prefix the name of the helper function with the name of the calling function to show the call history. For example, read_sector() and read_sector_callback().

A noun is often a better descriptor than an adjective or present participle, because a noun can be directly used in correspondence without having to be rephrased.


## Types
Use the smallest type that can represent the value. Every variable, parameter, and return value must have an explicit type.

# Solidity Coding Guidelines

## Architecture & Design Patterns
Upgradeability: Prefer non-upgradeable contracts; use UUPS pattern when upgradeability is required
- NEVER use Diamond pattern
- NEVER use Transparent proxy pattern
Composition over Inheritance: Max inheritance depth of 1; prefer composition
Libraries over Abstract Contracts: Prefer stateless libraries over abstract contracts
Abstract Base Contracts: Acceptable only in specific cases:
- When you have one base contract with network-specific implementations (virtual functions/hooks)
- For testing infrastructure (abstract base contracts are useful for test organization)
- NOT for production contracts unless adding hooks that are overwritten in implementations
Contract Size: Keep contracts small (24KB limit); split large contracts into logical modules

## Security Patterns
Checks-Effects-Interactions: ALWAYS follow this pattern - no exceptions
Reentrancy: Write contracts to avoid reentrancy through proper CEI ordering rather than defaulting to guards
- Reentrancy guards are a last resort for cases where CEI alone is insufficient
- When guards are needed, use transient storage for reentrancy locks
Access Control: Use Solady's access control (`Ownable`, `OwnableRoles`)
Pull over Push: Prefer pull pattern for ETH/token transfers to users
Pausability: Use OpenZeppelin's `Pausable` when pause functionality is needed

## Dependency Priority
1. **Solmate** - First choice for gas-optimized implementations
2. **Solady** - Second choice for newer contracts not yet in Solmate
3. **OpenZeppelin** - Third choice when Solmate/Solady don't have the needed functionality

## ERC Standard Implementations
ERC20: Prefer Solmate's `ERC20`, then Solady's
ERC721: Prefer Solmate's `ERC721`, then Solady's
ERC1155: Prefer Solmate's `ERC1155`, then Solady's
ERC4626: Prefer Solmate's `ERC4626`, then Solady's

## Solidity Version
Pin exact version (e.g., `pragma solidity 0.8.28;`)
Prefer newer versions with transient storage support
Use transient variables (`transient` keyword) when appropriate for temporary storage

## Naming Conventions
```solidity
// Functions: camelCase
function depositCollateral() external {}

// Constants: UPPER_SNAKE_CASE
uint256 public constant MAX_SUPPLY = 1_000_000e18;

// Private/Internal variables: _leadingUnderscore
uint256 private _totalDeposits;
mapping(address => uint256) internal _balances;

// Structs/Events/Errors: PascalCase
struct UserPosition { ... }
event Deposited(address indexed user, uint256 amount);
error InsufficientBalance();
```

## Custom Errors
Prefer custom errors over require strings (more gas efficient)
Can use custom errors in `require` statements (Solidity 0.8.26+)
Keep errors simple and parameterless unless the check uses that parameter
Do NOT include extra context (like addresses) that isn't part of the check
```solidity
// Good - parameter is part of the check
error InsufficientBalance(uint256 balance);
require(balance > 0, InsufficientBalance(balance));

// Good - simple error when no useful parameter
error ZeroAmount();
require(amount > 0, ZeroAmount());

// Avoid - address not part of the check, extra storage read
error InsufficientBalance(address user, uint256 balance);
```

## Type Explicitness
Use explicit `uint256` instead of `uint`
Use explicit `int256` instead of `int`
```solidity
// Good
uint256 amount;
int256 delta;

// Avoid
uint amount;
int delta;
```

## Time-based Logic
Prefer `block.number` over `block.timestamp` when possible
Use `block.timestamp` only when actual time is needed (e.g., expiration dates)

## Fallback/Receive
Do not include by default; add explicitly when needed for specific functionality

## Permit (EIP-2612)
Do NOT support permit/gasless approvals by default (personal preference)

## Multicall
<!-- TODO: Link to custom multicall/arbitrary call implementation documentation -->
Multicall functionality is generally desired
Use custom multicall and arbitrary call functions (documentation to be added)

## NatSpec Documentation
Required on all public and external functions
Include parameter names and return value descriptions
Keep concise but sufficient
```solidity
/// @notice Deposits collateral into the vault
/// @param amount The amount of collateral to deposit
/// @return shares The number of shares minted
function deposit(uint256 amount) external returns (uint256 shares) { ... }
```

## Events
Emit events only for user-facing state changes (deposits, withdrawals, significant actions)
Do NOT add events for internal state changes or admin operations unless needed
Do NOT add extra storage reads just to emit event data
```solidity
// Good - user-facing action
event Deposited(address indexed user, uint256 amount, uint256 shares);

// Avoid - internal state change
event TotalAssetsUpdated(uint256 newTotal);
```

## Indexed Parameters
Index 1-2 parameters maximum (usually just 1)
Index addresses for user-based lookups
Index IDs for ID-based mappings
```solidity
// Good - single indexed address
event Withdrawn(address indexed user, uint256 amount);

// Good - indexed ID for ID-based mapping
event PositionLiquidated(uint256 indexed positionId, uint256 debt);
```

## Modifiers
Keep modifiers simple (single logical check)
Use modifiers for checks used more than 3 times
Use internal functions instead if the check needs to return a value
```solidity
// Good - simple, reused check
modifier onlyActiveVault() {
    require(!paused, VaultPaused());
    require(block.number > activationBlock, VaultNotActive());
    _;
}

// Use internal function when return value needed
function _validateAndGetPosition(uint256 id) internal view returns (Position storage) {
    Position storage pos = positions[id];
    require(pos.owner != address(0), PositionNotFound());
    return pos;
}
```

## Function Ordering
Order within contract:
1. State variables
2. Events
3. Errors
4. Modifiers
5. Constructor / Initializer
6. External functions (mutating)
7. Public functions (mutating)
8. External view/pure functions
9. Public view/pure functions
10. Internal functions
11. Private functions

Within each section:
- Order by typical user interaction flow (e.g., `deposit` before `withdraw`)
- Keep related functions close together
- If function A calls internal function B, place B near the top of internal section
- Group by functionality when it aids readability

## Storage Patterns
Prefer `calldata` for read-only array/struct parameters
Use storage pointers for state modifications:
```solidity
struct VaultState {
    uint256 totalDeposits;
    uint256 totalShares;
}

VaultState internal _state;

function _updateState(VaultState storage state) internal {
    state.totalDeposits += msg.value;
}
```

## Math & Precision
Use standard precision constants:
- WAD: `1e18` for most token math
- RAY: `1e27` for higher precision calculations
Use Solmate's `FixedPointMathLib` when complex fixed-point math is needed (generally not required)
Overflow handling: Rely on Solidity 0.8+'s built-in checks

## Gas Optimization
Unchecked Blocks: Do NOT add `unchecked` blocks; leave existing ones in place if present
Struct Packing: For new structs, try to pack variables that are used together in the same function calls
- Do NOT modify packing of existing structs (packing depends on co-access patterns, not just size)
```solidity
// Good - variables accessed together are packed
struct Position {
    uint128 collateral;  // accessed with debt
    uint128 debt;        // accessed with collateral
    uint64 lastUpdate;   // accessed separately
    uint64 liquidationPrice;
}
```

## Assembly
Avoid inline assembly
Do not write assembly manually; if needed, it will be added explicitly

## Immutables & Constants
Use `immutable` for constructor-set values (unless part of a configurable struct)
Extract magic numbers to named constants
```solidity
// Good
uint256 public constant PRECISION = 1e18;
uint256 public constant MAX_FEE_BPS = 1000; // 10%
uint256 public immutable deploymentTime;

// Avoid
uint256 shares = amount * 1e18 / totalAssets;
```

## Storage Patterns
Mappings vs Arrays:
- Use mappings for indeterminate/dynamic collections
- Use arrays for fixed/bounded collections
Upgradeable Contracts: Manually specify storage slots using OpenZeppelin's storage slot pattern

## Rounding
ALWAYS round in favor of the protocol
Add explicit comments about rounding direction whenever rounding occurs
```solidity
// Round down (favors protocol - user receives less)
uint256 shares = (amount * totalShares) / totalAssets;

// Round up (favors protocol - user pays more)  
uint256 requiredCollateral = (debt * PRECISION + price - 1) / price; // round up
```

## Minimum Amounts
Enforce minimum amounts to prevent dust attacks and rounding exploits
Default minimum: `1e6` for 18-decimal tokens (adjust for 6-decimal tokens like USDC)
```solidity
uint256 public constant MIN_DEPOSIT = 1e6;

function deposit(uint256 amount) external {
    if (amount < MIN_DEPOSIT) revert BelowMinimum();
    ...
}
```

## Framework & Tooling
Framework: Foundry only (never Hardhat)
Formatter: Use `forge fmt`
Testing: Foundry tests in Solidity

## Testing
<!-- TODO: Link to custom testing framework documentation (Recon/Chimera-based) -->
Use custom testing framework based on Recon and Chimera
Additional documentation for testing patterns to be added

## Interfaces
Separate interface files with `I` prefix: `IVault.sol` for `Vault.sol`
Place interfaces in `src/interfaces/` directory
```solidity
// src/interfaces/IVault.sol
interface IVault {
    function deposit(uint256 amount) external returns (uint256 shares);
    function withdraw(uint256 shares) external returns (uint256 amount);
}
```

## Oracles
Use Uniswap TWAP when on-chain price data is needed
Use Chainlink for off-chain price feeds when appropriate

## Flash Loan Protection
Contract-specific; no default pattern (depends on the specific vulnerability surface)

## Contract Structure Template
```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "solady/auth/Ownable.sol";

/// @title MyContract
/// @notice Brief description of what this contract does
contract MyContract is Ownable {
    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/
    
    uint256 private _someValue;
    
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event ValueUpdated(uint256 newValue);
    
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    
    error InvalidValue();
    
    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    
    modifier validValue(uint256 value) {
        if (value == 0) revert InvalidValue();
        _;
    }
    
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    constructor() {
        _initializeOwner(msg.sender);
    }
    
    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function setValue(uint256 value) external validValue(value) {
        _someValue = value;
        emit ValueUpdated(value);
    }
    
    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function getValue() external view returns (uint256) {
        return _someValue;
    }
    
    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function _internalHelper() internal { ... }
}
```

## File Structure
```
project/
├── src/
│   ├── MyContract.sol      # Main deployable contract (directly in src/)
│   ├── interfaces/
│   │   └── IMyContract.sol
│   └── lib/
│       └── MyLibrary.sol
├── test/
│   └── MyContract.t.sol
└── script/
    └── Deploy.s.sol
```
Main deployable contracts go directly in `src/`, not in subdirectories
Use `lib/` for internal libraries
Use `interfaces/` for interface files

## Deployment
Constructor: Use constructor for non-upgradeable contracts
Initializer: Use initializer pattern only for upgradeable contracts (UUPS)
Verification: Attempt to verify on block explorers when deploying

## Multi-chain (if needed)
Use CREATE2 or CREATE3 for deterministic addresses across chains

