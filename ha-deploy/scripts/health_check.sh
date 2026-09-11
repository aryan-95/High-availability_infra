#!/bin/bash
# health_check.sh
# Verifies the /health endpoint returns HTTP 200.
# Usage: ./scripts/health_check.sh <base-url>
# Example: ./scripts/health_check.sh http://ha-deploy-alb-123456.us-east-1.elb.amazonaws.com

set -e

BASE_URL="${1:-http://localhost:5000}"
HEALTH_URL="${BASE_URL%/}/health"

echo "Checking $HEALTH_URL ..."

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$HEALTH_URL" || echo "000")

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "OK: application is healthy (HTTP $HTTP_CODE)"
  exit 0
else
  echo "FAIL: application is unhealthy (HTTP $HTTP_CODE)"
  exit 1
fi
