# Governed Agentic Data & AI Platform (GDP-AI) on Kubernetes (AWS EKS & Hybrid/Bare-Metal)

> 🚧 **Status: Work in Progress (WIP) / Active Development**  
> *This is an early-stage open-source project currently under active construction. Architecture drafts, Terraform modules, Helm templates, and component configurations are actively being developed, refined, and tested. None of the configurations are finalized or complete yet.*

An open-source, hybrid-ready AI & Data platform architecture being developed to solve the **Enterprise LLM Metric Hallucination Crisis** in mission-critical environments.

Demonstrates **Deterministic Text-to-Metrics** via an open-source semantic layer (**Cube.js & Cube Store**), **vLLM Inference** with PagedAttention, **LiteLLM Gateway**, **Redis Semantic Caching**, **Qdrant Vector DB**, and **NVIDIA DCGM Telemetry**.

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
                                   │  • HPA & PDB (minAvailable: 1)        │
                                   └───────────────────┬───────────────────┘
                                                       │
                                                       ▼
                                   ┌───────────────────────────────────────┐
                                   │       Governed AI Agent (vLLM)        │
                                   │  • PagedAttention & FP16 Precision    │
                                   │  • Model Cache PVC (Zero Redownloads) │
                                   │  • Translates questions to Cube query │
                                   └───────────────────┬───────────────────┘
                                                       │
                                                       ▼
    ┌───────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                       THE OPEN-SOURCE SEMANTIC LAYER (Cube.js)                                    │
    │  • Single Source of Truth for KPIs as Code (YAML/JS in Git)                                       │
    │  • Decoupled Architecture: Cube API (traffic) vs. Cube Refresh Worker (background rollups)        │
    │  • Enforces Business Logic, Row-Level Security, and Deterministic SQL Generation                  │
    └──────────────────┬────────────────────────────────────────────────────────┬───────────────────────┘
                       │                                                        │
          (OLAP Pre-Aggregations)                                  (Direct Mathematical SQL)
                       ▼                                                        ▼
    ┌──────────────────────────────────────────────┐       ┌────────────────────────────────────────────┐
    │       DISTRIBUTED CUBE STORE CLUSTER         │       │          ENTERPRISE DATASTORE              │
    │  • cubestore-router: Query Coordinator       │       │  • PostgreSQL 16 (In-Cluster with PVC)     │
    │  • cubestore-worker: StatefulSet + PVC cache │       │  • OR AWS Athena, AWS Redshift, Snowflake, │
    │  • Cold Storage: AWS S3 or MinIO Bucket      │       │    BigQuery, ClickHouse                    │
    └──────────────────────────────────────────────┘       └────────────────────────────────────────────┘
