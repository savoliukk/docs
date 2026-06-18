# Карта проєктів

Статус: канонічний індекс  
Призначення: швидка навігація за project і ownership boundary.

## TirasCloud-2

| Зона | Канонічні документи | Нотатки |
| --- | --- | --- |
| CI/CD | `projects/tirascloud-2/CI_CD_PIPELINE.md`, `projects/tirascloud-2/BUILD_STRATEGY.md`, `projects/tirascloud-2/CI_CD_INTEGRATION_CHECKLIST.md` | Jenkins, image build, GitOps tag update, Argo CD verification. |
| GitOps migration | `projects/tirascloud-2/GITOPS_MIGRATION_RUNBOOK.md` | Dev migration flow і repo boundary. |
| Platform operations | `projects/tirascloud-2/PLATFORM_OPERATIONS.md` | Kubernetes checks, Helm, rollback, Redis, MinIO, observability, DB operators. |
| Security/access PoC | `projects/tirascloud-2/ENTRA_ARC_MICROK8S_RBAC_POC.md` | Entra ID, Azure Arc, Azure RBAC, MicroK8s Guard webhook, Viewer/Admin verification, audit і rollback для Dev cluster access. |
| Health і smoke | `projects/tirascloud-2/HEALTH_AND_SMOKE_STRATEGY.md` | Readiness/liveness probe policy, service smoke alternatives і питання до dev team. |
| Runtime dependencies | `projects/tirascloud-2/DEPENDENCY_MAP.md` | Service, port, protocol і external dependency map. |
| Service traffic / UDP edge | `projects/tirascloud-2/SERVICE_TRAFFIC_ROUTING_TIRASCLOUD_2.md`, `projects/tirascloud-2/PLATFORM_OPERATIONS.md` | Device-facing L4 routing, bootstrap/worker ports, Dev NodePort, Етап/Prod MetalLB target і ClusterIP/internal boundary. |
| RocksDB | `projects/tirascloud-2/ROCKSDB_NATIVE_RUNTIME_BLOCKER.md`, `projects/tirascloud-2/ROCKSDB_RUNTIME_SMOKE_RUNBOOK.md` | Native runtime compatibility і safe post-deploy smoke. |

## Service Center

| Зона | Канонічні документи | Нотатки |
| --- | --- | --- |
| Product roadmap | `projects/Service Center/Roadmap.md` | MVP phases, platform hardening і product gaps. |
| Dependency map | `projects/Service Center/DetailedDependencyMap.md` | Runtime, build, data і test dependencies. |
| Infrastructure/GitOps | `projects/Service Center/InfrastructureAndGitOps.md` | Feature contour, Jenkins, Argo CD, secrets debt. |
| Platform runbooks | `projects/Service Center/PlatformRunbooks.md` | Operator index і promotion checklist. |
| LAS protocol gaps | `projects/Service Center/LAS_PROTOCOL_GAPS.md` | Contract drift і protocol cleanup. |

## Shared

| Зона | Канонічні документи | Нотатки |
| --- | --- | --- |
| Security discovery | `projects/shared/SECURITY_DISCOVERY_QUESTIONNAIRE.md` | Sanitized question-only intake template; source answers не copied. |
| Security governance | `projects/shared/SecurityGovernance.md` | NIST/CIS/OWASP approach, minimal security stack, pilot framing і workshop references. |
| Microsoft security pilot | `projects/shared/MICROSOFT_SECURITY_STACK_PILOT.md` | Microsoft-first trial-first decision pack для Entra/PIM, Private Access, Intune/Defender, Sentinel, GitHub security, Arc/Defender for Containers і Key Vault optional path. |
| Access and secrets | `projects/shared/AccessAndSecretsGovernance.md` | Human, machine, runtime, legacy shared access і Sealed Secrets як approved Kubernetes runtime secret workflow. |
| Kubernetes operations | `projects/shared/KubernetesOperationsCheatsheet.md` | Щоденні безпечні commands. |
| Kubernetes security map | `projects/shared/KUBERNETES_SECURITY_MIND_MAP.md` | Карта company security foundation + Kubernetes controls: identity/MFA, password vault, GitHub, AWS, admin panels, devices, restore, atoms і coverage matrix для `INFRA-17`. |
| Kubernetes security | `projects/shared/KubernetesSecurityHardening.md` | RBAC, audit, policy, runtime security, Sealed Secrets, admin panel/GitHub guardrails і Rancher/NeuVector evaluation. |
| Observability | `projects/shared/KubernetesObservabilityLoggingGitOps.md` | Filebeat, Logstash, Elasticsearch, Kibana і Coroot baseline. |
| Redis | `projects/shared/RedisOperatingModel.md` | Redis/Valkey placement і operating choices. |
| MinIO | `projects/shared/MinIOKubernetesInfrastructure.md` | Tenant, bucket, user і policy model. |
| Supply chain | `projects/shared/SoftwareSupplyChainSecurity.md` | SBOM, scanning, signing, provenance і safe LLM usage. |
| IaC workflow | `projects/shared/IaCInfrastructureWorkflow.md` | Infra repo workflow від discovery до GitOps rollout. |
| Jira | `projects/shared/JiraMethodology.md` | Statuses, labels і task shape. |
| Legacy privileged access | `projects/shared/PrivilegedAccessForLegacySystems.md` | PAM, proxy, ZTNA і shared-password containment. |

## Майбутні зони

| Зона | Рішення | Нотатки |
| --- | --- | --- |
| `archive/` | active archive zone | Оброблені source files зберігаються в `archive/{YYYY-MM-DD}/` після approved apply/archive cleanup run. |
| `career/` | approved for later creation | Extract portfolio і career artifacts пізніше, не в цьому apply run. |

