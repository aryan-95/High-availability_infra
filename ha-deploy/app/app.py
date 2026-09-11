"""
HA-Deploy: Highly Available Web Architecture with Automated CI/CD on AWS
Simple Flask application demonstrating EC2 metadata retrieval via IMDSv2,
health checks, and a small JSON API. Designed to run identically on a
laptop (Docker/local) and on EC2 behind an ALB/ASG.
"""

import os
import socket
import requests
from flask import Flask, jsonify, render_template

app = Flask(__name__)

# ---------------------------------------------------------------------------
# Configuration (env vars with safe local defaults)
# ---------------------------------------------------------------------------
APP_VERSION = os.environ.get("APP_VERSION", "1.0.0")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "local")
PORT = int(os.environ.get("PORT", 5000))
APP_NAME = "HA-Deploy"

IMDS_BASE_URL = "http://169.254.169.254/latest"
IMDS_TIMEOUT_SECONDS = 1  # fail fast locally / off-EC2


def get_imds_token():
    """Get an IMDSv2 session token. Returns None if not on EC2 / unreachable."""
    try:
        resp = requests.put(
            f"{IMDS_BASE_URL}/api/token",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "21600"},
            timeout=IMDS_TIMEOUT_SECONDS,
        )
        resp.raise_for_status()
        return resp.text
    except requests.exceptions.RequestException:
        return None


def get_metadata(path, token, default="unavailable"):
    """Fetch a single metadata path using IMDSv2. Falls back gracefully."""
    if token is None:
        return default
    try:
        resp = requests.get(
            f"{IMDS_BASE_URL}/meta-data/{path}",
            headers={"X-aws-ec2-metadata-token": token},
            timeout=IMDS_TIMEOUT_SECONDS,
        )
        resp.raise_for_status()
        return resp.text
    except requests.exceptions.RequestException:
        return default


def get_instance_metadata():
    """Return a dict of instance-id, availability-zone, and hostname.

    On EC2 this uses IMDSv2. Off EC2 (local dev, unit tests, CI) it
    degrades gracefully to placeholder values instead of raising.
    """
    token = get_imds_token()
    instance_id = get_metadata("instance-id", token, default="local-dev-instance")
    az = get_metadata("placement/availability-zone", token, default="local-dev-az")
    try:
        hostname = socket.gethostname()
    except Exception:
        hostname = "unknown-host"

    return {
        "instance_id": instance_id,
        "availability_zone": az,
        "hostname": hostname,
    }


@app.route("/")
def index():
    """Human-facing landing page showing where this request was served from."""
    meta = get_instance_metadata()
    return render_template(
        "index.html",
        app_name=APP_NAME,
        environment=ENVIRONMENT,
        instance_id=meta["instance_id"],
        availability_zone=meta["availability_zone"],
        hostname=meta["hostname"],
        version=APP_VERSION,
    )


@app.route("/health")
def health():
    """Health check endpoint used by the ALB Target Group and ASG."""
    return jsonify({"status": "healthy"}), 200


@app.route("/api/info")
def api_info():
    """Machine-readable info about this instance / deployment."""
    meta = get_instance_metadata()
    return jsonify(
        {
            "application": APP_NAME,
            "version": APP_VERSION,
            "environment": ENVIRONMENT,
            "hostname": meta["hostname"],
            "instance_id": meta["instance_id"],
            "availability_zone": meta["availability_zone"],
        }
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
