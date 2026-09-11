# HA-Deploy: Highly Available Web Architecture with Automated CI/CD on AWS

A college-project-level, industry-style DevOps project demonstrating a
highly available, self-healing, auto-scaling web application on AWS, deployed
with Terraform and built through an automated CI pipeline.

---

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [Project Objectives](#project-objectives)
3. [Architecture](#architecture)
4. [Architecture Explanation](#architecture-explanation)
5. [Technology Stack](#technology-stack)
6. [Project Structure](#project-structure)
7. [Prerequisites](#prerequisites)
8. [AWS Setup](#aws-setup)
9. [IAM Requirements](#iam-requirements)
10. [Terraform Deployment](#terraform-deployment)
11. [Application Deployment](#application-deployment)
12. [CI/CD Explanation](#cicd-explanation)
13. [Git Workflow](#git-workflow)
14. [AWS CLI Commands](#aws-cli-commands)
15. [High Availability Explanation](#high-availability-explanation)
16. [Resilience Explanation](#resilience-explanation)
17. [Scalability Explanation](#scalability-explanation)
18. [Near-Zero-Downtime Deployment](#near-zero-downtime-deployment)
19. [Immutable Infrastructure](#immutable-infrastructure)
20. [Monitoring](#monitoring)
21. [Security](#security)
22. [AWS Well-Architected Framework](#aws-well-architected-framework)
23. [Microservices Evolution](#microservices-evolution)
24. [Failure Demonstration](#failure-demonstration)
25. [Testing](#testing)
26. [Cleanup Instructions](#cleanup-instructions)
27. [Troubleshooting](#troubleshooting)
28. [Viva Questions and Answers](#viva-questions-and-answers)
29. [Presentation Flow](#presentation-flow)

---

## Problem Statement

Traditional single-server web deployments have a single point of failure:
if that one server crashes, is overloaded, or is being updated, the
application goes down. Manually SSHing in to fix or update servers causes
**configuration drift** — over time no two servers are configured the same
way, and nobody can say with certainty what's actually running in
production. HA-Deploy solves this by running the application across
multiple servers in multiple Availability Zones, behind a load balancer,
with automated, version-controlled infrastructure and deployments.

## Project Objectives

- Demonstrate a highly available architecture across two Availability Zones
- Automate all infrastructure provisioning with Terraform (Infrastructure as Code)
- Automate build/test with AWS CodeBuild (CI)
- Achieve automatic self-healing via ALB health checks + Auto Scaling
- Achieve horizontal scalability driven by CPU utilization
- Perform near-zero-downtime rolling deployments
- Practice immutable infrastructure instead of manual server patching
- Apply the AWS Well-Architected Framework's six pillars
- Document a clear path toward a microservices architecture

## Architecture

```
                                 Internet
                                     |
                                     v
                       Application Load Balancer (ALB)
                        (public subnets, 2 AZs, port 80)
                                     |
                  +------------------+------------------+
                  |                                     |
                  v                                     v
         Availability Zone A                   Availability Zone B
                  |                                     |
                  v                                     v
          EC2 Instance (private)               EC2 Instance (private)
          Flask app on :5000                   Flask app on :5000
                  |                                     |
                  +------------------+------------------+
                                     |
                                     v
                         Auto Scaling Group
                    (min 2 / desired 2 / max 6)
                                     |
                                     v
                               CloudWatch
                 (CPU alarms, health alarms, logs)

CI/CD:
Developer -> git push -> GitHub -> AWS CodeBuild
                                       |
                          install -> test -> build -> package
                                       |
                                       v
                     scripts/deploy.sh -> ASG Instance Refresh
                                       |
                                       v
                        Rolling deployment across both AZs
```

## Architecture Explanation

- **ALB in public subnets** is the only internet-facing component; it
  terminates HTTP on port 80 and forwards to healthy targets on port 5000.
- **EC2 instances in private subnets** have no public IP and cannot be
  reached directly from the internet — only from the ALB's security group.
  Outbound internet access (for package installs, GitHub, CloudWatch) goes
  through a NAT Gateway.
- **Auto Scaling Group** spans both private subnets/AZs, keeps a minimum of
  2 instances running, and can grow to 6 under load.
- **CloudWatch** collects CPU metrics and alarms, driving both scaling
  policies and operator visibility.
- **Target Group health checks** (`/health`) tell the ALB and ASG which
  instances are actually able to serve traffic.

## Technology Stack

| Layer               | Technology                                   |
|---------------------|-----------------------------------------------|
| Application          | Python 3.12, Flask, Gunicorn                  |
| Containerization      | Docker (local/dev only)                       |
| Infrastructure as Code| Terraform (~> 5.0 AWS provider)               |
| Compute               | EC2, Auto Scaling Group, Launch Template      |
| Networking            | VPC, public/private subnets, IGW, NAT Gateway |
| Load Balancing        | Application Load Balancer + Target Group      |
| CI                    | AWS CodeBuild                                 |
| Monitoring            | Amazon CloudWatch (metrics, alarms, logs)     |
| Identity              | IAM roles (least privilege) + IMDSv2          |
| Version Control       | Git / GitHub                                  |
| Testing               | Pytest                                        |

## Project Structure

```
ha-deploy/
├── app/
│   ├── app.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── templates/
│       └── index.html
├── terraform/
│   ├── versions.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── terraform.tfvars.example
│   ├── vpc.tf
│   ├── subnets.tf
│   ├── route_tables.tf
│   ├── internet_gateway.tf
│   ├── security_groups.tf
│   ├── iam.tf
│   ├── launch_template.tf
│   ├── autoscaling.tf
│   ├── alb.tf
│   ├── target_groups.tf
│   ├── cloudwatch.tf
│   └── outputs.tf
├── scripts/
│   ├── install_app.sh
│   ├── deploy.sh
│   └── health_check.sh
├── tests/
│   └── test_app.py
├── architecture/
│   └── architecture.md
├── buildspec.yml
├── .gitignore
└── README.md
```

## Prerequisites

- An AWS account with billing enabled
- AWS CLI v2 installed and configured (`aws configure`)
- Terraform >= 1.5.0 installed
- Git installed
- Python 3.12 (for local testing)
- Docker (optional, for container testing)

## AWS Setup

1. Create/confirm an IAM user or role with permissions to manage VPC, EC2,
   ELBv2, Auto Scaling, IAM, and CloudWatch (see [IAM Requirements](#iam-requirements)).
2. Configure the AWS CLI:
   ```bash
   aws configure
   # AWS Access Key ID, Secret Access Key, region (us-east-1), output format (json)
   ```
3. Verify access:
   ```bash
   aws sts get-caller-identity
   ```

## IAM Requirements

To **deploy this project**, the deploying user/role needs permissions
covering: `ec2:*` (VPC/subnets/SGs/launch templates), `elasticloadbalancing:*`,
`autoscaling:*`, `iam:CreateRole`, `iam:PutRolePolicy`,
`iam:CreateInstanceProfile`, `iam:PassRole`, `cloudwatch:*`, `logs:*`.
For a classroom AWS account, the managed policy `PowerUserAccess` is
sufficient; for stricter environments, scope a custom policy to these
services.

The **EC2 instances themselves** run under a dedicated least-privilege IAM
role (`aws_iam_role.ec2_role` in `terraform/iam.tf`) that only allows
publishing CloudWatch metrics/logs and using SSM — no S3, no database, no
broad `*` permissions.

## Terraform Deployment

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set app_repo_url to your GitHub repo, review region/instance_type

terraform init
terraform plan
terraform apply
```

Terraform will print `app_url` when finished — open that URL in a browser.

To tear everything down later, see [Cleanup Instructions](#cleanup-instructions).

## Application Deployment

The Launch Template's `user_data` (rendered from `scripts/install_app.sh`)
automatically installs Python, clones the app repo, and starts it as a
systemd service on every new instance — no manual steps needed after
`terraform apply`.

To deploy a **new version** later without destroying infrastructure:

```bash
# 1. Bump APP_VERSION, commit, push, let CodeBuild validate it
# 2. Update var.app_version in terraform.tfvars if desired
terraform apply           # creates a new Launch Template version
./scripts/deploy.sh ha-deploy-asg   # triggers rolling instance refresh
```

## CI/CD Explanation

```
GitHub -> AWS CodeBuild -> install -> test -> build/package -> ready to deploy
```

`buildspec.yml` defines four phases:

1. **install** — installs Python 3.12 and dependencies from `app/requirements.txt`.
2. **pre_build** — runs `pytest tests/test_app.py` (unit tests must pass).
3. **build** — validates the app imports cleanly, runs `terraform validate`,
   and packages the app into `dist/ha-deploy-app.tar.gz`.
4. **post_build** — confirms the artifact and reminds how to trigger deployment.

For a classroom demo, a single CodeBuild project triggered on push is
enough. In a production setup you would wire this into **AWS CodePipeline**
so that a successful build automatically triggers `scripts/deploy.sh`
(instance refresh) as a deploy stage — this project keeps that step manual
to stay simple to explain in a 5-10 minute demo.

## Git Workflow

```
main
 ├── feature/application
 ├── feature/infrastructure
 └── feature/monitoring
```

```bash
git checkout -b feature/application
git add .
git commit -m "Add Flask app with health check"
git push origin feature/application
# Open a Pull Request -> Code Review -> Merge to main -> CI/CD triggered
```

## AWS CLI Commands

| Command | Purpose |
|---|---|
| `aws sts get-caller-identity` | Confirms which AWS account/identity the CLI is using |
| `aws ec2 describe-instances` | Lists EC2 instances and their state/IPs/AZ |
| `aws ec2 describe-security-groups` | Shows security group rules (verify least-privilege setup) |
| `aws autoscaling describe-auto-scaling-groups` | Shows ASG size, health, and instances |
| `aws elbv2 describe-load-balancers` | Shows the ALB's DNS name and state |
| `aws elbv2 describe-target-health` | Shows which targets are healthy/unhealthy behind the ALB |
| `aws cloudwatch describe-alarms` | Lists CloudWatch alarms and their current state |

## High Availability Explanation

Multiple Availability Zones + multiple EC2 instances + ALB + Auto Scaling +
health checks together remove any single point of failure:

```
EC2-A fails
   |
   v
ALB health check fails for EC2-A
   |
   v
ALB stops sending traffic to EC2-A
   |
   v
EC2-B (different AZ) continues serving users
   |
   v
Auto Scaling launches a replacement instance
```

Because the ALB spans two AZs and only routes to instances passing
`/health`, an entire AZ outage still leaves the application reachable via
the other AZ.

## Resilience Explanation

1. **Instance crash** — the process (or instance) stops responding.
2. **Detection** — the ALB's Target Group polls `/health` every 15 seconds;
   after 3 consecutive failures the target is marked unhealthy and removed
   from rotation.
3. **Replacement** — the ASG's `health_check_type = "ELB"` means it trusts
   the Target Group's verdict; it terminates the unhealthy instance and
   launches a new one from the Launch Template to restore desired capacity.
4. **Why this is self-healing** — no human intervention is required between
   failure and recovery; the system detects and corrects itself.

**Manual demo procedure:**

```bash
# 1. Open the app through the ALB
curl http://<alb_dns_name>/

# 2. Identify an instance
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ha-deploy-asg

# 3. Terminate it
aws ec2 terminate-instances --instance-ids <instance-id>

# 4. Refresh the app in a browser / curl again
curl http://<alb_dns_name>/

# 5. Confirm it's still served (by the other instance)
# 6. Watch Auto Scaling launch a replacement
aws autoscaling describe-scaling-activities --auto-scaling-group-name ha-deploy-asg
```

## Scalability Explanation

```
High traffic -> CPU increases -> CloudWatch alarm -> Auto Scaling -> new EC2 instances -> ALB distributes traffic
Low traffic  -> CPU decreases -> CloudWatch alarm -> Auto Scaling scales instances back in
```

Configured thresholds (in `terraform/variables.tf`):
- Scale **OUT** when average CPU > `scale_out_cpu_threshold` (default 70%)
- Scale **IN** when average CPU < `scale_in_cpu_threshold` (default 30%)

**Vertical scaling** means making one server bigger (more CPU/RAM) — it has
a hard ceiling and requires downtime to resize. **Horizontal scaling** means
adding more servers of the same size — it has no practical ceiling and adds
redundancy as a side effect. This project uses horizontal scaling because it
directly improves both capacity *and* availability at the same time.

## Near-Zero-Downtime Deployment

This project targets **near-zero-downtime deployment** — not absolute zero
downtime, since DNS caching, in-flight requests, and connection draining
always carry some small risk window.

```
Version 1:  EC2-A(v1)  EC2-B(v1)

Deploy v2:  EC2-A(v1)  EC2-B(v1)  EC2-C(v2)   <- new capacity added first
                              |
                     wait for /health on EC2-C
                              |
                          EC2-C healthy
                              |
              gradually terminate EC2-A, EC2-B (old version)
```

The ASG's `instance_refresh` (Rolling strategy, 50% minimum healthy) drives
exactly this: it never drops below half of desired capacity, and the ALB
only ever sends traffic to instances that are already passing `/health`.

## Immutable Infrastructure

```
New app version
      |
      v
New Launch Template version (new AMI reference / new user_data)
      |
      v
New EC2 capacity launched from it
      |
      v
Health check passes
      |
      v
Old version's instances are terminated
```

Nobody SSHes into a running instance to `git pull` or patch code in place.
Every change produces a fresh instance from a known-good template. This
eliminates **configuration drift** — the situation where servers slowly
diverge from each other and from what's in version control because of ad
hoc manual changes, making failures hard to reproduce and audit.

## Monitoring

CloudWatch is used for:

- **EC2 CPU utilization** — drives the scale-out/scale-in alarms
- **Auto Scaling group metrics** — `GroupInServiceInstances`, alarmed if it
  drops below the configured minimum
- **ALB target health** — `UnHealthyHostCount` alarm for early warning
- **Application logs** — shipped to the `/ha-deploy/<env>/app` log group

To view metrics in the console: **CloudWatch → Alarms** for alarm state, and
**CloudWatch → Metrics → EC2 / ApplicationELB / AutoScaling** for raw graphs.

## Security

- No hardcoded AWS credentials anywhere in the codebase; the CLI/Terraform
  use your locally configured credentials, and EC2 instances use an IAM
  **instance role**, never embedded keys.
- **IMDSv2 is enforced** (`http_tokens = "required"`) on all instances.
- EC2 instances live in **private subnets** with no public IP.
- The EC2 security group only accepts app traffic from the **ALB's security
  group** — never directly from the internet.
- SSH is **disabled by default** and only opens (to a specific CIDR you set)
  if `enable_ssh = true`.
- `terraform.tfvars` (which could contain a real key name/CIDR) is
  gitignored; only `terraform.tfvars.example` (no secrets) is committed.

## AWS Well-Architected Framework

**1. Operational Excellence** — Git-based change history, Terraform for
repeatable infrastructure, CodeBuild automation, and CloudWatch alarms give
visibility and repeatability instead of manual, undocumented changes.

**2. Security** — least-privilege IAM role for EC2, security groups that
only allow the minimum required traffic, no public EC2 access, no hardcoded
credentials.

**3. Reliability** — Multi-AZ deployment, ALB health checks, Auto Scaling
replacing failed instances automatically (self-healing).

**4. Performance Efficiency** — ALB distributes load evenly, horizontal
scaling matches capacity to demand, `t3.micro` is right-sized for a demo
workload, CloudWatch monitors actual utilization.

**5. Cost Optimization** — Auto Scaling scales *in* during low traffic
instead of running peak capacity 24/7; a single NAT Gateway (not one per AZ)
and `t3.micro` instances keep the demo inexpensive.

**6. Sustainability** — scaling in during idle periods avoids running (and
powering) compute capacity nobody is using, improving overall resource
utilization efficiency.

## Microservices Evolution

See [`architecture/architecture.md`](architecture/architecture.md) for the
full diagram. In short: this project is currently a **modular monolithic
Flask application**. It could evolve so the ALB routes to independent
User / Order / Payment services, each with its own Target Group and Auto
Scaling Group — enabling independent deployment, independent scaling,
service isolation, and API-based communication between services.

## Failure Demonstration

See the step-by-step procedure under
[Resilience Explanation](#resilience-explanation) above — it doubles as the
live demo script: terminate an instance, show the app stays up, show the
ASG replace it.

## Testing

```bash
cd app
pip install -r requirements.txt
cd ..
pytest tests/test_app.py -v
```

All tests run without any AWS credentials or EC2 access — metadata lookups
fail fast and fall back to placeholder values, so tests work identically
locally, in CI, and in CodeBuild.

## Cleanup Instructions

```bash
cd terraform
terraform destroy
```

Confirm with `yes` when prompted. This removes the ALB, ASG (and its
instances), NAT Gateway, subnets, and VPC — avoiding ongoing charges.
Double-check in the AWS Console that the ALB, NAT Gateway, and EC2
instances are gone, since NAT Gateways in particular incur hourly charges
even when idle.

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `terraform apply` fails on AZ count | Region has < 2 AZs available | Use a region/account with at least 2 AZs (us-east-1 has 6) |
| ALB shows all targets unhealthy | App not started / wrong port / SG rule missing | Check `/var/log/cloud-init-output.log` on an instance via SSM; confirm SG allows port 5000 from ALB SG |
| `git clone` fails during bootstrap | `app_repo_url` still a placeholder | Set `app_repo_url` in `terraform.tfvars` to your real GitHub repo |
| Can't SSH into instance | SSH disabled by default | Set `enable_ssh = true` and `key_name`/`ssh_allowed_cidr` in tfvars, or use SSM Session Manager instead (no SSH needed) |
| CodeBuild `terraform validate` fails | Provider not initialized in this ephemeral environment | Ensure `terraform init -backend=false` runs before `validate` (already in buildspec.yml) |
| High AWS bill after demo | Forgot to destroy | Run `terraform destroy`; verify no ALB/NAT/instances remain in the console |

## Viva Questions and Answers

1. **What is DevOps?** A culture/practice combining development and
   operations to deliver software faster and more reliably through
   automation, collaboration, and continuous feedback.
2. **What is CI/CD?** Continuous Integration automatically builds/tests
   every code change; Continuous Delivery/Deployment automates getting
   that change into an environment safely.
3. **Why Terraform?** It's declarative Infrastructure as Code — the same
   config reliably reproduces identical infrastructure, and changes are
   version-controlled and reviewable like application code.
4. **What is Infrastructure as Code?** Defining infrastructure (networks,
   servers, load balancers) in code/config files instead of manual console
   clicks, so it's repeatable, versioned, and auditable.
5. **What is immutable infrastructure?** Servers are never modified in
   place after creation; changes are deployed by replacing instances with
   new ones built from an updated template.
6. **What is high availability?** The ability of a system to keep serving
   users despite individual component failures, typically via redundancy.
7. **How does your project achieve HA?** Two Availability Zones, multiple
   EC2 instances, an ALB distributing traffic, and health-check-driven
   failover.
8. **What is resilience?** A system's ability to detect and recover from
   failure automatically, without manual intervention.
9. **How does your project self-heal?** ALB health checks detect an
   unhealthy instance; the ASG (configured with `ELB` health checks)
   terminates it and launches a replacement automatically.
10. **How does Auto Scaling work?** It watches CloudWatch metrics (like
    CPU) against alarm thresholds and adds/removes instances to match a
    target capacity, within a min/max range.
11. **What is horizontal scaling?** Adding more instances of the same size
    to share load, instead of making one instance bigger (vertical
    scaling).
12. **Why use ALB?** It distributes incoming traffic across multiple
    healthy targets across AZs and provides built-in health checking.
13. **How does health checking work?** The Target Group periodically sends
    a request to `/health`; consecutive failures mark a target unhealthy
    and remove it from rotation.
14. **How do you achieve near-zero downtime?** Rolling instance refresh
    keeps a minimum healthy percentage in service throughout the
    deployment, replacing old instances only after new ones pass health
    checks.
15. **What happens if an EC2 instance fails?** The ALB stops routing to it
    once health checks fail, other instances continue serving, and the ASG
    replaces the failed instance.
16. **What are the six AWS Well-Architected pillars?** Operational
    Excellence, Security, Reliability, Performance Efficiency, Cost
    Optimization, Sustainability.
17. **Why use multiple Availability Zones?** AZs are physically isolated
    data centers; spreading instances across them means a single AZ outage
    doesn't take down the whole application.
18. **What is the Git workflow?** Feature branches off `main`
    (`feature/application`, `feature/infrastructure`, `feature/monitoring`),
    merged via reviewed Pull Requests, which trigger CI/CD.
19. **What is the role of AWS CLI?** It lets you inspect and interact with
    live AWS resources (instances, ASGs, load balancers, alarms) directly
    from the terminal, useful for verification and troubleshooting.
20. **How would you convert this architecture into microservices?** Split
    the Flask monolith by domain (users, orders, payments), give each its
    own Target Group + ASG behind the same ALB (path-based routing), and
    let them communicate over HTTP/REST or a queue instead of sharing
    process memory.

## Presentation Flow

A 5-10 minute presentation script, one slide per section:

**Slide 1 — Title**
- HA-Deploy: Highly Available Web Architecture with Automated CI/CD on AWS
- Presented by: [Your Name]
- Course/Module: DevOps

**Slide 2 — Problem Statement**
- Single-server deployments are a single point of failure
- Manual server changes cause configuration drift
- No automated recovery from failure or traffic spikes

**Slide 3 — Objectives**
- Build a highly available, self-healing architecture
- Automate infrastructure with Terraform
- Automate build/test with CI
- Demonstrate near-zero-downtime deployment

**Slide 4 — Architecture**
- Walk through the diagram: ALB -> 2 AZs -> EC2 -> ASG -> CloudWatch
- Point out public vs. private subnets
- Mention the CI/CD path alongside it

**Slide 5 — Technology Stack**
- Flask + Gunicorn for the app
- Terraform for infrastructure
- CodeBuild for CI
- CloudWatch for monitoring

**Slide 6 — CI/CD Pipeline**
- GitHub push triggers CodeBuild
- install -> test -> build -> package
- Deployment via scripted ASG instance refresh

**Slide 7 — High Availability + Resilience**
- Two AZs, ALB health checks, automatic instance replacement
- Live or recorded demo: terminate an instance, app stays up

**Slide 8 — Scalability + Immutable Infrastructure**
- CPU-based scale out/in policies
- New versions = new instances, never in-place edits

**Slide 9 — AWS Well-Architected Framework**
- One line per pillar tying it back to a concrete project decision

**Slide 10 — Demo + Results**
- Open the ALB URL, refresh to show different instance IDs
- Show CloudWatch alarms and ASG activity history

**Slide 11 — Future Scope**
- Split into microservices (users/orders/payments)
- Add HTTPS via ACM, add a CI/CD pipeline via CodePipeline
- Add centralized logging/tracing

**Slide 12 — Conclusion**
- Recap: HA, self-healing, scalable, automated, secure by design
- Thank you / questions
