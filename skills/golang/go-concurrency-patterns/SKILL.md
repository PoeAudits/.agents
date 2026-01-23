---
name: go-concurrency-patterns
description: Master Go concurrency with goroutines, channels, sync primitives, and context. Use when building concurrent Go applications, implementing worker pools, pipelines, or debugging race conditions.
---

# Go Concurrency Patterns

Production patterns for Go concurrency including goroutines, channels, synchronization primitives, and context management.

## Go Concurrency Mantra

```
Don't communicate by sharing memory;
share memory by communicating.
```

## Core Primitives

| Primitive | Purpose | Key Point |
|-----------|---------|-----------|
| `goroutine` | Lightweight concurrent execution | ~2KB stack, millions can run |
| `channel` | Communication between goroutines | Type-safe, blocks by default |
| `select` | Multiplex channel operations | Like switch for channels |
| `sync.Mutex` | Mutual exclusion | Protect shared state |
| `sync.RWMutex` | Read-heavy workloads | Multiple readers OR one writer |
| `sync.WaitGroup` | Wait for goroutines to complete | Add before, Done after, Wait blocks |
| `sync.Once` | One-time initialization | Thread-safe singleton |
| `context.Context` | Cancellation and deadlines | First parameter, always propagate |

## Goroutines

### Basic Launch

```go
go expensiveComputation(x, y, z)  // Returns immediately
```

### Goroutine Lifecycle Rule

**Every goroutine must have an explicit termination mechanism.**

```go
// Context Cancellation + WaitGroup
func runWorkers(ctx context.Context, n int) {
    var wg sync.WaitGroup

    for i := 0; i < n; i++ {
        wg.Add(1)
        go func(id int) {
            defer wg.Done()

            for {
                select {
                case <-ctx.Done():
                    return // Clean exit
                default:
                    doWork(id)
                }
            }
        }(i)
    }

    wg.Wait()
}

// Usage
ctx, cancel := context.WithCancel(context.Background())
go runWorkers(ctx, 10)
// Later: stop all workers
cancel()
```

### Common Leak: Unbuffered Channel Send

```go
// LEAK: Goroutine blocks forever if no receiver
func leak() {
    ch := make(chan int)
    go func() {
        ch <- 42 // Blocks forever
    }()
    // Function returns, goroutine leaked
}

// FIX: Buffered channel or ensure receiver
func fixed() {
    ch := make(chan int, 1) // Buffer size 1
    go func() {
        ch <- 42 // Won't block
    }()
}
```

## Channels

### Unbuffered vs Buffered

```go
// Unbuffered: Synchronous handoff (both must be ready)
done := make(chan bool)
go func() {
    doWork()
    done <- true // Blocks until main receives
}()
<-done // Guaranteed: work completed

// Buffered: Asynchronous up to buffer size
jobs := make(chan Job, 100)  // Can hold 100 before blocking
```

### Channel Closing Rules

```go
// Only sender closes
jobs := make(chan Job)
go func() {
    for _, job := range allJobs {
        jobs <- job
    }
    close(jobs) // Signal: no more jobs
}()

for job := range jobs {
    process(job) // Exits when channel closed
}

// NEVER: Close from receiver (causes panic)
// NEVER: Close closed channel (causes panic)
// NEVER: Send on closed channel (causes panic)
```

### Channel Direction in Function Signatures

```go
// Read-only channel (receive only)
func consumer(ch <-chan int) {
    for v := range ch {
        process(v)
    }
}

// Write-only channel (send only)
func producer(ch chan<- int) {
    ch <- 42
}
```

## Select Statement

### Timeout Pattern

```go
select {
case v := <-ch:
    fmt.Println("Received:", v)
case <-time.After(time.Second):
    fmt.Println("Timeout!")
}
```

### Non-Blocking with Default

```go
select {
case ch <- 42:
    fmt.Println("Sent")
default:
    fmt.Println("Channel full, skipping")
}
```

### Cancellation Pattern

