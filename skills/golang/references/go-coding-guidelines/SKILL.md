---
name: go-coding-guidelines
description: Must be read if not already read before writing any Go code.
---

# Go Coding Guidelines

Core Go coding standards for writing idiomatic, clean, and maintainable Go code. This skill covers naming conventions, interface design, error handling patterns, and common anti-patterns to avoid.

## Philosophy

- **Simplicity**: "Clear is better than clever" - favor readable code over abstractions
- **Explicit over implicit**: No exceptions, no hidden control flow, visible errors
- **Composition over inheritance**: Interfaces and embedding, not class hierarchies
- **Small interfaces**: 1-3 methods ideal, consumer-side placement

## Formatting

Use `gofmt` - non-negotiable. It handles indentation (tabs), alignment, and spacing.

```go
// gofmt aligns struct field comments automatically
type T struct {
    name    string // name of the object
    value   int    // its value
}
```

**Key rules:**
- Tabs for indentation
- No line length limit (wrap long lines with extra tab indent)
- No parentheses in control structures: `if x > 0 {` not `if (x > 0) {`

## Naming Conventions

### Package Names

Short, lowercase, single-word. No underscores or mixedCaps.

```go
import "encoding/base64"  // Package name is base64, not encoding_base64
```

Avoid stutter - use `bufio.Reader` not `bufio.BufReader`.

### Exported Names

Visibility determined by first character case:
- `Uppercase` = exported (public)
- `lowercase` = unexported (private)

### Getters and Setters

No `Get` prefix for getters:

```go
// GOOD
func (a *Account) Balance() int { return a.balance }
func (a *Account) SetBalance(amount int) { a.balance = amount }

// BAD - Java-style
func (a *Account) GetBalance() int { return a.balance }
```

### Error Variables

```go
// Exported sentinel errors (capitalized)
var ErrNotFound = errors.New("not found")
var ErrTimeout = errors.New("timeout")

// Unexported internal errors (lowercase)
var errInternal = errors.New("internal error")
```

### Interface Naming

One-method interfaces: method name + `-er` suffix.

```go
type Reader interface { Read(p []byte) (n int, err error) }
type Writer interface { Write(p []byte) (n int, err error) }
type Stringer interface { String() string }
```

Honor canonical names: `Read`, `Write`, `Close`, `Flush`, `String` have expected signatures.

### MixedCaps

Always use `MixedCaps` or `mixedCaps`, never underscores.

## Interface Design

**"The Bigger the Interface, the Weaker the Abstraction"**

### Single-Method Interfaces (Ideal)

```go
type Reader interface { Read(p []byte) (n int, err error) }
type Writer interface { Write(p []byte) (n int, err error) }
type Closer interface { Close() error }

// Compose interfaces
type ReadCloser interface {
    Reader
    Closer
}
```

### Consumer-Side Interface Placement

```go
// WRONG: Producer defines interface
package store
type CustomerStorage interface {
    StoreCustomer(Customer) error
    GetCustomer(string) (Customer, error)
    UpdateCustomer(Customer) error
    // 10+ methods...
}

// CORRECT: Consumer defines what it needs
package client
type customerGetter interface {
    GetCustomer(string) (store.Customer, error)
}

func ProcessCustomer(cg customerGetter) {
    customer, _ := cg.GetCustomer("123")
    // Only depends on GetCustomer method
}
```

### Return Concrete Types, Accept Interfaces (Postel's Law)

```go
// GOOD
func NewStore() *PostgresStore { return &PostgresStore{} }
func Process(storage CustomerStorage) error { /* Accepts interface */ }

// BAD: Returning interface
func NewStore() CustomerStorage { return &PostgresStore{} }
```

### When to Create Interfaces

- Multiple implementations exist or are planned
- Need for testing (mocking dependencies)
- Decoupling packages
- **NOT for**: Single implementation with no testing need

## Control Flow

