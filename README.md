# Enterprise GCP Infrastructure — Terraform

Production-grade, multi-application infrastructure on Google Cloud Platform built entirely with Terraform. Demonstrates real-world IaC patterns used at scale.

## Architecture
```
Internet
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  Global HTTPS Load Balancer (35.186.212.137)        │
└─────────────────┬───────────────────────────────────┘
                  │
    ┌─────────────▼──────────────┐
    │   dev-vpc (10.0.0.0/16)   │
    │                            │
    │  ┌─────────────────────┐  │
    │  │  Public Subnet      │  │
    │  │  10.0.1.0/24        │  │
    │  │                     │  │
    │  │  ┌───────────────┐  │  │
    │  │  │ MIG (nginx)   │  │  │
    │  │  │ 1-2 instances │  │  │
    │  │  │ e2-micro      │  │  │
    │  │  └───────────────┘  │  │
    │  └─────────────────────┘  │
    │                            │
    │  ┌─────────────────────┐  │
    │  │  Private Subnet     │  │
    │  │  10.0.2.0/24        │  │
    │  │                     │  │
    │  │  ┌───────────────┐  │  │
    │  │  │ Cloud SQL     │  │  │
    │  │  │ PostgreSQL 15 │  │  │
    │  │  │ 10.51.0.3     │  │  │
    │  │  └───────────────┘  │  │
    │  └─────────────────────┘  │
    └────────────────────────────┘

Data Pipeline:
GCS Landing → Pub/Sub → Cloud Function → BigQuery → GCS Curated

API Microservice:
Cloud Run (dev-api-service) — serverless, auto-scaling
```

## What's Built

| Module | Resources | Description |
|--------|-----------|-------------|
| networking | 9 | VPC, subnets, NAT, router, firewall rules |
| iam | 13 | Service accounts, least-privilege IAM bindings |
| compute | 9 | MIG, autoscaler, health check, HTTPS load balancer |
| database | 7 | Cloud SQL PostgreSQL, Secret Manager password |
| data-pipeline | 14 | GCS, Pub/Sub, BigQuery, Cloud Function ETL |
| serverless | 6 | Cloud Run, Artifact Registry, Secret Manager |
| monitoring | 4 | Alert policies, notification channel, dashboard |
| **Total** | **64** | **All managed by Terraform** |

## Quick Start

### Prerequisites
- GCP project with billing enabled
- Terraform >= 1.5.0
- gcloud CLI authenticated

### APIs Required
```bash
gcloud services enable compute.googleapis.com sqladmin.googleapis.com \
  run.googleapis.com cloudfunctions.googleapis.com cloudbuild.googleapis.com \
  artifactregistry.googleapis.com bigquery.googleapis.com pubsub.googleapis.com \
  secretmanager.googleapis.com monitoring.googleapis.com logging.googleapis.com \
  cloudresourcemanager.googleapis.com iam.googleapis.com \
  servicenetworking.googleapis.com storage.googleapis.com eventarc.googleapis.com
```

### Deploy
```bash
# 1. Create state bucket
gsutil mb gs://YOUR-PROJECT-terraform-state

# 2. Update backend.tf with your bucket name
# 3. Update terraform.tfvars with your project ID and email

cd environments/dev
terraform init
terraform plan
terraform apply
```

### Verify
```bash
bash scripts/verify.sh
```

### Destroy
```bash
bash scripts/destroy.sh
```

## Key Terraform Patterns Demonstrated

**Remote State** — GCS backend with state locking prevents concurrent modifications

**Module Composition** — 6 reusable modules wired together via output chaining:
```hcl
vpc_name = module.networking.vpc_name
service_account_email = module.iam.web_app_sa_email
```

**Implicit Dependencies** — Terraform builds a dependency graph from resource references, parallelizing creation where possible

**Least Privilege IAM** — Each service account has only the roles its workload requires

**Idempotency** — `terraform apply` can run 100 times; it only changes what differs from desired state

**Content-addressable deploys** — Function zip named by MD5 hash; code changes automatically trigger redeployment

**create_before_destroy** — Instance templates replaced with zero downtime

**Input Validation** — Variable validation blocks catch invalid environment names before any API calls

## Environment Differentiation

| Setting | dev | staging | prod |
|---------|-----|---------|------|
| Machine type | e2-micro | e2-small | e2-standard-2 |
| Min replicas | 1 | 1 | 2 |
| Max replicas | 2 | 4 | 10 |
| DB tier | db-f1-micro | db-g1-small | db-n1-standard-2 |
| Deletion protection | false | false | true |
| HA | zonal | zonal | regional |

## Cost

Full dev deployment costs approximately $2-5/hour. Destroy immediately after use with `bash scripts/destroy.sh`.
