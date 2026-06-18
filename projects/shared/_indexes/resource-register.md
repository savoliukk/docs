# Реєстр ресурсів

Статус: канонічний індекс  
Обсяг: archived source materials з `process/` і canonical docs у `projects/`

Використовувати цей файл для обліку raw resources, generated artifacts і їхньої canonical documentation target. Не копіювати secrets або sensitive values із source files у цей register.

## Канонічні документи проєктів

| Ресурс | Канонічна ціль | Статус | Чутливість | Нотатки |
| --- | --- | --- | --- | --- |
| Нотатки міграції GitOps TirasCloud-2 | `projects/tirascloud-2/GITOPS_MIGRATION_RUNBOOK.md` | active | internal-only | Merge source files із sanitized repo-specific facts. |
| Health і smoke strategy TirasCloud-2 | `projects/tirascloud-2/HEALTH_AND_SMOKE_STRATEGY.md` | draft | internal-only | Probe decisions from GitOps/source-code review; needs developer confirmation for service-specific readiness contracts. |
| Нотатки platform operations TirasCloud-2 | `projects/tirascloud-2/PLATFORM_OPERATIONS.md` | active | internal-only | Day-to-day Kubernetes, GitOps, storage, logging і DB ops. |
| Entra/Arc/MicroK8s RBAC PoC TirasCloud-2 | `projects/tirascloud-2/ENTRA_ARC_MICROK8S_RBAC_POC.md` | active | sensitive-review-needed | Working runbook для Entra ID, Azure Arc, Azure RBAC, MicroK8s Guard webhook, audit і rollback evidence. |
| Service traffic і UDP routing TirasCloud-2 | `projects/tirascloud-2/SERVICE_TRAFFIC_ROUTING_TIRASCLOUD_2.md` | active | internal-only | Єдина карта traffic routing: device-facing UDP L4, HTTP/WS ingress, TMQ channels, stateful/external dependencies, NodePort/MetalLB target і ClusterIP/internal boundary. |
| Нотатки RocksDB runtime smoke TirasCloud-2 | `projects/tirascloud-2/ROCKSDB_RUNTIME_SMOKE_RUNBOOK.md` | active | sensitive-review-needed | Script містить credential-like defaults; споживати лише sanitized behavior. |
| Нотатки інфраструктури Service Center | `projects/Service Center/InfrastructureAndGitOps.md` | active | sensitive-review-needed | Не promote до `SCDocs` у цьому run. |
| Runbook-нотатки Service Center | `projects/Service Center/PlatformRunbooks.md` | active | internal-only | Team-ready promotion потребує окремого approved run. |
| Security discovery questionnaire | `projects/shared/SECURITY_DISCOVERY_QUESTIONNAIRE.md` | active | internal-only | Sanitized question-only template; source answers intentionally not copied. |
| Microsoft-first security pilot | `projects/shared/MICROSOFT_SECURITY_STACK_PILOT.md` | active | sensitive-review-needed | Sanitized trial-first decision pack для Entra/PIM, Private Access, Intune/Defender, Sentinel, GitHub security, Arc/Defender for Containers і Key Vault optional path. |

## Shared resources

