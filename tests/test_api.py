from fastapi.testclient import TestClient

from devops_agent.api import app


def test_health() -> None:
    response = TestClient(app).get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_metrics() -> None:
    assert "opspilot_http_requests_total" in TestClient(app).get("/metrics").text
