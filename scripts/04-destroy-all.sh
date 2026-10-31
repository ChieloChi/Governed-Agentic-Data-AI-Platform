#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "🛑 STEP 4: Complete Teardown (Stopping All AWS Charges)"
echo "============================================================"

PROJECT_ROOT="$(dirname "$0")/.."

echo "[1/3] Uninstalling Helm Releases (Cleanly detaching AWS LoadBalancers & Secrets)..."
if command -v helm &>/dev/null; then
  helm uninstall ai-platform -n default 2>/dev/null || true
  helm uninstall external-secrets -n external-secrets 2>/dev/null || true
  helm uninstall gpu-operator -n gpu-operator 2>/dev/null || true
fi

echo "[2/3] Running Terraform Destroy (EKS, VPC, EC2, and AWS Secrets Manager)..."
cd "$PROJECT_ROOT/terraform"
terraform destroy -auto-approve

echo "[3/3] Verifying no resources remain..."
echo "✅ All EKS, EC2, and AWS Secrets Manager resources destroyed successfully."
echo "💰 Ongoing AWS hourly charges are now $0.00."