### Happy Path Left, Early Returns

Align success path to left margin, handle errors first.

```go
// BAD: Deep nesting
func join(s1, s2 string, max int) (string, error) {
    if s1 == "" {
        return "", errors.New("s1 is empty")
    } else {
        if s2 == "" {
            return "", errors.New("s2 is empty")
        } else {
            concat, err := concatenate(s1, s2)
            if err != nil {
                return "", err
            } else {
                if len(concat) > max {
                    return concat[:max], nil
                } else {
                    return concat, nil
                }
            }
        }
    }
}

// GOOD: Happy path aligned left
func join(s1, s2 string, max int) (string, error) {
    if s1 == "" {
        return "", errors.New("s1 is empty")
    }
    if s2 == "" {
        return "", errors.New("s2 is empty")
    }

    concat, err := concatenate(s1, s2)
    if err != nil {
        return "", err
    }

    if len(concat) > max {
        return concat[:max], nil
    }
    return concat, nil
}
```

**Guidelines:**
- Maximum 3-4 levels of nesting
- Omit else blocks when if returns
- Handle errors immediately
- Keep normal flow at lowest indentation

### If with Initialization

```go
if err := file.Chmod(0664); err != nil {
    log.Print(err)
    return err
}
```

### Switch

No automatic fallthrough. Cases can be comma-separated lists.

```go
func shouldEscape(c byte) bool {
    switch c {
    case ' ', '?', '&', '=', '#', '+', '%':
        return true
    }
    return false
}
```

**Expressionless switch (cleaner if-else-if):**

```go
switch {
case '0' <= c && c <= '9':
    return c - '0'
case 'a' <= c && c <= 'f':
    return c - 'a' + 10
}
```

### Type Switch

```go
switch t := value.(type) {
case string:
    return t
case Stringer:
    return t.String()
default:
    return fmt.Sprintf("%v", t)
}
```

## Composition Over Inheritance

### Type Embedding

```go
type Logger struct {
    *log.Logger
    prefix string
}

func NewLogger(prefix string) *Logger {
    return &Logger{
        Logger: log.New(os.Stdout, "", 0),
        prefix: prefix,
    }
}

// Logger methods automatically available
logger := NewLogger("APP")
logger.Println("message") // Calls embedded log.Logger.Println
```

### Warning: Avoid Embedding in Public APIs

```go
// BAD: Exposes implementation details
type MyHandler struct {
    http.Handler // Leaks all Handler methods
}

// GOOD: Explicit delegation
type MyHandler struct {
    handler http.Handler
}

func (h *MyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    // Custom logic
    h.handler.ServeHTTP(w, r)
}
```

## Key Idioms

### Defer for Cleanup

```go
func processFile(path string) error {
    f, err := os.Open(path)
    if err != nil {
        return err
    }
    defer f.Close() // Guaranteed cleanup regardless of return path

    if condition {
        return nil // File closed
    }
    return process(f) // File closed
}

// Mutex pattern
func (c *Counter) Increment() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.value++ // All paths unlock
}
```

**Critical: Call defer AFTER checking error:**

```go
// WRONG
defer f.Close() // f is nil if Open failed
f, err := os.Open(path)

// CORRECT
f, err := os.Open(path)
if err != nil {
    return err
}
defer f.Close()
```

### Multiple Return Values

```go
// (value, error) - Standard error handling
func GetUser(id string) (*User, error) { ... }

// (value, bool) - "comma ok" idiom
value, ok := myMap[key]
if !ok {
    // key not found
}

result, ok := someValue.(TargetType)
if !ok {
    // type assertion failed
}

data, ok := <-channel
if !ok {
    // channel closed
}
```

### Blank Identifier

```go
// Ignore unwanted values
_, err := os.Open(filename)

// Compile-time interface check
var _ http.Handler = (*MyHandler)(nil)

// Import for side effects
import _ "net/http/pprof"
```

### Useful Zero Values

