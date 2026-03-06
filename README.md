# Enterprise GCP Infrastructure — Terraform

> Production-grade, multi-application infrastructure on Google Cloud Platform built entirely with Terraform. 64 resources across 7 modules, verified with an automated test script, deployable from scratch in under 20 minutes.

[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-7b42bc?logo=terraform)](https://terraform.io)
[![GCP](https://img.shields.io/badge/Google%20Cloud-Platform-4285F4?logo=google-cloud)](https://cloud.google.com)
[![Verified](https://img.shields.io/badge/Verified-29%2F29%20checks-success)](scripts/verify.sh)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## Architecture Diagram

```svg
<svg width="1100" height="820" viewBox="0 0 1100 820" xmlns="http://www.w3.org/2000/svg" font-family="'Segoe UI',Arial,sans-serif">
  <rect width="1100" height="820" fill="#0f1117"/>
  <text x="550" y="34" text-anchor="middle" fill="#ffffff" font-size="18" font-weight="700">Enterprise GCP Infrastructure — Terraform</text>
  <text x="550" y="54" text-anchor="middle" fill="#6b7280" font-size="11">64 Resources · 7 Modules · 3 Applications · 1 terraform apply</text>
  <rect x="390" y="68" width="320" height="40" rx="8" fill="#1e293b" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="550" y="84" text-anchor="middle" fill="#93c5fd" font-size="11" font-weight="600">🌐 INTERNET</text>
  <text x="550" y="100" text-anchor="middle" fill="#64748b" font-size="10">Users / External Traffic</text>
  <line x1="550" y1="108" x2="550" y2="128" stroke="#3b82f6" stroke-width="2" stroke-dasharray="4,3"/>
  <polygon points="550,130 545,121 555,121" fill="#3b82f6"/>
  <rect x="280" y="130" width="540" height="48" rx="8" fill="#1e3a5f" stroke="#3b82f6" stroke-width="2"/>
  <text x="550" y="150" text-anchor="middle" fill="#60a5fa" font-size="12" font-weight="700">⚖ Global HTTP Load Balancer</text>
  <text x="550" y="168" text-anchor="middle" fill="#93c5fd" font-size="10">35.186.212.137 · dev-http-forwarding-rule · dev-web-backend · dev-web-url-map</text>
  <line x1="550" y1="178" x2="550" y2="198" stroke="#3b82f6" stroke-width="2"/>
  <polygon points="550,200 545,191 555,191" fill="#3b82f6"/>
  <rect x="20" y="200" width="1060" height="490" rx="10" fill="#111827" stroke="#374151" stroke-width="1.5" stroke-dasharray="6,4"/>
  <text x="40" y="220" fill="#4b5563" font-size="10" font-weight="600">🔒 dev-vpc · us-central1 · Custom VPC · auto_create_subnetworks=false</text>
  <rect x="40" y="228" width="460" height="240" rx="8" fill="#0f2340" stroke="#1d4ed8" stroke-width="1.5"/>
  <text x="60" y="246" fill="#3b82f6" font-size="10" font-weight="700">PUBLIC SUBNET · 10.0.1.0/24</text>
  <rect x="55" y="254" width="200" height="70" rx="6" fill="#1e3a5f" stroke="#2563eb" stroke-width="1"/>
  <text x="155" y="270" text-anchor="middle" fill="#60a5fa" font-size="10" font-weight="600">📋 Instance Template</text>
  <text x="155" y="284" text-anchor="middle" fill="#93c5fd" font-size="9">dev-web-template-xxx</text>
  <text x="155" y="297" text-anchor="middle" fill="#64748b" font-size="9">e2-micro · debian-11 · nginx</text>
  <text x="155" y="310" text-anchor="middle" fill="#64748b" font-size="9">create_before_destroy=true</text>
  <rect x="268" y="254" width="220" height="70" rx="6" fill="#1e3a5f" stroke="#2563eb" stroke-width="1"/>
  <text x="378" y="270" text-anchor="middle" fill="#60a5fa" font-size="10" font-weight="600">🖥 Managed Instance Group</text>
  <text x="378" y="284" text-anchor="middle" fill="#93c5fd" font-size="9">dev-web-mig · regional</text>
  <text x="378" y="297" text-anchor="middle" fill="#64748b" font-size="9">1–2 instances · CPU autoscale 70%</text>
  <text x="378" y="310" text-anchor="middle" fill="#64748b" font-size="9">auto-healing · multi-zone</text>
  <line x1="255" y1="289" x2="267" y2="289" stroke="#2563eb" stroke-width="1.5"/>
  <polygon points="268,289 260,285 260,293" fill="#2563eb"/>
  <rect x="55" y="336" width="200" height="42" rx="5" fill="#172554" stroke="#1d4ed8" stroke-width="1"/>
  <text x="155" y="352" text-anchor="middle" fill="#93c5fd" font-size="9" font-weight="600">VM: dev-web-jdww</text>
  <text x="155" y="366" text-anchor="middle" fill="#64748b" font-size="9">10.0.1.2 · us-central1-f</text>
  <rect x="268" y="336" width="220" height="42" rx="5" fill="#172554" stroke="#1d4ed8" stroke-width="1"/>
  <text x="378" y="352" text-anchor="middle" fill="#93c5fd" font-size="9" font-weight="600">❤ Health Check: /health · HTTP:80</text>
  <text x="378" y="366" text-anchor="middle" fill="#64748b" font-size="9">interval 10s · threshold 2 healthy / 3 unhealthy</text>
  <rect x="55" y="390" width="433" height="68" rx="6" fill="#0c1a2e" stroke="#1e3a5f" stroke-width="1"/>
  <text x="270" y="406" text-anchor="middle" fill="#4b5563" font-size="9" font-weight="600">🔥 FIREWALL RULES</text>
  <text x="130" y="422" text-anchor="middle" fill="#64748b" font-size="8">dev-allow-http-https</text>
  <text x="130" y="434" text-anchor="middle" fill="#475569" font-size="8">0.0.0.0/0→:80,:443</text>
  <text x="240" y="422" text-anchor="middle" fill="#64748b" font-size="8">dev-allow-iap-ssh</text>
  <text x="240" y="434" text-anchor="middle" fill="#475569" font-size="8">35.235.240.0/20→:22</text>
  <text x="350" y="422" text-anchor="middle" fill="#64748b" font-size="8">dev-allow-internal</text>
  <text x="350" y="434" text-anchor="middle" fill="#475569" font-size="8">10.0.0.0/8→all</text>
  <text x="460" y="422" text-anchor="middle" fill="#64748b" font-size="8">allow-health-checks</text>
  <text x="460" y="434" text-anchor="middle" fill="#475569" font-size="8">130.211.0.0/22→:80</text>
  <rect x="55" y="468" width="200" height="36" rx="5" fill="#0c1a2e" stroke="#1e3a5f" stroke-width="1"/>
  <text x="155" y="483" text-anchor="middle" fill="#64748b" font-size="9" font-weight="600">🔀 Cloud Router + NAT</text>
  <text x="155" y="496" text-anchor="middle" fill="#475569" font-size="8">dev-router · dev-nat · ALL_SUBNETWORKS</text>
  <rect x="520" y="228" width="280" height="240" rx="8" fill="#0f2d1f" stroke="#15803d" stroke-width="1.5"/>
  <text x="540" y="246" fill="#16a34a" font-size="10" font-weight="700">PRIVATE SUBNET · 10.0.2.0/24</text>
  <rect x="535" y="254" width="250" height="95" rx="6" fill="#14532d" stroke="#15803d" stroke-width="1"/>
  <text x="660" y="272" text-anchor="middle" fill="#4ade80" font-size="10" font-weight="600">🗄 Cloud SQL PostgreSQL 15</text>
  <text x="660" y="287" text-anchor="middle" fill="#86efac" font-size="9">dev-postgres-efa9df2e</text>
  <text x="660" y="301" text-anchor="middle" fill="#64748b" font-size="9">db-f1-micro · 10GB SSD · 10.51.0.3</text>
  <text x="660" y="315" text-anchor="middle" fill="#64748b" font-size="9">private IP only · ipv4_enabled=false</text>
  <text x="660" y="329" text-anchor="middle" fill="#64748b" font-size="9">backups · PITR · 7-day retention · maint Sun 3am</text>
  <rect x="535" y="358" width="120" height="42" rx="5" fill="#052e16" stroke="#15803d" stroke-width="1"/>
  <text x="595" y="374" text-anchor="middle" fill="#86efac" font-size="9" font-weight="600">DB: appdb</text>
  <text x="595" y="388" text-anchor="middle" fill="#64748b" font-size="8">User: appuser</text>
  <rect x="665" y="358" width="120" height="42" rx="5" fill="#052e16" stroke="#15803d" stroke-width="1"/>
  <text x="725" y="374" text-anchor="middle" fill="#86efac" font-size="9" font-weight="600">🔑 Secret Manager</text>
  <text x="725" y="388" text-anchor="middle" fill="#64748b" font-size="8">dev-db-password · 24-char</text>
  <rect x="535" y="410" width="250" height="48" rx="5" fill="#052e16" stroke="#15803d" stroke-width="1"/>
  <text x="660" y="428" text-anchor="middle" fill="#64748b" font-size="8" font-weight="600">VPC Peering: google_service_networking_connection</text>
  <text x="660" y="442" text-anchor="middle" fill="#475569" font-size="8">servicenetworking.googleapis.com · /16 reserved</text>
  <rect x="820" y="228" width="240" height="240" rx="8" fill="#1a0a2e" stroke="#7c3aed" stroke-width="1.5"/>
  <text x="840" y="246" fill="#a78bfa" font-size="10" font-weight="700">API MICROSERVICE</text>
  <rect x="835" y="254" width="210" height="90" rx="6" fill="#2d1b69" stroke="#7c3aed" stroke-width="1"/>
  <text x="940" y="272" text-anchor="middle" fill="#c4b5fd" font-size="10" font-weight="600">☁ Cloud Run v2</text>
  <text x="940" y="287" text-anchor="middle" fill="#a78bfa" font-size="9">dev-api-service</text>
  <text x="940" y="301" text-anchor="middle" fill="#64748b" font-size="8">dev-api-service-rnugorbs4q-uc.a.run.app</text>
  <text x="940" y="315" text-anchor="middle" fill="#64748b" font-size="9">0–3 instances · 512Mi · serverless</text>
  <text x="940" y="329" text-anchor="middle" fill="#64748b" font-size="9">allUsers invoker · HTTP 200 ✅</text>
  <rect x="835" y="354" width="100" height="42" rx="5" fill="#1a0a2e" stroke="#7c3aed" stroke-width="1"/>
  <text x="885" y="370" text-anchor="middle" fill="#a78bfa" font-size="9" font-weight="600">📦 Artifact</text>
  <text x="885" y="383" text-anchor="middle" fill="#64748b" font-size="8">dev-api-repo</text>
  <rect x="945" y="354" width="100" height="42" rx="5" fill="#1a0a2e" stroke="#7c3aed" stroke-width="1"/>
  <text x="995" y="370" text-anchor="middle" fill="#a78bfa" font-size="9" font-weight="600">🔑 API Key</text>
  <text x="995" y="383" text-anchor="middle" fill="#64748b" font-size="8">dev-api-key · 32-char</text>
  <rect x="835" y="406" width="210" height="52" rx="5" fill="#1a0a2e" stroke="#7c3aed" stroke-width="1"/>
  <text x="940" y="422" text-anchor="middle" fill="#64748b" font-size="8" font-weight="600">IAM: dev-api-service-sa</text>
  <text x="940" y="436" text-anchor="middle" fill="#475569" font-size="8">secretmanager.secretAccessor · logging.logWriter</text>
  <text x="940" y="450" text-anchor="middle" fill="#475569" font-size="8">Workload Identity · least privilege</text>
  <rect x="20" y="700" width="1060" height="180" rx="8" fill="#1c1400" stroke="#b45309" stroke-width="1.5"/>
  <text x="40" y="720" fill="#d97706" font-size="10" font-weight="700">DATA PIPELINE — Event-Driven ETL</text>
  <rect x="40" y="728" width="130" height="70" rx="6" fill="#292400" stroke="#b45309" stroke-width="1"/>
  <text x="105" y="746" text-anchor="middle" fill="#fbbf24" font-size="10" font-weight="600">🪣 GCS Landing</text>
  <text x="105" y="760" text-anchor="middle" fill="#64748b" font-size="8">-dev-landing</text>
  <text x="105" y="773" text-anchor="middle" fill="#64748b" font-size="8">OBJECT_FINALIZE</text>
  <text x="105" y="787" text-anchor="middle" fill="#64748b" font-size="8">30-day lifecycle</text>
  <line x1="170" y1="763" x2="188" y2="763" stroke="#b45309" stroke-width="1.5"/>
  <polygon points="190,763 182,759 182,767" fill="#b45309"/>
  <rect x="190" y="728" width="130" height="70" rx="6" fill="#292400" stroke="#b45309" stroke-width="1"/>
  <text x="255" y="746" text-anchor="middle" fill="#fbbf24" font-size="10" font-weight="600">📨 Pub/Sub</text>
  <text x="255" y="760" text-anchor="middle" fill="#64748b" font-size="8">dev-file-uploaded</text>
  <text x="255" y="773" text-anchor="middle" fill="#64748b" font-size="8">dead-letter queue</text>
  <text x="255" y="787" text-anchor="middle" fill="#64748b" font-size="8">retry: 10s–600s</text>
  <line x1="320" y1="763" x2="338" y2="763" stroke="#b45309" stroke-width="1.5"/>
  <polygon points="340,763 332,759 332,767" fill="#b45309"/>
  <rect x="340" y="728" width="150" height="70" rx="6" fill="#292400" stroke="#b45309" stroke-width="1"/>
  <text x="415" y="744" text-anchor="middle" fill="#fbbf24" font-size="10" font-weight="600">⚡ Cloud Function v2</text>
  <text x="415" y="758" text-anchor="middle" fill="#64748b" font-size="8">dev-etl-processor</text>
  <text x="415" y="771" text-anchor="middle" fill="#64748b" font-size="8">python311 · 256MB · 300s</text>
  <text x="415" y="784" text-anchor="middle" fill="#64748b" font-size="8">parse CSV → write BQ → move file</text>
  <line x1="490" y1="763" x2="508" y2="763" stroke="#b45309" stroke-width="1.5"/>
  <polygon points="510,763 502,759 502,767" fill="#b45309"/>
  <rect x="510" y="728" width="150" height="70" rx="6" fill="#292400" stroke="#b45309" stroke-width="1"/>
  <text x="585" y="746" text-anchor="middle" fill="#fbbf24" font-size="10" font-weight="600">📊 BigQuery</text>
  <text x="585" y="760" text-anchor="middle" fill="#64748b" font-size="8">dev_pipeline.raw_events</text>
  <text x="585" y="773" text-anchor="middle" fill="#64748b" font-size="8">DAY partitioned · JSON payload</text>
  <text x="585" y="787" text-anchor="middle" fill="#64748b" font-size="8">event_id · source_file · processed_at</text>
  <line x1="660" y1="763" x2="678" y2="763" stroke="#b45309" stroke-width="1.5"/>
  <polygon points="680,763 672,759 672,767" fill="#b45309"/>
  <rect x="680" y="728" width="130" height="70" rx="6" fill="#292400" stroke="#b45309" stroke-width="1"/>
  <text x="745" y="746" text-anchor="middle" fill="#fbbf24" font-size="10" font-weight="600">🪣 GCS Curated</text>
  <text x="745" y="760" text-anchor="middle" fill="#64748b" font-size="8">-dev-curated</text>
  <text x="745" y="773" text-anchor="middle" fill="#64748b" font-size="8">versioned · processed/</text>
  <text x="745" y="787" text-anchor="middle" fill="#64748b" font-size="8">YYYY/MM/DD/filename</text>
  <rect x="830" y="718" width="240" height="152" rx="6" fill="#0a1a0a" stroke="#166534" stroke-width="1.5"/>
  <text x="850" y="736" fill="#4ade80" font-size="10" font-weight="700">📊 MONITORING</text>
  <rect x="845" y="744" width="210" height="30" rx="4" fill="#052e16" stroke="#166534" stroke-width="1"/>
  <text x="950" y="764" text-anchor="middle" fill="#86efac" font-size="9">📧 Email: gbhorne@gmail.com</text>
  <rect x="845" y="782" width="210" height="30" rx="4" fill="#052e16" stroke="#166534" stroke-width="1"/>
  <text x="950" y="802" text-anchor="middle" fill="#86efac" font-size="9">🚨 Alert: CPU &gt; 80% · 5min window</text>
  <rect x="845" y="820" width="210" height="30" rx="4" fill="#052e16" stroke="#166534" stroke-width="1"/>
  <text x="950" y="840" text-anchor="middle" fill="#86efac" font-size="9">🚨 Alert: Cloud Run 5xx &gt; 5 errors</text>
  <rect x="20" y="695" width="1060" height="14" rx="0" fill="none"/>
  <rect x="20" y="690" width="500" height="8" rx="4" fill="#1e293b"/>
  <text x="30" y="698" fill="#4b5563" font-size="8">IAM · 4 service accounts · least-privilege · one SA per workload</text>
  <rect x="20" y="876" width="1060" height="30" rx="6" fill="#111827" stroke="#1f2937" stroke-width="1"/>
  <text x="550" y="887" text-anchor="middle" fill="#4b5563" font-size="9">Terraform Remote State · gs://terraform-489323-bucket/environments/dev/ · 64 resources · 29/29 verify.sh ✅</text>
  <text x="550" y="899" text-anchor="middle" fill="#374151" font-size="8">module.networking · module.iam · module.compute · module.database · module.data_pipeline · module.serverless · module.monitoring</text>
</svg>
```

---

## What's Built

This project deploys **3 production applications** on a shared, secure networking foundation:

### 1. Web Application (3-Tier)
A horizontally-scalable web tier fronted by a Global HTTP Load Balancer:
- **Global HTTPS Load Balancer** with static IP (`35.186.212.137`), URL map, HTTP proxy, and backend service
- **Regional Managed Instance Group** running nginx on Debian 11, spread across multiple zones in `us-central1`
- **CPU-based autoscaler** targeting 70% utilization, scaling between 1–2 instances in dev (2–10 in prod)
- **Auto-healing** — MIG automatically replaces instances that fail health checks after 5 minutes
- **Instance template** with `create_before_destroy = true` for zero-downtime template updates
- Instances have **no external IPs** — they receive traffic only through the load balancer
- **IAP-only SSH** — port 22 is only reachable from `35.235.240.0/20` (Google's IAP range)

### 2. Data Pipeline (Event-Driven ETL)
A fully serverless event-driven pipeline triggered by file uploads:
- **GCS Landing Bucket** — files uploaded here trigger the pipeline automatically
- **Pub/Sub notification** — GCS sends `OBJECT_FINALIZE` events to `dev-file-uploaded` topic
- **Dead-letter queue** — failed messages go to `dev-etl-dead-letter` after 5 attempts, with exponential backoff (10s–600s)
- **Cloud Function v2 (Python)** — parses CSV files, writes records to BigQuery, moves file to curated bucket
- **BigQuery** — `dev_pipeline.raw_events` table, DAY-partitioned on `event_timestamp` for cost-efficient queries
- **GCS Curated Bucket** — processed files stored at `processed/YYYY/MM/DD/filename` with versioning enabled
- **Content-addressable deployment** — function zip named by MD5 hash; code changes auto-trigger redeployment

### 3. API Microservice (Serverless)
A Cloud Run v2 service for the API layer:
- **Cloud Run v2** — scales to zero, auto-scales under load (0–3 instances in dev)
- **Artifact Registry** Docker repository for container images
- **API key** generated by `random_password`, stored in Secret Manager
- Workload identity via dedicated service account (`dev-api-service-sa`)

---

## Infrastructure Foundation

### Networking
```
Internet → Global LB (35.186.212.137)
                ↓
         dev-vpc (custom, no auto-subnets)
         ├── Public Subnet  10.0.1.0/24  (web tier)
         │       ↓ Cloud NAT (outbound internet, no external IPs on VMs)
         └── Private Subnet 10.0.2.0/24  (database)
                 ↓ VPC Peering → Cloud SQL private IP 10.51.0.3
```

| Resource | Name | Purpose |
|----------|------|---------|
| VPC | `dev-vpc` | Custom network, `auto_create_subnetworks=false` |
| Public Subnet | `10.0.1.0/24` | Web tier — MIG instances |
| Private Subnet | `10.0.2.0/24` | DB tier — Cloud SQL private IP |
| Cloud Router | `dev-router` | Enables Cloud NAT |
| Cloud NAT | `dev-nat` | Outbound internet for instances with no external IP |
| Firewall | `dev-allow-http-https` | Port 80/443 from `0.0.0.0/0` to `web-server` tagged instances |
| Firewall | `dev-allow-iap-ssh` | Port 22 from IAP range only (`35.235.240.0/20`) |
| Firewall | `dev-allow-internal` | All traffic between subnets |
| Firewall | `dev-allow-health-checks` | LB health check ranges (`130.211.0.0/22`, `35.191.0.0/16`) |

### IAM — Least Privilege
One dedicated service account per workload. No sharing, no default compute SA:

| Service Account | Roles | Workload |
|----------------|-------|---------|
| `dev-web-app-sa` | `logging.logWriter`, `monitoring.metricWriter` | GCE instances |
| `dev-data-pipeline-sa` | `bigquery.dataEditor`, `storage.objectAdmin`, `pubsub.editor` | Cloud Function |
| `dev-api-service-sa` | `secretmanager.secretAccessor`, `logging.logWriter` | Cloud Run |
| `dev-cloud-build-sa` | `run.developer`, `artifactregistry.writer` | CI/CD pipelines |

### Database
- **Cloud SQL PostgreSQL 15** with **private IP only** (`ipv4_enabled = false`)
- VPC peering via `google_service_networking_connection` — database is unreachable from internet
- Password generated by `random_password` (24 chars), stored immediately in **Secret Manager**
- Automated daily backups at 02:00 UTC with **point-in-time recovery** (PITR) enabled
- 7-day backup retention, maintenance window Sunday 03:00 UTC

---

## Resource Inventory

| Module | Count | Resources |
|--------|-------|-----------|
| `module.networking` | 9 | VPC, 2 subnets, router, NAT, 4 firewall rules, private service connection |
| `module.iam` | 13 | 4 service accounts, 9 IAM role bindings |
| `module.compute` | 9 | Instance template, MIG, autoscaler, health check, static IP, backend service, URL map, HTTP proxy, forwarding rule |
| `module.database` | 7 | Cloud SQL instance, database, user, 2x Secret Manager (secret + version), random password, random ID |
| `module.data_pipeline` | 14 | 3 GCS buckets, bucket object (function zip), GCS notification, 2x Pub/Sub topics, subscription, IAM binding, BigQuery dataset + table, Cloud Function v2 |
| `module.serverless` | 6 | Cloud Run service, IAM member, Artifact Registry, 2x Secret Manager, random password |
| `module.monitoring` | 4 | Notification channel, 2 alert policies, dashboard |
| **Total** | **64** | **All managed by Terraform remote state** |

---

## Key Terraform Patterns

### Remote State
```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-489323-bucket"
    prefix = "environments/dev"
  }
}
```
State stored in GCS with versioning. State locking prevents concurrent applies. Roll back to any previous state version via `gsutil`.

### Module Composition via Output Chaining
```hcl
module "compute" {
  source = "../../modules/compute"

  vpc_name              = module.networking.vpc_name       # implicit dependency
  subnet_name           = module.networking.public_subnet_name
  service_account_email = module.iam.web_app_sa_email      # IAM must complete first
}
```
Terraform builds a dependency graph from references. Resources are created in the correct order automatically, with maximum parallelism.

### Content-Addressable Function Deployment
```hcl
data "archive_file" "function_zip" {
  type       = "zip"
  source_dir = "${path.module}/function_source"
  output_path = "/tmp/etl-function.zip"
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "etl-function-${data.archive_file.function_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function_zip.output_path
}
```
Every code change produces a new MD5, a new object name, and an automatic redeployment. No manual steps.

### Zero-Downtime Instance Template Updates
```hcl
resource "google_compute_instance_template" "web" {
  name_prefix = "${var.environment}-web-template-"

  lifecycle {
    create_before_destroy = true
  }
}
```
New template created before old one destroyed. MIG rolling update uses the new template without downtime.

### Input Validation
```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}
```
Invalid values caught before any API calls are made.

---

## Environment Differentiation

The same 7 modules deploy to dev/staging/prod with different variable values:

| Setting | dev | staging | prod |
|---------|-----|---------|------|
| Machine type | `e2-micro` | `e2-small` | `e2-standard-2` |
| Min replicas | 1 | 1 | 2 |
| Max replicas | 2 | 4 | 10 |
| DB tier | `db-f1-micro` | `db-g1-small` | `db-n1-standard-2` |
| DB HA | `ZONAL` | `ZONAL` | `REGIONAL` |
| Deletion protection | `false` | `false` | `true` |
| Cloud Run instances | 0–2 | 1–5 | 2–20 |

---

## Quick Start

### Prerequisites
- GCP project with billing enabled
- Terraform >= 1.5.0
- gcloud CLI authenticated

### Enable APIs
```bash
gcloud services enable \
  compute.googleapis.com sqladmin.googleapis.com \
  run.googleapis.com cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com artifactregistry.googleapis.com \
  bigquery.googleapis.com pubsub.googleapis.com \
  secretmanager.googleapis.com monitoring.googleapis.com \
  logging.googleapis.com cloudresourcemanager.googleapis.com \
  iam.googleapis.com servicenetworking.googleapis.com \
  storage.googleapis.com eventarc.googleapis.com
```

### Deploy
```bash
# Create remote state bucket
gsutil mb gs://YOUR-PROJECT-terraform-state
gsutil versioning set on gs://YOUR-PROJECT-terraform-state

# Configure
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project_id and alert_email

# Deploy
terraform init
terraform plan
terraform apply
```

### Verify
```bash
bash scripts/verify.sh
# Expected: 29 passed, 0 failed
```

### Destroy
```bash
bash scripts/destroy.sh
```

---

## Verification Results

```
════════════════════════════════════════════════════
   Enterprise Terraform GCP - Verification Report
   Project: terraform-489323
   Fri Mar  6 03:39:00 AM UTC 2026
════════════════════════════════════════════════════
✅ PASS: VPC: dev-vpc exists
✅ PASS: Subnet: dev-public-subnet exists
✅ PASS: Subnet: dev-private-subnet exists
✅ PASS: Router: dev-router exists
✅ PASS: NAT: dev-nat exists
✅ PASS: Firewall: 4 dev rules found
✅ PASS: Service Account: dev-web-app-sa
✅ PASS: Service Account: dev-data-pipeline-sa
✅ PASS: Service Account: dev-api-service-sa
✅ PASS: Service Account: dev-cloud-build-sa
✅ PASS: MIG: dev-web-mig exists
✅ PASS: Instances: 1 dev-web instance(s) running
✅ PASS: Load Balancer: dev-http-forwarding-rule exists
✅ PASS: LB Static IP: 35.186.212.137
✅ PASS: HTTP Response: 35.186.212.137 returned 200 OK
✅ PASS: Cloud SQL: dev-postgres-efa9df2e exists
✅ PASS: Secret Manager: dev-db-password exists
✅ PASS: GCS: terraform-489323-dev-landing bucket exists
✅ PASS: GCS: terraform-489323-dev-curated bucket exists
✅ PASS: Pub/Sub: dev-file-uploaded topic exists
✅ PASS: BigQuery: dev_pipeline dataset exists
✅ PASS: Cloud Function: dev-etl-processor exists
✅ PASS: Cloud Run: dev-api-service exists
✅ PASS: Cloud Run URL: https://dev-api-service-rnugorbs4q-uc.a.run.app
✅ PASS: Cloud Run HTTP: returned 200 OK
✅ PASS: Artifact Registry: dev-api-repo exists
✅ PASS: Alert Policies: 2 dev policies found
✅ PASS: Terraform State: 64 resources tracked
════════════════════════════════════════════════════
   RESULTS: 29 passed, 0 failed
════════════════════════════════════════════════════
```

---

## Cost

Full dev environment costs approximately **$2–5 total** for a 1–2 hour deployment window. Cloud SQL is the primary cost driver at ~$0.015/hour for `db-f1-micro`.

Destroy everything immediately after use: `bash scripts/destroy.sh`

---

## Repository Structure

```
gcp-terraform-enterprise/
├── environments/
│   ├── dev/
│   │   ├── backend.tf          # Remote state config (GCS)
│   │   ├── main.tf             # Module composition
│   │   ├── variables.tf        # Input declarations
│   │   ├── outputs.tf          # Exposed values
│   │   └── terraform.tfvars    # Values (gitignored)
│   ├── staging/                # Same modules, different vars
│   └── prod/                   # Same modules, different vars
├── modules/
│   ├── networking/             # VPC, subnets, NAT, firewall
│   ├── iam/                    # Service accounts, IAM bindings
│   ├── compute/                # MIG, autoscaler, load balancer
│   ├── database/               # Cloud SQL, Secret Manager
│   ├── data-pipeline/          # GCS, Pub/Sub, BigQuery, Cloud Function
│   ├── serverless/             # Cloud Run, Artifact Registry
│   └── monitoring/             # Alerts, dashboard
├── scripts/
│   ├── verify.sh               # 29-check automated verification
│   └── destroy.sh              # Safe teardown with confirmation
└── docs/
    ├── QA.md                   # Interview Q&A guide
    └── MEDIUM.md               # Article draft
```

---

## Author

**Gregory B. Horne** — [@gbhorne](https://github.com/gbhorne)