```go
func worker(ctx context.Context, jobs <-chan Job) {
    for {
        select {
        case job := <-jobs:
            process(job)
        case <-ctx.Done():
            return // Cancel signal
        }
    }
}
```

### Priority Select

```go
highPriority := make(chan int)
lowPriority := make(chan int)

for {
    select {
    case msg := <-highPriority:
        handleHigh(msg)
    default:
        select {
        case msg := <-highPriority:
            handleHigh(msg)
        case msg := <-lowPriority:
            handleLow(msg)
        }
    }
}
```

## Context Package

### Creating Contexts

```go
// Root contexts
ctx := context.Background() // Main/init
ctx := context.TODO()       // Placeholder

// Cancellation
ctx, cancel := context.WithCancel(parent)
defer cancel() // Always call

// Timeout
ctx, cancel := context.WithTimeout(parent, 5*time.Second)
defer cancel()

// Deadline
ctx, cancel := context.WithDeadline(parent, time.Now().Add(5*time.Second))
defer cancel()

// Values (use sparingly, only for request-scoped data)
ctx = context.WithValue(parent, key, value)
```

### Context Best Practices

```go
// Pass context as first parameter
func makeRequest(ctx context.Context, url string) error {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()

    req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)
    resp, err := client.Do(req)
    if err != nil {
        return err // Returns context.DeadlineExceeded on timeout
    }
    defer resp.Body.Close()
    return nil
}

// Check cancellation in loops
func longRunning(ctx context.Context) error {
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        default:
            processChunk()
        }
    }
}
```

### Context Rules

- Pass context as first parameter: `func Do(ctx context.Context, ...)`
- Never store context in struct
- Always call cancel function (prevents leak)
- Use WithValue only for request-scoped data, not options

## Sync Primitives

### sync.Mutex

```go
type Counter struct {
    mu    sync.Mutex
    value int
}

func (c *Counter) Increment() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.value++
}
```

### sync.RWMutex (Read-Heavy Workloads)

```go
type Cache struct {
    mu    sync.RWMutex
    items map[string]Item
}

func (c *Cache) Get(key string) (Item, bool) {
    c.mu.RLock() // Multiple readers allowed
    defer c.mu.RUnlock()
    item, ok := c.items[key]
    return item, ok
}

func (c *Cache) Set(key string, item Item) {
    c.mu.Lock() // Exclusive write
    defer c.mu.Unlock()
    c.items[key] = item
}
```

### sync.WaitGroup

```go
var wg sync.WaitGroup

for _, item := range items {
    wg.Add(1) // BEFORE starting goroutine
    go func(i Item) {
        defer wg.Done()
        process(i)
    }(item)
}

wg.Wait() // Block until all complete
```

### sync.Once (One-Time Initialization)

```go
var (
    instance *Singleton
    once     sync.Once
)

func GetInstance() *Singleton {
    once.Do(func() {
        instance = &Singleton{}
        instance.init()
    })
    return instance
}
```

### sync/atomic (Lock-Free)

```go
type Counter struct {
    value atomic.Int64 // Go 1.19+
}

func (c *Counter) Increment() int64 {
    return c.value.Add(1)
}
```

### When to Use What

| Primitive | Use Case |
|-----------|----------|
| Mutex | Protecting compound operations, complex state |
| RWMutex | Read-heavy (10:1 read:write ratio+) |
| WaitGroup | Waiting for goroutines |
| Once | Lazy initialization |
| Atomic | Simple counters, flags |
| Channels | Communication, coordination |

## Concurrency Patterns

### Pattern 1: Worker Pool