```go
// sync.Mutex - ready to use
var mu sync.Mutex
mu.Lock() // Works immediately

// bytes.Buffer - valid empty buffer
var buf bytes.Buffer
buf.WriteString("hello") // No initialization needed

// Slices - safe to read
var s []int
fmt.Println(len(s)) // 0 (safe)
```

### new vs make

| Function | Creates | Returns | Use for |
|----------|---------|---------|---------|
| `new(T)` | Zeroed T | `*T` | Any type |
| `make(T, args)` | Initialized T | `T` | Slices, maps, channels only |

```go
p := new(SyncedBuffer)   // *SyncedBuffer, zeroed, ready to use
v := make([]int, 10)     // []int with len=10, initialized
m := make(map[string]int) // initialized map
ch := make(chan int, 10) // buffered channel
```

### Composite Literals

```go
return &File{fd: fd, name: name}  // Returns pointer to new File
a := [...]string{Enone: "no error", Eio: "Eio"}  // Array with indices
m := map[string]int{"UTC": 0, "EST": -5*60*60}   // Map literal
```

## Error Handling

### Error Wrapping with %w (Go 1.13+)

```go
func processFile(path string) error {
    file, err := os.Open(path)
    if err != nil {
        return fmt.Errorf("failed to open file %s: %w", path, err)
    }
    defer file.Close()

    data, err := io.ReadAll(file)
    if err != nil {
        return fmt.Errorf("failed to read file %s: %w", path, err)
    }

    return processData(data)
}
```

**Critical: Use %w, NOT %v:**

```go
// WRONG: Breaks error chain
return fmt.Errorf("failed: %v", err)

// CORRECT: Preserves chain
return fmt.Errorf("failed: %w", err)
```

### Checking Wrapped Errors

```go
// errors.Is - Check for specific error in chain
if errors.Is(err, os.ErrNotExist) {
    fmt.Println("File doesn't exist")
}

// errors.As - Extract specific error type
var pathErr *os.PathError
if errors.As(err, &pathErr) {
    fmt.Printf("Path error on: %s\n", pathErr.Path)
}
```

### Sentinel Errors vs Custom Error Types

**Sentinel Errors (Package-Level Variables):**

```go
package db

var (
    ErrConnectionFailed = errors.New("database connection failed")
    ErrRecordNotFound   = errors.New("record not found")
    ErrDuplicateKey     = errors.New("duplicate key violation")
)

// Caller checks with errors.Is
if errors.Is(err, db.ErrRecordNotFound) {
    // Handle not found
}
```

**Custom Error Types (Rich Context):**

```go
type ValidationError struct {
    Field   string
    Value   interface{}
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed for field '%s': %s (value: %v)",
        e.Field, e.Message, e.Value)
}

// Caller extracts rich information
var valErr *ValidationError
if errors.As(err, &valErr) {
    fmt.Printf("Field: %s, Value: %v\n", valErr.Field, valErr.Value)
}
```

**Important: Use pointer receivers for error types:**

```go
// CORRECT: Pointer receiver
func (e *ValidationError) Error() string { ... }

// WRONG: Value receiver (breaks errors.As)
func (e ValidationError) Error() string { ... }
```

### Handle Errors Once

Either log the error OR return it, not both.

```go
// BAD: Handle twice (log AND return)
if err != nil {
    log.Printf("error: %v", err)  // Logged here
    return err                     // And returned
}

// GOOD: Return error, let caller handle
if err != nil {
    return fmt.Errorf("process: %w", err)
}

// GOOD: Log and handle completely
if err != nil {
    log.Printf("non-fatal error: %v", err)
    // Continue execution (error handled)
}
```

### Error Message Conventions

```go
// GOOD - lowercase, no punctuation
var ErrNotFound = errors.New("configuration file not found")
return fmt.Errorf("failed to read settings for user %d: %w", userID, err)

// BAD
var ErrNotFound = errors.New("Error: Configuration file not found.")
return fmt.Errorf("Error occurred: %v", err) // Too generic
```

