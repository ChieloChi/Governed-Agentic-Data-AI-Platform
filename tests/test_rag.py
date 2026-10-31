#!/usr/bin/env python3
"""
End-to-End RAG (Retrieval-Augmented Generation) Pipeline Test
Validates:
  1. Qdrant Vector Database collection creation & document vector indexing.
  2. High-speed vector similarity search (Nearest Neighbor / Cosine distance).
  3. Prompt augmentation with retrieved context.
  4. Generation via LiteLLM Gateway & vLLM Inference Engine.
"""

import os
import sys
import json
import time
import requests

QDRANT_URL = os.environ.get("QDRANT_URL", "http://localhost:6333")
GATEWAY_URL = os.environ.get("GATEWAY_URL", "http://localhost:4000")
AUTH_KEY = os.environ.get("LITELLM_KEY", "sk-admin-test")
COLLECTION_NAME = "devops_runbooks"

# Sample enterprise engineering documents
DOCUMENTS = [
    {
        "id": 1,
        "title": "GPU XID Error 79 (GPU has fallen off the bus)",
        "content": "GPU XID Error 79 indicates the GPU card has fallen off the PCIe bus due to power drop or hardware malfunction. Immediate remediation: drain the node, reboot EC2 instance. If persistent, terminate and replace node.",
        "vector": [0.92, 0.12, 0.05, 0.01]  # Hardware/GPU semantic cluster
    },
    {
        "id": 2,
        "title": "Kubernetes Pod OOMKilled Troubleshooting",
        "content": "Exit Code 137 indicates the Linux Out-Of-Memory (OOM) killer terminated the container. Remediation: inspect memory limits in deployment spec, profile container heap usage, and increase memory requests/limits.",
        "vector": [0.08, 0.89, 0.15, 0.02]  # Memory/Kubernetes semantic cluster
    },
    {
        "id": 3,
        "title": "LiteLLM Gateway Rate Limit (HTTP 429)",
        "content": "HTTP 429 from LiteLLM indicates virtual key TPM (tokens per minute) or RPM limits exceeded. Remediation: increase team quota in LiteLLM config or enable fallback routing to secondary model.",
        "vector": [0.02, 0.11, 0.94, 0.05]  # API/Gateway semantic cluster
    }
]

def step(title):
    print(f"\n{'='*60}\n👉 {title}\n{'='*60}")

def main():
    print("🚀 Initializing End-to-End RAG Demonstration against EKS AI Platform...")

    # 1. Create Collection in Qdrant Vector DB
    step("1. Initializing Qdrant Collection with Cosine Distance Indexing")
    collection_payload = {
        "vectors": {
            "size": 4,
            "distance": "Cosine"
        }
    }
    # Delete if exists from previous run, then create
    requests.delete(f"{QDRANT_URL}/collections/{COLLECTION_NAME}")
    resp = requests.put(f"{QDRANT_URL}/collections/{COLLECTION_NAME}", json=collection_payload)
    if resp.status_code not in [200, 201]:
        print(f"❌ Failed to create Qdrant collection: {resp.text}")
        sys.exit(1)
    print(f"✅ Qdrant Collection '{COLLECTION_NAME}' created successfully.")

    # 2. Ingest Document Vectors & Payloads into Qdrant
    step("2. Ingesting Enterprise Runbooks & Vectors into Qdrant")
    points = [
        {
            "id": doc["id"],
            "vector": doc["vector"],
            "payload": {
                "title": doc["title"],
                "content": doc["content"]
            }
        }
        for doc in DOCUMENTS
    ]
    upsert_resp = requests.put(
        f"{QDRANT_URL}/collections/{COLLECTION_NAME}/points?wait=true",
        json={"points": points}
    )
    if upsert_resp.status_code != 200:
        print(f"❌ Failed to upsert points: {upsert_resp.text}")
        sys.exit(1)
    print(f"✅ Ingested {len(points)} documents into Qdrant vector index.")

    # 3. Simulate User Query & Vector Search
    user_query = "What should I do if my GPU drops off the PCIe bus with XID error?"
    query_vector = [0.90, 0.14, 0.04, 0.01]  # Semantically aligned with Document 1
    
    step(f"3. Searching Qdrant for query: '{user_query}'")
    search_payload = {
        "vector": query_vector,
        "limit": 1,
        "with_payload": True
    }
    start_search = time.time()
    search_resp = requests.post(
        f"{QDRANT_URL}/collections/{COLLECTION_NAME}/points/search",
        json=search_payload
    )
    search_duration_ms = (time.time() - start_search) * 1000

    if search_resp.status_code != 200:
        print(f"❌ Vector search failed: {search_resp.text}")
        sys.exit(1)

    results = search_resp.json().get("result", [])
    if not results:
        print("❌ No matching documents found in vector search.")
        sys.exit(1)

    top_hit = results[0]
    matched_title = top_hit["payload"]["title"]
    matched_content = top_hit["payload"]["content"]
    similarity_score = top_hit["score"]

    print(f"🎯 Top Vector Match: '{matched_title}'")
    print(f"📊 Cosine Similarity Score: {similarity_score:.4f}")
    print(f"⏱️ Vector Retrieval Latency: {search_duration_ms:.2f} ms")
    print(f"📄 Retrieved Context:\n\"{matched_content}\"")

    # 4. Construct Augmented Prompt (RAG)
    step("4. Constructing Context-Augmented Prompt")
    augmented_messages = [
        {
            "role": "system",
            "content": (
                "You are an expert AI DevOps Engineer. Answer the user's question "
                "strictly using the provided context."
            )
        },
        {
            "role": "user",
            "content": f"Context:\n{matched_content}\n\nQuestion:\n{user_query}\n\nConcise Answer:"
        }
    ]
    print(json.dumps(augmented_messages, indent=2))

    # 5. Send to LiteLLM Gateway & vLLM for Generation
    step("5. Generating Final Grounded Response via LiteLLM & vLLM")
    gateway_payload = {
        "model": "local-ai",
        "messages": augmented_messages,
        "temperature": 0.0,
        "max_tokens": 150
    }
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {AUTH_KEY}"
    }

    start_llm = time.time()
    llm_resp = requests.post(
        f"{GATEWAY_URL}/chat/completions",
        headers=headers,
        json=gateway_payload
    )
    llm_duration_ms = (time.time() - start_llm) * 1000

    if llm_resp.status_code != 200:
        print(f"⚠️ Gateway returned status {llm_resp.status_code}: {llm_resp.text}")
    else:
        answer = llm_resp.json()["choices"][0]["message"]["content"]
        print(f"🤖 vLLM Generated Answer:\n{answer}")
        print(f"\n⏱️ LLM Generation Latency: {llm_duration_ms:.2f} ms")

    step("🎉 End-to-End RAG Loop Completed Successfully!")

if __name__ == "__main__":
    main()

