---
name: go-garbage-collector
description: Master Go garbage collector tuning with GOGC, GOMEMLIMIT, profiling, and heap optimization. Use when debugging GC performance issues, reducing memory usage, tuning GC frequency, analyzing heap allocations, or optimizing Go application memory footprint.
---

# Go Garbage Collector

Production patterns for understanding and tuning Go's mark-sweep garbage collector.

## Core Concepts

### Memory Allocation

| Location | Description | GC Managed |
|----------|-------------|------------|
| Stack | Local variables with known lifetime, compiler determines cleanup | No |
| Heap | Values that "escape" - dynamic size, returned references, closures | Yes |

### GC Model

Go uses a **concurrent, non-moving, mark-sweep** garbage collector:

- **Mark phase**: Traces object graph from roots (globals, stack variables)
- **Sweep phase**: Reclaims unmarked memory
- **Concurrent**: Most work done while application runs (not stop-the-world)

**Cost Formula:**
```
GC CPU cost = (Live heap + GC roots) * Cost per byte + Fixed cost
GC Memory = Live heap + New heap allocated before mark completes
```

## Tuning Parameters

### GOGC (GC Percentage)

Controls trade-off between GC CPU and memory. Sets target heap size for next cycle.

```
Target heap = Live heap + (Live heap + GC roots) * GOGC / 100
```

| GOGC Value | Effect |
|------------|--------|
| 100 (default) | Target = 2x live heap |
| 50 | Half the memory overhead, 2x CPU cost |
| 200 | 2x memory overhead, half CPU cost |
| off | Disable GC (use with GOMEMLIMIT) |

```go
import "runtime/debug"

// Reduce memory at cost of more GC cycles
debug.SetGCPercent(50)

// Increase memory to reduce GC overhead
debug.SetGCPercent(200)

// Disable (requires GOMEMLIMIT to avoid OOM)
debug.SetGCPercent(-1)
```

```bash
GOGC=50 ./myapp
GOGC=off ./myapp  # Only with GOMEMLIMIT set
```

### GOMEMLIMIT (Go 1.19+)

Soft memory limit on total Go runtime memory usage.

```go
import "runtime/debug"

// Set 1GB limit
debug.SetMemoryLimit(1 << 30)
```

```bash
GOMEMLIMIT=1GiB ./myapp
```

**Best practice for containers:**
```bash
# Leave 5-10% headroom for non-Go memory
GOMEMLIMIT=900MiB ./myapp  # In 1GB container
```

**Maximum resource economy (GOGC=off + GOMEMLIMIT):**
```bash
GOGC=off GOMEMLIMIT=1GiB ./myapp
```
This minimizes GC frequency while staying within memory bounds.

**Warning: Thrashing**
If live heap approaches GOMEMLIMIT, GC runs constantly. The runtime limits GC CPU to ~50% to prevent complete stalls, but performance degrades significantly.

### Suggested Configuration

| Scenario | GOGC | GOMEMLIMIT |
|----------|------|------------|
| Default | 100 | Not set |
| Memory constrained container | 100 | 90% of container limit |
| Latency sensitive | 50-100 | Set to prevent spikes |
| Max throughput | off | Set based on available memory |
| Shared with other processes | 50-100 | Not recommended |

## Identifying GC Costs

### CPU Profiles

Look for these functions in `go tool pprof`:

| Function | Indicates |
|----------|-----------|
| `runtime.gcBgMarkWorker` | Background marking (scales with live heap) |
| `runtime.mallocgc` | Heap allocations (>15% = allocation heavy) |
| `runtime.gcAssistAlloc` | Goroutines helping GC (>5% = allocation outpacing GC) |

```bash
go test -cpuprofile cpu.prof -bench .
go tool pprof -top cpu.prof
# Use 'top -cum' to see cumulative time
```

### Execution Traces

```go
import "runtime/trace"

f, _ := os.Create("trace.out")
trace.Start(f)
defer trace.Stop()
```

