#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "🚀 STEP 1: Provisioning Ephemeral AI EKS Cluster with Terraform"
echo "============================================================"

ENV="${1:-dev}"
PROJECT_ROOT="$(dirname "$0")/.."
TF_DIR="$PROJECT_ROOT/terraform/environments/$ENV"

if [ ! -d "$TF_DIR" ]; then
  echo "❌ Error: Environment '$ENV' not found in $TF_DIR"
  exit 1
fi

echo "Deploying target environment: $ENV"
cd "$TF_DIR"

echo "[1/3] Initializing Terraform..."
terraform init

echo "[2/3] Applying Terraform plan (Creating VPC, EKS, and Spot GPU Node)..."
echo "Note: EKS Control Plane provisioning typically takes ~8-10 minutes."
terraform apply -auto-approve

echo "[3/3] Updating local kubeconfig..."
CLUSTER_NAME=$(terraform output -raw cluster_name)
AWS_REGION=$(terraform output -raw configure_kubectl_command | grep -oP '(?<=--region )[^\s]+')
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

echo ""
echo "✅ EKS Cluster is ready!"
echo "Checking worker nodes:"
kubectl get nodes -o wide

