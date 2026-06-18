# Microsoft Security Stack Pilot

Статус: особистий робочий документ  
Джерела: primary source `archive/2026-05-25/Microsoft Security Stack Research.md`; supporting duplicate/reference `archive/2026-05-25/deep-research-report (2).md`; older duplicate/reference `archive/2026-05-25/deep-research-report (1).md`

## Призначення

Цей документ фіксує sanitized Microsoft-first security pilot для компанії зі стеком GitHub, Jenkins, Argo CD, self-hosted або MicroK8s Kubernetes і частковим AWS scope.

Це не vendor recommendation для негайної закупівлі. Це 30-денний evaluation path, який має дати evidence для buy/no-buy рішення без production-wide rollout і без зміни поточного approved Kubernetes secret workflow.

## Scope guardrails

Microsoft-first pilot має сенс як identity, access, endpoint, evidence і selected posture layer. Він не є replacement для всієї security operating model.

Пілот покриває тільки:

- 5-10 users або 5-15 admin/pilot endpoints;
- 2-4 internal admin surfaces: Jenkins dev, Argo CD dev, Grafana/Kibana або MinIO/RabbitMQ admin UI;
- 1 non-prod Kubernetes або MicroK8s cluster;
- 1 AWS dev/sandbox account, якщо AWS входить у scope;
- 2-5 GitHub private repos для Secret Protection і 1-2 repos для Code Security/CodeQL;
- Sentinel тільки для вузького evidence stream, не як full log lake.

Не робити в першому pilot:

- mass Intune enrollment для всієї компанії;
- blanket production enforcement;
- wide Sentinel ingestion без cost guardrails;
- заміну Jenkins або Argo CD на Microsoft-native flow;
- заміну app-native RBAC у Jenkins, Argo CD, Grafana, Kibana, MinIO або RabbitMQ;
- full migration runtime secrets у Azure Key Vault;
- Arc GitOps як replacement для поточного Argo CD workflow;
- production Defender for Containers enforcement без budget approval і rollback plan.

Поточні boundaries:

- Dedicated password manager для human/shared secrets лишається обов'язковим. Azure Key Vault не є team password vault.
- Sealed Secrets лишається approved Kubernetes runtime secret workflow для поточного плану.
- Azure Key Vault / Secret Store / CSI можна тестувати тільки як optional pilot або future path для selected non-prod workload secrets.
- Kubernetes native hardening лишається базою: RBAC, Pod Security Admission, NetworkPolicy, audit logs, Sealed Secrets, backup/restore evidence.
- Jenkins-native hardening і pipeline scanning не зникають, бо Defender for Cloud DevOps security не є повним native Jenkins connector.
- Backup/DR і break-glass не замінюються Microsoft security tooling.

## Product fit matrix

| Product / capability | Pilot fit | Що перевірити | Guardrail |
| --- | --- | --- | --- |
| Entra ID P2 / Conditional Access | High | MFA, risky sign-in controls, admin CA policies, sign-in/audit visibility | Не запускати policies, які можуть lock out admin users, без tested break-glass. |
| Entra PIM | High | JIT admin для Entra/Azure roles, approval, justification, activation logs | Не вважати PAM/session recording для legacy systems. |
| Access Reviews / ID Governance | Medium-high | Recertification privileged groups і offboarding evidence | Lifecycle workflows можуть потребувати окремого licensing/add-on verification. |
| Entra Private Access / Global Secure Access | High для private admin panels | Доступ до 2-4 admin UIs через MFA/compliant-device conditions | Не замінює app-native auth/RBAC; перевірити client, OS, protocol і disconnect limitations. |
| Intune + Defender endpoint | High для admin devices | Enrollment, compliance policy, device inventory, Defender alerts | Не робити mass BYOD rollout без legal/HR/device policy decision. |
| Microsoft Sentinel | Medium-high як evidence layer | Entra/PIM, selected GitHub, Defender, AWS CloudTrail і admin access evidence | Не підключати noisy build/app logs; контролювати ingestion і owner-а detections. |
| Defender for Cloud / Foundational CSPM / Defender CSPM / CIEM | Medium-high | AWS/Azure posture findings, identity permission graph, actionable recommendations | Pricing/resource-count model і noise мають бути підтверджені перед purchase. |
| Azure Arc-enabled Kubernetes | Medium | Attach одного non-prod cluster, agent health, extension lifecycle, operational overhead | Не замінює native Kubernetes RBAC, audit, NetworkPolicy або Argo CD. |
| Defender for Containers | Medium | Image/Kubernetes findings, runtime alerts, Defender integration через Arc | Вмикати тільки після budget approval; MicroK8s fit є technical validation, не production proof. |
| Azure Key Vault + CSI / Secret Store | Medium-low для поточного workflow | Один non-prod retrieval/rotation scenario і audit evidence | Не замінює Sealed Secrets зараз і не є password manager для людей. |
| GitHub Secret Protection | High | Push protection / secret scanning на high-risk repos | Billing by active committers і private repo licensing потребують verification. |
| GitHub Code Security / CodeQL | Medium-high | Code scanning на 1-2 repos з найбільшим risk-to-change ratio | Не запускати blanket rollout, якщо false positives створюють developer debt. |
| Defender for Cloud DevOps security | Medium | GitHub visibility і code-to-cloud posture | Jenkins не є повним native target; Jenkins покривати через pipeline scanning, SARIF, CLI або Jenkins-native controls. |

