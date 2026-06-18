# Security hardening Kubernetes

Статус: особистий робочий документ  
Джерела: MicroK8s security audit, Rancher/NeuVector research, Kubernetes security notes у `archive/2026-05-11/`, Microsoft-first pilot research in `archive/2026-05-25/`, `KUBERNETES_SECURITY_MIND_MAP.md`

## Призначення

Цей документ визначає практичний шлях security hardening для MicroK8s/Kubernetes environments, які використовує мала DevOps/IT команда.

Це не compliance certificate. Live-state facts треба свіжо перевірити перед використанням цього документа як team-ready evidence.

## Executive posture

Вважати cluster production-ready лише тоді, коли перевірені ці controls:

- Kubernetes RBAC is enforced;
- external API exposure is reviewed;
- SSO/MFA or another approved identity path exists;
- break-glass access is documented;
- Sealed Secrets workflow is actually used for GitOps secrets;
- audit logs are enabled and retained;
- NetworkPolicy default-deny is in place where appropriate;
- backup and restore drills are proven;
- CI/CD and GitOps credentials are least-privilege;
- storage and stateful workloads have an explicit DR model.

## Scope guardrail

З approved security mind map від 2026-05-13: Kubernetes hardening не має стартувати з важкого security bundle, доки не закриті базові risks навколо identity, MFA, password vault, GitHub, AWS logging, admin panels, devices і restore.

Практична черга:

1. IdP/MFA і password vault для human/shared secrets.
2. GitHub 2FA, branch protection, CODEOWNERS, secret scanning і dependency alerts.
3. AWS CloudTrail, groups, least privilege і temporary production access.
4. SSO/MFA або private access для Jenkins, Argo CD, Grafana, Kibana, MinIO, RabbitMQ.
5. Kubernetes RBAC, ServiceAccount inventory, Pod Security Admission, NetworkPolicy, Sealed Secrets, audit logs.
6. Restore drills, incident mini-runbooks і перший scanner/runtime pilot.

Це не знижує пріоритет Kubernetes RBAC і secrets. Це фіксує, що Kubernetes controls не компенсують слабкий offboarding, паролі в чатах або незахищений GitHub.

## P0 blockers

| Блокер | Чому це важливо | Ціль |
| --- | --- | --- |
| `AlwaysAllow` authorization | RBAC не enforce least privilege | `Node,RBAC` або equivalent approved mode. |
| No tested restore | Backup без restore proof є false confidence | Restore drill для critical data. |
| Plaintext runtime secrets in GitOps | Secret exposure і rotation debt | Sealed Secrets як approved workflow. |
| Unknown API exposure | Public API risk може бути схований за assumptions | External reachability і firewall/NAT evidence. |
| No default-deny network baseline | Легкий lateral movement | Namespace-level policy baseline. |
| Unprotected admin panels | Jenkins/Argo/Grafana/Kibana/MinIO/RabbitMQ можуть стати production entry point | SSO/MFA або private access + inventory. |
| Weak GitHub delivery path | Зміна коду або manifest може обійти cluster controls | 2FA, branch protection, review, status checks, CODEOWNERS, secret scanning. |

## RBAC migration checklist

Потребує перевірки перед будь-якою зміною:

```bash
sudo grep -E -- '--authorization-mode|--authorization-config|--audit-policy-file|--audit-log-path' \
  /var/snap/microk8s/current/args/kube-apiserver
kubectl auth can-i '*' '*' --all-namespaces --as=<test-user>
```

Безпечний migration pattern:

1. Інвентаризувати users, groups, service accounts і controller bindings.
2. Підготувати required roles для CNI, ingress, GitOps, CI/CD, storage, observability і DB operators.
3. Підготувати break-glass admin path.
4. Протестувати на clone або під час maintenance window, якщо можливо.
5. Увімкнути RBAC.
6. Перевірити node, CNI, ingress, Argo CD, Jenkins і operators.
7. Зафіксувати rollback path.

## Sealed Secrets baseline

Поточний затверджений workflow: **Sealed Secrets**.

Правила:

- plaintext Kubernetes Secret values не можна commit;
- SealedSecret manifests можна commit, якщо вони encrypted для правильного cluster/controller;
- docs можуть називати Secret objects і key names, але не values;
- rotation має створювати новий sealed manifest і перевіряти всіх consumers;
- backup ключа cluster/controller стає частиною DR scope.

Потребує перевірки:

- У яких clusters встановлено Sealed Secrets controller?
- Чи current runtime secrets представлені як SealedSecrets?
- Чи controller key backup задокументований і restore-tested?

## Policy і runtime security

Запропонована staged model:

| Етап | Controls |
| --- | --- |
| Baseline | RBAC, Sealed Secrets, NetworkPolicy, audit, backup/restore. |
| Policy-as-code | Обрати Kyverno або Gatekeeper, не обидва одразу. |
| Image/posture scanning | Trivy або Kubescape baseline у CI і cluster reports. |
| Runtime detection | Falco, Tetragon, NeuVector або equivalent після tuning. |
| Management plane | Rancher pilot лише після того, як RBAC foundation реальна. |

## Azure Arc / Defender for Containers evaluation

Azure Arc-enabled Kubernetes і Defender for Containers можна розглядати як Microsoft-first evaluation path для одного non-prod Kubernetes або MicroK8s cluster.

Ціль такого pilot:

- перевірити Arc agent health, outbound connectivity, permissions і extension lifecycle;
- отримати posture/runtime findings через Defender for Containers, якщо budget approval є;
- зрозуміти noise profile, operational overhead і support fit для self-hosted/MicroK8s;
- зібрати evidence для buy/no-buy decision у `MICROSOFT_SECURITY_STACK_PILOT.md`.

Guardrails:

- Arc не замінює native Kubernetes RBAC, Pod Security Admission, NetworkPolicy, audit logs або backup/restore.
- Defender for Containers не замінює Sealed Secrets workflow і не доводить production readiness без local validation.
- Arc GitOps не має замінювати поточний Argo CD workflow у pilot.
- Вмикати paid Defender plans тільки після budget/trial review і rollback path.

## Kubernetes evidence blocks

Перед тим як називати cluster hardened, підготувати evidence по 12 blocks:

| Block | Evidence |
| --- | --- |
| API authorization | `authorization-mode`, `kubectl auth can-i`, `cluster-admin` bindings. |
| Human access | Role/group model, kubeconfig inventory або OIDC/Rancher/Teleport/Azure Arc access path. |
| ServiceAccounts | Accounts, bindings, token behavior і blast radius для workloads/automation. |
| Namespaces | System/apps/databases/observability/operators separation і owners. |
| Pod Security | PSA labels, warn/audit/enforce mode, exception register. |
| Admission policy | One primary policy layer: Kyverno, Gatekeeper або native `ValidatingAdmissionPolicy`. |
| Network isolation | CNI enforcement, default-deny namespaces, allowlist flows. |
| Secrets | Sealed Secrets adoption, no plaintext values in Git, controller key backup. |
| Images | Scan reports або registry/CI scanner evidence. |
| Audit | API audit flags, destination, retention і query example. |
| Backup | Control plane objects, volumes, DBs, Sealed Secrets key і restore drill. |
| Operators | Operator RBAC review and rollback notes. |

## Оцінка Rancher і NeuVector

Rancher може надати centralized Kubernetes management, users/groups/roles і multi-cluster access. NeuVector/SUSE Security може надати vulnerability scanning, admission controls, runtime visibility, network/process/file monitoring і security events.

Використовувати їх як pilot candidates, а не як заміну basic controls. Якщо underlying API server не enforce RBAC, management-plane RBAC недостатньо.

Потребує перевірки:

- Поточна version compatibility з target Kubernetes/MicroK8s version.
- License/support model.
- Чи Rancher працює на окремому management cluster.
- Як audit logs потрапляють у logging stack.
- Який NeuVector mode безпечний першим: Discover, Monitor, потім selective Protect.

## Докази production readiness

Перед promotion підготувати:

- access matrix;
- list of local admins and break-glass holders;
- `kubectl auth can-i` test evidence;
- NetworkPolicy inventory;
- Secret workflow evidence;
- backup and restore drill result;
- audit log location and retention;
- CI/CD credential inventory;
- incident response and rollback runbooks.

## Відкриті питання

- Чи API exposure зовнішньо перевірений з untrusted network?
- Який IdP є long-term source of truth?
- Який мінімально прийнятний audit retention?
- Який runtime security tool операційно реалістичний для команди?
- Чи Jenkins/Argo CD/Grafana/Kibana/MinIO/RabbitMQ закриті SSO/MFA або private access?
- Чи GitHub organization має required 2FA, branch protection, secret scanning і dependency alerts?
- Чи AWS CloudTrail увімкнений як процес і має захищене retention?
