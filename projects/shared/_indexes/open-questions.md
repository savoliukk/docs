# Відкриті питання

Статус: канонічний індекс  
Призначення: відстежувати unresolved decisions, які впливають на docs, platform work або promotion.

## Рішення, закриті останнім apply scope

| Питання                                                | Рішення                                                |
| ------------------------------------------------------- | ------------------------------------------------------- |
| Створити `archive/` пізніше і перемістити processed files? | Так, але лише в окремому cleanup run. |
| Створити `career/` пізніше для portfolio/career extraction? | Так, але не в цьому apply run. |
| Затверджений Kubernetes secret workflow? | Sealed Secrets. |
| Redis target після Dev? | Sentinel або Cluster; exact mode ще треба вибрати. |
| Promote Service Center docs до `SCDocs` зараз? | Ні. Використовувати окремий approved promotion run. |

## Потребує перевірки

| Тема | Питання | Кандидат-власник | Цільовий документ |
| --- | --- | --- | --- |
| MicroK8s RBAC | Чи API server досі використовує `AlwaysAllow`, чи RBAC уже enabled? | Platform owner | `KubernetesSecurityHardening.md` |
| API exposure | Чи Kubernetes API reachable з untrusted networks? | Platform owner | `KubernetesSecurityHardening.md` |
| Audit logs | Чи enabled Kubernetes audit policy і audit log shipping? | Platform owner | `KubernetesSecurityHardening.md` |
| NetworkPolicy | Чи default-deny active в app namespaces? | Platform owner | `KubernetesSecurityHardening.md` |
| Sealed Secrets | Чи runtime secrets фактично представлені як SealedSecrets у GitOps? | DevOps | `AccessAndSecretsGovernance.md` |
| Redis | Яка target прийнята після Dev: Sentinel чи Cluster? | Platform + app owners | `RedisOperatingModel.md` |
| RocksDB | Який Node/glibc/RocksDB runtime прийнятий для affected services? | TirasCloud owner | `ROCKSDB_RUNTIME_SMOKE_RUNBOOK.md` |
| TirasCloud UDP | Який external edge IP/VIP використовується для кожного environment? | Network + platform owner | TirasCloud UDP docs |
| Service Center SCNode | Чи SCNode є частиною `scnet-feature`, окремим LAS app або later contour? | Service Center owner | `InfrastructureAndGitOps.md` |
| Service Center smoke | Які smoke tests mandatory після кожного feature deploy? | Service Center owner | `PlatformRunbooks.md` |
| SCDocs promotion | Які exact `SCDocs` files allowed у promotion run? | Docs owner | future prompt |
| LLM tools | Які LLM tools approved для company-sensitive code і docs? | Security / engineering | `SoftwareSupplyChainSecurity.md` |
| Access lifecycle owner | Хто owns joiner/mover/leaver checklist і підтверджує відкликання production/GitHub/AWS/VPN/admin panel доступів? | Security / IT owner | `KUBERNETES_SECURITY_MIND_MAP.md` |
| GitHub hardening | Чи увімкнені organization 2FA, branch protection, required review/status checks, CODEOWNERS, secret scanning і Dependabot alerts? | Engineering owner | `KUBERNETES_SECURITY_MIND_MAP.md` |
| AWS audit baseline | Чи CloudTrail увімкнений як процес, має protected retention і usable query path? | Platform owner | `KUBERNETES_SECURITY_MIND_MAP.md` |
| Admin panel access | Які Jenkins/Argo CD/Grafana/Kibana/MinIO/RabbitMQ endpoints public/private і чи закриті вони SSO/MFA або private access? | Platform owner | `KUBERNETES_SECURITY_MIND_MAP.md` |
| Device baseline | Який мінімальний device policy потрібен для admin access: inventory, disk encryption, screen lock, MDM, remote wipe? | IT owner | `KUBERNETES_SECURITY_MIND_MAP.md` |
| Restore evidence | Які systems мають restore drill evidence: critical DB/data, Kubernetes objects, Sealed Secrets key, GitHub/docs/password vault backups? | Platform + app owners | `KUBERNETES_SECURITY_MIND_MAP.md` |
| Incident mini-runbooks | Хто готує короткі runbooks для account compromise, lost laptop, secret leak, GitHub compromise і ransomware? | Security / operations | `KUBERNETES_SECURITY_MIND_MAP.md` |
| Kubernetes security baseline | Який stack затверджуємо для `INFRA-17`: lightweight native baseline, Rancher+NeuVector pilot, Entra/Azure Arc access model або комбінований підхід? | Tech lead + Platform owner | `KUBERNETES_SECURITY_MIND_MAP.md` |
| Kubernetes IdP | Який IdP є source of truth для Kubernetes human access: Entra, Keycloak, LDAP/AD або інший? | Tech lead + Security | `KUBERNETES_SECURITY_MIND_MAP.md` |
| Kubernetes policy engine | Що обираємо як primary policy-as-code layer: Kyverno, Gatekeeper або тільки native `ValidatingAdmissionPolicy` для narrow guardrails? | Platform owner | `KUBERNETES_SECURITY_MIND_MAP.md` |
| Kubernetes scanner/runtime | Який перший low-overhead scanner/runtime pilot: Trivy Operator, Kubescape, NeuVector, Falco або Tetragon? | Platform owner | `KUBERNETES_SECURITY_MIND_MAP.md` |
| Human password vault | Який password manager використовується для human/shared secrets: Passbolt CE, Vaultwarden, Psono CE або інший approved option? | Security / IT owner | `AccessAndSecretsGovernance.md` |
| Security stack pilot | Який перший stack пілотувати для 5-7 людей: Microsoft-first, JumpCloud-neutral, Google-first або selected DevOps-heavy components? | Security / IT owner | `SecurityGovernance.md` |
| Microsoft-first pilot scope | Чи затверджений narrow pilot scope: 5-10 users, limited admin devices, selected repos, one non-prod cluster, one AWS dev/sandbox account і selected admin panels? | Security / IT owner | `MICROSOFT_SECURITY_STACK_PILOT.md` |
| Microsoft pricing/licensing/trials | Які Entra, Intune, Defender, Sentinel, Arc, Key Vault і GitHub security pricing/trial assumptions підтверджені офіційними quote/billing джерелами? | Security / Finance | `MICROSOFT_SECURITY_STACK_PILOT.md` |
| Entra Private Access fit | Чи Entra Private Access стабільно закриває Jenkins/Argo CD/Grafana/Kibana/MinIO/RabbitMQ admin panels без unacceptable client/protocol/device friction? | Platform + Security | `MICROSOFT_SECURITY_STACK_PILOT.md`, `AccessAndSecretsGovernance.md` |
| Intune / BYOD admin devices | Чи legal/support model дозволяє Intune enrollment або compliant-device requirement для admin/BYOD/contractor endpoints? | IT owner | `MICROSOFT_SECURITY_STACK_PILOT.md`, `AccessAndSecretsGovernance.md` |
| Sentinel cost/noise | Який реальний ingestion cost, noise profile і detection owner для вузького Sentinel evidence scope? | Security / Platform owner | `MICROSOFT_SECURITY_STACK_PILOT.md` |
| GHAS billing/noise | Який active committer billing impact і false-positive profile для GitHub Secret Protection / Code Security на selected private repos? | Engineering owner | `MICROSOFT_SECURITY_STACK_PILOT.md`, `SoftwareSupplyChainSecurity.md` |
| Arc/MicroK8s validation | Чи Azure Arc-enabled Kubernetes і Defender for Containers стабільні та корисні на одному actual non-prod MicroK8s/self-hosted cluster? | Platform owner | `MICROSOFT_SECURITY_STACK_PILOT.md`, `KubernetesSecurityHardening.md` |
| TirasCloud Arc RBAC Viewer/Admin | Чи `TC-K8S-Viewers` і `TC-K8S-ClusterAdmins` проходять заплановані allow/deny тести через `az connectedk8s proxy`? | Platform owner | `ENTRA_ARC_MICROK8S_RBAC_POC.md` |
| TirasCloud Arc RBAC revoke | Чи видалення Viewer role assignment реально дає forbidden після propagation і це зафіксовано як evidence? | Platform owner | `ENTRA_ARC_MICROK8S_RBAC_POC.md` |
| TirasCloud Kubernetes audit evidence | Чи MicroK8s API audit logs увімкнені, доставляються Filebeat у Kibana `logs-k8s-*` і показують denied Viewer requests? | Platform owner | `ENTRA_ARC_MICROK8S_RBAC_POC.md`, `KubernetesSecurityHardening.md` |
| TirasCloud MicroK8s CA | Який production-ready CA/certificate path замінить temporary `insecure-skip-tls-verify=true` у PoC kubeconfig? | Platform owner | `ENTRA_ARC_MICROK8S_RBAC_POC.md` |
| TirasCloud Arc Guard certificates | Хто owns refresh/rotation Guard webhook certificate files, copied from `azure-arc-guard-manifests`, before expiry? | Platform owner | `ENTRA_ARC_MICROK8S_RBAC_POC.md` |
| Key Vault / CSI rotation | Чи Azure Key Vault / CSI / Secret Store retrieval і rotation працюють краще за поточний Sealed Secrets path для selected non-prod workload? | Platform + Security | `MICROSOFT_SECURITY_STACK_PILOT.md`, `AccessAndSecretsGovernance.md` |
| Defender DevOps / Jenkins limitation | Чи Defender for Cloud DevOps security дає enough value при Jenkins як main CI, або Jenkins треба покривати тільки pipeline-native scanners/SARIF/CLI? | Engineering owner | `MICROSOFT_SECURITY_STACK_PILOT.md`, `SoftwareSupplyChainSecurity.md` |
| Vendor pricing/licensing | Які публічні ціни, seat limits, trial limits і sales-quote моделі підтверджені офіційними джерелами для shortlisted tools? | Security / Finance | `SecurityGovernance.md`, `AccessAndSecretsGovernance.md` |
| Vendor due diligence | Які відповіді постачальників підтверджують SCIM/offboarding, audit export, break-glass, outage behavior, DR і small-team support model? | Security / IT owner | `AccessAndSecretsGovernance.md` |
| Non-durable citations | Які citation markers із source research треба замінити на durable official URLs перед team-ready publication? | Docs owner | `SecurityGovernance.md`, `AccessAndSecretsGovernance.md` |
| Public case claims | Які vendor/public case claims можна використовувати як evidence після перевірки, а які лишаються тільки research context? | Security / Docs owner | `SecurityGovernance.md` |
| Private access layer | Який tool або pattern затверджений для Jenkins/Argo CD/Grafana/Kibana/MinIO/RabbitMQ/DB admin panels: Cloudflare Access, Tailscale, VPN/private ingress або комбінація? | Platform + Security | `AccessAndSecretsGovernance.md` |
| Security ownership | Хто затверджує мінімальний policy packet і owns security champion model після pilot? | Security / IT owner | `SecurityGovernance.md` |
| TirasCloud UDP MetalLB | Який MetalLB pool, VIP ownership і annotation/config syntax затверджені для Dev/Етап/Prod manifests? | Network + platform owner | `SERVICE_TRAFFIC_ROUTING_TIRASCLOUD_2.md`, `PLATFORM_OPERATIONS.md` |
| TirasCloud UDPRoute | Який поточний maturity/status `UDPRoute` у Gateway API, і чи дозволено його розглядати для production UDP? | Platform owner | `SERVICE_TRAFFIC_ROUTING_TIRASCLOUD_2.md` |
| TirasCloud source IP | Які MikroTik/cloud LB правила гарантують відсутність зайвого SNAT/Masquerade для inbound device UDP traffic? | Network owner | `SERVICE_TRAFFIC_ROUTING_TIRASCLOUD_2.md` |


