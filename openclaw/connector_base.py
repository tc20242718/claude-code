from abc import ABC, abstractmethod
from enum import Enum
from typing import Any, Dict, Optional


class AgentType(Enum):
    LOCAL = "local"
    CLOUD = "cloud"


class ConnectorBase(ABC):
    def __init__(self, name: str, agent_type: AgentType):
        self.name = name
        self.agent_type = agent_type
        self.is_available = False

    @abstractmethod
    def health_check(self) -> bool:
        pass

    @abstractmethod
    def execute_task(self, task: Dict[str, Any]) -> Dict[str, Any]:
        pass

    @abstractmethod
    def requires_approval(self, task: Dict[str, Any]) -> bool:
        pass


class LocalConnector(ConnectorBase):
    def __init__(self, name: str):
        super().__init__(name, AgentType.LOCAL)

    def health_check(self) -> bool:
        self.is_available = True
        return True

    def execute_task(self, task: Dict[str, Any]) -> Dict[str, Any]:
        if not self.is_available:
            return {"status": "error", "message": "Agent not available"}
        return {"status": "executing", "agent": self.name, "task": task}

    def requires_approval(self, task: Dict[str, Any]) -> bool:
        return task.get("risk_level", "low") in ["medium", "high"]


class CloudConnector(ConnectorBase):
    def __init__(self, name: str, api_endpoint: str, api_key: str):
        super().__init__(name, AgentType.CLOUD)
        self.api_endpoint = api_endpoint
        self.api_key = api_key

    def health_check(self) -> bool:
        try:
            import requests
            response = requests.get(f"{self.api_endpoint}/health", timeout=5)
            self.is_available = response.status_code == 200
        except Exception:
            self.is_available = False
        return self.is_available

    def execute_task(self, task: Dict[str, Any]) -> Dict[str, Any]:
        if not self.is_available:
            return {"status": "error", "message": "Cloud API not available"}
        return {"status": "queued_cloud", "agent": self.name, "task": task}

    def requires_approval(self, task: Dict[str, Any]) -> bool:
        return True
