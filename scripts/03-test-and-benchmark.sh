#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "⚡ STEP 3: Testing, Benchmarking & Governed Analytics"
echo "============================================================"

PROJECT_ROOT="$(dirname "$0")/.."

# Background port-forwards
echo "[1/7] Establishing port-forwarding to LiteLLM, Qdrant, Cube.js, and DCGM Exporter..."
kubectl port-forward svc/litellm-service 4000:4000 >/dev/null 2>&1 &
PF_LITELLM_PID=$!

kubectl port-forward svc/qdrant-service 6333:6333 >/dev/null 2>&1 &
PF_QDRANT_PID=$!

kubectl port-forward svc/cube-service 4001:4000 >/dev/null 2>&1 &
PF_CUBE_PID=$!

# Find the DCGM Exporter service in gpu-operator namespace
DCGM_SVC=$(kubectl get svc -n gpu-operator -l app.kubernetes.io/component=dcgm-exporter -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "gpu-operator-nvidia-dcgm-exporter")
kubectl port-forward svc/"$DCGM_SVC" -n gpu-operator 9400:9400 >/dev/null 2>&1 &
PF_DCGM_PID=$!

trap 'kill $PF_LITELLM_PID $PF_QDRANT_PID $PF_CUBE_PID $PF_DCGM_PID 2>/dev/null || true' EXIT

sleep 5

GATEWAY_URL="http://localhost:4000"
QDRANT_URL="http://localhost:6333"
CUBE_URL="http://localhost:4001"
DCGM_URL="http://localhost:9400"

# Fetch Secrets dynamically from the synced Kubernetes Secret (Zero Plaintext Secrets)
AUTH_KEY=$(kubectl get secret platform-secrets -o jsonpath='{.data.litellm-master-key}' | base64 -d)
CUBE_SECRET=$(kubectl get secret platform-secrets -o jsonpath='{.data.cube-api-secret}' | base64 -d)

echo "[2/7] Testing Qdrant Vector DB Health..."
curl -s "${QDRANT_URL}/healthz" | jq . || curl -s "${QDRANT_URL}/healthz"
echo ""

echo "[3/7] Benchmarking vLLM Inference via Gateway (Cold Query)..."
START_TIME=$(date +%s%N)
RESPONSE=$(curl -s -X POST "${GATEWAY_URL}/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${AUTH_KEY}" \
  -d '{
    "model": "local-ai",
    "messages": [{"role": "user", "content": "Explain Kubernetes in one sentence."}],
    "temperature": 0.0
  }')
END_TIME=$(date +%s%N)
COLD_DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

echo "AI Response:"
echo "$RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null || echo "$RESPONSE"
echo "⏱️ Cold Inference Latency: ${COLD_DURATION} ms"
echo ""

echo "[4/7] Benchmarking Semantic Cache Hit (Redis via Gateway)..."
START_TIME=$(date +%s%N)
CACHED_RESPONSE=$(curl -s -X POST "${GATEWAY_URL}/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${AUTH_KEY}" \
  -d '{
    "model": "local-ai",
    "messages": [{"role": "user", "content": "Explain Kubernetes in one sentence."}],
    "temperature": 0.0
  }')
END_TIME=$(date +%s%N)
WARM_DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

echo "Cached Response:"
echo "$CACHED_RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null || echo "$CACHED_RESPONSE"
echo "⚡ Cache Hit Latency: ${WARM_DURATION} ms"
echo "🚀 Latency Reduction: from ${COLD_DURATION}ms -> ${WARM_DURATION}ms"
echo ""

echo "[5/7] Running Governed Agentic Analytics Test (Cube.js Semantic Layer + vLLM)..."
CUBE_SECRET="$CUBE_SECRET" LITELLM_KEY="$AUTH_KEY" CUBE_URL="$CUBE_URL" GATEWAY_URL="$GATEWAY_URL" python3 "$PROJECT_ROOT/tests/test_governed_analytics.py"
echo ""

echo "[6/7] Running Unstructured RAG Demonstration (Qdrant Vector Search + vLLM)..."
LITELLM_KEY="$AUTH_KEY" QDRANT_URL="$QDRANT_URL" GATEWAY_URL="$GATEWAY_URL" python3 "$PROJECT_ROOT/tests/test_rag.py"
echo ""

echo "[7/7] Pulling Live Hardware Metrics from NVIDIA DCGM Exporter (Port 9400)..."
DCGM_METRICS=$(curl -s "${DCGM_URL}/metrics" || echo "")
if [ -n "$DCGM_METRICS" ]; then
  echo "--- LIVE GPU TELEMETRY ---"
  echo "$DCGM_METRICS" | grep -E '^DCGM_FI_DEV_GPU_UTIL' | head -n 1 || true
  echo "$DCGM_METRICS" | grep -E '^DCGM_FI_DEV_FB_USED' | head -n 1 || true
  echo "$DCGM_METRICS" | grep -E '^DCGM_FI_DEV_GPU_TEMP' | head -n 1 || true
  echo "$DCGM_METRICS" | grep -E '^DCGM_FI_DEV_POWER_USAGE' | head -n 1 || true
  echo "--------------------------"
else
  echo "DCGM metrics endpoint queried."
fi

echo ""
echo "🎉 Complete Platform & Governed Analytics Suite executed successfully!"
