---
name: go-fuzzing
description: Write and run Go fuzz tests for automated bug detection and security vulnerability discovery. Use when writing fuzz tests, using FuzzXxx functions, running `go test -fuzz`, managing fuzz corpus, or debugging fuzz test failures.
---

# Go Fuzzing

Native fuzz testing in Go (1.18+) for automated bug detection through coverage-guided input generation.

## Quick Start

```go
func FuzzReverse(f *testing.F) {
    // Seed corpus with initial values
    f.Add("hello")
    f.Add("world")
    
    // Fuzz target
    f.Fuzz(func(t *testing.T, s string) {
        reversed := Reverse(s)
        doubleReversed := Reverse(reversed)
        if s != doubleReversed {
            t.Errorf("double reverse mismatch: %q -> %q -> %q", s, reversed, doubleReversed)
        }
    })
}
```

Run: `go test -fuzz=FuzzReverse -fuzztime=30s`

## Fuzz Test Requirements

| Requirement | Details |
|-------------|---------|
| Function name | `FuzzXxx` accepting `*testing.F` |
| File | Must be in `*_test.go` |
| Fuzz target | Call `f.Fuzz()` with `*testing.T` as first param |
| Target count | Exactly one per fuzz test |
| Seed corpus types | Must match fuzz target param types exactly |

### Supported Fuzzing Argument Types

```
string, []byte
int, int8, int16, int32/rune, int64
uint, uint8/byte, uint16, uint32, uint64
float32, float64
bool
```

## Running Fuzz Tests

```bash
# Run as unit test (tests seed corpus only)
go test -run=FuzzReverse

# Run fuzzing
go test -fuzz=FuzzReverse

# Run with time limit
go test -fuzz=FuzzReverse -fuzztime=30s

# Run specific number of iterations
go test -fuzz=FuzzReverse -fuzztime=1000x

# Control parallelism
go test -fuzz=FuzzReverse -parallel=4

# Disable minimization
go test -fuzz=FuzzReverse -fuzzminimizetime=0
```

### Command Line Flags

| Flag | Description | Default |
|------|-------------|---------|
| `-fuzz=<regex>` | Run fuzz test matching regex | - |
| `-fuzztime=<duration>` | Total fuzzing time or iterations | indefinitely |
| `-fuzzminimizetime=<duration>` | Time for minimization | 60s |
| `-parallel=<n>` | Number of fuzzing processes | `$GOMAXPROCS` |

## Seed Corpus

### Adding Seeds Programmatically

```go
func FuzzJSON(f *testing.F) {
    // Add seed values matching fuzz target params
    f.Add([]byte(`{"name": "test"}`), int64(100))
    f.Add([]byte(`{}`), int64(0))
    
    f.Fuzz(func(t *testing.T, data []byte, limit int64) {
        // test logic
    })
}
```

### Corpus File Format

Store corpus entries in `testdata/fuzz/{FuzzTestName}/`:

```
go test fuzz v1
[]byte("hello\xbd\xb2=\xbc")
int64(572293)
```

Each line after version header is a Go literal value matching fuzz target params.

### Converting Binary Files to Corpus

```bash
go install golang.org/x/tools/cmd/file2fuzz@latest
file2fuzz -o testdata/fuzz/FuzzMyTest/seed1 input.bin
```

## Failure Handling

### When Fuzzing Finds a Bug

Output shows:
```
Failing input written to testdata/fuzz/FuzzFoo/a878c3134fe0404d...
To re-run:
go test -run=FuzzFoo/a878c3134fe0404d...
```

The failing input is automatically saved to seed corpus for regression testing.

### Failure Causes

- Panic in code or test
- `t.Fail()`, `t.Error()`, `t.Fatal()` called
- Non-recoverable error (os.Exit, stack overflow)
- Timeout (1 second default per fuzz target execution)

## Patterns

### Pattern 1: Input Validation Fuzzing

```go
func FuzzParseInput(f *testing.F) {
    f.Add("valid-input")
    f.Add("")
    f.Add("invalid\x00input")
    
    f.Fuzz(func(t *testing.T, input string) {
        // Should never panic regardless of input
        result, err := ParseInput(input)
        if err != nil {
            return // errors are expected for invalid input
        }
        
        // Valid results should be usable
        if result.IsValid() && result.Value() == "" {
            t.Error("valid result has empty value")
        }
    })
}
```

### Pattern 2: Roundtrip Testing

```go
func FuzzEncodeDecode(f *testing.F) {
    f.Add([]byte("test data"))
    f.Add([]byte{0x00, 0xff, 0x80})
    
    f.Fuzz(func(t *testing.T, original []byte) {
        encoded := Encode(original)
        decoded, err := Decode(encoded)
        if err != nil {
            t.Fatalf("decode failed: %v", err)
        }
        if !bytes.Equal(original, decoded) {
            t.Errorf("roundtrip mismatch")
        }
    })
}
```

### Pattern 3: Comparison Testing

```go
func FuzzCompare(f *testing.F) {
    f.Add("input")
    
    f.Fuzz(func(t *testing.T, input string) {
        result1 := Implementation1(input)
        result2 := Implementation2(input)
        
        if result1 != result2 {
            t.Errorf("implementations differ for %q", input)
        }
    })
}
```

### Pattern 4: Multi-Parameter Fuzzing

```go
func FuzzMultiParam(f *testing.F) {
    f.Add("hello", int64(10), true)
    f.Add("", int64(-1), false)
    
    f.Fuzz(func(t *testing.T, s string, n int64, flag bool) {
        result := Process(s, n, flag)
        // validate result
    })
}
```

## Best Practices

### Do's

- **Keep targets fast** - Targets execute thousands of times per second
- **Make targets deterministic** - Random behavior reduces effectiveness
- **Seed with edge cases** - Empty strings, zero values, boundary values
- **Test error paths** - Return early on expected errors, don't fail
- **Use coverage guidance** - Run on AMD64/ARM64 for meaningful corpus growth

### Don'ts

- **Don't use global state** - Targets run in parallel with nondeterministic order
- **Don't rely on external resources** - Network, files, databases slow testing
- **Don't log excessively** - Slows fuzzing significantly
- **Don't use `t.Parallel()`** - Fuzzing handles parallelism internally

## Output Interpretation

```
fuzz: elapsed: 3s, execs: 325017 (108336/sec), new interesting: 11 (total: 202)
```

| Field | Meaning |
|-------|---------|
| elapsed | Time since fuzzing started |
| execs | Total inputs tested (and rate) |
| new interesting | Inputs that expanded code coverage |
| total | Total corpus size |

Expect "new interesting" to grow quickly initially, then taper off with occasional bursts.

## Platform Notes

Coverage instrumentation requires AMD64 or ARM64 for meaningful corpus growth.

## Resources

- [Go Fuzzing Tutorial](https://go.dev/doc/tutorial/fuzz)
- [testing.F documentation](https://pkg.go.dev/testing#F)
- [OSS-Fuzz Go integration](https://google.github.io/oss-fuzz/getting-started/new-project-guide/go-lang/)
