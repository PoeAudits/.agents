---
name: go-backend-development
description: Build production-grade Go web servers, REST APIs, database integration, middleware, and microservices. Use when developing HTTP services, implementing middleware patterns, integrating databases, or building microservices architectures.
---

# Go Backend Development

Production patterns for building web servers, APIs, database-backed applications, and microservices in Go.

## When to Use This Skill

- Building HTTP servers and REST APIs
- Implementing middleware (logging, auth, rate limiting)
- Integrating databases with connection pooling
- Building microservices with gRPC or HTTP
- Implementing production patterns (health checks, graceful shutdown)

**For concurrency patterns** (goroutines, channels, worker pools): See `go-concurrency-patterns`
**For testing patterns** (table-driven, benchmarks): See `go-testing`
**For coding guidelines** (error handling, interfaces): See `go-coding-guidelines`

## Web Server Development

### HTTP Server Basics

```go
package main

import (
    "fmt"
    "net/http"
)

func main() {
    http.HandleFunc("/", handler)
    http.ListenAndServe("localhost:8080", nil)
}

func handler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprint(w, "Hello!")
}
```

### Request Handling Patterns

**Handler Functions:**

```go
func handler(w http.ResponseWriter, r *http.Request) {
    // Read request
    method := r.Method
    path := r.URL.Path
    query := r.URL.Query()

    // Write response
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    fmt.Fprintf(w, `{"message": "success"}`)
}
```

**Handler Structs (Dependency Injection):**

```go
type APIHandler struct {
    db     *sql.DB
    logger *slog.Logger
}

func (h *APIHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    h.logger.Info("request received",
        "method", r.Method,
        "path", r.URL.Path)
    // Handle request using h.db
}
```

### Middleware Pattern

Middleware wraps handlers to add cross-cutting concerns.

**Signature:**

```go
func middleware(next http.Handler) http.Handler
```

**Logging Middleware:**

```go
func loggingMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        next.ServeHTTP(w, r)
        log.Printf("%s %s %v", r.Method, r.URL.Path, time.Since(start))
    })
}
```

**Authentication Middleware:**

```go
func authMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        token := r.Header.Get("Authorization")
        if !isValidToken(token) {
            http.Error(w, "Unauthorized", http.StatusUnauthorized)
            return
        }
        next.ServeHTTP(w, r)
    })
}
```

**CORS Middleware:**

```go
func corsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Access-Control-Allow-Origin", "*")
        w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

        if r.Method == "OPTIONS" {
            w.WriteHeader(http.StatusOK)
            return
        }

        next.ServeHTTP(w, r)
    })
}
```

**Chaining Middleware:**

```go
handler := loggingMiddleware(authMiddleware(corsMiddleware(apiHandler)))
http.Handle("/api/", handler)
```

### Response Writer Wrapper

Capture status code and response size:

```go
type responseWriter struct {
    http.ResponseWriter
    status int
    size   int
}

func (rw *responseWriter) WriteHeader(code int) {
    rw.status = code
    rw.ResponseWriter.WriteHeader(code)
}

func (rw *responseWriter) Write(b []byte) (int, error) {
    n, err := rw.ResponseWriter.Write(b)
    rw.size += n
    return n, err
}

func loggingMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        wrapped := &responseWriter{ResponseWriter: w, status: http.StatusOK}
        start := time.Now()

        next.ServeHTTP(wrapped, r)

        log.Printf("%s %s %d %d %v",
            r.Method, r.URL.Path, wrapped.status, wrapped.size, time.Since(start))
    })
}
```

### Routing Patterns

**Path Parameters (Go 1.22+):**

```go
mux := http.NewServeMux()
mux.HandleFunc("GET /users/{id}", getUser)
mux.HandleFunc("POST /users", createUser)
mux.HandleFunc("DELETE /users/{id}", deleteUser)

func getUser(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id")
    // ...
}
```

**RESTful API Structure:**

