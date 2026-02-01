---
name: go-testing
description: Write effective Go tests using table-driven patterns, test helpers, benchmarks, HTTP handler testing, and integration test strategies. Use when writing unit tests, benchmarks, mocking dependencies, or setting up test infrastructure in Go projects.
---

# Go Testing

Production patterns for writing effective, maintainable Go tests.

## Table-Driven Tests

The standard Go testing pattern. Use anonymous structs for test cases.

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive numbers", 2, 3, 5},
        {"negative numbers", -2, -3, -5},
        {"mixed signs", -2, 3, 1},
        {"zeros", 0, 0, 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d",
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}
```

### With Error Cases

```go
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        wantErr bool
    }{
        {"valid email", "user@example.com", false},
        {"missing @", "userexample.com", true},
        {"empty string", "", true},
        {"missing domain", "user@", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := validateEmail(tt.email)
            if (err != nil) != tt.wantErr {
                t.Errorf("validateEmail(%q) error = %v, wantErr %v",
                    tt.email, err, tt.wantErr)
            }
        })
    }
}
```

### Parallel Tests

```go
func TestCalculatePrice(t *testing.T) {
    t.Parallel() // Mark test as parallel-safe

    tests := []struct {
        name     string
        quantity int
        price    float64
        expected float64
    }{
        {"single item", 1, 10.0, 10.0},
        {"multiple items", 5, 10.0, 50.0},
    }

    for _, tt := range tests {
        tt := tt // Capture range variable (required for parallel)
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel() // Run subtests in parallel
            result := CalculatePrice(tt.quantity, tt.price)
            if result != tt.expected {
                t.Errorf("got %v, want %v", result, tt.expected)
            }
        })
    }
}
```

## Test Helpers

### Using t.Helper()

Mark helper functions so errors report the caller's line number:

```go
func assertEqual(t *testing.T, got, want interface{}) {
    t.Helper() // Error points to caller, not this line
    if got != want {
        t.Errorf("got %v, want %v", got, want)
    }
}

func assertNoError(t *testing.T, err error) {
    t.Helper()
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}

func assertError(t *testing.T, err error) {
    t.Helper()
    if err == nil {
        t.Fatal("expected error, got nil")
    }
}
```

### Test Setup with Cleanup

```go
func setupTestDB(t *testing.T) *sql.DB {
    t.Helper()

    db, err := sql.Open("sqlite3", ":memory:")
    if err != nil {
        t.Fatalf("failed to open test db: %v", err)
    }

    // Automatic cleanup when test completes
    t.Cleanup(func() {
        db.Close()
    })

    // Run migrations
    if err := runMigrations(db); err != nil {
        t.Fatalf("failed to run migrations: %v", err)
    }

    return db
}

func TestUserRepository(t *testing.T) {
    db := setupTestDB(t) // Cleanup runs automatically

    repo := NewUserRepository(db)
    // ... test code
}
```

### Temporary Directories

```go
func TestFileProcessing(t *testing.T) {
    // Creates temp dir, cleaned up automatically
    dir := t.TempDir()

    testFile := filepath.Join(dir, "test.txt")
    if err := os.WriteFile(testFile, []byte("test data"), 0644); err != nil {
        t.Fatal(err)
    }

    result, err := ProcessFile(testFile)
    // ... assertions
}
```

## HTTP Handler Testing

Use `net/http/httptest` for testing HTTP handlers:

```go
import (
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestHandler(t *testing.T) {
    // Create request
    req := httptest.NewRequest("GET", "/api/users", nil)
    req.Header.Set("Content-Type", "application/json")

    // Create response recorder
    w := httptest.NewRecorder()

    // Call handler
    handler(w, req)

    // Check response
    resp := w.Result()
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        t.Errorf("expected status 200, got %d", resp.StatusCode)
    }

    body, _ := io.ReadAll(resp.Body)
    if !strings.Contains(string(body), "expected content") {
        t.Errorf("unexpected body: %s", body)
    }
}
```

### Testing with Request Body

```go
func TestCreateUser(t *testing.T) {
    body := strings.NewReader(`{"name": "John", "email": "john@example.com"}`)
    req := httptest.NewRequest("POST", "/api/users", body)
    req.Header.Set("Content-Type", "application/json")

    w := httptest.NewRecorder()
    createUserHandler(w, req)

    if w.Code != http.StatusCreated {
        t.Errorf("expected 201, got %d", w.Code)
    }
}
```

### Test Server for Integration

```go
func TestAPIClient(t *testing.T) {
    // Create test server
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        if r.URL.Path != "/api/data" {
            t.Errorf("unexpected path: %s", r.URL.Path)
        }
        w.WriteHeader(http.StatusOK)
        w.Write([]byte(`{"result": "success"}`))
    }))
    defer server.Close()

    // Use test server URL
    client := NewAPIClient(server.URL)
    result, err := client.GetData()

    assertNoError(t, err)
    assertEqual(t, result, "success")
}
```

## Benchmarks

```go
func BenchmarkFibonacci(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Fibonacci(20)
    }
}

// With setup (excluded from timing)
func BenchmarkSort(b *testing.B) {
    data := generateTestData(10000)

    b.ResetTimer() // Exclude setup from timing

    for i := 0; i < b.N; i++ {
        Sort(data)
    }
}

// Parallel benchmark
func BenchmarkConcurrentMap(b *testing.B) {
    m := make(map[string]int)
    var mu sync.Mutex

    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
            mu.Lock()
            m["key"]++
            mu.Unlock()
        }
    })
}