```go
type Job struct {
    ID   int
    Data string
}

type Result struct {
    JobID  int
    Output string
    Err    error
}

func WorkerPool(ctx context.Context, numWorkers int, jobs <-chan Job) <-chan Result {
    results := make(chan Result)

    var wg sync.WaitGroup
    for i := 0; i < numWorkers; i++ {
        wg.Add(1)
        go func(workerID int) {
            defer wg.Done()
            for job := range jobs {
                select {
                case <-ctx.Done():
                    return
                default:
                    results <- processJob(job)
                }
            }
        }(i)
    }

    go func() {
        wg.Wait()
        close(results)
    }()

    return results
}

// Usage
func main() {
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()

    jobs := make(chan Job, 100)

    // Send jobs
    go func() {
        for i := 0; i < 50; i++ {
            jobs <- Job{ID: i, Data: fmt.Sprintf("job-%d", i)}
        }
        close(jobs)
    }()

    // Process with 5 workers
    for result := range WorkerPool(ctx, 5, jobs) {
        fmt.Printf("Result: %+v\n", result)
    }
}
```

### Pattern 2: Pipeline (Generator -> Processor -> Consumer)

```go
// Stage 1: Generate
func generate(ctx context.Context, nums ...int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out)
        for _, n := range nums {
            select {
            case <-ctx.Done():
                return
            case out <- n:
            }
        }
    }()
    return out
}

// Stage 2: Process (square)
func square(ctx context.Context, in <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out)
        for n := range in {
            select {
            case <-ctx.Done():
                return
            case out <- n * n:
            }
        }
    }()
    return out
}

// Usage
func main() {
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()

    // Pipeline: generate -> square -> print
    for n := range square(ctx, generate(ctx, 2, 3, 4)) {
        fmt.Println(n) // 4, 9, 16
    }
}
```

### Pattern 3: Fan-Out/Fan-In

```go
// Fan-in: Merge multiple channels into one
func merge(ctx context.Context, cs ...<-chan int) <-chan int {
    var wg sync.WaitGroup
    out := make(chan int)

    output := func(c <-chan int) {
        defer wg.Done()
        for n := range c {
            select {
            case <-ctx.Done():
                return
            case out <- n:
            }
        }
    }

    wg.Add(len(cs))
    for _, c := range cs {
        go output(c)
    }

    go func() {
        wg.Wait()
        close(out)
    }()

    return out
}

// Usage: Fan out to multiple workers, fan in results
func main() {
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()

    in := generate(ctx, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

    // Fan out to 3 workers
    c1 := square(ctx, in)
    c2 := square(ctx, in)
    c3 := square(ctx, in)

    // Fan in results
    for result := range merge(ctx, c1, c2, c3) {
        fmt.Println(result)
    }
}
```

### Pattern 4: Bounded Concurrency (Semaphore)

```go
import "golang.org/x/sync/semaphore"

type RateLimitedWorker struct {
    sem *semaphore.Weighted
}

func NewRateLimitedWorker(maxConcurrent int64) *RateLimitedWorker {
    return &RateLimitedWorker{
        sem: semaphore.NewWeighted(maxConcurrent),
    }
}

func (w *RateLimitedWorker) Do(ctx context.Context, tasks []func() error) []error {
    var (
        wg     sync.WaitGroup
        mu     sync.Mutex
        errors []error
    )

    for _, task := range tasks {
        if err := w.sem.Acquire(ctx, 1); err != nil {
            return []error{err}
        }

        wg.Add(1)
        go func(t func() error) {
            defer wg.Done()
            defer w.sem.Release(1)

            if err := t(); err != nil {
                mu.Lock()
                errors = append(errors, err)
                mu.Unlock()
            }
        }(task)
    }

    wg.Wait()
    return errors
}

// Alternative: Channel-based semaphore
type Semaphore chan struct{}

func NewSemaphore(n int) Semaphore {
    return make(chan struct{}, n)
}

func (s Semaphore) Acquire() { s <- struct{}{} }
func (s Semaphore) Release() { <-s }
```

### Pattern 5: errgroup (Concurrent Operations with Error Handling)