```go
// GET /api/users
func listUsers(w http.ResponseWriter, r *http.Request) { /* ... */ }

// GET /api/users/{id}
func getUser(w http.ResponseWriter, r *http.Request) { /* ... */ }

// POST /api/users
func createUser(w http.ResponseWriter, r *http.Request) { /* ... */ }

// PUT /api/users/{id}
func updateUser(w http.ResponseWriter, r *http.Request) { /* ... */ }

// DELETE /api/users/{id}
func deleteUser(w http.ResponseWriter, r *http.Request) { /* ... */ }
```

### JSON Request/Response

**Reading JSON Body:**

```go
func createUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid JSON", http.StatusBadRequest)
        return
    }

    // Validate
    if req.Email == "" {
        http.Error(w, "Email required", http.StatusBadRequest)
        return
    }

    // Process...
}
```

**Writing JSON Response:**

```go
func writeJSON(w http.ResponseWriter, status int, data interface{}) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(data)
}

func getUser(w http.ResponseWriter, r *http.Request) {
    user := User{ID: 1, Name: "John"}
    writeJSON(w, http.StatusOK, user)
}
```

**Error Response Helper:**

```go
type ErrorResponse struct {
    Error   string `json:"error"`
    Code    string `json:"code,omitempty"`
    Details any    `json:"details,omitempty"`
}

func writeError(w http.ResponseWriter, status int, message string) {
    writeJSON(w, status, ErrorResponse{Error: message})
}
```

## Database Integration

### Connection Management

**Connection Pool Configuration:**

```go
import "database/sql"

func initDB(dsn string) (*sql.DB, error) {
    db, err := sql.Open("postgres", dsn)
    if err != nil {
        return nil, err
    }

    // Configure connection pool
    db.SetMaxOpenConns(25)              // Max open connections
    db.SetMaxIdleConns(5)               // Max idle connections
    db.SetConnMaxLifetime(5 * time.Minute)   // Max connection lifetime
    db.SetConnMaxIdleTime(10 * time.Minute)  // Max idle time

    // Verify connection
    if err := db.Ping(); err != nil {
        return nil, err
    }

    return db, nil
}
```

### Query Patterns

**Single Row Query:**

```go
func getUser(ctx context.Context, db *sql.DB, userID int) (*User, error) {
    user := &User{}
    err := db.QueryRowContext(ctx,
        "SELECT id, name, email FROM users WHERE id = $1",
        userID,
    ).Scan(&user.ID, &user.Name, &user.Email)

    if err == sql.ErrNoRows {
        return nil, ErrNotFound
    }
    if err != nil {
        return nil, fmt.Errorf("query user: %w", err)
    }

    return user, nil
}
```

**Multiple Row Query:**

```go
func listUsers(ctx context.Context, db *sql.DB) ([]*User, error) {
    rows, err := db.QueryContext(ctx, "SELECT id, name, email FROM users")
    if err != nil {
        return nil, fmt.Errorf("query users: %w", err)
    }
    defer rows.Close()

    var users []*User
    for rows.Next() {
        user := &User{}
        if err := rows.Scan(&user.ID, &user.Name, &user.Email); err != nil {
            return nil, fmt.Errorf("scan user: %w", err)
        }
        users = append(users, user)
    }

    if err := rows.Err(); err != nil {
        return nil, fmt.Errorf("iterate users: %w", err)
    }

    return users, nil
}
```

**Insert with Returning:**

```go
func createUser(ctx context.Context, db *sql.DB, user *User) error {
    query := `
        INSERT INTO users (name, email, created_at)
        VALUES ($1, $2, $3)
        RETURNING id`

    err := db.QueryRowContext(ctx, query,
        user.Name, user.Email, time.Now(),
    ).Scan(&user.ID)

    return err
}
```

**Update:**

