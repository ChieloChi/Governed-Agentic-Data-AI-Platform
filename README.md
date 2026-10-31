# Governed Agentic Data & AI Platform (GDP-AI) on AWS EKS

Production-grade, ephemeral AI & Data platform architecture on AWS EKS solving the **Enterprise LLM Hallucination Crisis** presented by Cleber de Lima (Director of Data, AI & Agentic Automation at Betsson Group) at Big Data London.

Demonstrates **Deterministic Text-to-Metrics** via an open-source semantic layer (**Cube.js**), **vLLM Inference** with PagedAttention, **LiteLLM Gateway**, **Redis Semantic Caching**, **Qdrant Vector DB**, and **NVIDIA DCGM Telemetry**.

---

## 🏛 Architecture: Governed Analytics + AI Serving

```
                                      [ Business User / Autonomous Agent ]
                                                       │
                                                       ▼
                                   ┌───────────────────────────────────────┐
                                   │       LiteLLM AI Gateway Proxy        │
                                   │  • Virtual Keys, Rate Limits (TPM)    │
                                   │  • Redis Semantic Prompt Caching      │
                                   └───────────────────┬───────────────────┘
                                                       │
                                                       ▼
                                   ┌───────────────────────────────────────┐
                                   │       Governed AI Agent (vLLM)        │
                                   │  • Translates question to Cube query  │
                                   │  • Receives verified, auditable facts │
                                   │  • Generates natural language summary │
                                   └───────────────────┬───────────────────┘
                                                       │
                                                       ▼
    ┌───────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                       THE OPEN-SOURCE SEMANTIC LAYER (Cube.js)                                    │
    │  • Single Source of Truth for KPIs as Code (YAML/JS in Git)                                       │
    │  • Pre-aggregations Engine (Cube Store OLAP cache)                                               │
    │  • Enforces Business Logic, Row-Level Security, and Deterministic SQL Generation                  │
    └──────────────────────────────────────────────┬────────────────────────────────────────────────────┘
                                                   │
                                                   │ Deterministic, mathematically sound SQL
                                                   ▼
    ┌───────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                       ENTERPRISE ANALYTICS DATASTORE (PostgreSQL)                                 │
    │  • Multi-tenant Schemas: Customers, Transactions, Gameplay Sessions, Revenue, Regulatory Regions  │
    └───────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 💡 The Core Problem Solved: Zero-Hallucination Analytics

> *"The hard part is not the model. It is trust... The worst outcome of this era is not a missing answer — it is a confident wrong one. That is why the semantic layer became the core of everything we designed: the single source of truth for people, and the context an agent needs to understand what you actually meant."*  
> — **Cleber de Lima**, Director of Data, AI, and Agentic Automation (Betsson Group)

### The Difference:
* **Naive LLM (Hallucination Trap):** An LLM tries to guess table names and write raw SQL. It invents formulas, confuses gross revenue with net revenue, and outputs confident falsehoods.
* **Governed Agentic Analytics (This Platform):** The AI Agent queries **Cube.js** using governed measures (`GameSessions.grossGamingRevenue`). Cube compiles the verified SQL formula approved by data engineers in Git. The LLM only formats verified facts, eliminating hallucination entirely.

---

## 🛠 Technology Stack

* **Infrastructure as Code:** Terraform (VPC, EKS 1.30, Spot GPU Node Group `g4dn.xlarge` with NVIDIA T4).
* **Enterprise Security:** AWS Secrets Manager + EKS OIDC + External Secrets Operator (IRSA).
* **Hardware Orchestration:** NVIDIA GPU Operator + DCGM Exporter (Port 9400) + GFD auto-labeling.
* **Serving Engine:** vLLM (`vllm/vllm-openai:v0.6.3`) with PagedAttention and FP16 precision.
* **Semantic Layer:** Cube Core (`cubejs/cube:v0.36.0`) with declarative JS metric schemas.
* **Analytics Datastore:** PostgreSQL 16 (Multi-tenant transactions, players, and game sessions).
* **Gateway & FinOps:** LiteLLM Proxy + Redis Semantic Prompt Cache.
* **Unstructured Vector RAG:** Qdrant Vector Database (HNSW indexing).

---

## 💰 Cost Breakdown for a 30-Minute Run

| Component | AWS Resource | Pricing Model | Est. Cost for 30 Mins |
| :--- | :--- | :--- | :--- |
| **Control Plane** | Amazon EKS Cluster | \$0.10/hour | **\$0.05** |
| **GPU Node** | `g4dn.xlarge` (NVIDIA T4) | Spot (~$0.16/hour) | **\$0.08** |
| **System Node** | `t3.medium` (4GB RAM) | Spot (~$0.015/hour) | **\$0.01** |
| **Secrets Manager** | AWS Secrets Manager | Pro-rated (Zero window) | **<\$0.01** |
| **Networking** | Direct Internet Gateway | No NAT GW fees | **\$0.00** |
| **Total** | | | **~$0.15 – $0.20** |

---

## 🚀 The 4-Step Operational Lifecycle

### 1. Provision Infrastructure & AWS Secrets Manager
```bash
./scripts/01-provision-eks.sh
```

### 2. Deploy Operators, Datastore, Cube Semantic Layer & AI Stack
```bash
./scripts/02-deploy-ai-stack.sh
```

### 3. Run Benchmarks, Governed Analytics & Live GPU Telemetry
```bash
./scripts/03-test-and-benchmark.sh
```
* Queries **Cube.js** for Sweden (SE) Gross Gaming Revenue and deposit volume.
* Feeds mathematically verified numbers into **vLLM** to generate an executive briefing with **zero hallucination**.
* Tests Redis semantic cache latency reduction (<10ms).
* Pulls live hardware metrics (VRAM, watts, temperature) from the **NVIDIA DCGM Exporter**.

### 4. Complete Teardown (Zero Lingering Cost)
```bash
./scripts/04-destroy-all.sh
```
Teardown destroys all AWS resources, Helm releases, and AWS Secrets Manager secrets simultaneously.