```go
import "golang.org/x/sync/errgroup"

func fetchAllURLs(ctx context.Context, urls []string) ([]string, error) {
    g, ctx := errgroup.WithContext(ctx)

    results := make([]string, len(urls))

    for i, url := range urls {
        i, url := i, url // Capture loop variables

        g.Go(func() error {
            req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
            if err != nil {
                return fmt.Errorf("creating request for %s: %w", url, err)
            }

            resp, err := http.DefaultClient.Do(req)
            if err != nil {
                return fmt.Errorf("fetching %s: %w", url, err)
            }
            defer resp.Body.Close()

            results[i] = fmt.Sprintf("%s: %d", url, resp.StatusCode)
            return nil
        })
    }

    // Wait for all goroutines; first error cancels all others
    if err := g.Wait(); err != nil {
        return nil, err
    }

    return results, nil
}

// With concurrency limit (Go 1.21+)
func fetchWithLimit(ctx context.Context, urls []string, limit int) ([]string, error) {
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(limit) // Max concurrent goroutines

    results := make([]string, len(urls))

    for i, url := range urls {
        i, url := i, url
        g.Go(func() error {
            // ... fetch logic
            return nil
        })
    }

    return results, g.Wait()
}
```

### Pattern 6: Graceful Shutdown

```go
type Server struct {
    shutdown chan struct{}
    wg       sync.WaitGroup
}

func NewServer() *Server {
    return &Server{
        shutdown: make(chan struct{}),
    }
}

func (s *Server) Start(ctx context.Context) {
    for i := 0; i < 5; i++ {
        s.wg.Add(1)
        go s.worker(ctx, i)
    }
}

func (s *Server) worker(ctx context.Context, id int) {
    defer s.wg.Done()
    defer fmt.Printf("Worker %d stopped\n", id)

    ticker := time.NewTicker(time.Second)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            fmt.Printf("Worker %d cleaning up...\n", id)
            time.Sleep(500 * time.Millisecond) // Simulated cleanup
            return
        case <-ticker.C:
            fmt.Printf("Worker %d working...\n", id)
        }
    }
}

func (s *Server) Shutdown(timeout time.Duration) {
    close(s.shutdown)

    done := make(chan struct{})
    go func() {
        s.wg.Wait()
        close(done)
    }()

    select {
    case <-done:
        fmt.Println("Clean shutdown completed")
    case <-time.After(timeout):
        fmt.Println("Shutdown timed out")
    }
}

func main() {
    ctx, cancel := context.WithCancel(context.Background())

    sigCh := make(chan os.Signal, 1)
    signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

    server := NewServer()
    server.Start(ctx)

    <-sigCh
    cancel()
    server.Shutdown(5 * time.Second)
}
```

### Pattern 7: Query Racing (First Response Wins)

```go
func Query(conns []Conn, query string) Result {
    ch := make(chan Result, 1) // Buffer to prevent goroutine leak

    for _, conn := range conns {
        go func(c Conn) {
            select {
            case ch <- c.DoQuery(query):
            default: // Non-blocking if someone else won
            }
        }(conn)
    }

    return <-ch // Return first result
}
```

### Pattern 8: Concurrent Map

```go
// For frequent reads, infrequent writes: sync.Map
type Cache struct {
    m sync.Map
}

func (c *Cache) Get(key string) (interface{}, bool) {
    return c.m.Load(key)
}

func (c *Cache) Set(key string, value interface{}) {
    c.m.Store(key, value)
}

func (c *Cache) GetOrSet(key string, value interface{}) (interface{}, bool) {
    return c.m.LoadOrStore(key, value)
}

// For write-heavy workloads: Sharded map
type ShardedMap struct {
    shards    []*shard
    numShards int
}

type shard struct {
    sync.RWMutex
    data map[string]interface{}
}

func NewShardedMap(numShards int) *ShardedMap {
    m := &ShardedMap{
        shards:    make([]*shard, numShards),
        numShards: numShards,
    }
    for i := range m.shards {
        m.shards[i] = &shard{data: make(map[string]interface{})}
    }
    return m
}

func (m *ShardedMap) getShard(key string) *shard {
    h := 0
    for _, c := range key {
        h = 31*h + int(c)
    }
    return m.shards[h%m.numShards]
}

func (m *ShardedMap) Get(key string) (interface{}, bool) {
    shard := m.getShard(key)
    shard.RLock()
    defer shard.RUnlock()
    v, ok := shard.data[key]
    return v, ok
}

func (m *ShardedMap) Set(key string, value interface{}) {
    shard := m.getShard(key)
    shard.Lock()
    defer shard.Unlock()
    shard.data[key] = value
}
```

