//! Error handling and audit logging system

use serde::{Deserialize, Serialize};
use std::fmt;
use std::time::{SystemTime, UNIX_EPOCH};
use tracing::{debug, error, warn, info};

/// Structured error type for audit logging
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuditedError {
    /// Unique error identifier for correlation
    pub id: String,
    /// Error classification
    pub category: ErrorCategory,
    /// Human-readable error message
    pub message: String,
    /// Timestamp when error occurred
    pub timestamp: u64,
    /// Error source (file:line)
    pub source: String,
    /// Additional context
    pub context: Option<serde_json::Value>,
    /// Whether the error is recoverable
    pub recoverable: bool,
}

/// Error categories for classification and filtering
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
pub enum ErrorCategory {
    /// Configuration/environment errors
    Configuration,
    /// Authentication and authorization errors
    Authentication,
    /// Tool execution errors
    ToolExecution,
    /// Network/API errors
    Network,
    /// File system errors
    FileSystem,
    /// Query/Agent errors
    Query,
    /// Parser/serialization errors
    Serialization,
    /// MCP server errors
    Mcp,
    /// Internal system errors
    Internal,
    /// Unknown/uncategorized errors
    Other,
}

impl fmt::Display for ErrorCategory {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Configuration => write!(f, "Configuration"),
            Self::Authentication => write!(f, "Authentication"),
            Self::ToolExecution => write!(f, "ToolExecution"),
            Self::Network => write!(f, "Network"),
            Self::FileSystem => write!(f, "FileSystem"),
            Self::Query => write!(f, "Query"),
            Self::Serialization => write!(f, "Serialization"),
            Self::Mcp => write!(f, "Mcp"),
            Self::Internal => write!(f, "Internal"),
            Self::Other => write!(f, "Other"),
        }
    }
}

impl AuditedError {
    /// Create a new audited error
    pub fn new(
        category: ErrorCategory,
        message: impl Into<String>,
        source: impl Into<String>,
        recoverable: bool,
    ) -> Self {
        let message = message.into();
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or(0);

        let id = format!(
            "{}-{}",
            timestamp,
            uuid::Uuid::new_v4().to_string()[0..8].to_string()
        );

        Self {
            id: id.clone(),
            category,
            message: message.clone(),
            timestamp,
            source: source.into(),
            context: None,
            recoverable,
        }
    }

    /// Add context to the error
    pub fn with_context(mut self, context: serde_json::Value) -> Self {
        self.context = Some(context);
        self
    }

    /// Log the error and return it
    pub fn log(self) -> Self {
        let log_message = format!(
            "[{}] {} (id: {}, recoverable: {})",
            self.category, self.message, self.id, self.recoverable
        );

        if self.recoverable {
            warn!("{}", log_message);
        } else {
            error!("{}", log_message);
        }

        if let Some(ctx) = &self.context {
            debug!("Error context: {:?}", ctx);
        }

        self
    }
}

/// Audit log entry for tracking important operations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuditLogEntry {
    /// Unique identifier for the operation
    pub id: String,
    /// Operation type (e.g., "tool_execution", "file_write", "auth")
    pub operation: String,
    /// Timestamp when operation started
    pub timestamp: u64,
    /// Duration in milliseconds
    pub duration_ms: Option<u64>,
    /// Operation result status
    pub status: OperationStatus,
    /// User or agent performing operation (if available)
    pub actor: Option<String>,
    /// Resource being operated on
    pub resource: Option<String>,
    /// Additional metadata
    pub metadata: Option<serde_json::Value>,
}

/// Status of an audited operation
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
pub enum OperationStatus {
    /// Operation succeeded
    Success,
    /// Operation completed with warnings
    PartialSuccess,
    /// Operation failed but can be retried
    Failed,
    /// Operation was cancelled
    Cancelled,
}

impl fmt::Display for OperationStatus {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Success => write!(f, "success"),
            Self::PartialSuccess => write!(f, "partial_success"),
            Self::Failed => write!(f, "failed"),
            Self::Cancelled => write!(f, "cancelled"),
        }
    }
}

impl AuditLogEntry {
    /// Create a new audit log entry
    pub fn new(operation: impl Into<String>) -> Self {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or(0);

        Self {
            id: uuid::Uuid::new_v4().to_string(),
            operation: operation.into(),
            timestamp,
            duration_ms: None,
            status: OperationStatus::Success,
            actor: None,
            resource: None,
            metadata: None,
        }
    }

    /// Set operation status
    pub fn with_status(mut self, status: OperationStatus) -> Self {
        self.status = status;
        self
    }

    /// Set resource name
    pub fn with_resource(mut self, resource: impl Into<String>) -> Self {
        self.resource = Some(resource.into());
        self
    }

    /// Set actor (user/agent)
    pub fn with_actor(mut self, actor: impl Into<String>) -> Self {
        self.actor = Some(actor.into());
        self
    }

    /// Add metadata
    pub fn with_metadata(mut self, metadata: serde_json::Value) -> Self {
        self.metadata = Some(metadata);
        self
    }

    /// Log and complete the entry
    pub fn complete(mut self, duration_ms: u64) -> Self {
        self.duration_ms = Some(duration_ms);
        info!(
            "Operation {} completed: {} (duration: {}ms)",
            self.operation, self.status, duration_ms
        );
        self
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_audited_error_creation() {
        let err = AuditedError::new(
            ErrorCategory::Network,
            "Connection timeout",
            "main.rs:42",
            true,
        );
        assert_eq!(err.category, ErrorCategory::Network);
        assert_eq!(err.message, "Connection timeout");
        assert!(err.recoverable);
    }

    #[test]
    fn test_audited_error_with_context() {
        let err = AuditedError::new(
            ErrorCategory::Configuration,
            "Invalid config",
            "config.rs:10",
            false,
        )
        .with_context(serde_json::json!({ "key": "value" }));

        assert!(err.context.is_some());
    }

    #[test]
    fn test_audit_log_entry() {
        let entry = AuditLogEntry::new("test_operation")
            .with_status(OperationStatus::Success)
            .with_resource("test.txt")
            .with_actor("test_user");

        assert_eq!(entry.operation, "test_operation");
        assert_eq!(entry.status, OperationStatus::Success);
        assert_eq!(entry.resource, Some("test.txt".to_string()));
        assert_eq!(entry.actor, Some("test_user".to_string()));
    }

    #[test]
    fn test_operation_status_display() {
        assert_eq!(OperationStatus::Success.to_string(), "success");
        assert_eq!(OperationStatus::Failed.to_string(), "failed");
        assert_eq!(OperationStatus::Cancelled.to_string(), "cancelled");
    }
}
