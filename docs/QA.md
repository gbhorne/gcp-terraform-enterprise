# Terraform GCP — Interview Q&A

## State Management

**Q: Why use remote state instead of local?**
A: Local state is lost if your machine dies and can't be shared with a team. GCS backend stores state remotely with versioning enabled — you can roll back to any previous state. It also enables state locking via Cloud Storage object locking, preventing two engineers from running `terraform apply` simultaneously and corrupting state.

**Q: What happens if two people run terraform apply at the same time?**
A: With GCS backend, Terraform uses a `.terraform.tflock` file to implement a mutex. The second apply fails immediately with a lock error rather than corrupting state. In a CI/CD pipeline you enforce this at the pipeline level too — only one apply job runs at a time per environment.

**Q: How do you recover from a corrupted state file?**
A: GCS versioning means you can restore a previous state version via `gsutil cp`. Then use `terraform state rm` to remove the corrupted resource and `terraform import` to re-import the real resource. Never edit state files manually.

## Modules

**Q: What's the difference between a module input and a data source?**
A: Module inputs are values you pass in from the calling configuration — you control them. Data sources query existing infrastructure at plan time — GCP tells you the value. Example: `var.vpc_name` is a module input. `data.google_storage_project_service_account` is a data source that looks up GCS's service account email, which you can't know in advance.

**Q: Why use output chaining between modules?**
A: It creates explicit, readable dependencies. `subnet_name = module.networking.public_subnet_name` tells Terraform: create the subnet first, then pass its name to compute. Without this, you'd hardcode names and lose the dependency graph — Terraform wouldn't know the correct creation order.

**Q: When would you use count vs for_each?**
A: Use `count` for simple numeric repetition where items are identical. Use `for_each` when each instance needs unique configuration — it uses a map so each resource has a stable identity. With `count`, removing item 0 from a list causes everything to shift and Terraform recreates all downstream resources. With `for_each`, removing a key only affects that specific resource.

## Networking

**Q: Why put the database in the private subnet with no public IP?**
A: Defense in depth. A database with a public IP is reachable from the internet — one misconfigured firewall rule and it's exposed. Private IP means it's only reachable from within the VPC. Combined with the VPC peering (`google_service_networking_connection`), Cloud SQL gets a private IP in Google's managed network that your VMs can reach but the internet cannot.

**Q: How does IAP SSH work and why is it better than a bastion host?**
A: IAP (Identity-Aware Proxy) creates an encrypted tunnel from your local machine to the VM through Google's infrastructure. Port 22 is never exposed to the internet — the only allowed SSH source is `35.235.240.0/20` (Google's IAP range). No bastion host to maintain, patch, or pay for. Access is controlled by IAM, fully audited in Cloud Audit Logs.

**Q: Why does Cloud NAT only cover the private subnet originally?**
A: The public subnet instances were intended to have external IPs for direct internet access. Private subnet instances have no external IP, so they need NAT to reach the internet for package downloads. In this project we changed it to `ALL_SUBNETWORKS_ALL_IP_RANGES` because our public subnet instances also have no external IP — they receive traffic only through the load balancer.

## IAM

**Q: What is least privilege and how did you implement it?**
A: Least privilege means each identity gets only the permissions it needs — nothing more. The web app service account gets `logging.logWriter` and `monitoring.metricWriter` because it writes logs and metrics. It doesn't get Storage or BigQuery access because it never touches those services. If the web app is compromised, the blast radius is limited to what that SA can do.

**Q: What's the difference between a service account and a user account in GCP?**
A: User accounts are for humans, authenticated via Google login. Service accounts are for workloads — VMs, Cloud Functions, Cloud Run services. They authenticate via keys or (better) workload identity, never passwords. Service accounts can be granted IAM roles just like users. Best practice: one service account per workload, never share them.

## Security

**Q: How is the database password managed?**
A: `random_password` generates a cryptographically random 24-character password at apply time. It's immediately stored in Secret Manager via `google_secret_manager_secret_version`. The password is marked as `sensitive` in Terraform state — it's stored encrypted but never printed in plan output. Applications fetch it at runtime via the Secret Manager API using their service account's `secretmanager.secretAccessor` role.

**Q: How would you rotate the database password?**
A: `terraform taint module.database.random_password.db_password` marks it for recreation. Next apply generates a new password, creates a new Secret Manager version, and updates the Cloud SQL user. The old version remains in Secret Manager until explicitly deleted, giving you a rollback window.

## Architecture Decisions

**Q: Why Cloud Functions v2 instead of v1?**
A: v2 runs on Cloud Run under the hood — same infrastructure, more consistent behavior. Longer timeouts (up to 60 minutes vs 9 minutes), larger instances (up to 32GB RAM), concurrency support, and Eventarc integration for a richer event trigger ecosystem. v1 is being deprecated.

**Q: Why use a Managed Instance Group instead of a single VM?**
A: MIG gives you auto-healing (replaces failed instances automatically), autoscaling (adds instances under load), rolling updates (new template deployed without downtime), and multi-zone distribution (instances spread across zones for availability). A single VM gives you none of these.

**Q: How would you promote this to production?**
A: Create `environments/prod/` with the same module calls but different variable values — larger machine types, `db-n1-standard-2`, `availability_type = "REGIONAL"`, `deletion_protection = true`, min 2 replicas. The modules don't change — only the inputs. This is the core value of module-based IaC: write once, parameterize for each environment.
