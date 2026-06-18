# Security governance

Статус: особистий робочий документ  
Джерела: NIST/CIS/OWASP process notes, NIST CSF workshop materials, sanitized discovery questionnaire, minimal security stack research, sanitized small-team implementation research in `archive/2026-05-14/`, Microsoft-first pilot research in `archive/2026-05-25/`, NIST SP 1300 PDF reference

## Призначення

Цей документ збирає практичний підхід security governance для малої hardware/software команди.

Це не compliance certificate. Це робоча модель для перетворення security frameworks на рішення, checklists, owners і повторювані runbooks.

## Рекомендований baseline

Використовувати frameworks для різних задач:

| Framework | Практична роль |
| --- | --- |
| NIST CSF 2.0 | management model для cyber risk: Govern, Identify, Protect, Detect, Respond, Recover |
| CIS Controls | concrete baseline для security hygiene |
| OWASP | application і API security practices |
| NIST SSDF | secure software development process |
| NISTIR 8259A / ETSI EN 303 645 | connected device/product security reference |

Практична формула:

```text
NIST CSF каже, чим керувати.
CIS каже, які minimum controls реалізувати.
OWASP каже, як уникати common software risks.
SSDF каже, як робити development безпечнішим.
Device-specific standards скеровують hardware/IoT decisions.
```

## Мінімальний security stack

Для малої IT-команди без окремої security-команди перший baseline має прибрати хаос у доступах, а не починатися з великого SIEM/PAM або складного self-hosted security stack.

Must-have зараз:

- IdP/SSO/MFA і group-based lifecycle для onboarding/offboarding;
- password manager для human/shared passwords;
- private access layer для internal/admin panels: Cloudflare Access, Tailscale, VPN або інший approved access proxy;
- AWS IAM Identity Center, AWS Organizations і CloudTrail, якщо AWS є production або critical environment;
- GitHub hardening: MFA, branch protection, reviews, CODEOWNERS, secret scanning/dependency alerts там, де доступно;
- Kubernetes baseline: RBAC, Pod Security Admission, audit logs, NetworkPolicy і documented production access path;
- Kubernetes runtime secrets через поточний approved workflow Sealed Secrets;
- backup/restore evidence для critical data, GitOps state, password manager recovery і Sealed Secrets controller key.

Shortlist напрямки для пілоту:

| Напрямок | Коли обирати | Ризик |
| --- | --- | --- |
| Microsoft-first | потрібен all-in-one для identity, endpoints, MFA, lifecycle і device policy | migration/change-management overhead |
| JumpCloud-neutral | потрібен нейтральний IdP/MDM/lifecycle без міграції workplace suite | все одно потрібні окремий password vault і private access layer |
| Google-first | компанія вже живе в Google Workspace і хоче мінімум змін | слабший endpoint/device posture для desktop fleet |
| DevOps-heavy selected components | потрібні окремі open-source controls: SOPS, ESO, Kyverno, Trivy, Velero | не будувати як primary stack без dedicated owner |

Microsoft-first pilot documented окремо в `MICROSOFT_SECURITY_STACK_PILOT.md`. Використовувати його як trial-first decision pack для Entra/PIM, Private Access, Intune/Defender, Sentinel, GitHub security і Arc/Defender for Containers, а не як заміну password manager, Sealed Secrets, app-native RBAC, Kubernetes native hardening або backup/DR.

Needs verification:

- vendor pricing, licensing, free-tier/trial limits і sales-quote моделі перед закупівлею;
- non-durable citation markers у source research треба замінити на durable official URLs перед team-ready publication;
- public case claims або vendor comparison claims не використовувати як governance evidence без перевірки.

## Governance artifacts

Мінімально корисні artifacts:

- system inventory;
- data inventory;
- access inventory;
- owners for critical systems;
- risk register;
- control baseline;
- incident response runbook;
- recovery/backup test log;
- access and secrets governance runbook;
- security roadmap.

## Мінімальний пакет політик

На старті достатньо короткого policy packet, а не великого compliance binder. Кожна політика має мати owner-а, scope, мінімальні правила, verification evidence і дату перегляду.

| Policy | Що має зафіксувати |
| --- | --- |
| Identity & Access Policy | IdP, MFA, groups, onboarding/offboarding SLA, review cadence. |
| Privileged Access Policy | Prod/admin access, requester/approver, expiry, audit trail, break-glass. |
| Secrets Policy | Human/shared passwords, runtime secrets, заборона секретів у чатах/Git, rotation trigger. |
| Git & CI/CD Policy | PR review, protected branches, CODEOWNERS, required checks, secret scanning. |
| Kubernetes Baseline Policy | RBAC, ServiceAccounts, Pod Security Admission, audit logs, NetworkPolicy, Sealed Secrets. |
| Backup/Restore & IR-lite Policy | Backup owners, restore drill cadence, incident roles, escalation channel, evidence log. |

## Security champion model

Для малої команди не потрібна окрема security-team, але потрібна явна ownership model.

| Роль | Відповідальність |
| --- | --- |
| Security / IT owner | IdP, endpoint baseline, policy packet, vendor diligence, access reviews. |
| DevOps / platform owner | Cloud/Kubernetes/admin panels, logs, backup/restore, Sealed Secrets DR. |
| Dev champion | GitHub guardrails, CODEOWNERS/reviews, secrets cleanup у repos, CI/CD policy adoption. |
| Support / operations champion | Доступ до internal panels, role changes, offboarding checklist, incident handoff. |

Це operating model, а не job title. Якщо одна людина виконує кілька ролей, це треба явно записати і переглядати після першого pilot.

## Discovery questionnaire

