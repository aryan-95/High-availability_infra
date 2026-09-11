#!/bin/bash
# install_app.sh
# Runs as EC2 user_data (rendered by Terraform's templatefile()).
# Bootstraps a fresh instance: install deps, pull app code, run it as a service.
# This is the "immutable infrastructure" bootstrap: it always builds a fresh
# instance from scratch; nobody logs in later to hand-edit code on it.

set -e

APP_VERSION="${app_version}"
ENVIRONMENT="${environment}"
APP_REPO_URL="${app_repo_url}"

APP_DIR="/opt/ha-deploy"
SERVICE_NAME="ha-deploy"

echo "== HA-Deploy bootstrap starting (version=$APP_VERSION, env=$ENVIRONMENT) =="

dnf install -y python3.12 python3.12-pip git >/dev/null 2>&1 || \
  yum install -y python3.12 python3.12-pip git

rm -rf "$APP_DIR"
git clone --depth 1 "$APP_REPO_URL" "$APP_DIR" || {
  echo "WARNING: git clone failed (repo URL may be a placeholder)."
  echo "Creating a minimal fallback app so the demo still runs."
  mkdir -p "$APP_DIR/app"
  cp -r /tmp/ha-deploy-fallback/* "$APP_DIR/app/" 2>/dev/null || true
}

cd "$APP_DIR/app"
python3.12 -m pip install --upgrade pip >/dev/null
python3.12 -m pip install -r requirements.txt >/dev/null

cat > /etc/systemd/system/$${SERVICE_NAME}.service <<EOF
[Unit]
Description=HA-Deploy Flask Application
After=network.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR/app
Environment=APP_VERSION=$APP_VERSION
Environment=ENVIRONMENT=$ENVIRONMENT
Environment=PORT=5000
ExecStart=/usr/bin/python3.12 -m gunicorn --bind 0.0.0.0:5000 --workers 2 app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable $${SERVICE_NAME}
systemctl restart $${SERVICE_NAME}

echo "== HA-Deploy bootstrap complete =="