### Pattern 9: Leaky Buffer (Object Reuse)

```go
var freeList = make(chan *Buffer, 100)

func getBuffer() *Buffer {
    select {
    case b := <-freeList:
        return b // Reuse existing
    default:
        return new(Buffer) // Allocate new
    }
}

func putBuffer(b *Buffer) {
    b.Reset()
    select {
    case freeList <- b:
        // Buffer on free list
    default:
        // Free list full, GC will reclaim
    }
}
```

## Race Detection

```bash
# Run tests with race detector
go test -race ./...

# Build with race detector
go build -race .

# Run with race detector
go run -race main.go
```

### Common Race Conditions

```go
// RACE: Unsynchronized map
var cache = make(map[string]string)

func get(key string) string { return cache[key] }    // RACE
func set(key, value string) { cache[key] = value }   // RACE

// FIX: Use sync.Map or mutex
var cache sync.Map
func get(key string) string {
    val, _ := cache.Load(key)
    return val.(string)
}

// RACE: Loop variable capture
for _, item := range items {
    go func() {
        process(item) // RACE: all goroutines see last value
    }()
}

// FIX: Pass as parameter
for _, item := range items {
    go func(i Item) {
        process(i)
    }(item)
}
```

## Common Pitfalls

### 1. Goroutine Leaks

```go
// LEAK: No exit path
go func() {
    for {
        doWork() // Runs forever
    }
}()

// FIX: Context cancellation
go func() {
    for {
        select {
        case <-ctx.Done():
            return
        default:
            doWork()
        }
    }
}()
```

### 2. Deadlock on Unbuffered Channel

```go
// DEADLOCK
ch := make(chan int)
ch <- 1  // Blocks forever - no receiver
v := <-ch

// FIX: Use buffered channel or separate goroutine
ch := make(chan int, 1)
ch <- 1
v := <-ch
```

### 3. Not Calling cancel()

```go
// LEAK: Context resources not freed
ctx, cancel := context.WithCancel(parent)
doWork(ctx)

// FIX: Always defer cancel
ctx, cancel := context.WithCancel(parent)
defer cancel()
doWork(ctx)
```

### 4. time.After in Loops (Memory Leak)

```go
// LEAK: Creates new timer each iteration
for {
    select {
    case <-time.After(5 * time.Second):
        timeout()
    }
}

// FIX: Reuse timer
timer := time.NewTimer(5 * time.Second)
defer timer.Stop()
for {
    select {
    case <-timer.C:
        timeout()
        timer.Reset(5 * time.Second)
    }
}
```

### 5. Defer in Hot Loops

```go
// WRONG: Defers accumulate until function returns
for _, item := range items {
    mu.Lock()
    defer mu.Unlock() // Never executes until function returns
    process(item)
}

// FIX: Explicit unlock
for _, item := range items {
    mu.Lock()
    process(item)
    mu.Unlock()
}
```

## Best Practices Summary

### Do's

- Use context for cancellation and deadlines
- Close channels from sender side only
- Use errgroup for concurrent operations with errors
- Buffer channels when you know the count
- Prefer channels over mutexes when possible
- Always have an exit path for goroutines

### Don'ts

- Don't leak goroutines - always have exit path
- Don't close from receiver - causes panic
- Don't ignore context cancellation - check ctx.Done()
- Don't use time.Sleep for synchronization
- Don't use shared memory without protection
- Don't store context in structs

## Resources

- [Go Concurrency Patterns](https://go.dev/blog/pipelines)
- [Go Context Package](https://go.dev/blog/context)
- [Share Memory By Communicating](https://go.dev/blog/codelab-share)
- [Effective Go - Concurrency](https://go.dev/doc/effective_go#concurrency)
