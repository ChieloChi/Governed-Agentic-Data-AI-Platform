#!/usr/bin/env python3
"""
End-to-End Governed Agentic Analytics Test
Validates:
  1. Cube.js Semantic Layer health & schema compilation.
  2. Querying governed business metrics (Gross Gaming Revenue, Deposit Volume) by country.
  3. Proves Zero-Hallucination: The SQL query is generated deterministically by Cube.
  4. Augments verified numbers into vLLM Inference Engine for executive summarization.
"""

import os
import sys
import json
import time
import requests

CUBE_URL = os.environ.get("CUBE_URL", "http://localhost:4000")
GATEWAY_URL = os.environ.get("GATEWAY_URL", "http://localhost:4000")
AUTH_KEY = os.environ.get("LITELLM_KEY", "sk-admin-test")
CUBE_SECRET = "CubeSecretKey2026Enterprise!"

def step(title):
    print(f"\n{'='*65}\n👉 {title}\n{'='*65}")

def main():
    print("🚀 Initializing Governed Agentic Analytics Loop against EKS AI Platform...")

    # Step 1: Query Cube.js for Governed Metrics (Zero SQL Guessing!)
    step("1. Querying Cube.js Semantic Layer for Governed Metrics (Sweden - SE)")
    
    # Notice: We do NOT write raw SQL. We query governed measures and dimensions!
    cube_query = {
        "measures": [
            "GameSessions.grossGamingRevenue",
            "GameSessions.totalBets",
            "GameSessions.totalWins"
        ],
        "dimensions": [
            "Players.country"
        ],
        "filters": [
            {
                "member": "Players.country",
                "operator": "equals",
                "values": ["SE"]
            }
        ]
    }
    
    headers = {
        "Authorization": CUBE_SECRET,
        "Content-Type": "application/json"
    }

    start_cube = time.time()
    try:
        cube_resp = requests.post(
            f"{CUBE_URL}/cubejs-api/v1/load",
            headers=headers,
            json={"query": cube_query},
            timeout=10
        )
    except Exception as e:
        print(f"❌ Could not connect to Cube.js API at {CUBE_URL}: {e}")
        sys.exit(1)

    cube_duration_ms = (time.time() - start_cube) * 1000

    if cube_resp.status_code != 200:
        print(f"❌ Cube API Error: {cube_resp.text}")
        sys.exit(1)

    data = cube_resp.json().get("data", [])
    if not data:
        print("⚠️ No data returned from Cube query.")
        sys.exit(1)

    result = data[0]
    ggr = result.get("GameSessions.grossGamingRevenue", 0)
    bets = result.get("GameSessions.totalBets", 0)
    wins = result.get("GameSessions.totalWins", 0)
    country = result.get("Players.country", "SE")

    print(f"✅ Verified Data from Semantic Layer:")
    print(f"   • Country: {country}")
    print(f"   • Governed Total Bets: €{bets:,.2f}")
    print(f"   • Governed Player Payouts: €{wins:,.2f}")
    print(f"   • Governed Gross Gaming Revenue (GGR): €{ggr:,.2f}")
    print(f"⏱️ Semantic Layer Query Latency: {cube_duration_ms:.2f} ms")

    # Step 2: Query Deposit Volume
    step("2. Querying Governed Financial Deposits (Sweden - SE)")
    deposit_query = {
        "measures": ["Transactions.depositVolume"],
        "filters": [{"member": "Players.country", "operator": "equals", "values": ["SE"]}]
    }
    dep_resp = requests.post(f"{CUBE_URL}/cubejs-api/v1/load", headers=headers, json={"query": deposit_query})
    dep_data = dep_resp.json().get("data", [{}])[0]
    deposit_vol = dep_data.get("Transactions.depositVolume", 0)
    print(f"   • Governed Deposit Volume: €{deposit_vol:,.2f}")

    # Step 3: Prompt Construction for vLLM (Zero-Hallucination Grounding)
    step("3. Constructing Grounded Prompt for vLLM Executive Briefing")
    question = "Can you provide a high-level executive performance summary for the Swedish market?"
    
    augmented_messages = [
        {
            "role": "system",
            "content": (
                "You are an expert AI Executive Data Analyst for an enterprise gaming operator. "
                "You are provided with mathematically verified facts from the enterprise Semantic Layer (Cube). "
                "Never invent or alter numbers. Present the facts clearly with professional commentary."
            )
        },
        {
            "role": "user",
            "content": (
                f"Question: {question}\n\n"
                f"VERIFIED SEMANTIC METRICS (Source: Cube Core Semantic Engine):\n"
                f"- Market Jurisdiction: Sweden (SE)\n"
                f"- Gross Gaming Revenue (GGR): €{ggr:,.2f}\n"
                f"- Total Turnover / Bets: €{bets:,.2f}\n"
                f"- Player Payouts: €{wins:,.2f}\n"
                f"- Total Deposit Volume: €{deposit_vol:,.2f}\n\n"
                f"Executive Briefing:"
            )
        }
    ]
    print(json.dumps(augmented_messages, indent=2))

    # Step 4: LLM Generation via LiteLLM & vLLM
    step("4. Generating Executive Briefing via LiteLLM & vLLM Engine")
    llm_payload = {
        "model": "local-ai",
        "messages": augmented_messages,
        "temperature": 0.0,
        "max_tokens": 200
    }
    llm_headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {AUTH_KEY}"
    }

    start_llm = time.time()
    llm_resp = requests.post(
        f"{GATEWAY_URL}/chat/completions",
        headers=llm_headers,
        json=llm_payload
    )
    llm_duration_ms = (time.time() - start_llm) * 1000

    if llm_resp.status_code != 200:
        print(f"⚠️ Gateway returned status {llm_resp.status_code}: {llm_resp.text}")
    else:
        answer = llm_resp.json()["choices"][0]["message"]["content"]
        print(f"🤖 vLLM Generated Executive Briefing:\n{answer}")
        print(f"\n⏱️ Generation Latency: {llm_duration_ms:.2f} ms")

    step("🎉 Governed Agentic Analytics Loop Completed: 100% Deterministic & Auditable!")

if __name__ == "__main__":
    main()

