# Управління доступом і секретами

Статус: особистий робочий документ  
Джерела: `archive/2026-05-11/Research щодо Security & Access Policy.md`, `archive/2026-05-11/Практичний blueprint для Access & Secrets Governance у невеликій або середній IT-компанії.md`, `archive/2026-05-11/Без назви.md`, `archive/2026-05-11/Без назви 1.md`, sanitized access/security implementation research in `archive/2026-05-14/`, Microsoft-first pilot research in `archive/2026-05-25/`

## Призначення

Цей документ визначає робочу модель для доступу людей, машинного доступу, runtime secrets, застарілих спільних паролів, відкликання доступу, ротації та аварійного відновлення через break-glass.

Головний ризик, який треба зменшити, — непомітний постійний доступ: працівник, підрядник або зловмисник зберігає доступ через старі облікові записи, спільні паролі, персональні tokens, некеровані пристрої або забуті CI credentials.

## Категорії доступу

| Категорія | Приклади | Обов'язковий контроль |
| --- | --- | --- |
| Людська ідентичність | email, IdP, GitHub, cloud console, VPN | MFA, lifecycle, власник, шлях відкликання |
| Endpoint | laptops, BYOD, admin workstations | інвентаризація, lock/wipe, EDR/AV, політика оновлень |
| Source control | GitHub orgs/repos, deploy keys, PATs | branch protection, audit, secret scanning, PAT policy |
| CI/CD | Jenkins, runners, registry access | credential IDs, least privilege, ротація |
| Runtime secrets | Kubernetes Secrets, app env vars, DB credentials | зовнішнє джерело істини або зашифрований GitOps workflow |
| Інфраструктурний доступ | VPN, SSH, Kubernetes, cloud roles | role-based access, audit, break-glass |
| Застарілий спільний пароль | старий web app, RDP app, система з одним паролем | proxy/vault/session controls і ротація |

## Рекомендований прагматичний baseline

Для малої команди почати з:

- IdP with MFA and conditional access;
- password manager for human/shared secrets;
- GitHub organization baseline: MFA, branch protection, secret scanning;
- cloud roles instead of long-lived IAM users where possible;
- registry robot/org tokens instead of personal tokens;
- Kubernetes runtime secret workflow: Sealed Secrets як поточний approved workflow; External Secrets Operator, SOPS або cloud secret manager тільки як future alternatives;
- break-glass accounts for IdP, cloud, DNS, and password manager;
- задокументовані grant/revoke/rotation runbooks.

## Мінімальний стек доступів

Перший practical stack має закрити lifecycle, MFA, shared passwords, internal admin panels, GitHub/AWS baseline і Kubernetes secrets. Не починати з великого PAM/SIEM/Vault stack, якщо немає окремого owner-а для support, backup, upgrades і incident response.

Рекомендована послідовність:

1. Обрати IdP як source of truth: Microsoft Entra ID, Google Workspace/Cloud Identity, JumpCloud або інший approved provider.
2. Увімкнути MFA для всіх critical accounts і окремо захистити admin/break-glass accounts.
3. Обрати password manager для human/shared passwords: Bitwarden, 1Password або інший approved tool.
4. Закрити internal/admin panels через SSO/MFA, access proxy, VPN або allowlist.
5. Нормалізувати AWS/GitHub доступи через groups, roles, branch protection, CODEOWNERS, audit і secret scanning.
6. Для Kubernetes runtime secrets використовувати Sealed Secrets як поточний approved workflow.

Tool candidates:

| Зона | Candidate | Статус у цьому knowledge base |
| --- | --- | --- |
| Human/shared passwords | Bitwarden, 1Password | shortlist для пілоту; ціни/licensing треба перевірити перед закупівлею |
| Identity/lifecycle | Microsoft Entra ID P2, Entra PIM, Access Reviews, JumpCloud-neutral, Google-first | shortlist напрямки; точний IdP ще open decision |
| Internal panels | Entra Private Access, Cloudflare Access, Tailscale, VPN/private access | candidate baseline для Jenkins, Argo CD, Grafana, Kibana, MinIO, RabbitMQ, DB admins |
| Kubernetes runtime secrets | Sealed Secrets | approved workflow для поточного плану |
| Future runtime secrets | Azure Key Vault / CSI / Secret Store, External Secrets Operator, SOPS, AWS Secrets Manager, Vault/OpenBao | alternatives/next stage, не approved default зараз |