```

---

## 💡 The Core Problem Solved: Zero-Hallucination Analytics

> In enterprise agentic systems, the hardest challenge is not model serving—it is **mathematical trust and metric integrity**. When autonomous agents or LLMs attempt to generate SQL directly against raw production databases, they hallucinate calculations, misinterpret join cardinality, and output confidently incorrect figures. The semantic layer serves as the single source of truth for both humans and autonomous agents.

### The Difference:
* **Naive LLM (Hallucination Trap):** An LLM tries to guess table names and write raw SQL. It invents formulas, confuses gross revenue with net revenue, and outputs confident falsehoods.
* **Governed Agentic Analytics (This Platform):** The AI Agent queries **Cube.js** using governed measures (`GameSessions.grossGamingRevenue`). Cube compiles the verified SQL formula approved by data engineers in Git. The LLM only formats verified facts, eliminating hallucination entirely.

---

## 🛠 Technology Stack & Enterprise Features

* **Infrastructure as Code:** Enterprise Modular Terraform:
  * Centralized S3 remote state bootstrap (`bootstrap/`) with KMS CMK encryption & TLS 1.2+ policy.
  * Reusable modules (`modules/vpc`, `modules/security`, `modules/eks`, `modules/karpenter`, `modules/secrets`).
  * Isolated environments: `environments/dev/` (cost-optimized, direct IGW/single NAT, Spot instances) vs. `environments/prod/` (multi-AZ HA, KMS envelope encryption, dedicated database subnets).
* **Enterprise Security:**
  * **AWS Mode:** AWS Secrets Manager + EKS OIDC + External Secrets Operator (IRSA).
  * **Hybrid/Bare-Metal Mode:** HashiCorp Vault ClusterSecretStore toggle.
  * **Strict Linux Security Contexts:** Non-root UIDs (Postgres/Redis `999`, services `65510`), `allowPrivilegeEscalation: false`, `capabilities.drop: ["ALL"]`, `seccompProfile: RuntimeDefault`.
* **Autoscaling & FinOps (Karpenter v1.0):** Workload-aware, group-less EC2 Spot autoscaling. Dynamically provisions `g4dn` (T4) or `g5` (A10G) instances in <45s when vLLM requests GPU, and consolidates/terminates nodes to zero within 30s of idle time.
* **Hardware Orchestration:** NVIDIA GPU Operator + DCGM Exporter (Port 9400) + GFD auto-labeling.
* **Serving Engine:** vLLM (`vllm/vllm-openai:v0.6.3`) with PagedAttention and FP16 precision.
* **Semantic Layer:**
  * **Cube Core (`cubejs/cube:v0.36.0`):** Decoupled API and Refresh Worker deployments.
  * **Cube Store:** Distributed Rust OLAP acceleration engine (Router + Worker StatefulSet with PVCs).
  * **Hybrid Storage:** Dynamic export to Amazon S3 or self-hosted MinIO.
* **Analytics Datastores:**
  * In-cluster PostgreSQL 16 (with PVC and init schemas for players, transactions, game sessions).
  * External databases supported out-of-the-box: AWS Athena, AWS Redshift, Snowflake, BigQuery, ClickHouse.
* **Gateway & FinOps:** LiteLLM Proxy + Redis Semantic Prompt Cache + Virtual Keys + HPA.
* **Unstructured Vector RAG:** Qdrant Vector Database with persistent storage.
* **Kubernetes Resilience:** Full Startup, Readiness, and Liveness probes on all pods, PodDisruptionBudgets (`minAvailable: 1`), and HPAs.

---

## 💰 Cost Breakdown for a 30-Minute Ephemeral Run

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
* Queries **Cube.js** for Sweden (`SE`) Gross Gaming Revenue and deposit volume.
* Feeds mathematically verified numbers into **vLLM** to generate an executive briefing with **zero hallucination**.
* Tests Redis semantic cache latency reduction (<10ms).
* Pulls live hardware metrics (VRAM, watts, temperature) from the **NVIDIA DCGM Exporter**.

### 4. Complete Teardown (Zero Lingering Cost)
```bash
./scripts/04-destroy-all.sh
```
Teardown destroys all AWS resources, Helm releases, and AWS Secrets Manager secrets simultaneously.

---

## ⚙️ Configuration Matrix (`values.yaml`)

| Feature | Toggle Path | Options |
|---|---|---|
| **Cube Store OLAP Cache** | `cubeStore.enabled` | `false` (ephemeral/lightweight) \| `true` (multi-million row pre-aggregations) |
| **Secrets Backend** | `secretsManager.aws.enabled` / `vault.enabled` | AWS Secrets Manager (IRSA) vs. HashiCorp Vault |
| **Object Storage** | `objectStorage.s3.enabled` / `minio.enabled` | Amazon S3 vs. MinIO S3 API |
| **External Datastore** | `externalDatabase.enabled` | In-cluster Postgres vs. AWS Athena / Redshift / Snowflake |
| **Single Sign-On** | `keycloak.enabled` | `false` \| `true` (Keycloak IAM Realm) |
| **Autoscaling & PDB** | `cube.api.autoscaling.enabled`, `litellm.autoscaling.enabled` | Target CPU/Memory HPA + PDB minAvailable |
| **KEDA (Scale-to-Zero)** | `keda.enabled` | `false` (Standard HPA) \| `true` (Prometheus/Redis Event-driven scale-to-zero) |

---

## 📄 License
Apache 2.0. Open-source enterprise architecture for governed data & AI engineering.
