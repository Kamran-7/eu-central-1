# Capapay (bstable) Infrastructure 

Reusable Terraform for Capapay’s backend infrastructure across **dev** and **prod**. Environments are **fully isolated** (separate VPCs and separate Terraform state). Terraform provisions infrastructure; **your CI/CD pipeline deploys the applications to ECS**.

**Client:** Capapay  
**Resource Naming:** `bstable`  
**Region:** `us-east-1`

---

## Table of Contents
- [What This Provisions](#what-this-provisions-per-environment)
- [Architecture CIDRs](#architecture-cidrs-defaults)
- [Repository Layout](#repository-layout)
- [Prerequisites](#prerequisites)
- [One-Time Backend Bootstrap](#one-time-backend-bootstrap-remote-state)
- [Environment Configuration](#environment-configuration)
  - [envs/dev/dev.tfvars](#envsdevdevtfvars-non-secret)
  - [envs/dev/devsecrets.tfvars](#envsdevdevsecretstfvars-secret-gitignored)
  - [Production Example](#production-example)
- [Using This Repository](#using-this-repository-applydestroy)
- [Deployments via Pipeline](#deployments-handled-by-the-pipeline-not-terraform)
- [Outputs & Access](#outputs--access)
- [Why Backend Switching Matters](#why-backend-switching-matters--reconfigure)
- [Verifying Connectivity](#verifying-connectivity-optional)
- [Resource Naming Convention](#resource-naming-convention)
- [Best Practices Followed](#best-practices-followed)
- [Troubleshooting](#troubleshooting-quick)
- [Quick Start](#quick-start)

---

## What This Provisions (per environment)

- **Networking (VPC)**
  - VPC with DNS enabled
  - Public subnets (for ALB)
  - Private **app** subnets (for ECS Fargate)
  - Private **DB** subnets (for RDS)
  - NAT Gateway for private egress 

- **Load Balancing**
  - Internet-facing **Application Load Balancer (ALB)**
  - Listener `:80` (HTTPS `:443` via ACM)
  - Target Group with **target_type = "ip"** (required for Fargate)

- **ECR (Elastic Container Registry)**
  - Repositories for: **backend**, **beat**, **worker**
  - Lifecycle policies (keep last N images; purge old untagged)

- **ECS (Fargate)**
  - ECS Cluster with Container Insights
  - Services: `backend`, `beat` (Celery Beat), `worker` (Celery Worker), `rabbitmq` 
  - IAM **Execution Role** (pull images, send logs) and **Task Role** (app permissions)
  - CloudWatch Logs with retention

- **RDS (PostgreSQL)**
  - DB in **private DB subnets** (not publicly accessible)
  - Security Group allows **only ECS tasks** to connect on DB port

- **CloudWatch Alarms** 

   **Application Load Balancer:**
   - **5XX, 4XX Error Rate** - Alerts on server errors exceeding threshold
   - **Target Health** - Monitors unhealthy target count
   - Configurable thresholds per environment

  **ECS Services (Backend, Worker, Beat):**
   - **CPU Utilization** - High CPU usage alerts
   - **Memory Utilization** - Memory pressure monitoring
   - Per-service alarms for all Fargate tasks

  **RDS Database:**
  - **CPU Utilization** - Database CPU monitoring
  - **Free Storage Space and Memory** - Low disk space alerts
  - **Database Connections** - High connection count warnings
  - **Read/Write Latency** - Performance degradation detection

  **Alert Delivery:**
  - SNS topics created per environment
  - Email subscriptions (configurable in tfvars)
  - Integration-ready for PagerDuty, Slack, etc.

   #### Logging Infrastructure
     **CloudWatch Log Groups** - Per-service log streams
  - `/ecs/bstable-{env}-backend`
  - `/ecs/bstable-{env}-worker`
  - `/ecs/bstable-{env}-beat`
  - `/ecs/bstable-{env}-rabbitmq` (if enabled)

   -  **RDS Enhanced Monitoring** - Dedicated log group
   -  **RDS Engine Logs** - PostgreSQL logs exported to CloudWatch
   -  **Configurable Retention** - 7 days (dev) to 14+ days (prod)

---

## Architecture CIDRs (defaults)

### Dev VPC — `10.0.0.0/16`
- Public: `10.0.0.0/24`, `10.0.1.0/24`
- Private App: `10.0.2.0/24`, `10.0.3.0/24`, `10.0.4.0/24`
- Private DB: `10.0.5.0/24`, `10.0.6.0/24`

### Prod VPC — `192.168.0.0/16`
- Public: `192.168.0.0/24`, `192.168.1.0/24`
- Private App: `192.168.2.0/24`, `192.168.3.0/24`, `192.168.4.0/24`
- Private DB: `192.168.5.0/24`, `192.168.6.0/24`

> Dev and Prod **do not** route to each other and maintain **separate state**.

---

## Repository Layout

```
bstable-infra/
├── envs/
│   ├── dev/
│   │   ├── backend-dev.hcl            # remote state backend (S3 + DynamoDB)
│   │   ├── dev.tfvars             # NON-secret settings for dev
│   │   └── dev.secrets.tfvars     # SECRET settings for dev (gitignored)
│   └── prod/
│       ├── backend-prod.hcl
│       ├── prod.tfvars
│       └── prod.secrets.tfvars    # SECRET settings for prod (gitignored)
│
├── modules/
│   ├── vpc/         # VPC, subnets, routes (incl. DB subnets)
│   ├── alb/         # ALB, TG, listeners, SG
│   ├── ecr/         # ECR repos + lifecycle
│   ├── ecs/         # Cluster, SG, IAM, services, logs
│   ├── rds-server/  # RDS instance, param group, subnet group
│   └── alarms/      # Cloudwatch Alarms for ECS, ALB, RDS resource
├── state-bootstrap  #For S3 backend creation 
├── main.tf          # wires modules together
├── variables.tf     # root inputs
├── outputs.tf       # root outputs
├── providers.tf     # AWS provider + default tags
├── versions.tf      # TF/provider versions
├── locals.tf        # name prefixes + common tags
├── .gitignore
└── README.md
```

**.gitignore (relevant)**
```
*.secrets.tfvars
terraform.tfvars
*.auto.tfvars
.terraform/
.terraform.lock.hcl
*.tfvars.backup
*.tfstate.*
```

---

## Prerequisites

- Terraform `>= 1.5`
- AWS CLI configured for the target AWS account/role
- S3 State bucket

---

## One-Time Backend Bootstrap (Remote State)

Run **once** to host Terraform state in S3 with S3 state lock .

```bash
cd state-bootstrap
terraform init
terraform plan
terraform apply
cd ..
```

Creates:
- S3 bucket (versioned, encrypted) for state
- S3 state lock

---

## Environment Configuration

### `envs/dev/dev.tfvars` (non-secret)
```hcl
# Core
project     = "bstable"
environment = "dev"
aws_region  = "us-east-1"

# Networking
vpc_cidr             = "10.0.0.0/16"
public_subnet_count  = 2
private_subnet_count = 3
db_subnet_cidrs      = ["10.0.5.0/24", "10.0.6.0/24"]

# ECR
repositories               = ["backend", "beat", "worker"]
image_retention_count      = 5
expire_untagged_after_days = 7
kms_key_arn                = null  # dev: AES256 default ok

# ECS
enable_autoscaling    = false
backend_desired_count = 1
worker_desired_count  = 1
log_retention_days    = 3

# Application image tag provided by CI/CD (ECR images)
image_tag = "0.0.100"
```

### `envs/dev/dev.secrets.tfvars` (secret, **gitignored**)
```hcl
db_password = "dev_Str0ng_Pass!"
```

### Production Example

`envs/prod/prod.tfvars`
```hcl
# Core
project     = "bstable"
environment = "prod"
aws_region  = "us-east-1"

# Networking
vpc_cidr             = "192.168.0.0/16"
public_subnet_count  = 2
private_subnet_count = 3

# RDS (prod VPC must have its own DB subnets in 2 AZs)
db_engine         = "postgres"
db_engine_version = "16.6"
db_subnet_cidrs   = ["192.168.5.0/24", "192.168.6.0/24"]
POSTGRES_DB       = "appdb"
POSTGRES_USER     = "prod_user"


# RDS → CloudWatch (engine logs) + Enhanced Monitoring + PI
enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
rds_log_retention_days          = 14
rds_monitoring_interval         = 15
rds_enhanced_retention_days     = 14
performance_insights_enabled    = true
#performance_insights_kms_key_id = null  # (optional) set your CMK ARN if required

# ECR
repositories               = ["backend", "beat", "worker"]
image_retention_count      = 10 # prod: keep a bit more
expire_untagged_after_days = 7
kms_key_arn                = null # (recommended: use a CMK in prod when ready)

# ECS
enable_autoscaling    = true
backend_desired_count = 2
worker_desired_count  = 1
log_retention_days    = 14

# RabbitMQ service (public image in public subnets)
create_rabbitmq    = true
rabbitmq_image     = "public.ecr.aws/docker/library/rabbitmq:4.0-management"
rabbitmq_user      = "bstable-queue"
rabbitmq_mgmt_cidr = [] # keep UI closed by default; set ["X.X.X.X/32"] temporarily if needed

enable_alarms           = true
alert_emails            = ["xyz@abc.com"]
alb_5xx_rate_threshold  = 1
ecs_cpu_high_threshold  = 75
ecs_mem_high_threshold  = 80
rds_conn_high_threshold = 500

alb_4xx_rate_threshold           = 1
rds_free_storage_threshold_gb    = 10
rds_freeable_memory_threshold_mb = 512

enable_service_discovery = true

```

`envs/prod/prod.secrets.tfvars`  
```hcl
db_password = "abc@123"
```

---

## Using This Repository (Apply/Destroy)

> **Always** point Terraform to the correct **backend** before plan/apply/destroy. This ensures you operate on the intended environment’s state.

### Dev
```bash
terraform init -reconfigure -backend-config=envs/dev/backend-dev.hcl
terraform fmt -recursive
terraform validate
terraform plan  -var-file=envs/dev/dev.tfvars  -var-file=envs/dev/dev.secrets.tfvars
terraform apply -var-file=envs/dev/dev.tfvars  -var-file=envs/dev/dev.secrets.tfvars
```

### Prod
```bash
terraform init -reconfigure -backend-config=envs/prod/backend-prod.hcl
terraform plan  -var-file=envs/prod/prod.tfvars  -var-file=envs/prod/prod.secrets.tfvars
terraform apply -var-file=envs/prod/prod.tfvars  -var-file=envs/prod/prod.secrets.tfvars
```

### Destroy (per environment)
```bash
# Dev
terraform init -reconfigure -backend-config=envs/dev/backend-dev.hcl
terraform destroy -var-file=envs/dev/dev.tfvars -var-file=envs/dev/dev.secrets.tfvars

# Prod
terraform init -reconfigure -backend-config=envs/prod/backend-prod.hcl
terraform destroy -var-file=envs/prod/prod.tfvars -var-file=envs/prod/prod.secrets.tfvars
```

---

## Deployments: Handled by the Pipeline (Not Terraform)

After the infrastructure is created, **ECS deployments are fully handled by your CI/CD pipeline**. You do **not** use Terraform for app version rollouts.

**Pipeline responsibilities (each release):**
1. **Build** Docker images for `backend`, `beat`, `worker`, rabbitmq.
2. **Tag** images (e.g., `0.0.101`).
3. **Push** to the correct ECR repos (e.g., `dev-bstable-backend:0.0.101`).
4. **Register** a new ECS task definition revision using that tag.
5. **Update** the ECS service (or force a new deployment).
6. **Wait** for healthy state (ALB checks).

> In Terraform, `image_tag` can serve as a **bootstrap/default**. Day-to-day deployments should be driven by CI/CD changing task definitions and updating services—**no Terraform run required**.

---

## Outputs & Access

After apply:
```bash
terraform output
terraform output alb_dns_name
```

- Use **ALB DNS** to reach the backend (expects the app to listen on `:80`).
- Additional outputs include ECS cluster/service ARNs, VPC/subnet IDs, ECR repo URLs, etc.

---

## Why Backend Switching Matters (`-reconfigure`)

Terraform stores the “truth” in a **state file**. Dev and Prod each have their own state in S3.  
Running:
```
terraform init -reconfigure -backend-config=envs/dev/backend.hcl
```
pins Terraform to **dev’s** state. Without switching:

- You may accidentally update the **wrong environment**.
- You can generate **confusing diffs**.
- You risk **state corruption**.

**Rule:** Before any plan/apply/destroy, run `init -reconfigure` with the desired `backend.hcl`.

---

## Verifying Connectivity (Optional)

### ECS → RDS (from inside a running task)
```bash
TASK=$(aws ecs list-tasks --cluster bstable-dev-cluster --service-name bstable-dev-backend --query 'taskArns[0]' --output text)

aws ecs execute-command   --cluster bstable-dev-cluster   --task "$TASK"   --container backend   --interactive   --command "sh"

# inside the container:
nc -zv $DB_HOST $DB_PORT  # e.g., 5432
```
---

## Resource Naming Convention
All resources follow:
```
{project}-{environment}-{resource}
```
Examples:
- `bstable-dev-vpc`, `bstable-dev-alb`
- `dev-bstable-backend` (ECR repo)
- `bstable-dev-backend` (ECS service / TaskDef family)
- `bstable-dev-rds-sg` (Security Group)

This keeps ownership clear and avoids collisions.

---

## Best Practices Followed

- **Environment isolation:** separate VPCs and **separate remote state** (S3 + DynamoDB locking).
- **Least privilege IAM:** distinct **task role** and **execution role**.
- **Security Groups:** **SG→SG** rules for ECS→RDS; no broad internal CIDRs.
- **CloudWatch Logs:** per-service log groups with retention.
- **ECR lifecycle:** keep recent images; purge untagged junk.
- **Deterministic releases:** ECS pulls ECR images by tag (pipeline-managed).
- **Consistent naming & tagging:** enforced via locals and provider default tags.
- **No secrets in git:** secrets live in `*.secrets.tfvars` (gitignored).

---

## Troubleshooting 

- **ECS `CannotPullContainerError … : not found`**  
  The tag doesn’t exist in ECR (or repo mismatch). Confirm the image was pushed to the right repo with the right tag; redeploy via pipeline.


- **RDS version error**  
  If a pinned minor version is not creatable, remove `engine_version` (let AWS choose) or use a currently available minor (e.g., `16.x`).


- **Wrong environment changing**  
  Re-init with the correct backend:
  ```
  terraform init -reconfigure -backend-config=envs/<env>/backend.hcl
  ```
---

> **Note**: Routine deployments go through the **pipeline** (build → push ECR → update ECS). Terraform is only for **infrastructure changes**.
