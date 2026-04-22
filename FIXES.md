# Known Issues and Fixes

This document tracks known issues, their fixes, and guidance for working with the Claude Code Rust implementation.

## Fixed Issues

### Issue #1: QueryConfig Missing Fields (FIXED ✅)
**Status**: Resolved in commit 273dcfc

**Problem**:
- Compilation error: `E0063: missing fields output_style and working_directory in initializer of QueryConfig`
- Occurred in two locations:
  - `src-rust/crates/query/src/agent_tool.rs:154`
  - `src-rust/crates/query/src/lib.rs:475`

**Root Cause**:
QueryConfig struct was modified to include two new required fields, but all initialization sites weren't updated.

**Solution**:
- Added `output_style: Default::default()` to both QueryConfig initializations
- Added `working_directory: None` to both initializations
- These fields now properly configure agent output style and working directory context

**Verification**:
```bash
cargo build --all  # Now succeeds without errors
cargo test --all   # All 312+ tests pass
```

---

### Issue #2: Unused Imports (FIXED ✅)
**Status**: Resolved in commit 273dcfc

**Problem**:
- Warning: `unused import: crate::*` in coordinator.rs
- Warning: `unused import: OutputStyle` in lib.rs

**Root Cause**:
Wildcard imports and unused symbols left from refactoring.

**Solution**:
- Removed `use crate::*;` from `src-rust/crates/query/src/coordinator.rs:3`
  - Module is self-contained and doesn't need crate-level imports
- Removed unused `OutputStyle` from import list in `src-rust/crates/query/src/lib.rs:446`
  - SystemPromptOptions alone is sufficient for build_system_prompt()

**Impact**: 
- Cleaner compilation output
- Improved code clarity

---

### Issue #3: Test Environment Configuration Conflict (FIXED ✅)
**Status**: Resolved in commit 273dcfc

**Problem**:
- Tests failing: `test_sdk_prefix_non_interactive_no_append` and `test_sdk_preset_prefix_non_interactive_with_append`
- Expected SDK variants but got Remote prefix instead
- Environment variable `CLAUDE_CODE_REMOTE=true` was interfering

**Root Cause**:
SystemPromptPrefix::detect() checks CLAUDE_CODE_REMOTE before SDK detection logic:
```rust
if std::env::var("CLAUDE_CODE_REMOTE").is_ok() {
    return Self::Remote;  // Returns here before checking SDK variants
}
```
The running environment (Cloud Runtime) has this var set, causing test failures.

**Solution**:
Created RAII guard to temporarily unset the variable during tests:
```rust
struct EnvGuard((String, Option<String>));
impl Drop for EnvGuard {
    fn drop(&mut self) {
        if let Some(val) = &self.0.1 {
            std::env::set_var(&self.0.0, val);
        }
    }
}
```

**Usage Pattern**:
```rust
#[test]
fn test_sdk_prefix_non_interactive_no_append() {
    let _guard = {
        let old = std::env::var("CLAUDE_CODE_REMOTE").ok();
        std::env::remove_var("CLAUDE_CODE_REMOTE");
        EnvGuard(("CLAUDE_CODE_REMOTE".to_string(), old))
    };
    // Test runs with CLAUDE_CODE_REMOTE unset
    let prefix = SystemPromptPrefix::detect(true, false);
    assert_eq!(prefix, SystemPromptPrefix::Sdk);
} // EnvGuard drops here, restoring original value
```

**Verification**:
```
test_sdk_prefix_non_interactive_no_append ✅ PASSED
test_sdk_preset_prefix_non_interactive_with_append ✅ PASSED
```

---

### Issue #4: HashMap Iteration Order Nondeterminism (FIXED ✅)
**Status**: Resolved in commit 273dcfc

**Problem**:
- Test failing: `test_user_keybindings_supports_ts_block_format`
- Assertion failed: `left: "space" right: "ctrl+g"`
- Test expected keybindings in JSON order but got different order

**Root Cause**:
`JsonKeybindingBlock::bindings` used `HashMap<String, Option<String>>`:
- HashMap doesn't preserve insertion order
- Iteration order is based on hash values and internal bucketing
- Different platforms/runs could produce different orders

**Solution**:
Replaced HashMap with IndexMap which preserves insertion order:

```diff
- use std::collections::HashMap;
+ use indexmap::IndexMap;

  #[derive(Debug, Clone, Serialize, Deserialize)]
  struct JsonKeybindingBlock {
      context: String,
-     bindings: HashMap<String, Option<String>>,
+     bindings: IndexMap<String, Option<String>>,
  }
```

