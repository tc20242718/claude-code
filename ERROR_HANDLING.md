# Error Handling and Audit Logging Guide

This guide explains how to use the structured error handling and audit logging system in the Claude Code Rust implementation.

## Overview

The error handling system provides:

1. **Structured Errors** - Unique IDs, categorization, and context for error correlation
2. **Audit Logging** - Track important operations with status, duration, and metadata
3. **Error Recovery** - Distinguish between recoverable and fatal errors
4. **Observability** - Integration with `tracing` for comprehensive logging

## Module Location

`src-rust/crates/core/src/error_handler.rs`

## Error Categories

Errors are classified into categories for filtering and handling:

| Category | Use Case | Examples |
|----------|----------|----------|
| `Configuration` | Config/environment errors | Invalid settings, missing env vars |
| `Authentication` | Auth/permission errors | Invalid token, auth failure |
| `ToolExecution` | Tool runtime errors | Command failed, tool not found |
| `Network` | Network/API errors | Connection timeout, HTTP error |
| `FileSystem` | File operation errors | Permission denied, file not found |
| `Query` | Agent/query errors | Invalid prompt, query failure |
| `Serialization` | Parser/format errors | Invalid JSON, deserialization |
| `Mcp` | MCP server errors | Protocol error, server unavailable |
| `Internal` | System errors | Panic, internal inconsistency |
| `Other` | Uncategorized errors | Default for unknown errors |

## Using AuditedError

### Basic Error Creation

```rust
use cc_core::error_handler::{AuditedError, ErrorCategory};
use tracing::error;

// Create a basic error
let err = AuditedError::new(
    ErrorCategory::Network,
    "Failed to connect to API",
    "main.rs:42",
    true,  // recoverable
);

// Log and return
Err(err.log())
```

### Error with Context

```rust
use serde_json::json;

let err = AuditedError::new(
    ErrorCategory::Configuration,
    "Invalid config value",
    "config.rs:100",
    false,  // not recoverable
).with_context(json!({
    "key": "max_retries",
    "value": "-5",
    "expected": "positive integer",
}));

err.log();
```

### Recoverable vs Fatal Errors

```rust
// Recoverable error - logged as warning
let recoverable = AuditedError::new(
    ErrorCategory::Network,
    "Connection timeout, will retry",
    "api.rs:50",
    true,  // recoverable = warning level
);

// Fatal error - logged as error
let fatal = AuditedError::new(
    ErrorCategory::Authentication,
    "Invalid authentication token",
    "oauth.rs:30",
    false,  // not recoverable = error level
);
```

### Error ID Correlation

Each error gets a unique ID for tracking:

```rust
let err = AuditedError::new(
    ErrorCategory::ToolExecution,
    "Tool execution failed",
    "bash.rs:80",
    true,
);

println!("Error ID: {}", err.id);
// Output: Error ID: 1713662400-a1b2c3d4

// Use this ID in logs or error reports for correlation
```

## Using AuditLogEntry

### Basic Operation Logging

```rust
use cc_core::error_handler::{AuditLogEntry, OperationStatus};
use std::time::Instant;

let start = Instant::now();

// Create audit entry
let entry = AuditLogEntry::new("file_write")
    .with_resource("config.json")
    .with_actor("user_cli");

// ... perform operation ...

let duration = start.elapsed().as_millis() as u64;
entry
    .with_status(OperationStatus::Success)
    .complete(duration);

// Logs: "Operation file_write completed: success (duration: 45ms)"
```

### Operation with Metadata

```rust
let entry = AuditLogEntry::new("tool_execution")
    .with_resource("bash")
    .with_actor("agent:search")
    .with_metadata(json!({
        "command": "find . -name '*.rs'",
        "exit_code": 0,
        "lines_output": 42,
    }));

entry
    .with_status(OperationStatus::Success)
    .complete(123);  // 123ms
```

### Handling Operation Failures