Needs verification:

- vendor pricing, trial limits, seat limits і enterprise add-ons перед budget decision;
- GitHub security add-ons, AWS Secrets Manager, CloudTrail, AWS Backup, Sentinel, Datadog, Teleport, Boundary, Rancher/SUSE billing перед TCO spreadsheet;
- source research citation markers мають бути замінені на stable official links перед team-ready publication.

## Vendor due-diligence checklist

Питання до постачальників фіксувати як decision evidence, не як готову рекомендацію до закупівлі.

| Зона | Мінімальні питання перед pilot або закупівлею |
| --- | --- |
| IdP / SSO / device tools | SCIM/group sync edge cases, offboarding latency, MFA/break-glass model, login/change audit export, BYOD/device posture limits. |
| Password manager | Shared vault/group model, audit export, emergency access, recovery path, offboarding flow, support for separating human and machine secrets. |
| Private access layer | Coverage for web/SSH/Kubernetes/DB access, JIT requests, session/audit evidence, IdP outage behavior, minimum rollout for 25-50 users. |
| Cloud/GitHub controls | IAM permission sets, CloudTrail retention/query path, organization 2FA, branch rules, CODEOWNERS, secret scanning/push protection availability. |
| Kubernetes security tools | Resource footprint, webhook/runtime failure modes, noisy-alert profile, rollback path, small-team recommended profile, Argo CD/GitOps compatibility. |
| Runtime secrets alternatives | Rotation model, DR after cluster loss, key ownership, audit/export, operator footprint, migration path from current Sealed Secrets workflow. |

До team-ready рішення додавати `Needs verification`, якщо відповідь заснована на vendor story, community feedback або pricing page без офіційного quote/contract.

## Microsoft-first access pilot boundaries

Entra ID P2, Conditional Access, PIM і Access Reviews є хорошими candidate controls для identity-centric pilot:

- MFA і Conditional Access для pilot admin users;
- PIM для JIT elevation у Entra/Azure roles або selected admin groups;
- Access Reviews для privileged groups і offboarding evidence;
- Entra Private Access для 2-4 internal/admin panels з MFA і, якщо готово, compliant-device condition.

Boundaries:

- Entra PIM не замінює legacy PAM, session recording або app-native RBAC.
- Entra Private Access не замінює локальні ролі, audit і cleanup admin users у Jenkins, Argo CD, Grafana, Kibana, MinIO або RabbitMQ.
- Microsoft stack не замінює dedicated password manager для human/shared secrets.
- Azure Key Vault / CSI / Secret Store можна тестувати тільки як optional non-prod workload-secret pilot; Sealed Secrets лишається approved Kubernetes runtime secret workflow.
- Buy/no-buy рішення вести через `MICROSOFT_SECURITY_STACK_PILOT.md`, з окремими рішеннями для Entra, Private Access, Intune/Defender, Sentinel, GitHub security, Arc/Defender for Containers і Key Vault.

## Модель застарілих спільних паролів

Якщо legacy system має один спільний пароль, ціль не в тому, щоб "сказати меншій кількості людей". Ціль — обгорнути його контролями:

- password manager with access groups and audit;
- credential proxy or session proxy where practical;
- VPN/ZTNA access boundary;
- IP allow-listing;
- session logging for privileged actions;
- rotation after staff/contractor changes;
- break-glass procedure.

Можливі категорії інструментів:

- PAM/privileged access proxy;
- remote desktop/jump host with hidden credential injection;
- ZTNA or access proxy for legacy web apps;
- SSH/VPN/network-layer access without distributing static keys;
- database access broker for DB credentials.

## Workflow надання доступу

Кожне надання доступу має фіксувати:

- requester;
- approver;
- system;
- role/group;
- reason;
- expiry or review date;
- owner;
- ticket/reference.

Мінімальні кроки:

1. Підтвердити роль і бізнес-потребу.
2. Надати доступ через group/role, а не прямий некерований доступ.
3. Перевірити, що login працює.
4. Зафіксувати власника і дату expiry/review.

## Workflow відкликання доступу

Відкликання має покривати всі площини доступу:

- IdP/session tokens;
- GitHub/org/repo access;
- VPN/ZTNA;
- cloud roles;
- Kubernetes access;
- CI/CD credentials;
- registry tokens;
- password manager groups;
- legacy shared passwords;
- devices.