## 30-day roadmap

### Days 1-3: safety, scope, licensing inventory

- Зафіксувати pilot users, admin devices, repos, admin panels, non-prod cluster і AWS dev/sandbox account.
- Зафіксувати trial start/end dates і expected paid conversion paths.
- Підготувати break-glass accounts і exclusion rules.
- Визначити rollback/disable path для кожного product area.
- Узгодити, які logs дозволено ingest у Sentinel.

Evidence:

- pilot scope register;
- licensing/trial calendar;
- break-glass test record;
- list of out-of-scope production systems.

### Days 4-7: Entra P2 baseline

- Увімкнути MFA / Conditional Access для pilot admin users.
- Налаштувати PIM для selected Entra/Azure admin roles або pilot admin groups.
- Запустити access review для privileged groups.
- Перевірити sign-in/audit/PIM activation logs.

Evidence:

- Conditional Access policy export або screenshot summary без sensitive values;
- PIM activation log;
- access review output;
- break-glass validation note.

### Days 8-12: Private Access до admin panels

- Обрати 2-4 admin surfaces: Jenkins dev, Argo CD dev, Grafana/Kibana, MinIO або RabbitMQ.
- Протестувати Entra Private Access / Global Secure Access client і connector path.
- Додати Conditional Access requirement: MFA і, якщо готово, compliant device.
- Перевірити app-native RBAC окремо від network/private access layer.

Evidence:

- список protected admin resources;
- успішний/неуспішний access test;
- latency/disconnect notes;
- app-native RBAC gaps.

### Days 13-17: Intune і Defender endpoint posture

- Enroll тільки pilot admin endpoints.
- Створити мінімальний compliance baseline для admin access.
- Увімкнути Defender for Business або Defender for Endpoint P2 pilot path.
- Перевірити device inventory і alert visibility.

Evidence:

- device inventory;
- compliance policy result;
- Defender alert/test result;
- BYOD/legal/support gaps.

### Days 18-21: Sentinel evidence layer

- Створити один Sentinel workspace або використовувати approved test workspace.
- Підключити вузькі data sources: Entra sign-ins/audit, PIM events, selected Defender alerts, selected GitHub security/audit events, AWS CloudTrail тільки якщо у scope.
- Побудувати мінімальний evidence workbook або saved queries.
- Зафіксувати ingestion/cost estimate і noise profile.

Evidence:

- workspace/query list;
- usage/cost snapshot;
- 3-5 actionable detections або reasons why not;
- owner для tuning.

### Days 22-25: GitHub / GHAS / Defender DevOps

- Увімкнути GitHub Secret Protection на 2-5 high-risk repos.
- Увімкнути Code Security / CodeQL на 1-2 repos.
- Перевірити developer workflow: PR annotations, false positives, suppression process.
- Підключити GitHub до Defender for Cloud DevOps security, якщо є licensing/role approval.
- Для Jenkins зробити тільки narrow experiment: SARIF/CodeQL/Defender CLI або existing scanner integration у одному job.

Evidence:

- secret scanning / push protection findings summary без secret values;
- CodeQL findings summary;
- developer friction notes;
- Jenkins limitation note.

### Days 24-28: Arc / Kubernetes / Key Vault

- Arc-enable один non-prod Kubernetes або MicroK8s cluster.
- Перевірити agent health, outbound connectivity, extension lifecycle і permissions.
- Увімкнути Defender for Containers тільки після budget approval.
- Протестувати один Key Vault / CSI / Secret Store або fallback External Secrets scenario без production data.
- Не змінювати current Sealed Secrets approval.