### Panic vs Error Decision Tree

```
Is this condition expected during normal operation?
├─ Yes → Return error
└─ No → Is this a programmer error?
    ├─ Yes → Panic (with clear message)
    └─ No → Is the program in an invalid state?
        ├─ Yes → Panic
        └─ No → Return error
```

**Use Errors When:**
- Expected failures (file not found, network timeout)
- Business logic failures (invalid email format)

**Use Panic When:**
- Nil argument that should never be nil (document this!)
- Initialization failure that makes program unusable
- Impossible condition indicating a bug

```go
// Panic for programmer error
func ProcessData(data *Data) {
    if data == nil {
        panic("ProcessData: data argument must not be nil")
    }
}

// Panic for initialization failure
func init() {
    cfg, err := loadConfig()
    if err != nil {
        panic(fmt.Sprintf("fatal: failed to load config: %v", err))
    }
    globalConfig = cfg
}
```

## Methods

### Pointer vs Value Receivers

```go
func (s *ByteSlice) Append(data []byte) {
    *s = append(*s, data...)  // Modifies caller's slice
}

func (s ByteSlice) Len() int {
    return len(s)  // Read-only, value receiver OK
}
```

**Rule:** Value methods can be called on pointers and values. Pointer methods only on pointers (unless addressable).

## Printing

```go
fmt.Printf("%v\n", value)   // Default format
fmt.Printf("%+v\n", s)      // Struct with field names
fmt.Printf("%#v\n", s)      // Go syntax representation
fmt.Printf("%T\n", value)   // Type of value
fmt.Printf("%q\n", str)     // Quoted string
```

**Custom String method:**

```go
func (t *T) String() string {
    return fmt.Sprintf("%d/%g/%q", t.a, t.b, t.c)
}
```

**Avoid infinite recursion:**

```go
func (m MyString) String() string {
    return fmt.Sprintf("MyString=%s", string(m))  // Convert to break recursion
}
```

## Anti-Patterns to Avoid

### [CRITICAL] Swallowing Errors

```go
// WRONG
data, _ := fetchData()

// CORRECT
data, err := fetchData()
if err != nil {
    return fmt.Errorf("fetch failed: %w", err)
}
```

### [CRITICAL] Using %v Instead of %w

```go
// WRONG: Breaks error chain
return fmt.Errorf("failed: %v", err)

// CORRECT
return fmt.Errorf("failed: %w", err)
```

### [HIGH] Defer in Hot Loops

```go
// WRONG: Defers accumulate
for _, item := range items {
    mu.Lock()
    defer mu.Unlock() // Never executes until function returns
    process(item)
}

// CORRECT
for _, item := range items {
    mu.Lock()
    process(item)
    mu.Unlock()
}
```

### [MEDIUM] Map Without Pre-allocation

```go
// WRONG: Multiple rehashes
m := make(map[string]Item)
for _, item := range items {
    m[item.ID] = item
}

// CORRECT: Pre-sized
m := make(map[string]Item, len(items))
```

### [HIGH] Checking Error Strings

```go
// WRONG: Fragile
if err != nil && strings.Contains(err.Error(), "not found") {
    // ...
}

// CORRECT: Use errors.Is
if errors.Is(err, sql.ErrNoRows) {
    // ...
}
```

### [MEDIUM] Producer-Side Interfaces

```go
// WRONG
package store
type Storage interface { ... }
type Store struct {}

// CORRECT
package client
type storage interface { ... } // Define where used
```

## Quality Checks

```bash
# Format Go code
go fmt ./...

# Static analysis
go vet ./...

# Comprehensive linting (if golangci-lint installed)
golangci-lint run

# Run tests with race detector
go test -race ./...
```

## References

- [Effective Go](https://go.dev/doc/effective_go)
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md)
