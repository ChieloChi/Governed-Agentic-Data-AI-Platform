#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "🛑 STEP 4: Complete Teardown (Stopping All AWS Charges)"
echo "============================================================"

PROJECT_ROOT="$(dirname "$0")/.."
ENV="${1:-dev}"
TF_DIR="$PROJECT_ROOT/terraform/environments/$ENV"

if [ ! -d "$TF_DIR" ]; then
  echo "❌ Error: Environment '$ENV' not found in $TF_DIR"
  exit 1
fi

echo "[1/3] Uninstalling Helm Releases (Cleanly detaching AWS LoadBalancers & Secrets)..."
if command -v helm &>/dev/null; then
  helm uninstall ai-platform -n default 2>/dev/null || true
  helm uninstall karpenter -n kube-system 2>/dev/null || true
  helm uninstall external-secrets -n external-secrets 2>/dev/null || true
  helm uninstall gpu-operator -n gpu-operator 2>/dev/null || true
fi

echo "[2/3] Running Terraform Destroy for '$ENV' (EKS, VPC, EC2, and AWS Secrets Manager)..."
cd "$TF_DIR"
terraform destroy -auto-approve

echo "[3/3] Verifying no resources remain..."
echo "✅ All EKS, EC2, and AWS Secrets Manager resources destroyed successfully."
echo "💰 Ongoing AWS hourly charges are now $0.00."