// Sub-benchmarks for different input sizes
func BenchmarkProcess(b *testing.B) {
    sizes := []int{10, 100, 1000, 10000}

    for _, size := range sizes {
        b.Run(fmt.Sprintf("size-%d", size), func(b *testing.B) {
            data := make([]int, size)
            b.ResetTimer()
            for i := 0; i < b.N; i++ {
                Process(data)
            }
        })
    }
}
```

### Running Benchmarks

```bash
# Run all benchmarks
go test -bench=. ./...

# Run specific benchmark
go test -bench=BenchmarkFibonacci

# With memory allocation stats
go test -bench=. -benchmem

# Run for specific duration
go test -bench=. -benchtime=5s

# Compare benchmarks (requires benchstat)
go test -bench=. -count=10 > old.txt
# ... make changes ...
go test -bench=. -count=10 > new.txt
benchstat old.txt new.txt
```

## Integration Tests

### Build Tags

Separate integration tests using build tags:

```go
//go:build integration

package myapp_test

import "testing"

func TestDatabaseOperations(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test in short mode")
    }

    db := setupTestDatabase(t)

    err := InsertUser(db, &User{Name: "John"})
    if err != nil {
        t.Fatalf("failed to insert user: %v", err)
    }

    user, err := GetUser(db, "John")
    assertNoError(t, err)
    assertEqual(t, user.Name, "John")
}
```

### Running Tests

```bash
# Unit tests only (default)
go test ./...

# Skip slow tests
go test -short ./...

# Include integration tests
go test -tags=integration ./...

# Verbose output
go test -v ./...

# With coverage
go test -cover ./...
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

## Mocking Patterns

### Interface-Based Mocking

```go
// Define interface at consumer site
type UserRepository interface {
    GetUser(id int) (*User, error)
    SaveUser(user *User) error
}

// Mock implementation
type MockUserRepository struct {
    GetUserFunc  func(id int) (*User, error)
    SaveUserFunc func(user *User) error
}

func (m *MockUserRepository) GetUser(id int) (*User, error) {
    return m.GetUserFunc(id)
}

func (m *MockUserRepository) SaveUser(user *User) error {
    return m.SaveUserFunc(user)
}

// Usage in test
func TestUserService(t *testing.T) {
    mock := &MockUserRepository{
        GetUserFunc: func(id int) (*User, error) {
            return &User{ID: id, Name: "Test User"}, nil
        },
    }

    service := NewUserService(mock)
    user, err := service.GetUser(1)

    assertNoError(t, err)
    assertEqual(t, user.Name, "Test User")
}
```

### Recording Mock Calls

```go
type MockRepository struct {
    Calls []string
    // ... methods
}

func (m *MockRepository) GetUser(id int) (*User, error) {
    m.Calls = append(m.Calls, fmt.Sprintf("GetUser(%d)", id))
    return &User{ID: id}, nil
}

func TestServiceCallsRepository(t *testing.T) {
    mock := &MockRepository{}
    service := NewService(mock)

    service.ProcessUser(1)

    if len(mock.Calls) != 1 {
        t.Errorf("expected 1 call, got %d", len(mock.Calls))
    }
    if mock.Calls[0] != "GetUser(1)" {
        t.Errorf("unexpected call: %s", mock.Calls[0])
    }
}
```

## Testing Concurrent Code

### Race Detector

```bash
go test -race ./...
```

### Testing with Goroutines

```go
func TestConcurrentAccess(t *testing.T) {
    counter := NewCounter()
    var wg sync.WaitGroup

    for i := 0; i < 100; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            counter.Increment()
        }()
    }

    wg.Wait()

    if counter.Value() != 100 {
        t.Errorf("expected 100, got %d", counter.Value())
    }
}
```

### Testing Timeouts

```go
func TestWithTimeout(t *testing.T) {
    ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
    defer cancel()

    result := make(chan int, 1)
    go func() {
        // Simulated slow operation
        time.Sleep(50 * time.Millisecond)
        result <- 42
    }()

    select {
    case v := <-result:
        assertEqual(t, v, 42)
    case <-ctx.Done():
        t.Fatal("operation timed out")
    }
}
```

## Test Organization

### File Structure

```
package/
├── user.go
├── user_test.go          # Unit tests
├── user_bench_test.go    # Benchmarks (optional)
└── user_integration_test.go  # Integration tests (with build tag)
```

### TestMain for Setup/Teardown

```go
func TestMain(m *testing.M) {
    // Setup
    db := setupTestDatabase()

    // Run tests
    code := m.Run()

    // Teardown
    db.Close()

    os.Exit(code)
}
```

## Best Practices

### Do's

- **Use `t.Helper()`** - In all test helper functions
- **Use `t.Cleanup()`** - For automatic resource cleanup
- **Use `t.Parallel()`** - For independent tests (capture loop variables!)
- **Use subtests** - `t.Run()` for organized, filterable tests
- **Test error messages** - Verify errors contain expected context
- **Use table-driven tests** - For comprehensive coverage

### Don'ts

- **Don't use `t.Parallel()` with shared state** - Unless properly synchronized
- **Don't ignore cleanup** - Use `defer` or `t.Cleanup()`
- **Don't test implementation details** - Test behavior, not internals
- **Don't write flaky tests** - Avoid time-dependent assertions
- **Don't use `time.Sleep()` for synchronization** - Use channels or sync primitives

## Quick Reference

| Command | Purpose |
|---------|---------|
| `go test ./...` | Run all tests |
| `go test -v` | Verbose output |
| `go test -run=TestName` | Run specific test |
| `go test -short` | Skip slow tests |
| `go test -race` | Enable race detector |
| `go test -cover` | Show coverage |
| `go test -bench=.` | Run benchmarks |
| `go test -benchmem` | Show allocations |
| `go test -tags=integration` | Include tagged tests |
| `go test -count=1` | Disable test caching |
