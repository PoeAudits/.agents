---
name: go-diagnostics
description: Master Go diagnostics including profiling (CPU, memory, goroutine), tracing, debugging with Delve, and runtime statistics. Use when diagnosing performance issues, memory leaks, goroutine leaks, analyzing latency, debugging Go applications, or understanding runtime behavior.
---

# Go Diagnostics

Comprehensive guide for diagnosing logic and performance problems in Go programs using profiling, tracing, debugging, and runtime statistics.

## Diagnostics Categories

| Category | Purpose | Tools |
|----------|---------|-------|
| Profiling | Analyze CPU, memory, blocking | pprof, go tool pprof |
| Tracing | Analyze latency, execution flow | go tool trace, distributed tracers |
| Debugging | Inspect program state | Delve, GDB |
| Runtime Stats | Monitor health metrics | runtime, debug packages |

**Note:** Diagnostics tools may interfere with each other. Use tools in isolation for precise measurements.

## Profiling with pprof

### Built-in Profiles

| Profile | Description | Default |
|---------|-------------|---------|
| cpu | CPU time consumption | Enabled |
| heap | Memory allocation samples | Enabled |
| goroutine | Stack traces of all goroutines | Enabled |
| threadcreate | OS thread creation points | Enabled |
| block | Goroutine blocking on sync primitives | Disabled |
| mutex | Lock contention | Disabled |

### Enable HTTP Profiling

```go
import (
    "net/http"
    _ "net/http/pprof" // Side-effect import registers handlers
)

func main() {
    // Profiles available at /debug/pprof/
    go http.ListenAndServe(":6060", nil)
    
    // Your application code
}
```

### Custom Profiler Path

```go
import (
    "log"
    "net/http"
    "net/http/pprof"
)

func main() {
    mux := http.NewServeMux()
    mux.HandleFunc("/custom_debug_path/profile", pprof.Profile)
    mux.HandleFunc("/custom_debug_path/heap", pprof.Handler("heap").ServeHTTP)
    log.Fatal(http.ListenAndServe(":7777", mux))
}
```

### Enable Block and Mutex Profiles

```go
import "runtime"

func init() {
    runtime.SetBlockProfileRate(1)     // Enable block profiling
    runtime.SetMutexProfileFraction(1) // Enable mutex profiling
}
```

### Collect Profiles via CLI

```bash
# CPU profile (30 seconds)
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30

# Heap profile
go tool pprof http://localhost:6060/debug/pprof/heap

# Goroutine profile
go tool pprof http://localhost:6060/debug/pprof/goroutine

# Block profile (must be enabled)
go tool pprof http://localhost:6060/debug/pprof/block

# Mutex profile (must be enabled)
go tool pprof http://localhost:6060/debug/pprof/mutex
```

### pprof Commands

```bash
# Interactive mode
go tool pprof <profile>

# Inside pprof:
top           # Show top consumers
top10         # Top 10 consumers
list <func>   # Source-level view of function
web           # Open graph in browser
weblist <func> # Source view in browser (shows line-by-line cost)
pdf           # Generate PDF report
```

### Programmatic Profiling

```go
import (
    "os"
    "runtime/pprof"
)

func profileCPU() {
    f, _ := os.Create("cpu.prof")
    defer f.Close()
    pprof.StartCPUProfile(f)
    defer pprof.StopCPUProfile()
    
    // Code to profile
}

func profileMemory() {
    f, _ := os.Create("mem.prof")
    defer f.Close()
    
    // Code to profile
    
    pprof.WriteHeapProfile(f)
}
```

### Profile During Tests

```bash
# CPU profile
go test -cpuprofile=cpu.prof -bench=.

# Memory profile
go test -memprofile=mem.prof -bench=.

# Block profile
go test -blockprofile=block.prof -bench=.

# Analyze
go tool pprof cpu.prof
```

## Execution Tracer

Capture runtime events including scheduling, syscalls, GC, and goroutine execution.

### Collect Trace

```bash
# Via HTTP endpoint
curl -o trace.out http://localhost:6060/debug/pprof/trace?seconds=5

# Via test
go test -trace=trace.out

# Analyze
go tool trace trace.out
```

### Programmatic Tracing

```go
import (
    "os"
    "runtime/trace"
)

func main() {
    f, _ := os.Create("trace.out")
    defer f.Close()
    
    trace.Start(f)
    defer trace.Stop()
    
    // Code to trace
}
```

### Trace Use Cases

- Understand goroutine execution patterns
- Identify GC impact on latency
- Detect poorly parallelized execution
- Find syscall/network blocking issues

