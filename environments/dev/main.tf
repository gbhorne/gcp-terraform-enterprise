# ── Providers ─────────────────────────────────────────────────────────────────
provider "google" {
  project = var.project_id
  region  = var.region
}

# ── Networking ────────────────────────────────────────────────────────────────
module "networking" {
  source = "../../modules/networking"

  project_id          = var.project_id
  environment         = "dev"
  region              = var.region
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
}

# ── IAM ───────────────────────────────────────────────────────────────────────
module "iam" {
  source = "../../modules/iam"

  project_id  = var.project_id
  environment = "dev"
}

# ── Compute ───────────────────────────────────────────────────────────────────
module "compute" {
  source = "../../modules/compute"

  project_id            = var.project_id
  environment           = "dev"
  region                = var.region
  machine_type          = "e2-micro"
  vpc_name              = module.networking.vpc_name
  subnet_name           = module.networking.public_subnet_name
  service_account_email = module.iam.web_app_sa_email
  min_replicas          = 1
  max_replicas          = 2
}

# ── Database ──────────────────────────────────────────────────────────────────
module "database" {
  source = "../../modules/database"

  project_id             = var.project_id
  environment            = "dev"
  region                 = var.region
  tier                   = "db-f1-micro"
  disk_size              = 10
  vpc_id                 = module.networking.vpc_id
  private_vpc_connection = module.networking.private_vpc_connection
  deletion_protection    = false
}

# ── Data Pipeline ─────────────────────────────────────────────────────────────
module "data_pipeline" {
  source = "../../modules/data-pipeline"

  project_id             = var.project_id
  environment            = "dev"
  region                 = var.region
  data_pipeline_sa_email = module.iam.data_pipeline_sa_email
}
# ── Serverless API ────────────────────────────────────────────────────────────
module "serverless" {
  source = "../../modules/serverless"

  project_id            = var.project_id
  environment           = "dev"
  region                = var.region
  api_service_sa_email  = module.iam.api_service_sa_email
  vpc_connector_network = module.networking.vpc_name
}

# ── Monitoring ────────────────────────────────────────────────────────────────
module "monitoring" {
  source = "../../modules/monitoring"

  project_id  = var.project_id
  environment = "dev"
  alert_email = var.alert_email
  mig_name    = module.compute.mig_name
}
