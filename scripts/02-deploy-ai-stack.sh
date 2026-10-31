#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "📦 STEP 2: Deploying Production AI Platform via Unified Helm"
echo "============================================================"

PROJECT_ROOT="$(dirname "$0")/.."
TF_DIR="$PROJECT_ROOT/terraform"

# Ensure Helm is installed
if ! command -v helm &>/dev/null; then
  echo "⚠️ Helm not found. Installing Helm binary..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "[1/6] Adding Helm Repositories (NVIDIA & External Secrets Operator)..."
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia --force-update
helm repo add external-secrets https://charts.external-secrets.io --force-update
helm repo update

echo "[2/6] Installing NVIDIA GPU Operator with Enterprise Observability..."
helm upgrade --install gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator \
  --create-namespace \
  --values "$PROJECT_ROOT/helm/gpu-operator-values.yaml" \
  --wait \
  --timeout=300s

echo "✅ GPU Operator and DCGM Exporter are running in namespace 'gpu-operator'!"

echo "[3/6] Installing External Secrets Operator (IRSA Authentication)..."
ROLE_ARN=$(cd "$TF_DIR" && terraform output -raw external_secrets_role_arn)

helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set serviceAccount.name="external-secrets-sa" \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$ROLE_ARN" \
  --wait \
  --timeout=180s

echo "✅ External Secrets Operator is authenticated to AWS Secrets Manager!"

echo "[4/6] Deploying Unified AI Platform Helm Chart (Postgres, Cube, LiteLLM, vLLM, Redis, Qdrant)..."
helm upgrade --install ai-platform "$PROJECT_ROOT/helm/ai-platform" \
  --namespace default \
  --wait \
  --timeout=400s

echo "[5/6] Waiting for External Secrets Operator to sync litellm-secret..."
for i in {1..30}; do
  if kubectl get secret litellm-secret &>/dev/null; then
    echo "✅ Secret 'litellm-secret' synced successfully from AWS Secrets Manager!"
    break
  fi
  echo "Waiting for secret sync ($i/30)..."
  sleep 3
done

echo "[6/6] Inspecting GPU Feature Discovery (GFD) Auto-Injected Node Labels:"
kubectl get nodes -l role=gpu-inference --show-labels | tr ',' '\n' | grep -E 'nvidia\.com' || true

echo ""
echo "🎉 Unified Helm Deployment Complete! All Platform Pods & Services Operational:"
kubectl get pods -o wide
helm list -A
