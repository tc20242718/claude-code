# Changelog

All notable changes to the Claude Code Rust implementation will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Error Handling & Audit Logging System** (`error_handler.rs`)
  - Structured error type (`AuditedError`) for audit logging with unique IDs and error correlation
  - Error categorization system (Configuration, Authentication, ToolExecution, Network, FileSystem, Query, Serialization, Mcp, Internal, Other)
  - Audit log entry system (`AuditLogEntry`) for tracking important operations
  - Operation status tracking (Success, PartialSuccess, Failed, Cancelled)
  - Context enrichment for errors and audit logs
  - Full test coverage for error handling module

- **Comprehensive Logging Documentation**
  - Error handling guide with examples
  - Audit logging best practices
  - Structured logging configuration

- **.gitignore file** for Rust build artifacts and common IDE files
  - Includes target/, Cargo.lock, build artifacts
  - IDE configuration (.vscode, .idea)
  - OS-specific files (.DS_Store, .env)

### Fixed
- **Compilation Errors - QueryConfig Missing Fields** (commit 273dcfc)
  - Added missing `output_style` field to QueryConfig struct
  - Added missing `working_directory` field to QueryConfig struct
  - Fixed agent_tool.rs QueryConfig initialization
  - Fixed test helper function make_config() initialization
  
- **Unused Imports** (commit 273dcfc)
  - Removed unused wildcard import from coordinator.rs
  - Removed unused OutputStyle import from lib.rs
  
- **Test Environment Conflicts** (commit 273dcfc)
  - Fixed SDK prefix detection tests failing due to CLAUDE_CODE_REMOTE env var
  - Implemented RAII guard (EnvGuard) for safe environment variable handling in tests
  - Tests now properly clean up environment state

- **Keybindings HashMap Iteration Order Bug** (commit 273dcfc)
  - Replaced HashMap with IndexMap in JsonKeybindingBlock
  - Preserves JSON insertion order for deterministic test results
  - Fixes flaky test: test_user_keybindings_supports_ts_block_format

### Changed
- Upgraded keybindings module to use IndexMap for ordered key/value pairs

### Verified
- All 312+ tests passing across 9 crates
- Full test suite passes without errors or failures
- Build completes successfully with no compilation errors
- Code compiles with only minor dead-code warnings (non-blocking)

## Build & Test Status

### Latest Test Run
- **Total Tests**: 312+
- **Passed**: 312+
- **Failed**: 0
- **Status**: ✅ All passing

### Crate Test Breakdown
- cc-api: 12 tests ✅
- cc-bridge: 27 tests ✅
- cc-buddy: 3 tests ✅
- cc-commands: 23 tests ✅
- cc-core: 203 tests ✅
- cc-mcp: 9 tests ✅
- cc-query: 2 tests ✅
- cc-tools: 33 tests ✅

## Known Limitations

### Stub Implementations (Deferred)
The following features are currently stubbed and marked for future implementation:

1. **LSP Diagnostics** (`src-rust/crates/core/src/lsp.rs`)
   - Currently returns empty diagnostics list
   - Marked with `#[test] test_get_diagnostics_stub_empty()`
   - Full Language Server Protocol integration pending

2. **MCP Server Instructions Caching** (`src-rust/crates/mcp/src/lib.rs:657`)
   - McpClient doesn't store instructions yet
   - Returns empty vector placeholder
   - Full MCP instruction set support pending

3. **Bundled Skills Documentation** (`src-rust/crates/tools/src/bundled_skills.rs`)
   - Documentation stubs for deferred tools
   - Skill discovery mechanism placeholder

4. **Stickers Feature** (`src-rust/crates/commands/src/lib.rs`)
   - Returns "coming soon!" placeholder
   - Full implementation pending

## Migration Guide

### For Users Upgrading from Previous Version
1. Ensure CLAUDE_CODE_REMOTE environment variable is properly configured if using remote mode
2. Update keybindings files - now use deterministic ordering (no behavior change, but order is preserved)
3. New error_handler module available for applications that need structured error logging

## Development Notes

### Recent Refactoring
- Error handling now uses structured logging with unique IDs for error correlation
- Keybindings now use IndexMap for consistent ordering across platforms
- Environment variable handling in tests is now properly scoped with RAII guards

### Testing Strategy
- All core functionality covered by 312+ tests
- Error handling module includes full test coverage
- Environment-dependent tests use RAII guards for clean state management

## Acknowledgments

This Rust implementation is a clean-room reimplementation based on behavioral specifications extracted from the Claude Code TypeScript source code.