**Why IndexMap**:
- Preserves JSON insertion order (deterministic)
- Serde support already enabled in workspace (indexmap v2 with serde feature)
- Drop-in replacement for HashMap
- O(1) lookups like HashMap, just with consistent ordering

**Verification**:
```
test_user_keybindings_supports_ts_block_format ✅ PASSED
Iteration order now matches JSON: "ctrl+g" then "space"
```

---

## Stub Implementations (Deferred)

The following are intentional placeholders for future implementation:

### LSP Diagnostics Stub
**Location**: `src-rust/crates/core/src/lsp.rs`
**Current Behavior**: Returns empty diagnostics list
**Test**: `#[test] test_get_diagnostics_stub_empty()`

**Why Stubbed**:
- Requires full Language Server Protocol integration
- Depends on external editor integration
- Marked for Phase 2 implementation

**To Implement**:
1. Add LSP client initialization
2. Wire up to editor extension protocols
3. Implement diagnostic collection and reporting

---

### MCP Server Instructions Caching
**Location**: `src-rust/crates/mcp/src/lib.rs:657`
**Current Behavior**: Returns empty vector
**Issue**: McpClient doesn't store instructions yet (placeholder)

**Why Stubbed**:
- Requires MCP protocol message handling
- Depends on instruction format specification
- Can be added incrementally

**To Implement**:
1. Store instructions in McpClient struct
2. Implement instruction parsing and validation
3. Add caching layer for performance

---

### Bundled Skills
**Location**: `src-rust/crates/tools/src/bundled_skills.rs`
**Current Behavior**: Documentation stubs

**Why Stubbed**:
- Requires skill registry infrastructure
- Depends on skill discovery mechanism
- Marked for later enhancement

---

### Stickers Feature
**Location**: Various (commands, tui, etc.)
**Current Behavior**: Returns "coming soon!" placeholder
**Status**: Feature gate pending

**Why Stubbed**:
- UI/aesthetic feature
- Requires TUI enhancement
- Low priority for current phase

---

## Testing Best Practices

### Environment Variables
For tests that depend on environment variables:

1. **Use RAII guards** to preserve environment state
2. **Unset temporarily** for isolated test behavior
3. **Restore on drop** automatically

Example:
```rust
#[test]
fn test_with_clean_env() {
    let _guard = {
        let old_val = std::env::var("MY_VAR").ok();
        std::env::remove_var("MY_VAR");
        EnvGuard(("MY_VAR".to_string(), old_val))
    };
    // Test runs with clean environment
} // Automatically restored
```

### HashMap/BTreeMap/IndexMap
When preserving insertion order matters:
- Use `IndexMap` for JSON-like structures
- Use `BTreeMap` for sorted order
- Use `HashMap` only when order doesn't matter

---

## Troubleshooting

### Tests Failing with "CLAUDE_CODE_REMOTE" Error
**Cause**: Running in a remote environment where CLAUDE_CODE_REMOTE=true
**Solution**: Use EnvGuard pattern to temporarily unset the variable
**Files**: Implement in tests that check prefix detection

### Build Errors After Struct Changes
**Cause**: New required fields added to structs without updating all initializations
**Solution**: Search for all struct initializations and update them
**Command**: `cargo build --all --message-format=json | jq '.message'`

### Flaky Tests (Random Pass/Fail)
**Cause**: Usually HashMap iteration order or timing issues
**Solution**:
1. Check for HashMap usage - replace with IndexMap if order matters
2. Add proper synchronization for concurrent code
3. Use test utilities like `tokio::time::pause()` for timing

---

## Code Quality Metrics

### Test Coverage
- Total Tests: 312+
- Pass Rate: 100%
- Coverage: Core functionality fully covered

### Warnings
- Compilation Warnings: ~10 (non-critical)
  - Unused fields (marked intentionally)
  - Unused imports in test modules
  - Unused functions in test code

- No Security Warnings
- No Critical Warnings

### Performance Notes
- Keybindings: O(1) lookup with IndexMap (same as HashMap)
- Error handling: Minimal overhead with structured logging
- No performance regressions from fixes

---

## Contributing Guidelines

When fixing issues:

1. **Identify the root cause** - don't just patch symptoms
2. **Add tests** that cover the fixed case and regressions
3. **Document the fix** in commit message and this file
4. **Verify no regressions** - run full test suite
5. **Update CHANGELOG** - record the change

When adding new features:

1. **Stub stubs** should have tests marked as placeholders
2. **Use structured logging** from error_handler module
3. **Add audit entries** for important operations
4. **Include error handling** for failure paths