| Source resource | Канонічна ціль | Статус | Чутливість | Дія |
| --- | --- | --- | --- | --- |
| `archive/2026-05-11/kubernetes-observability-logging-gitops-guide.md` | `projects/shared/KubernetesObservabilityLoggingGitOps.md` | merged summary | internal-only | Зберігати як source reference. |
| Redis research files у `archive/2026-05-11/` | `projects/shared/RedisOperatingModel.md` | merged summary | internal-only | Потребує final Redis mode decision: Sentinel або Cluster. |
| `archive/2026-05-11/minio-kubernetes-infrastructure-plan.md` | `projects/shared/MinIOKubernetesInfrastructure.md` | merged summary | internal-only | Product-specific docs мають посилатися сюди. |
| MicroK8s security audit і Rancher/NeuVector files у `archive/2026-05-11/` | `projects/shared/KubernetesSecurityHardening.md` | merged summary | sensitive-review-needed | Live-state facts потребують fresh verification перед team use. |
| `archive/2026-05-11/Software supply chain security.md` | `projects/shared/SoftwareSupplyChainSecurity.md` | merged summary | normal | Shared CI/CD security baseline. |
| `archive/2026-05-11/LLM_Code_Sensitive_Data_SOP_UA.md` | `projects/shared/SoftwareSupplyChainSecurity.md` | referenced | sensitive-review-needed | Використовувати як AI/LLM safe-use SOP source; не копіювати incident/vendor details wholesale. |
| `archive/2026-05-11/Workflow побудови IaC-інфраструктури.md` | `projects/shared/IaCInfrastructureWorkflow.md` | merged summary | internal-only | Generic IaC/GitOps workflow. |
| `archive/2026-05-11/Без назви.md`, `archive/2026-05-11/Без назви 1.md` | `projects/shared/PrivilegedAccessForLegacySystems.md` | merged summary | normal | Варіанти legacy shared-password access. |
| NIST CSF / CIS / OWASP Markdown sources | `projects/shared/SecurityGovernance.md` | linked summary | normal | Використовувати як workshop/reference material. |
| NIST PDF/PPTX artifacts | цей register | reference only | normal | Не копіювати великі chunks в operational docs. |
| SUSE/Rancher/NeuVector PNG | цей register | reference only | internal-only | Лише image artifact. |
| `archive/2026-05-13/KUBERNETES_SECURITY_MIND_MAP v2.md` | `projects/shared/KUBERNETES_SECURITY_MIND_MAP.md` | merged summary | sensitive-review-needed | Primary source для оновленої security map: Kubernetes як один шар ширшої безпеки доступів, GitHub, AWS, admin panels, devices і restore. |
| `archive/2026-05-13/KUBERNETES_SECURITY_MIND_MAP v1.md` | `projects/shared/KUBERNETES_SECURITY_MIND_MAP.md` | duplicate/reference | sensitive-review-needed | Використано лише non-conflicting gaps: atoms, coverage matrix, shortlist criteria. |
| `archive/2026-05-13/security_tool_decision_matrix_v0_1.xlsx` | `projects/shared/KUBERNETES_SECURITY_MIND_MAP.md` | resource artifact | internal-only | XLSX artifact із sheets `00_ReadMe`, `01_Master_Matrix`, `02_Core_Coverage`, `03_Bonus_Coverage`, `04_Scoring_Guide`, `05_Sources`; рядки не копіювалися wholesale. |
| Kubernetes security mind map для `INFRA-17` | `projects/shared/KUBERNETES_SECURITY_MIND_MAP.md` | active canonical | internal-only | Оновлена карта: company security foundation, Kubernetes/non-Kubernetes boundary, baseline checklist, atoms і candidate coverage для tool comparison. |
| `archive/2026-05-14/Discovery questionnaire (security).md` | `projects/shared/SECURITY_DISCOVERY_QUESTIONNAIRE.md`, `projects/shared/SecurityGovernance.md` | sanitized template created | sensitive-review-needed | Перенесено тільки question-only content; answer column і sensitive values intentionally omitted. Archived після approved cleanup run. |
| `archive/2026-05-14/Мінімальний стек безпеки для малої ІТ‑компанії без окремої security‑команди.md` | `projects/shared/SecurityGovernance.md`, `projects/shared/AccessAndSecretsGovernance.md` | merged summary | sensitive-review-needed | Tool shortlist і pilot framing merged; vendor pricing/licensing і citation markers need verification. Archived після approved cleanup run. |
| `archive/2026-05-14/Як правильно відкривати Kubernetes-сервіси - назовні HTTP через Ingress, UDP через L4, внутрішнє — через ClusterIP.md` | `projects/tirascloud-2/SERVICE_TRAFFIC_ROUTING_TIRASCLOUD_2.md`, `projects/tirascloud-2/PLATFORM_OPERATIONS.md` | merged summary | internal-only | HTTP/WS vs UDP L4 vs ClusterIP boundary merged; private IPs sanitized to placeholders. Archived після approved cleanup run. |
| `archive/2026-05-14/Дослідження безпеки й керування доступами для малої ІТ-компанії без окремої security-команди.md` | `projects/shared/SecurityGovernance.md`, `projects/shared/AccessAndSecretsGovernance.md` | merged compact summary | sensitive-review-needed | Policy packet, security champion model і vendor due-diligence checklist merged; raw citations, pricing assumptions і source details не copied. |
| `archive/2026-05-14/Реальні впровадження безпеки для малої ІТ-компанії з профілем, близьким до вашого.md` | `projects/shared/SecurityGovernance.md`, `projects/shared/AccessAndSecretsGovernance.md` | supporting research reference | sensitive-review-needed | Використано як sanitized evidence для pilot/ownership/due-diligence framing; vendor claims потребують verification. |
| `archive/2026-05-14/Аналітичний звіт про реальні відгуки користувачів щодо вибраних засобів безпеки.md` | `projects/shared/SecurityGovernance.md`, `projects/shared/AccessAndSecretsGovernance.md` | reference only | sensitive-review-needed | User-feedback signals використано тільки як context; community quotes, raw links і non-durable citations не переносились. |
| `archive/2026-05-25/Microsoft Security Stack Research.md` | `projects/shared/MICROSOFT_SECURITY_STACK_PILOT.md`, `projects/shared/SecurityGovernance.md`, `projects/shared/AccessAndSecretsGovernance.md`, `projects/shared/SoftwareSupplyChainSecurity.md`, `projects/shared/KubernetesSecurityHardening.md` | merged sanitized summary | sensitive-review-needed | Primary source для Microsoft-first pilot; pricing, licensing, public cases, community anecdotes і citation markers потребують verification. |
| `archive/2026-05-25/deep-research-report (2).md` | `projects/shared/MICROSOFT_SECURITY_STACK_PILOT.md` | supporting duplicate/reference | sensitive-review-needed | Використано як supporting reference для product fit, roadmap, evidence pack і buy/no-buy framing. |
| `archive/2026-05-25/deep-research-report (1).md` | `projects/shared/MICROSOFT_SECURITY_STACK_PILOT.md` | older duplicate/reference | sensitive-review-needed | Старіший duplicate/reference; не копіювати citation markers wholesale. |

## Кандидати для archive

Архівувати consumed source files тільки в окремому approved cleanup/archive run. Source files із cleanup run 2026-05-14 перенесені в `archive/2026-05-14/`.

| Кандидат | Причина | Майбутній шлях |
| --- | --- | --- |
| Duplicate Jira/Kubectl notes | Уже merged у shared docs | `archive/2026-05-11/` |
| Generated NIST presentation artifacts | Source/reference artifacts, не operational docs | `archive/2026-05-11/` |
| Large raw research files після merge | Тримати canonical docs стислими | `archive/2026-05-11/` |

