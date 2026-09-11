"""
Unit tests for the HA-Deploy Flask application.
Run with: pytest tests/test_app.py -v
(Run from the repo root with app/ on the path, or `cd app && pytest ../tests`.)
"""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "app"))

import pytest
from app import app as flask_app


@pytest.fixture
def client():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as client:
        yield client


def test_index_returns_200(client):
    response = client.get("/")
    assert response.status_code == 200


def test_index_contains_app_name(client):
    response = client.get("/")
    assert b"HA-Deploy" in response.data


def test_health_returns_200_and_healthy_json(client):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.get_json()
    assert data == {"status": "healthy"}


def test_api_info_returns_200(client):
    response = client.get("/api/info")
    assert response.status_code == 200


def test_api_info_contains_required_fields(client):
    response = client.get("/api/info")
    data = response.get_json()
    for field in [
        "application",
        "version",
        "environment",
        "hostname",
        "instance_id",
        "availability_zone",
    ]:
        assert field in data


def test_api_info_degrades_gracefully_without_imds(client):
    """Off EC2 (e.g. in CI), metadata calls should fail fast and fall back,
    not raise an exception or hang."""
    response = client.get("/api/info")
    assert response.status_code == 200
    data = response.get_json()
    assert data["instance_id"] != ""
    assert data["availability_zone"] != ""
