import unittest
from connector_base import LocalConnector, CloudConnector, AgentType


class TestLocalConnector(unittest.TestCase):
    def setUp(self):
        self.connector = LocalConnector("test_local_agent")

    def test_health_check(self):
        self.assertTrue(self.connector.health_check())
        self.assertTrue(self.connector.is_available)

    def test_execute_task_available(self):
        task = {"description": "test task", "risk_level": "low"}
        result = self.connector.execute_task(task)
        self.assertEqual(result["status"], "executing")
        self.assertEqual(result["agent"], "test_local_agent")

    def test_requires_approval_low_risk(self):
        task = {"risk_level": "low"}
        self.assertFalse(self.connector.requires_approval(task))

    def test_requires_approval_high_risk(self):
        task = {"risk_level": "high"}
        self.assertTrue(self.connector.requires_approval(task))

    def test_execute_task_unavailable(self):
        self.connector.is_available = False
        task = {"description": "test task"}
        result = self.connector.execute_task(task)
        self.assertEqual(result["status"], "error")


class TestCloudConnector(unittest.TestCase):
    def setUp(self):
        self.connector = CloudConnector(
            "test_cloud_agent", "http://localhost:8000", "test_api_key"
        )

    def test_requires_approval_always(self):
        task = {"risk_level": "low"}
        self.assertTrue(self.connector.requires_approval(task))

    def test_agent_type(self):
        self.assertEqual(self.connector.agent_type.value, "cloud")


if __name__ == "__main__":
    unittest.main()
