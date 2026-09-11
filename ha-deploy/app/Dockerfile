# HA-Deploy application container
# Used for local testing / containerization demo.
# Production runs on EC2 + Auto Scaling Group, not this container.

FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV APP_VERSION=1.0.0 \
    ENVIRONMENT=docker-local \
    PORT=5000

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