```go
func updateUser(ctx context.Context, db *sql.DB, user *User) error {
    result, err := db.ExecContext(ctx,
        "UPDATE users SET name = $1, email = $2 WHERE id = $3",
        user.Name, user.Email, user.ID)
    if err != nil {
        return err
    }

    rows, err := result.RowsAffected()
    if err != nil {
        return err
    }
    if rows == 0 {
        return ErrNotFound
    }

    return nil
}
```

### Transaction Handling

```go
func transferFunds(ctx context.Context, db *sql.DB, from, to int, amount decimal.Decimal) error {
    tx, err := db.BeginTx(ctx, nil)
    if err != nil {
        return fmt.Errorf("begin tx: %w", err)
    }
    defer tx.Rollback() // Rollback if not committed

    // Debit from account
    _, err = tx.ExecContext(ctx,
        "UPDATE accounts SET balance = balance - $1 WHERE id = $2",
        amount, from)
    if err != nil {
        return fmt.Errorf("debit: %w", err)
    }

    // Credit to account
    _, err = tx.ExecContext(ctx,
        "UPDATE accounts SET balance = balance + $1 WHERE id = $2",
        amount, to)
    if err != nil {
        return fmt.Errorf("credit: %w", err)
    }

    if err := tx.Commit(); err != nil {
        return fmt.Errorf("commit: %w", err)
    }

    return nil
}
```

**Transaction Helper:**

```go
func withTransaction(ctx context.Context, db *sql.DB, fn func(*sql.Tx) error) error {
    tx, err := db.BeginTx(ctx, nil)
    if err != nil {
        return err
    }

    if err := fn(tx); err != nil {
        tx.Rollback()
        return err
    }

    return tx.Commit()
}

// Usage
err := withTransaction(ctx, db, func(tx *sql.Tx) error {
    // Multiple operations in transaction
    return nil
})
```

### Prepared Statements

For repeated queries:

```go
func batchInsert(ctx context.Context, db *sql.DB, users []*User) error {
    stmt, err := db.PrepareContext(ctx,
        "INSERT INTO users (name, email) VALUES ($1, $2)")
    if err != nil {
        return err
    }
    defer stmt.Close()

    for _, user := range users {
        _, err := stmt.ExecContext(ctx, user.Name, user.Email)
        if err != nil {
            return err
        }
    }

    return nil
}
```

## Production Patterns

### Graceful Shutdown

```go
func main() {
    srv := &http.Server{
        Addr:         ":8080",
        Handler:      router,
        ReadTimeout:  15 * time.Second,
        WriteTimeout: 15 * time.Second,
        IdleTimeout:  60 * time.Second,
    }

    // Start server
    go func() {
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("listen: %v", err)
        }
    }()

    // Wait for interrupt signal
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit
    log.Println("Shutting down server...")

    // Graceful shutdown with timeout
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    if err := srv.Shutdown(ctx); err != nil {
        log.Fatal("Server forced to shutdown:", err)
    }

    log.Println("Server exited")
}
```

### Configuration Management

```go
type Config struct {
    Port        int           `env:"PORT" envDefault:"8080"`
    DBHost      string        `env:"DB_HOST" envDefault:"localhost"`
    DBPort      int           `env:"DB_PORT" envDefault:"5432"`
    DBName      string        `env:"DB_NAME,required"`
    DBUser      string        `env:"DB_USER,required"`
    DBPassword  string        `env:"DB_PASSWORD,required"`
    LogLevel    string        `env:"LOG_LEVEL" envDefault:"info"`
    Timeout     time.Duration `env:"TIMEOUT" envDefault:"30s"`
}

func loadConfig() (*Config, error) {
    cfg := &Config{}
    if err := env.Parse(cfg); err != nil {
        return nil, fmt.Errorf("parse config: %w", err)
    }
    return cfg, nil
}
```

**Manual Environment Parsing:**