```rust
// Track partial success
let entry = AuditLogEntry::new("batch_operation")
    .with_resource("files")
    .with_metadata(json!({
        "total": 100,
        "succeeded": 95,
        "failed": 5,
    }));

if failed_count > 0 {
    entry.with_status(OperationStatus::PartialSuccess)
} else {
    entry.with_status(OperationStatus::Success)
}.complete(duration);
```

## Integration with Existing Code

### Example: Tool Execution

```rust
// In tools/src/bash.rs
use cc_core::error_handler::{AuditedError, AuditLogEntry, ErrorCategory, OperationStatus};
use std::time::Instant;

async fn execute_bash(cmd: &str) -> Result<String> {
    let start = Instant::now();
    let entry = AuditLogEntry::new("bash_execution")
        .with_resource(cmd)
        .with_actor("bash_tool");

    match run_command(cmd).await {
        Ok(output) => {
            entry.with_status(OperationStatus::Success)
                .complete(start.elapsed().as_millis() as u64);
            Ok(output)
        }
        Err(e) => {
            let err = AuditedError::new(
                ErrorCategory::ToolExecution,
                format!("Bash command failed: {}", e),
                "bash.rs:95",
                true,  // usually recoverable
            ).with_context(json!({
                "command": cmd,
                "error": e.to_string(),
            }));
            
            entry.with_status(OperationStatus::Failed)
                .complete(start.elapsed().as_millis() as u64);
            
            Err(err.log())
        }
    }
}
```

### Example: API Call

```rust
// In api/src/lib.rs
use cc_core::error_handler::{AuditedError, AuditLogEntry, ErrorCategory, OperationStatus};

async fn call_api(endpoint: &str) -> Result<Response> {
    let start = Instant::now();
    let entry = AuditLogEntry::new("api_call")
        .with_resource(endpoint);

    match make_request(endpoint).await {
        Ok(response) => {
            entry.with_status(OperationStatus::Success)
                .complete(start.elapsed().as_millis() as u64);
            Ok(response)
        }
        Err(e) => {
            let err = AuditedError::new(
                ErrorCategory::Network,
                format!("API call failed: {}", e),
                "api.rs:150",
                e.is_retryable(),  // depends on error type
            ).with_context(json!({
                "endpoint": endpoint,
                "status": e.status_code(),
                "retryable": e.is_retryable(),
            }));
            
            entry.with_status(OperationStatus::Failed)
                .complete(start.elapsed().as_millis() as u64);
            
            Err(err.log())
        }
    }
}
```

## Logging Integration

The error handler integrates with `tracing`:

```rust
// Recoverable errors → warn! level
error.log()  // Uses warn! for recoverable=true

// Fatal errors → error! level
error.log()  // Uses error! for recoverable=false
```

### Enabling Debug Logging

```bash
# Run with debug logging
RUST_LOG=debug cargo run

# Run with specific module debug
RUST_LOG=cc_core::error_handler=debug cargo run

# Run with trace level
RUST_LOG=trace cargo run
```

### Log Output Example

```
2024-04-22T15:30:45.123Z  WARN cc_query::agent_tool: [Network] Connection timeout (id: 1713662400-a1b2c3d4, recoverable: true)
2024-04-22T15:30:45.124Z  INFO cc_query::agent_tool: Operation bash_execution completed: success (duration: 45ms)
2024-04-22T15:30:46.000Z ERROR cc_api::client: [Authentication] Invalid token (id: 1713662460-x9y8z7w6, recoverable: false)
```

## Best Practices

### 1. Always Provide Context

```rust
// ❌ Bad
let err = AuditedError::new(ErrorCategory::Network, "Failed", "api.rs:100", true);

// ✅ Good
let err = AuditedError::new(
    ErrorCategory::Network,
    format!("Failed to fetch from {}: {}", url, error),
    "api.rs:100",
    true,
).with_context(json!({
    "url": url,
    "timeout_ms": timeout,
    "error": error.to_string(),
}));
```

