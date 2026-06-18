# Routing Rules

Ці правила використовуються під час Run 1, щоб Codex розкладав inbox-файли по проектах і не створював зайві дублікати.

## Мовна політика

- Відповіді агента, фінальні звіти, draft snippets, patch-plans, MANIFEST prose і Markdown output files мають бути українською мовою.
- Не змінюй technical identifiers: paths, filenames, commands, env vars, Kubernetes objects, Jenkins credential IDs, product names, protocols, standards і canonical automation scope keys.
- У `Exact next apply prompt` залишай canonical keys англійською для сумісності з Run 2; пояснювальний prose пиши українською, якщо це безпечно для contract.

## TirasCloud GitOps / Platform

Primary target:

```text
C:\work\docs\projects\tirascloud-2\GITOPS_MIGRATION_RUNBOOK.md
C:\work\docs\projects\tirascloud-2\PLATFORM_OPERATIONS.md
```

Fact-check context:

```text
C:\work\ideal-octo-giggle\AGENTS.md
C:\work\ideal-octo-giggle\foundation
C:\work\ideal-octo-giggle\cluster
```

Route here:

- `Перенесення кластера Tiras Dev в GitOps.md`
- `Workflow побудови IaC-інфраструктури.md`
- `InfraCluster Review.md`
- `InfraFoundation Review.md`
- `helm-upgrade-playbook.md`
- `deployment-rollback-runbook.md`
- `Kubectl cheatsheet.md`
- `Kubeadm vs microk8s.md`
- `kubernetes-observability-logging-gitops-guide.md`
- Redis, MinIO, Percona матеріали, якщо вони описують platform services для GitOps/Kubernetes.

## TirasCloud-2 Application / CI/CD

Primary target:

```text
C:\work\docs\projects\tirascloud-2\CI_CD_PIPELINE.md
C:\work\docs\projects\tirascloud-2\BUILD_STRATEGY.md
C:\work\docs\projects\tirascloud-2\DEPENDENCY_MAP.md
```

Fact-check context:

```text
C:\work\TirasCloud-2\AGENTS.md
C:\work\TirasCloud-2\Jenkinsfile
C:\work\TirasCloud-2\modules
C:\work\TirasCloud-2\docker
```

Route here:

- `Runbook міграції TirasCloud (Dev).md`
- `Software supply chain security.md`
- build, deploy, Jenkins, image, SBOM, provenance, signing materials that map to TirasCloud-2.

## TirasCloud UDP Edge / Service Exposure

Primary target:

```text
C:\work\docs\projects\tirascloud-2\UDP_PAYLOAD_ROUTING_TIRASCLOUD_2.md
C:\work\docs\projects\tirascloud-2\DEPENDENCY_MAP.md
C:\work\docs\projects\tirascloud-2\PLATFORM_OPERATIONS.md
```

Index targets:

```text
C:\work\docs\projects\shared\_indexes\technology-map.md
C:\work\docs\projects\shared\_indexes\open-questions.md
```

Route here:

- Kubernetes service exposure notes for TirasCloud HTTP/HTTPS/WebSocket, UDP L4, `ClusterIP`, `NodePort`, `LoadBalancer`, MetalLB, Gateway API or Ingress boundaries.
- Device-facing UDP notes that mention `gateway`, `firegw`, `udpnew`, `fireudp`, firmware ports, `externalTrafficPolicy`, MikroTik NAT or edge IP/VIP contracts.
- Environment exposure boundaries for Dev/Stage/Prod when the note is about TirasCloud services, even if the filename is generic.

Do not route these notes to Service Center only because they mention Kubernetes, Ingress or Gateway API. Service Center routing applies only when the source explicitly discusses `SCNet`, `SCNode`, `SCInfrastructure`, LAS, VPN or Service Center docs.

## Service Center App / GitOps / Docs

Primary target:

```text
C:\work\docs\projects\Service Center\InfrastructureAndGitOps.md
C:\work\docs\projects\Service Center\LAS_PROTOCOL_GAPS.md
C:\work\docs\projects\Service Center\PlatformRunbooks.md
```

Promotion candidates:

```text
C:\work\SCDocs\SC_Infrastructure.md
C:\work\SCDocs\SCNet_Feature_Kubernetes_Runbook.md
C:\work\SCDocs\SC_VPN_Setup_Runbook.md
C:\work\SCDocs\SC_VPN_User_Guide.md
C:\work\SCDocs\minio-kubernetes-infrastructure-plan.md
C:\work\SCDocs\protocol.md
```

Fact-check context:

```text
C:\work\SCNet\docs
C:\work\SCNet\k8s
C:\work\SCNode\src
C:\work\SCInfrastructure\docs
C:\work\SCInfrastructure\apps
C:\work\SCInfrastructure\ci
C:\work\SCDocs
```

Route here:

- `SC_Infrastructure.md`
- `SC_Infrastructure_recommendations.md`
- Service Center Kubernetes, VPN, MinIO, observability, GitOps and CI/CD notes.
- LAS/protocol notes that should reconcile `SCNet`, `SCNode`, and `SCDocs\protocol.md`.

## Shared Security / Governance

Primary target:

```text
C:\work\docs\projects\shared\SecurityGovernance.md
C:\work\docs\projects\shared\AccessAndSecretsGovernance.md
```

Route here:

- `discovery-questionnaire (security).md`
- `NIST CIS OWASP підхід.md`
- `Research щодо Security & Access Policy.md`
- `Практичний blueprint для Access & Secrets Governance у невеликій або середній IT-компанії.md`
- `Без назви.md`
- `Без назви 1.md`
- NIST presentation, workshop, speaker speech and structure files.

## Shared Process Management

Primary target:

```text
C:\work\docs\projects\shared\JiraMethodology.md
```

Route here:

- `Методологія ведення Jira.md`

## Duplicate Handling

- If a same-name or same-topic document exists in `C:\work\SCDocs`, treat `SCDocs` as a promotion target, not an automatic write target.
- If `process` has a more complete version than `SCDocs`, prepare a merge proposal with source sections.
- If `SCDocs` has operationally reviewed content, preserve its operator wording and only suggest additions.
- If a file is unclear, route to `shared/triage-needed` and explain what context is missing.
