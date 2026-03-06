#!/bin/bash
echo "════════════════════════════════════════════════════"
echo "   Enterprise Terraform GCP - Teardown Script"
echo "════════════════════════════════════════════════════"
echo ""
echo "⚠️  This will destroy ALL resources in the dev environment."
read -p "Type 'yes' to confirm: " confirm
[ "$confirm" != "yes" ] && echo "Aborted." && exit 1

export GOOGLE_APPLICATION_CREDENTIALS=$(ls /tmp/tmp.*/application_default_credentials.json 2>/dev/null | head -1)

cd ~/gcp-terraform-enterprise/environments/dev
echo ""
echo "Running terraform destroy..."
terraform destroy -auto-approve

echo ""
echo "✅ Teardown complete."