### 2. Use Error IDs for Debugging

```rust
// When returning error to user
match operation().await {
    Err(e) => {
        eprintln!("Operation failed: {} (error ID: {})", e.message, e.id);
        return Err(e);
    }
    Ok(v) => Ok(v),
}

// User can provide error ID to support for fast diagnosis
```

### 3. Distinguish Recoverable Errors

```rust
// Transient errors (should retry)
let recoverable = AuditedError::new(
    ErrorCategory::Network,
    "Connection timeout",
    file_line,
    true,  // Network timeout can be retried
);

// Permanent errors (don't retry)
let permanent = AuditedError::new(
    ErrorCategory::Authentication,
    "Invalid API key",
    file_line,
    false,  // Auth error won't succeed on retry
);
```

### 4. Complete Audit Entries

```rust
let start = Instant::now();
let entry = AuditLogEntry::new("operation");

// ✅ Always complete the entry
result = perform_operation();
entry.complete(start.elapsed().as_millis() as u64);

// ❌ Don't leave entries incomplete
entry; // unused - duration never logged
```

### 5. Use Meaningful Resource Names

```rust
// For file operations
.with_resource("/home/user/config.json")

// For network operations
.with_resource("https://api.example.com/v1/chat")

// For tool operations
.with_resource("bash:find")  // tool_name:command

// For agent operations
.with_resource("agent:research")  // agent_type:name
```

## Structured Logging Export

The error handler and audit entries use serde for JSON serialization:

```rust
use serde_json::to_string_pretty;

let err = AuditedError::new(...).with_context(...);
let json = to_string_pretty(&err)?;
println!("{}", json);
```

Output:
```json
{
  "id": "1713662400-a1b2c3d4",
  "category": "Network",
  "message": "Connection timeout",
  "timestamp": 1713662400,
  "source": "api.rs:100",
  "context": {
    "url": "https://api.anthropic.com/v1/messages",
    "timeout_ms": 30000
  },
  "recoverable": true
}
```

## Testing with Error Handling

```rust
#[test]
fn test_error_creation() {
    use cc_core::error_handler::{AuditedError, ErrorCategory};
    
    let err = AuditedError::new(
        ErrorCategory::Network,
        "Connection timeout",
        "test.rs:42",
        true,
    );
    
    assert_eq!(err.category, ErrorCategory::Network);
    assert_eq!(err.message, "Connection timeout");
    assert!(err.recoverable);
    assert!(!err.id.is_empty());
}
```

## Performance Considerations

- **Error creation**: O(1) with UUID generation
- **Logging**: Async with tracing, non-blocking
- **Context serialization**: Only when logged (lazy)
- **Memory**: ~200 bytes per error with context

Minimal overhead - use freely for production code.

## Migration from String Errors

```rust
// Old: String errors
Err("Something went wrong".to_string())

// New: Structured errors
Err(AuditedError::new(
    ErrorCategory::Internal,
    "Something went wrong",
    "module.rs:50",
    false,
).log())
```

## Troubleshooting

### Errors Not Appearing in Logs

1. Check RUST_LOG environment variable
2. Ensure tracing_subscriber is initialized
3. Verify log level is set (default: info)

### Missing Context in Errors

1. Always call `.with_context()` for detailed debugging
2. Use `serde_json::json!` macro for easy context creation
3. Include relevant variables and state

### Audit Entries Not Logged

1. Always call `.complete()` to finalize the entry
2. Ensure tracing is initialized before operations
3. Check log level includes info (audit entries use info level)

## Further Reading

- [tracing documentation](https://docs.rs/tracing/)
- [Structured Logging Best Practices](https://www.kartar.net/2015/12/structured-logging/)
- [Error Handling in Rust](https://doc.rust-lang.org/book/ch09-00-error-handling.html)
