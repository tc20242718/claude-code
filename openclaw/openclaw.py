import os
from typing import Dict, Any, List, Optional
from dotenv import load_dotenv
from connector_base import LocalConnector, CloudConnector, ConnectorBase

load_dotenv()


class OpenClaw:
    def __init__(self):
        self.local_agents: Dict[str, LocalConnector] = {}
        self.cloud_agents: Dict[str, CloudConnector] = {}
        self.pending_approvals: Dict[str, Dict[str, Any]] = {}
        self.telegram_token = os.getenv("TELEGRAM_BOT_TOKEN")
        self.telegram_chat_id = os.getenv("TELEGRAM_CHAT_ID")

    def register_local_agent(self, name: str) -> LocalConnector:
        agent = LocalConnector(name)
        self.local_agents[name] = agent
        return agent

    def register_cloud_agent(
        self, name: str, api_endpoint: str, api_key: str
    ) -> CloudConnector:
        agent = CloudConnector(name, api_endpoint, api_key)
        self.cloud_agents[name] = agent
        return agent

    def health_check_all(self) -> Dict[str, bool]:
        status = {}
        for name, agent in self.local_agents.items():
            status[f"local_{name}"] = agent.health_check()
        for name, agent in self.cloud_agents.items():
            status[f"cloud_{name}"] = agent.health_check()
        return status

    def route_task(self, task: Dict[str, Any]) -> Dict[str, Any]:
        risk_level = task.get("risk_level", "low")

        if risk_level == "low":
            return self._execute_local(task)
        elif risk_level in ["medium", "high"]:
            return self._request_approval(task)
        return {"status": "error", "message": "Unknown risk level"}

    def _execute_local(self, task: Dict[str, Any]) -> Dict[str, Any]:
        agent_name = task.get("agent", "default")
        if agent_name in self.local_agents:
            agent = self.local_agents[agent_name]
            if agent.is_available:
                return agent.execute_task(task)
        return {"status": "error", "message": f"Agent {agent_name} not available"}

    def _request_approval(self, task: Dict[str, Any]) -> Dict[str, Any]:
        task_id = f"task_{len(self.pending_approvals)}"
        self.pending_approvals[task_id] = task
        self._send_approval_request(task_id, task)
        return {"status": "pending_approval", "task_id": task_id}

    def _send_approval_request(self, task_id: str, task: Dict[str, Any]):
        if self.telegram_token and self.telegram_chat_id:
            try:
                import requests

                message = f"Approval Required\n\nTask ID: {task_id}\nDescription: {task.get('description', 'N/A')}\nRisk Level: {task.get('risk_level', 'unknown')}"
                requests.post(
                    f"https://api.telegram.org/bot{self.telegram_token}/sendMessage",
                    data={
                        "chat_id": self.telegram_chat_id,
                        "text": message,
                    },
                )
            except Exception as e:
                print(f"Failed to send Telegram message: {e}")

    def approve_task(self, task_id: str) -> Dict[str, Any]:
        if task_id not in self.pending_approvals:
            return {"status": "error", "message": "Task not found"}

        task = self.pending_approvals.pop(task_id)
        return self._route_to_cloud(task)

    def reject_task(self, task_id: str) -> Dict[str, Any]:
        if task_id not in self.pending_approvals:
            return {"status": "error", "message": "Task not found"}

        self.pending_approvals.pop(task_id)
        return {"status": "rejected", "task_id": task_id}

    def _route_to_cloud(self, task: Dict[str, Any]) -> Dict[str, Any]:
        cloud_agent_name = task.get("cloud_agent", list(self.cloud_agents.keys())[0] if self.cloud_agents else None)

        if cloud_agent_name and cloud_agent_name in self.cloud_agents:
            agent = self.cloud_agents[cloud_agent_name]
            if agent.is_available:
                return agent.execute_task(task)

        return {"status": "error", "message": "No available cloud agent"}

    def get_status(self) -> Dict[str, Any]:
        return {
            "local_agents": list(self.local_agents.keys()),
            "cloud_agents": list(self.cloud_agents.keys()),
            "pending_approvals": list(self.pending_approvals.keys()),
            "health": self.health_check_all(),
        }