Evidence:

- Arc status;
- extension install/upgrade notes;
- Defender recommendation/alert summary, якщо enabled;
- Key Vault retrieval/rotation test;
- comparison with Sealed Secrets boundary.

### Days 29-30: evidence pack і decision review

- Зібрати evidence pack по identity, access, endpoint, GitHub, Sentinel, cloud/Kubernetes і secrets pilot.
- Відокремити verified facts від vendor claims і community anecdotes.
- Прийняти buy/no-buy/defer рішення по кожному product area.
- Відкрити follow-up tasks тільки для confirmed gaps.

## Evidence pack

Decision meeting має мати компактний evidence pack:

- pilot scope і out-of-scope list;
- trial/licensing calendar і known paid conversion risks;
- Conditional Access/PIM/access review evidence;
- protected admin panels і Private Access test outcomes;
- endpoint inventory/compliance/Defender signal;
- Sentinel usage, cost і detection usefulness;
- GitHub Secret Protection / Code Security findings summary без secret values;
- Defender for Cloud / CSPM / AWS findings summary;
- Arc/Defender for Containers operational notes;
- Key Vault / CSI / Secret Store retrieval/rotation notes;
- explicit gaps: password manager, app-native RBAC, Jenkins-native hardening, Sealed Secrets, backup/DR.

## Buy/no-buy criteria

| Area | Buy / continue if | No-buy / defer if |
| --- | --- | --- |
| Entra ID P2 / PIM | Standing admin реально зменшився; CA не ламає workflow; access reviews ловлять stale access | Apps/users bypass Entra; PIM latency або licensing risk блокує роботу; немає identity owner-а |
| Entra Private Access | Більшість pilot admin panels reachable privately з MFA/compliant-device condition | Client/protocol limitations, disconnects або UX гірші за Cloudflare Access/Tailscale/VPN path |
| Intune / Defender endpoint | Admin devices можна enrollment/control без excessive support cost | BYOD/legal friction, slow policy propagation або unmanaged admin devices лишають core risk |
| Sentinel | Evidence pack корисний, ingestion під контролем, detections actionable | Too much noise, unclear cost, немає detection owner-а, existing observability достатній |
| Defender CSPM / CIEM | AWS/Azure recommendations actionable і low-noise | AWS-native або other CNAPP дає кращий signal/cost |
| Arc / Defender for Containers | Cluster stable, findings useful, operational overhead acceptable | Arc/extensions noisy, fragile або не додають value поверх native Kubernetes tooling |
| Key Vault / CSI / Secret Store | Retrieval/rotation працює на selected non-prod workload і audit useful | YAML/RBAC/rotation complexity гірша за Sealed Secrets або platform-neutral secret manager |
| GitHub Secret Protection / Code Security | Findings actionable і PR workflow прийнятний | Active committer billing або false positives створюють disproportionate debt |
| Defender DevOps / Jenkins experiment | GitHub visibility useful, Jenkins SARIF/CLI experiment low-friction | Jenkins лишається main CI і Microsoft connector майже нічого не додає |

## Gaps and boundaries

Microsoft-first stack не закриває повністю:

- team password vault для human/shared secrets;
- legacy PAM/session recording;
- app-native RBAC і local admin cleanup у Jenkins/Argo/Grafana/Kibana/MinIO/RabbitMQ;
- Jenkins-native pipeline security;
- Kubernetes native hardening і admission policy tuning;
- GitOps secret workflow, де поточним approved path є Sealed Secrets;
- backup/restore drills і DR ownership;
- incident runbooks і operational ownership;
- production-ready evidence для MicroK8s + Arc + Defender for Containers без local validation.

## Needs verification

- Vendor pricing, licensing, trial limits, seat limits, active committer billing, paid conversion і tax/region/agreement effects.
- Public case claims від Microsoft/GitHub або інших vendor pages.
- Community anecdotes з Reddit, Hacker News, GitHub Issues, forums і review sites.
- Non-durable citation markers із source research перед team-ready publication.
- Current Microsoft portal paths, product names, retirement timelines і licensing bundles перед закупівлею.
- MicroK8s / Azure Arc / Defender for Containers support і operational fit на actual target cluster.
- Private Access client limitations, OS/device requirements, protocol limits і reconnect behavior.
- Sentinel ingestion estimate на реальному data volume.
- Key Vault / CSI / Secret Store rotation behavior і RBAC/service-principal model.
- GitHub Secret Protection / Code Security billing для actual private repos і active committers.