```go
func loadConfig() *Config {
    return &Config{
        Port:     getEnvInt("PORT", 8080),
        DBHost:   getEnv("DB_HOST", "localhost"),
        LogLevel: getEnv("LOG_LEVEL", "info"),
    }
}

func getEnv(key, fallback string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return fallback
}

func getEnvInt(key string, fallback int) int {
    if value := os.Getenv(key); value != "" {
        if i, err := strconv.Atoi(value); err == nil {
            return i
        }
    }
    return fallback
}
```

### Structured Logging (slog)

```go
import "log/slog"

func setupLogger(level string) *slog.Logger {
    var logLevel slog.Level
    switch level {
    case "debug":
        logLevel = slog.LevelDebug
    case "warn":
        logLevel = slog.LevelWarn
    case "error":
        logLevel = slog.LevelError
    default:
        logLevel = slog.LevelInfo
    }

    return slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
        Level: logLevel,
    }))
}

// Request logging
func loggingMiddleware(logger *slog.Logger) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()

            // Add request context
            reqLogger := logger.With(
                "method", r.Method,
                "path", r.URL.Path,
                "remote", r.RemoteAddr,
            )

            reqLogger.Info("request started")

            wrapped := &responseWriter{ResponseWriter: w, status: http.StatusOK}
            next.ServeHTTP(wrapped, r)

            reqLogger.Info("request completed",
                "status", wrapped.status,
                "duration", time.Since(start))
        })
    }
}
```

### Health Checks

```go
type HealthChecker struct {
    db    *sql.DB
    redis *redis.Client
}

func (h *HealthChecker) Handler() http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
        defer cancel()

        status := http.StatusOK
        checks := map[string]string{}

        // Check database
        if err := h.db.PingContext(ctx); err != nil {
            status = http.StatusServiceUnavailable
            checks["database"] = "unhealthy: " + err.Error()
        } else {
            checks["database"] = "healthy"
        }

        // Check Redis
        if err := h.redis.Ping(ctx).Err(); err != nil {
            status = http.StatusServiceUnavailable
            checks["redis"] = "unhealthy: " + err.Error()
        } else {
            checks["redis"] = "healthy"
        }

        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(status)
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status": map[int]string{200: "healthy", 503: "unhealthy"}[status],
            "checks": checks,
        })
    }
}

// Liveness vs Readiness
func livenessHandler(w http.ResponseWriter, r *http.Request) {
    // Simple check - is the process running?
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("ok"))
}

func readinessHandler(db *sql.DB) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        // Can we serve traffic?
        if err := db.Ping(); err != nil {
            http.Error(w, "not ready", http.StatusServiceUnavailable)
            return
        }
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("ready"))
    }
}
```

### Rate Limiting

```go
import "golang.org/x/time/rate"

func rateLimitMiddleware(rps float64, burst int) func(http.Handler) http.Handler {
    limiter := rate.NewLimiter(rate.Limit(rps), burst)

    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            if !limiter.Allow() {
                http.Error(w, "Too Many Requests", http.StatusTooManyRequests)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}

// Per-client rate limiting
type ClientLimiter struct {
    clients map[string]*rate.Limiter
    mu      sync.Mutex
    rps     rate.Limit
    burst   int
}

func NewClientLimiter(rps float64, burst int) *ClientLimiter {
    return &ClientLimiter{
        clients: make(map[string]*rate.Limiter),
        rps:     rate.Limit(rps),
        burst:   burst,
    }
}

func (cl *ClientLimiter) GetLimiter(clientIP string) *rate.Limiter {
    cl.mu.Lock()
    defer cl.mu.Unlock()

    limiter, exists := cl.clients[clientIP]
    if !exists {
        limiter = rate.NewLimiter(cl.rps, cl.burst)
        cl.clients[clientIP] = limiter
    }

    return limiter
}

func (cl *ClientLimiter) Middleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        ip := r.RemoteAddr // Or extract from X-Forwarded-For
        limiter := cl.GetLimiter(ip)

        if !limiter.Allow() {
            http.Error(w, "Too Many Requests", http.StatusTooManyRequests)
            return
        }
        next.ServeHTTP(w, r)
    })
}
```