Використовувати `projects/shared/SECURITY_DISCOVERY_QUESTIONNAIRE.md` як sanitized intake questionnaire. Source answers не переносити в canonical docs; для реальних відповідей створювати окрему sanitized working copy або ticket.

High-priority areas:

- business context and critical systems;
- identity provider and account lifecycle;
- shared credentials and secrets;
- devices and endpoint management;
- VPN/remote access;
- cloud, Kubernetes, and production access;
- GitHub/GitLab, CI/CD, supply chain;
- logging, monitoring, detection;
- incident response;
- backup and disaster recovery;
- legacy one-password systems.

## Operating cycle NIST CSF 2.0

### Govern

Вирішити:

- who owns risk;
- which systems matter most;
- which policies are mandatory;
- what budget/time is realistic.

Artifacts:

- owner matrix;
- risk register;
- minimum security policy set.

### Identify

Побудувати inventory:

- systems;
- repositories;
- domains;
- SaaS;
- cloud accounts;
- devices;
- data types;
- privileged access paths.

Artifacts:

- system inventory;
- data classification;
- dependency map.

### Protect

Мінімальний baseline:

- MFA for critical accounts;
- password manager;
- least privilege;
- endpoint protection;
- GitHub branch protection and secret scanning;
- Kubernetes secret workflow;
- backup coverage.

### Detect

Почати з практичного detection:

- IdP login anomalies;
- GitHub audit events;
- cloud audit logs;
- endpoint alerts;
- Kubernetes and app logs;
- backup failures.

### Respond

Написати невеликі runbooks для:

- compromised account;
- leaked token;
- lost laptop;
- suspicious admin login;
- ransomware suspicion;
- production secret exposure.

### Recover

Recovery — це не наявність backup. Це перевірене restore.

Відстежувати:

- restore test date;
- owner;
- recovery time;
- gaps found;
- follow-up actions.

## Workshop assets

Робочі матеріали в `archive/2026-05-11/`:

- `nist_csf2_smb_structure_uk.md`;
- `nist_csf2_smb_speaker_speech_uk.md`;
- `nist-csf2-security-governance-workshop-slides.md`;
- `nist_csf2_smb_presentation_uk.pdf`;
- `nist_csf2_smb_presentation_uk.pptx`;
- `NIST.SP.1300.pdf.pdf`.

Тримати PDF/PPTX як source або generated artifacts. Не копіювати великі chunks в operational docs.

## Pilot plan

Пілот на 5-7 людей має довести не installation success, а зменшення operational chaos.

Включити:

- DevOps або platform owner;
- system admin або IT owner;
- 1-2 developers;
- QA/support representative;
- tech lead або manager;
- один remote-user сценарій.

Покрити системи:

- GitHub;
- AWS access через IAM Identity Center, якщо AWS у scope;
- Jenkins, Argo CD, Grafana/Kibana/MinIO або інші admin panels;
- один non-sensitive Kubernetes namespace;
- один вузький read-mostly production access scenario без повного prod-admin rollout.

Критерії успіху:

- усі пілотні користувачі під MFA;
- admin panels закриті SSO/MFA, access proxy, VPN або allowlist;
- shared/admin passwords винесені з чатів у password manager;
- offboarding виконується за визначений SLA і має audit trail;
- temporary access має expiry;
- restore drill має documented evidence.

Якщо pilot direction = Microsoft-first, рішення має спиратися на `MICROSOFT_SECURITY_STACK_PILOT.md`: buy/no-buy приймати по product areas, а не одним blanket рішенням "купити Microsoft security stack".

## Пов’язані канонічні документи

Використовувати ці focused docs замість розширення цього overview:

- `MICROSOFT_SECURITY_STACK_PILOT.md` для Microsoft-first security pilot, evidence pack, buy/no-buy criteria і product gaps.
- `KubernetesSecurityHardening.md` для Kubernetes/MicroK8s hardening, RBAC, audit, policy, runtime security і Rancher/NeuVector evaluation.
- `AccessAndSecretsGovernance.md` для access lifecycle, secret rotation, break-glass і Sealed Secrets workflow.
- `SoftwareSupplyChainSecurity.md` для CI/CD trust chain, SBOM, provenance, signing, dependency scanning і LLM/AI-agent safety.
- `PrivilegedAccessForLegacySystems.md` для legacy shared-password containment.

## Policy hook для використання LLM і AI

Використання AI/LLM є частиною security governance, коли code, logs, incidents або customer data можуть бути exposed.

Baseline:

- використовувати synthetic або sanitized context за замовчуванням;
- approved enterprise/local tooling потрібний для company-sensitive snippets;
- personal/free LLM accounts не мають отримувати proprietary code або production data;
- AI agents не мають мати production, secrets, cloud admin або destructive write access за замовчуванням;
- secret scanning і human review лишаються обов'язковими, навіть якщо LLM допомогла draft change.

## Правила security documentation

Документувати:

- control intent;
- owners;
- allowed tools;
- secret object names;
- credential ID names;
- runbook steps;
- verification commands, які не друкують values.

Не документувати:

- passwords;
- PATs;
- private keys;
- kubeconfig contents;
- database connection strings with credentials;
- screenshots that reveal tokens.

## Відкриті питання

- Який identity provider є long-term source of truth?
- Який password manager затверджений?
- Який endpoint management stack реалістичний для команди?
- Які cloud account model і break-glass path затверджені?
- Які security roadmap items обов'язкові на наступні 30/60/90 днів?
- Який stack запускати першим пілотом: Microsoft-first, JumpCloud-neutral, Google-first або selected DevOps-heavy components?
- Які vendor pricing/licensing assumptions підтверджені офіційними джерелами перед закупівлею?
- Хто затверджує мінімальний policy packet і owns security champion model після pilot?