```bash
go tool trace trace.out
```

### GC Traces

```bash
# Basic GC trace
GODEBUG=gctrace=1 ./myapp

# Pacer trace (advanced)
GODEBUG=gcpacertrace=1 ./myapp
```

## Reducing Heap Allocations

### Heap Profiling

```bash
go test -memprofile mem.prof -bench .
go tool pprof -alloc_space mem.prof  # Total allocations (best for GC tuning)
go tool pprof -inuse_space mem.prof  # Current live memory
```

### Escape Analysis

```bash
# See escape decisions
go build -gcflags='-m=3' ./...

# VS Code: "Source Action... > Show compiler optimization details"
```

Common escape causes:
- Returning pointers to local variables
- Storing in interface{}
- Closures capturing variables
- Size determined at runtime (variable-length slices)

### Implementation Optimizations

**Pointer-free structs are cheaper to scan:**
```go
// Faster: No pointers
type Fast struct {
    ID   int
    Data [100]byte
}

// Slower: Contains pointers
type Slow struct {
    ID   int
    Data *[100]byte
}
```

**Group pointers at struct start:**
```go
// Better: GC stops scanning after last pointer
type Optimized struct {
    Next *Node      // Pointers first
    Prev *Node
    Data [1024]byte // Non-pointer fields last
}
```

**Use indices instead of pointers:**
```go
// Reduce GC work with index-based references
type Pool struct {
    items []Item
}

func (p *Pool) Get(idx int) *Item {
    return &p.items[idx]
}
```

## Linux Transparent Huge Pages

For heaps > 1GiB, THP can improve throughput 5-10%.

**Recommended settings:**
```bash
# Enable THP
echo always > /sys/kernel/mm/transparent_hugepage/enabled

# Use lazy coalescing (avoids stalls)
echo defer > /sys/kernel/mm/transparent_hugepage/defrag

# Prevent khugepaged from undoing Go's memory returns
echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none
```

**Disable THP for specific process (Go 1.21.6+):**
```bash
GODEBUG=disablethp=1 ./myapp
```

## Finalizers, Cleanups, and Weak Pointers

### Prefer Cleanups (Go 1.24+) Over Finalizers

```go
// Cleanup: More efficient, no object resurrection
f := new(myFile)
f.fd = syscall.Open(...)
runtime.AddCleanup(f, func(fd int) {
    syscall.Close(fd)
}, f.fd)
```

```go
// Finalizer: Object is resurrected, less efficient
runtime.SetFinalizer(f, func(f *myFile) {
    syscall.Close(f.fd)
})
```

### Common Mistakes

**Cleanup referencing the object (never runs):**
```go
// WRONG: Cleanup keeps f alive
runtime.AddCleanup(f, func(fd int) {
    syscall.Close(f.fd)  // References f!
}, f.fd)

// CORRECT: Only use the argument
runtime.AddCleanup(f, func(fd int) {
    syscall.Close(fd)
}, f.fd)
```

**Finalizer on cyclic structure (never runs):**
```go
// WRONG: Cycle prevents collection
f := new(myCycle)
f.self = f
runtime.SetFinalizer(f, func(f *myCycle) { ... })
```

### Testing Tips

```go
// Force GC and wait for cleanups/finalizers
runtime.GC()
runtime.Gosched()  // May need to loop checking state
```

## Best Practices

### Do's
- Profile before tuning (heap profiles, CPU profiles, traces)
- Set GOMEMLIMIT in containers (with 5-10% headroom)
- Use stack allocation when possible (avoid escaping)
- Prefer cleanups over finalizers (Go 1.24+)
- Close resources explicitly (don't rely solely on GC)

### Don'ts
- Don't set GOMEMLIMIT too close to live heap (causes thrashing)
- Don't set GOGC=off without GOMEMLIMIT
- Don't use GOMEMLIMIT in unknown environments (CLI tools)
- Don't create reference cycles with finalizers
- Don't capture objects in cleanup/finalizer functions