### Request Timeout

```go
func timeoutMiddleware(timeout time.Duration) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            ctx, cancel := context.WithTimeout(r.Context(), timeout)
            defer cancel()

            r = r.WithContext(ctx)
            next.ServeHTTP(w, r)
        })
    }
}
```

## Microservices Patterns

### Service Structure

```go
type UserService struct {
    db     *sql.DB
    cache  *redis.Client
    logger *slog.Logger
}

func NewUserService(db *sql.DB, cache *redis.Client, logger *slog.Logger) *UserService {
    return &UserService{
        db:     db,
        cache:  cache,
        logger: logger,
    }
}

func (s *UserService) GetUser(ctx context.Context, userID string) (*User, error) {
    // Check cache first
    if user, err := s.getFromCache(ctx, userID); err == nil {
        return user, nil
    }

    // Query database
    user, err := s.getFromDB(ctx, userID)
    if err != nil {
        return nil, err
    }

    // Update cache async
    go s.updateCache(context.Background(), user)

    return user, nil
}

func (s *UserService) getFromCache(ctx context.Context, userID string) (*User, error) {
    data, err := s.cache.Get(ctx, "user:"+userID).Bytes()
    if err != nil {
        return nil, err
    }

    var user User
    if err := json.Unmarshal(data, &user); err != nil {
        return nil, err
    }

    return &user, nil
}

func (s *UserService) updateCache(ctx context.Context, user *User) {
    data, _ := json.Marshal(user)
    s.cache.Set(ctx, "user:"+user.ID, data, 5*time.Minute)
}
```

### gRPC Service

```go
type userServer struct {
    pb.UnimplementedUserServiceServer
    db *sql.DB
}

func (s *userServer) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.User, error) {
    user := &pb.User{}
    err := s.db.QueryRowContext(ctx,
        "SELECT id, name, email FROM users WHERE id = $1",
        req.GetId(),
    ).Scan(&user.Id, &user.Name, &user.Email)

    if err == sql.ErrNoRows {
        return nil, status.Errorf(codes.NotFound, "user not found: %s", req.GetId())
    }
    if err != nil {
        return nil, status.Errorf(codes.Internal, "query failed: %v", err)
    }

    return user, nil
}

func (s *userServer) ListUsers(req *pb.ListUsersRequest, stream pb.UserService_ListUsersServer) error {
    rows, err := s.db.QueryContext(stream.Context(), "SELECT id, name, email FROM users")
    if err != nil {
        return status.Errorf(codes.Internal, "query failed: %v", err)
    }
    defer rows.Close()

    for rows.Next() {
        user := &pb.User{}
        if err := rows.Scan(&user.Id, &user.Name, &user.Email); err != nil {
            return status.Errorf(codes.Internal, "scan failed: %v", err)
        }
        if err := stream.Send(user); err != nil {
            return err
        }
    }

    return rows.Err()
}
```

### Circuit Breaker

```go
type CircuitBreaker struct {
    maxFailures int
    timeout     time.Duration

    mu          sync.Mutex
    failures    int
    lastFailure time.Time
    state       string // closed, open, half-open
}

func NewCircuitBreaker(maxFailures int, timeout time.Duration) *CircuitBreaker {
    return &CircuitBreaker{
        maxFailures: maxFailures,
        timeout:     timeout,
        state:       "closed",
    }
}

func (cb *CircuitBreaker) Call(fn func() error) error {
    cb.mu.Lock()

    // Check if we should allow the call
    switch cb.state {
    case "open":
        if time.Since(cb.lastFailure) > cb.timeout {
            cb.state = "half-open"
        } else {
            cb.mu.Unlock()
            return errors.New("circuit breaker open")
        }
    }

    cb.mu.Unlock()

    // Execute the function
    err := fn()

    cb.mu.Lock()
    defer cb.mu.Unlock()

    if err != nil {
        cb.failures++
        cb.lastFailure = time.Now()
        if cb.failures >= cb.maxFailures {
            cb.state = "open"
        }
        return err
    }

    // Success - reset
    cb.failures = 0
    cb.state = "closed"
    return nil
}
```

