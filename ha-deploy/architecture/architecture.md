# HA-Deploy Architecture

## Current Architecture (Modular Monolith)

```
                          Internet
                              |
                              v
                  Application Load Balancer (public subnets, 2 AZs)
                              |
                +-------------+-------------+
                |                           |
                v                           v
        Availability Zone A         Availability Zone B
                |                           |
                v                           v
        EC2 Instance(s)              EC2 Instance(s)
        (private subnet)             (private subnet)
        Flask app v.X                Flask app v.X
                |                           |
                +-------------+-------------+
                              |
                     Auto Scaling Group
                     (min 2, desired 2, max 6)
                              |
                              v
                        CloudWatch
              (CPU metrics, alarms, health signals)
```

CI/CD path:

```
Developer -> GitHub -> AWS CodeBuild (install, test, build, package)
                              |
                              v
                 scripts/deploy.sh -> ASG Instance Refresh
                              |
                              v
                    Rolling replacement across AZs
```

The application today is a **single Flask process** exposing `/`, `/health`,
and `/api/info`. It is intentionally NOT split into services yet — that
would add operational complexity a college demo doesn't need.

## Future Evolution: Microservices

If HA-Deploy grew into a real product, the same ALB + ASG pattern extends
naturally into independent services, each with its own Target Group, Auto
Scaling Group, and deployment pipeline:

```
                    Application Load Balancer
                              |
        +----------------+----------------+----------------+
        |                |                |
        v                v                v
   User Service     Order Service    Payment Service
   (own ASG)         (own ASG)         (own ASG)
   /users/*          /orders/*         /payments/*
```

Key properties this unlocks:

- **Independent deployment** — the Payment Service can ship a fix without
  redeploying User or Order services.
- **Independent scaling** — Order Service can scale to 10 instances during
  a sale while User Service stays at 2.
- **Service isolation** — a crash or bug in one service doesn't take down
  the others; blast radius is contained.
- **API-based communication** — services talk over HTTP/REST or a message
  queue (e.g. SQS) instead of sharing memory or a database schema directly.

**Current implementation status: this project is a modular monolithic Flask
application.** The microservices layout above is the documented future
direction, not something implemented in this repository.
