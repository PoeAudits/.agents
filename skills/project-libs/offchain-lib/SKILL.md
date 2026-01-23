---
name: offchain-lib
description: Use when working with the offchain-lib, a library for working with off-chain data, such as APIs, databases, and files. Includes batching logic for rpc calls.
---

# offchain-lib - Agent Guide

A Python library for efficient off-chain Ethereum data gathering with automatic batching, typed results, intelligent caching, and multi-source pricing.

## Quick Reference

```bash
# Usage example
from offchain_lib import connect

lib = connect("http://localhost:8545")
with lib.batch() as batch:
    weth = batch.token(WETH_ADDR).get_symbol().get_decimals().get_balance_of(HOLDER)
    pair = batch.v2_pair(PAIR_ADDR).get_reserves().get_token0()
# Results populated after context exit
print(weth.symbol_value, weth.balance.value)
```

---

## Architecture Overview

```
src/offchain_lib/
├── __init__.py          # OffchainLib main class, connect() function
├── config.py            # Config, CacheConfig, MulticallConfig, PricingConfig
├── errors.py            # Exception hierarchy
├── logging.py           # Library logging configuration
├── core/
│   ├── batch.py         # BatchContext - the main orchestrator
│   ├── executor.py      # MulticallExecutor - RPC batching
│   ├── retry.py         # RetryStrategy, with_retry helper
│   └── types.py         # CacheType, PendingCall, PriceCall, CallResult
├── entities/
│   ├── base.py          # BaseEntity, FieldResult, NotQueried, NOT_QUERIED
│   ├── token.py         # Token entity (ERC20)
│   ├── v2_pair.py       # V2Pair entity (Uniswap V2)
│   └── v3_pool.py       # V3Pool entity (Uniswap V3), Slot0Data
├── cache/
│   ├── database.py      # CacheDatabase - SQLite connection
│   ├── schema.py        # SQL schema definitions
│   ├── static.py        # StaticCache - permanent cache (symbol, decimals)
│   ├── dynamic.py       # DynamicCache - TTL-based cache
│   └── prices.py        # PriceCache - price storage
├── multicall/
│   ├── encoder.py       # SELECTORS dict, encode_call()
│   ├── decoder.py       # decode_string, decode_uint256, etc.
│   └── batcher.py       # CallBatcher - groups calls
└── pricing/
    ├── aggregator.py    # PriceAggregator, AggregatedPrice
    ├── outliers.py      # eliminate_outliers()
    └── sources/
        ├── base.py      # PriceSource protocol
        ├── defillama.py # DefiLlamaSource
        ├── coingecko.py # CoinGeckoSource
        └── uniswap_v3.py # UniswapV3Source (placeholder)
```

---

## Core Concepts

### 1. BatchContext (core/batch.py)

The central orchestrator. Collects calls, checks cache, executes via multicall, populates results.

```python
with lib.batch() as batch:
    token = batch.token(address)  # Creates entity bound to batch
    token.get_symbol()            # Queues call, returns self for chaining
# On exit: cache check -> multicall -> populate results -> update cache
```

**Key methods:**
- `token(address)`, `v2_pair(address)`, `v3_pool(address)` - Create entities
- `_queue_call(call, entity)` - Called by entities to queue RPC calls
- `_execute()` - Called on context exit, orchestrates everything

### 2. Entities (entities/)

Dataclasses representing on-chain contracts. Each field is wrapped in `FieldResult[T]`.

**Pattern:**
```python
@dataclass
class Token(BaseEntity):
    symbol: FieldResult[str] = field(default_factory=make_field_result)
    
    def get_symbol(self) -> Token:
        call = PendingCall(target=self.address, selector=SELECTORS["symbol"], ...)
        self._queue(call)
        return self  # Chainable
    
    @property
    def symbol_value(self) -> str:
        # Raises AttributeError if not queried, RuntimeError if failed
        return self._get_value(self.symbol, "symbol")
```

**Available entities:**
- `Token` - ERC20: symbol, decimals, name, balance, total_supply, price_usd
- `V2Pair` - Uniswap V2: token0, token1, reserves, total_supply
- `V3Pool` - Uniswap V3: token0, token1, fee, liquidity, slot0, protocol_fees

### 3. FieldResult (entities/base.py)

Wrapper for query results with explicit success/failure tracking:

```python
@dataclass
class FieldResult(Generic[T]):
    value: T | NotQueried = NOT_QUERIED
    success: bool = False
    error: str | None = None
    
    @property
    def ok(self) -> bool:
        return self.success and not isinstance(self.value, NotQueried)
```

**Usage patterns:**
```python
# Check before access
if token.symbol.ok:
    print(token.symbol.value)

# Or use convenience property (raises on failure)
print(token.symbol_value)

# Check for errors
if not token.balance.success:
    print(f"Error: {token.balance.error}")
```

### 4. CacheType (core/types.py)

```python
class CacheType(Enum):
    NONE = "none"      # Don't cache
    STATIC = "static"  # Cache permanently (symbol, decimals, name, token0, token1, fee)
    DYNAMIC = "dynamic"  # Cache with TTL (balances, reserves, liquidity)
```

### 5. PendingCall (core/types.py)

Represents a queued RPC call:

```python
@dataclass
class PendingCall:
    target: str           # Contract address
    selector: bytes       # Function selector (4 bytes)
    args: bytes           # ABI-encoded arguments
    cache_type: CacheType
    cache_key: str | None # Format: "chain_id:address:field[:extra]"
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `__init__.py` | `OffchainLib` class, `connect()` function |
| `core/batch.py` | `BatchContext` - main orchestrator |
| `core/types.py` | `CacheType`, `PendingCall`, `PriceCall`, `CallResult` |
| `entities/base.py` | `BaseEntity`, `FieldResult`, `NOT_QUERIED` |
| `entities/token.py` | `Token` entity with ERC20 methods |
| `multicall/encoder.py` | `SELECTORS` dict for function signatures |
| `cache/static.py` | `StaticCache`, `TokenData`, `V2PairData`, `V3PoolData`, `V2PositionData`, `DiscoveredTokenData` |
| `cache/dynamic.py` | `DynamicCache` - TTL-based cache with `set_many()` for bulk writes |
| `cache/prices.py` | `PriceCache` - price storage with `set_prices_many()` for bulk writes |
| `cache/diff.py` | `DiffResult`, comparison functions for cache data diffing |
| `config.py` | All configuration dataclasses |
| `errors.py` | Exception hierarchy |

---

## Cache Key Format

```
chain_id:address:field_name[:extra_key]

Examples:
1:0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2:symbol
1:0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2:balanceOf:0x1234...
1:0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc:getReserves
```

---

## Error Handling

```python
from offchain_lib import (
    OffchainError,      # Base for all library errors
    ConfigError,        # Configuration issues
    ConnectionError,    # RPC connection failures
    MulticallError,     # Multicall execution failures
    CacheError,         # Cache operation failures
    PricingError,       # Price fetching failures
    EntityError,        # Entity-related errors
)
```

---

## Logging

```python
from offchain_lib import configure_logging, get_logger
import logging

configure_logging(level=logging.DEBUG)

# Or get logger directly
logger = get_logger()
logger.info("Custom message")
```

Log levels used:
- DEBUG: Cache hits, individual call results, diff timing, cache bulk writes
- INFO: Batch execution summary, price aggregation
- WARNING: Retries, rate limits, partial failures, slow diff operations (>100ms)
- ERROR: Failed calls, connection errors
```bash