Для завершення доступу підрядника або employee offboarding спочатку відкликати доступ, потім audit activity.

## Workflow ротації секретів

Політика за замовчуванням:

- leaked secret - revoke/rotate негайно;
- compromised token - спочатку revoke, потім investigate;
- static production credentials: rotate за визначеним графіком або замінити на dynamic/managed credentials;
- CI tokens: надавати перевагу OIDC або short-lived credentials;
- registry tokens: використовувати robot/org tokens із ownership.

Checklist ротації:

1. Визначити власника і consumers.
2. Створити новий secret/version.
3. Задеплоїти consumers з новим secret.
4. Виконати smoke test.
5. Відкликати старий secret.
6. Зафіксувати дату і verification.

## Runtime secrets in Kubernetes

Дозволена документація:

- Secret object names;
- key names;
- env var names;
- source system name;
- rotation owner.

Заборонена документація:

- actual secret values;
- full connection strings with credentials;
- private keys;
- PATs;
- kubeconfig contents.

Цільові варіанти:

- External Secrets Operator + cloud secret manager;
- Sealed Secrets for Git-centric encrypted manifests;
- SOPS for encrypted GitOps bootstrap;
- Vault/Infisical when dynamic secrets or stronger workflow is justified.

Поточний затверджений workflow:

- Sealed Secrets є затвердженим Kubernetes secret workflow для поточного плану репозиторію.
- Recommendations про SOPS/ESO/AWS Secrets Manager або Azure Key Vault / CSI / Secret Store у research notes є future/alternative options, але не змінюють current approved workflow.
- Plaintext Secret manifests є тимчасовим боргом і не мають просуватись до Етап/Prod.
- Backup і restore ключа SealedSecret controller мають бути частиною DR plan.
- Документи можуть називати Secret objects, key names і env vars, але не values.

## Guardrail доступу для AI/LLM

LLM tools і AI coding agents треба розглядати як ще одну площину доступу.

Не надавати agents:

- production secrets;
- kubeconfigs with privileged access;
- CI/CD deploy keys;
- password manager access;
- cloud admin tokens;
- production DB access.

Використовувати `SoftwareSupplyChainSecurity.md` як затверджений baseline безпеки для LLM/agent.

## Break-glass

Break-glass — це окремий шлях відновлення, а не просто ще один admin user.

Мінімум:

- two emergency accounts where platform guidance recommends it;
- strong MFA/passwordless where available;
- offline recovery documentation;
- dual approval for use;
- audit record after use;
- immediate credential review/rotation after use.

Цілі break-glass:

- IdP;
- cloud root/org access;
- DNS/registrar;
- password manager;
- Kubernetes/GitOps control plane.

## Roadmap 30/60/90

### Перші 30 днів

- Призначити власників для IdP, endpoints, GitHub, cloud, registry, DNS, password manager.
- Примусово увімкнути MFA для critical access.
- Вибрати password manager і перенести спільні human secrets.
- Інвентаризувати GitHub PATs/deploy keys і registry tokens.
- Визначити legacy one-password systems.

### 60 днів

- Нормалізувати onboarding/offboarding checklist.
- Визначити CI/CD credential policy.
- Вибрати runtime secret workflow для Kubernetes.
- Додати secret scanning/push protection там, де доступно.
- Визначити break-glass procedure.

### 90 днів

- Провести перший access review.
- Rotate highest-risk static secrets.
- Замінити personal tokens на org/robot/OIDC paths.
- Протестувати recovery для password manager, DNS, cloud і Kubernetes/GitOps.
- Написати incident runbooks для leaked token і compromised account.

## Відкриті питання

- Яка комбінація IdP/password manager затверджена?
- Чи команда достатньо AWS-heavy, щоб стандартизуватися на AWS Secrets Manager + ESO?
- Яким legacy systems потрібен proxy access першими?
- Які secrets можна усунути через OIDC або dynamic credentials?
- Хто є власником quarterly access review?
- Який private access layer затверджений для Jenkins/Argo CD/Grafana/Kibana/MinIO/RabbitMQ/DB admin panels?
- Які vendor pricing/licensing assumptions підтверджені офіційно перед закупівлею?
- Які vendor due-diligence answers підтверджені офіційними джерелами, а які лишаються pilot assumptions?