**Note:** Use profiling (not tracing) for CPU/memory hot spots.

## Debugging with Delve

Delve is the recommended debugger for Go programs.

### Install

```bash
go install github.com/go-delve/delve/cmd/dlv@latest
```

### Build for Debugging

```bash
# Disable optimizations for accurate debugging
go build -gcflags=all="-N -l" -o app .

# With DWARF location lists (allows debugging optimized code)
go build -gcflags="-dwarflocationlists=true" -o app .
```

### Debug Commands

```bash
# Debug current package
dlv debug

# Debug specific binary
dlv exec ./app

# Attach to running process
dlv attach <pid>

# Debug test
dlv test

# Connect remotely
dlv connect localhost:2345
```

### Delve Commands

```
break main.main      # Set breakpoint
break file.go:42     # Breakpoint at line
continue             # Run until breakpoint
next                 # Step over
step                 # Step into
stepout              # Step out
print <var>          # Print variable
locals               # Show local variables
args                 # Show function arguments
goroutines           # List goroutines
goroutine <id>       # Switch to goroutine
stack                # Print stack trace
```

## Runtime Statistics

### Memory Statistics

```go
import "runtime"

func printMemStats() {
    var m runtime.MemStats
    runtime.ReadMemStats(&m)
    
    // Heap
    fmt.Printf("HeapAlloc: %d MB\n", m.HeapAlloc/1024/1024)
    fmt.Printf("HeapSys: %d MB\n", m.HeapSys/1024/1024)
    fmt.Printf("HeapObjects: %d\n", m.HeapObjects)
    
    // GC
    fmt.Printf("NumGC: %d\n", m.NumGC)
    fmt.Printf("GCPauseTotal: %d ms\n", m.PauseTotalNs/1000000)
}
```

### GC Statistics

```go
import "runtime/debug"

func printGCStats() {
    var stats debug.GCStats
    debug.ReadGCStats(&stats)
    
    fmt.Printf("LastGC: %v\n", stats.LastGC)
    fmt.Printf("NumGC: %d\n", stats.NumGC)
    fmt.Printf("PauseTotal: %v\n", stats.PauseTotal)
}
```

### Goroutine Monitoring

```go
import "runtime"

func monitorGoroutines() {
    fmt.Printf("NumGoroutine: %d\n", runtime.NumGoroutine())
}

// Get stack trace
func dumpStacks() {
    buf := make([]byte, 1024*1024)
    n := runtime.Stack(buf, true) // true = all goroutines
    fmt.Printf("%s\n", buf[:n])
}
```

### Heap Dump

```go
import "runtime/debug"

func writeHeapDump() {
    f, _ := os.Create("heap.dump")
    defer f.Close()
    debug.WriteHeapDump(f.Fd())
}
```

## GODEBUG Environment Variable

### GC Tracing

```bash
# Print GC events
GODEBUG=gctrace=1 ./app

# Output format:
# gc 1 @0.012s 2%: 0.026+0.17+0.019 ms clock, 0.21+0.047/0.16/0.14+0.15 ms cpu, 4->4->0 MB, 5 MB goal, 8 P
```

### Init Tracing

```bash
# Print package initialization timing
GODEBUG=inittrace=1 ./app
```

### Scheduler Tracing

```bash
# Print scheduling events every 1000ms
GODEBUG=schedtrace=1000 ./app

# With detailed goroutine info
GODEBUG=schedtrace=1000,scheddetail=1 ./app
```

### Disable CPU Extensions

```bash
# Disable all optional CPU instructions
GODEBUG=cpu.all=off ./app

# Disable specific extension
GODEBUG=cpu.sse41=off ./app
GODEBUG=cpu.avx=off ./app
```

## Quick Reference

### Performance Issue Diagnosis

| Symptom | Tool | Command |
|---------|------|---------|
| High CPU | CPU profile | `go tool pprof http://localhost:6060/debug/pprof/profile` |
| Memory growth | Heap profile | `go tool pprof http://localhost:6060/debug/pprof/heap` |
| Goroutine leak | Goroutine profile | `go tool pprof http://localhost:6060/debug/pprof/goroutine` |
| Latency spikes | Execution trace | `go tool trace trace.out` |
| Lock contention | Mutex profile | `go tool pprof http://localhost:6060/debug/pprof/mutex` |
| Blocking on channels | Block profile | `go tool pprof http://localhost:6060/debug/pprof/block` |

### Production Profiling Tips

- Safe to profile in production (expect slight overhead)
- Collect one profile type at a time
- Use periodic sampling from random replicas
- CPU profiling adds ~5% overhead when active