### HTTP Client with Retry

```go
type HTTPClient struct {
    client     *http.Client
    maxRetries int
    baseDelay  time.Duration
}

func NewHTTPClient(timeout time.Duration, maxRetries int) *HTTPClient {
    return &HTTPClient{
        client: &http.Client{
            Timeout: timeout,
        },
        maxRetries: maxRetries,
        baseDelay:  100 * time.Millisecond,
    }
}

func (c *HTTPClient) Do(ctx context.Context, req *http.Request) (*http.Response, error) {
    var resp *http.Response
    var err error

    for attempt := 0; attempt <= c.maxRetries; attempt++ {
        if attempt > 0 {
            // Exponential backoff
            delay := c.baseDelay * time.Duration(1<<uint(attempt-1))
            select {
            case <-ctx.Done():
                return nil, ctx.Err()
            case <-time.After(delay):
            }
        }

        req = req.WithContext(ctx)
        resp, err = c.client.Do(req)

        if err == nil && resp.StatusCode < 500 {
            return resp, nil
        }

        if resp != nil {
            resp.Body.Close()
        }
    }

    return resp, err
}
```

### Service Discovery (Simple)

```go
type ServiceRegistry struct {
    mu       sync.RWMutex
    services map[string][]string
}

func NewServiceRegistry() *ServiceRegistry {
    return &ServiceRegistry{
        services: make(map[string][]string),
    }
}

func (r *ServiceRegistry) Register(name, addr string) {
    r.mu.Lock()
    defer r.mu.Unlock()
    r.services[name] = append(r.services[name], addr)
}

func (r *ServiceRegistry) Deregister(name, addr string) {
    r.mu.Lock()
    defer r.mu.Unlock()

    addrs := r.services[name]
    for i, a := range addrs {
        if a == addr {
            r.services[name] = append(addrs[:i], addrs[i+1:]...)
            break
        }
    }
}

func (r *ServiceRegistry) Discover(name string) (string, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()

    addrs := r.services[name]
    if len(addrs) == 0 {
        return "", fmt.Errorf("service %s not found", name)
    }

    // Simple round-robin
    return addrs[rand.Intn(len(addrs))], nil
}
```

## Project Structure

Recommended layout for Go backend services:

```
project/
├── cmd/
│   └── server/
│       └── main.go           # Application entry point
├── internal/
│   ├── api/                  # HTTP handlers
│   │   ├── handler.go
│   │   ├── middleware.go
│   │   └── routes.go
│   ├── service/              # Business logic
│   │   └── user.go
│   ├── repository/           # Data access
│   │   └── user.go
│   └── model/                # Domain types
│       └── user.go
├── pkg/                      # Public packages (if any)
├── migrations/               # Database migrations
├── config/                   # Configuration files
├── docker/                   # Docker files
├── Makefile
├── go.mod
└── go.sum
```

## Best Practices Summary

### HTTP Handlers
- Always set appropriate timeouts on servers
- Use structured responses (JSON with consistent format)
- Implement proper error responses with codes
- Add request IDs for tracing

### Database
- Always use parameterized queries (prevent SQL injection)
- Use context for cancellation and timeouts
- Configure connection pool appropriately
- Handle `sql.ErrNoRows` explicitly

### Production
- Implement graceful shutdown
- Add health check endpoints (liveness + readiness)
- Use structured logging
- Implement rate limiting for public endpoints
- Set appropriate timeouts at all levels

### Microservices
- Use circuit breakers for external calls
- Implement retry with exponential backoff
- Add distributed tracing (OpenTelemetry)
- Use gRPC for internal service communication
