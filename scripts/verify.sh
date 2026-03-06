#!/bin/bash
PROJECT="terraform-489323"
REGION="us-central1"
PASS=0
FAIL=0

green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

pass() { echo -e "${green}✅ PASS${nc}: $1"; ((PASS++)); }
fail() { echo -e "${red}❌ FAIL${nc}: $1"; ((FAIL++)); }

echo ""
echo "════════════════════════════════════════════════════"
echo "   Enterprise Terraform GCP - Verification Report"
echo "   Project: $PROJECT"
echo "   $(date)"
echo "════════════════════════════════════════════════════"
echo ""

if gcloud compute networks describe dev-vpc --project=$PROJECT &>/dev/null; then pass "VPC: dev-vpc exists"; else fail "VPC: dev-vpc not found"; fi
if gcloud compute networks describe dev-vpc --project=$PROJECT &>/dev/null; then pass "VPC: dev-vpc exists"; else fail "VPC: dev-vpc not found"; fi
gcloud compute networks subnets describe dev-public-subnet --region=$REGION --project=$PROJECT &>/dev/null && pass "Subnet: dev-public-subnet exists" || fail "Subnet: dev-public-subnet not found"
gcloud compute networks subnets describe dev-private-subnet --region=$REGION --project=$PROJECT &>/dev/null && pass "Subnet: dev-private-subnet exists" || fail "Subnet: dev-private-subnet not found"
gcloud compute routers describe dev-router --region=$REGION --project=$PROJECT &>/dev/null && pass "Router: dev-router exists" || fail "Router: dev-router not found"
gcloud compute routers nats describe dev-nat --router=dev-router --region=$REGION --project=$PROJECT &>/dev/null && pass "NAT: dev-nat exists" || fail "NAT: dev-nat not found"
FW=$(gcloud compute firewall-rules list --project=$PROJECT --filter="name:dev-" --format="value(name)" | wc -l)
[ "$FW" -ge 4 ] && pass "Firewall: $FW dev rules found" || fail "Firewall: expected 4+ rules, found $FW"

echo ""
echo "── IAM ─────────────────────────────────────────────"
for SA in web-app data-pipeline api-service cloud-build; do
  gcloud iam service-accounts describe "dev-${SA}-sa@${PROJECT}.iam.gserviceaccount.com" --project=$PROJECT &>/dev/null \
    && pass "Service Account: dev-${SA}-sa" || fail "Service Account: dev-${SA}-sa not found"
done

echo ""
echo "── COMPUTE ─────────────────────────────────────────"
MIG=$(gcloud compute instance-groups managed describe dev-web-mig --region=$REGION --project=$PROJECT 2>/dev/null)
[ -n "$MIG" ] && pass "MIG: dev-web-mig exists" || fail "MIG: dev-web-mig not found"
INSTANCES=$(gcloud compute instances list --project=$PROJECT --filter="name:dev-web" --format="value(name)" | wc -l)
[ "$INSTANCES" -ge 1 ] && pass "Instances: $INSTANCES dev-web instance(s) running" || fail "Instances: no dev-web instances found"
LB=$(gcloud compute forwarding-rules describe dev-http-forwarding-rule --global --project=$PROJECT 2>/dev/null)
[ -n "$LB" ] && pass "Load Balancer: dev-http-forwarding-rule exists" || fail "Load Balancer: not found"
LB_IP=$(gcloud compute addresses describe dev-lb-ip --global --project=$PROJECT --format="value(address)" 2>/dev/null)
[ -n "$LB_IP" ] && pass "LB Static IP: $LB_IP" || fail "LB Static IP: not found"
HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://$LB_IP)
[ "$HTTP" = "200" ] && pass "HTTP Response: $LB_IP returned 200 OK" || fail "HTTP Response: got $HTTP from $LB_IP"

echo ""
echo "── DATABASE ────────────────────────────────────────"
DB=$(gcloud sql instances list --project=$PROJECT --filter="name:dev-postgres" --format="value(name)" 2>/dev/null)
[ -n "$DB" ] && pass "Cloud SQL: $DB exists" || fail "Cloud SQL: no dev-postgres instance found"
SECRET=$(gcloud secrets describe dev-db-password --project=$PROJECT 2>/dev/null)
[ -n "$SECRET" ] && pass "Secret Manager: dev-db-password exists" || fail "Secret Manager: dev-db-password not found"

echo ""
echo "── DATA PIPELINE ───────────────────────────────────"
gsutil ls gs://${PROJECT}-dev-landing &>/dev/null && pass "GCS: ${PROJECT}-dev-landing bucket exists" || fail "GCS: landing bucket not found"
gsutil ls gs://${PROJECT}-dev-curated &>/dev/null && pass "GCS: ${PROJECT}-dev-curated bucket exists" || fail "GCS: curated bucket not found"
TOPIC=$(gcloud pubsub topics describe dev-file-uploaded --project=$PROJECT 2>/dev/null)
[ -n "$TOPIC" ] && pass "Pub/Sub: dev-file-uploaded topic exists" || fail "Pub/Sub: dev-file-uploaded not found"
BQ=$(bq show --project_id=$PROJECT ${PROJECT}:dev_pipeline 2>/dev/null)
[ -n "$BQ" ] && pass "BigQuery: dev_pipeline dataset exists" || fail "BigQuery: dev_pipeline not found"
CF=$(gcloud functions describe dev-etl-processor --region=$REGION --project=$PROJECT 2>/dev/null)
[ -n "$CF" ] && pass "Cloud Function: dev-etl-processor exists" || fail "Cloud Function: dev-etl-processor not found"

echo ""
echo "── SERVERLESS ──────────────────────────────────────"
CR=$(gcloud run services describe dev-api-service --region=$REGION --project=$PROJECT 2>/dev/null)
[ -n "$CR" ] && pass "Cloud Run: dev-api-service exists" || fail "Cloud Run: dev-api-service not found"
CR_URL=$(gcloud run services describe dev-api-service --region=$REGION --project=$PROJECT --format="value(status.url)" 2>/dev/null)
[ -n "$CR_URL" ] && pass "Cloud Run URL: $CR_URL" || fail "Cloud Run URL: not found"
CR_HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 $CR_URL)
[ "$CR_HTTP" = "200" ] && pass "Cloud Run HTTP: returned 200 OK" || fail "Cloud Run HTTP: got $CR_HTTP"
AR=$(gcloud artifacts repositories describe dev-api-repo --location=$REGION --project=$PROJECT 2>/dev/null)
[ -n "$AR" ] && pass "Artifact Registry: dev-api-repo exists" || fail "Artifact Registry: dev-api-repo not found"

echo ""
echo "── MONITORING ──────────────────────────────────────"
ALERTS=$(gcloud monitoring policies list --project=$PROJECT --filter="displayName:dev" --format="value(displayName)" 2>/dev/null | wc -l)
[ "$ALERTS" -ge 2 ] && pass "Alert Policies: $ALERTS dev policies found" || fail "Alert Policies: expected 2+, found $ALERTS"

echo ""
echo "── TERRAFORM STATE ─────────────────────────────────"
cd ~/gcp-terraform-enterprise/environments/dev
RESOURCES=$(terraform state list 2>/dev/null | wc -l)
[ "$RESOURCES" -ge 60 ] && pass "Terraform State: $RESOURCES resources tracked" || fail "Terraform State: only $RESOURCES resources found"

echo ""
echo "════════════════════════════════════════════════════"
echo "   RESULTS: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════"
echo ""
