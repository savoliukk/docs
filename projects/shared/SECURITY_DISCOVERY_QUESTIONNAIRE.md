# Security discovery questionnaire

Статус: sanitized discovery context + questionnaire  
Джерело: `archive/2026-05-14/Discovery questionnaire (security).md`  
Конфіденційність: sensitive-review-needed

Цей документ є шаблоном intake для security discovery у малій IT-компанії без окремої security-команди.

Правила використання:

- не записувати тут відповіді з реальними секретами, токенами, private keys, kubeconfig, connection strings або customer data;
- відомі історичні відповіді нижче вже sanitized для context-use; нові raw відповіді записувати в окрему sanitized working copy або ticket із placeholders;
- відповідь `так/ні` без деталей прийнятна, якщо деталі можуть розкрити чутливу інформацію;
- питання з `P0` закривають minimum baseline, `P1` допомагають побудувати roadmap, `P2` потрібні для зрілішої governance/compliance програми.

## 0. Відомий контекст з історії

Статус відповідей: historical discovery snapshot, потребує підтвердження перед закупівлею, production changes або team-ready publication.

Основне джерело відповідей: `archive/2026-05-14/Discovery questionnaire (security).md`.

Звірено з canonical context:

- `SecurityGovernance.md`: baseline для small-team security governance, pilot і policy packet.
- `AccessAndSecretsGovernance.md`: access lifecycle, password manager, Sealed Secrets, break-glass.
- `KubernetesSecurityHardening.md`: MicroK8s/Kubernetes hardening, RBAC, audit, NetworkPolicy, admin panel boundary.
- `SoftwareSupplyChainSecurity.md`: GitHub/CI/CD, secret scanning, dependency scanning, SBOM/provenance/signing.
- `PrivilegedAccessForLegacySystems.md`: containment для shared-password legacy systems.

Git history для target/source questionnaire не містить committed revisions у цьому repo snapshot; знайдені відповіді взяті з archived source file.

### 0.1. Профіль компанії

- Команда: приблизно 18 штатних співробітників, 3 постійно віддалені працівники і суміжні відділи, які взаємодіють з інструментами; загальний контур може сягати до 50 людей.
- Ролі: Developers, DevOps, системні адміністратори, QA, Support, Management.
- Очікуване зростання: без суттєвого росту за 12 місяців.
- Формат роботи: переважно офісно, є кілька постійно віддалених співробітників; один офіс плюс remote developers з дому.
- Співробітники за межами України: за історичною відповіддю, ні.
- Головна ціль security effort: захист production, зменшення хаосу.
- Власник access/security ще не визначений; ймовірне навантаження на DevOps або системного адміністратора.
- Бажаний підхід: мінімум інструментів, простіше, з низьким operational overhead.
- Найбільші ризики: витік паролів, production access, злам GitHub, ransomware, звільнений співробітник із доступом.
- ISO 27001, SOC 2, NIST/CIS/GDPR як формальна програма поки не плануються, але клієнтські security questions вже траплялися.

### 0.2. Поточний робочий стек

- Єдиного workspace/source of truth для identity і collaboration не визначено.
- Комунікації: Telegram і Discord; email використовується рідше для клієнтів або третіх сторін.
- Task tracking: Jira і Trello.
- Документація: немає єдиного місця; QA веде частину в Google Docs, частина є в Confluence, також можуть існувати особисті Notion/Obsidian notes.
- Source control: GitHub.
- Cloud/servers: AWS і локальні сервери для dev environments.
- Kubernetes: MicroK8s.
- CI/CD: Jenkins як основний CI provider.
- CD/GitOps: Argo CD є, але історично покриває лише dev; значна частина deploy все ще manual.
- Admin/internal panels: Grafana, можливо Kibana, Argo CD, Jenkins, MinIO, RabbitMQ, PostgreSQL admin; Mongo Express і VPN panel планувалися, але не були налаштовані.
- HR/finance/legal services: окремі сервіси не використовуються.
- Customer support tooling: немає; future candidate area.
- Hardware/IoT context: є власний cloud для IoT систем, user apps, конфігурації, централізованого firmware update, event logging і monitoring.
- Third-party vendors із прямим доступом: за історичною відповіддю, немає; AWS є infrastructure provider.
- SaaS inventory/owners неповний; явно згадані Jira, Confluence, Trello.

### 0.3. Identity, SSO і lifecycle

- Єдиного IdP немає.
- Є корпоративні поштові скриньки, але не повний identity lifecycle.
- MFA для всіх не ввімкнена; бажано впровадити.
- SSO для GitHub/Jira/cloud/admin services немає; бажано впровадити.
- Shared accounts існують.
- Доступи видаються вручну кожному користувачу; group-based access model не побудована.
- Role model для Developer, QA, Support, DevOps, Finance, Management, Contractor ще треба побудувати.
- Temporary access з expiry відсутній.
- Політика access-only-through-SSO бажана, але ще не реалізована.
- Passkeys бажані; FIDO2 hardware keys наразі сприймаються як overkill.
- SCIM provisioning/deprovisioning бажаний.
- Access packages, approval workflows або entitlement management бажані.
- Onboarding зараз відбувається вручну через management.
- Offboarding описаний як слабкий; немає відповідального, який підтверджує повне відкликання доступів.
- Були випадки, коли людина після звільнення ще мала доступ.
- Critical revoke targets у перші хвилини offboarding: prod environment, office network, employee PC, internal services exposed через internet.
- Contractor process, temporary production access process, manager approval і regular access review відсутні або не формалізовані.
- Потрібне автоматичне або принаймні кероване переведення між групами при зміні ролі.

### 0.4. Паролі, secrets і legacy access

- Паролі історично можуть зберігатися в особистих чатах.
- Є credentials, які важко персоналізувати для кожного користувача.
- Є production/server/admin password, який знають кілька людей.
- Ротація shared passwords після звільнення виконується частково.
- Секрети в Git repositories були або є; напрямок руху: прибрати їх звідти.
- `.env` файли, за історичною відповіддю, майже не використовуються і зазвичай не є основним каналом ризику.
- Enterprise password manager потрібен, якщо без нього неможливо закрити gap; vaults по командах бажані.
- Audit доступу до паролів, розділення human passwords і machine secrets бажані.
- Production runtime secrets workflow у canonical docs уже визначений: Sealed Secrets є approved workflow для Kubernetes runtime secrets; External Secrets, SOPS, AWS Secrets Manager, Vault/OpenBao лишаються future alternatives.
- Automatic rotation потрібна за потреби або при можливій компрометації.
- Legacy systems: окремі shared-password системи існують; MFA історично не підтримує жодна з таких систем.
- Shared legacy passwords знають лише довірені ролі на кшталт tech leads або керівників; це все одно лишається risk через відсутність індивідуальної accountability.
- Legacy password rotation, network/VPN/proxy containment, reverse proxy з SSO/MFA, bastion/jump host і password manager check-in/check-out є реалістичними напрямками.
- Session recording наразі не є явною ціллю.
- Неприйнятні або слабкі legacy risks: відсутність logging і owner-а системи.

### 0.5. Пристрої, remote access і admin panels

- Основна OS: Windows; Linux використовується як друга OS для взаємодії з Linux environment; Android/iOS використовуються для тестування; macOS є щонайменше кілька пристроїв.
- Інвентар пристроїв є.
- Disk encryption залежить від конфігурації конкретного ПК.
- Обов'язковий screen lock/password policy не зафіксований.
- Endpoint protection: лише standard Windows Defender.
- Remote lock/wipe для втраченого ноутбука відсутній.
- Заборона доступу до critical SaaS з unmanaged devices бажана.
- Централізована інсталяція software бажана.
- Local admin rights у користувачів є для власних ПК; задачі прибрати local admin у більшості поки не було.
- Remote access: VPN або public URL.
- Немає повної інвентаризації internal apps, доступних з internet.
- Є admin panels без SSO/MFA.
- IP allowlist відсутній.
- Remote access до офісних/локальних серверів є.
- SSH access до Linux servers є і контролюється вручну.
- RDP access до Windows servers є.
- Zero Trust replacement для VPN можна розглядати лише якщо він не створить великого operational overhead.
- Device posture перед access бажаний: managed, encrypted, EDR active.
- Contractors без VPN поки рідкі кейси.
- Short-lived SSH certificates і session recording не є поточною потребою.
- Bastion host, Teleport, Boundary або strongDM-подібна модель бажані як напрямок дослідження.

### 0.6. Cloud, Kubernetes і production access

- Production/cloud: AWS.
- Production access мають приблизно 3-4 людини.
- Admin/root cloud access: 2 людини; ще приблизно 5 людей мають частковий доступ.
- Environments існують, але dev/stage/prod access separation лише частковий.
- Окремих cloud accounts/subscriptions/projects для prod і non-prod немає.
- IAM model гібридна: частина least privilege, частина широкі доступи.
- MFA для cloud root/admin accounts є.
- Break-glass доступ до cloud є.
- IaC: частково Ansible для bootstrap.
- Manual changes у production через web console є.
- CloudTrail/Azure Activity Logs/GCP Audit Logs як процес за історичною відповіддю відсутні; для AWS це P0/P1 gap.
- Kubernetes RBAC історично не налаштований; canonical hardening doc додатково фіксує risk `AlwaysAllow` як open verification item.
- Kubernetes access історично через персональні kubeconfig.
- Argo CD/Jenkins/Grafana не protected by SSO/MFA.
- JIT production access і approval-based elevation бажані.
- Policy-as-code через OPA/Gatekeeper/Kyverno бажана, але після базового RBAC/secrets/audit foundation.

### 0.7. GitHub, CI/CD і supply chain

- Code hosting: GitHub.
- Contributors використовують personal GitHub accounts; MFA залежить від налаштувань самих акаунтів.
- SSO/SAML для GitHub відсутній.
- Organization Owner/Admin: керівник.
- External collaborators або відсутні, або дуже рідкі.
- Branch protection для main/master відсутній.
- Code owners / mandatory review потрібні.
- CI/CD secrets історично зберігаються в Git repositories як Sealed або Kubernetes Secret; canonical rule: не commit-ити plaintext secrets, використовувати Sealed Secrets для Kubernetes runtime secrets.
- CI/CD pipelines можуть змінювати DevOps і developers.
- Secret scanning, dependency scanning/SCA і container image scanning відсутні.
- SBOM бажаний, але не перший blocker.
- Image signing і provenance/SLSA відсутні.
- GitHub Enterprise/GitLab Premium не обов'язкові на цьому етапі, але можуть бути бонусом.
- Окремий supply-chain security tool планується у майбутньому.
- Canonical first controls: GitHub MFA/org 2FA, branch protection, required reviews/status checks, CODEOWNERS, secret scanning, dependency alerts, Trivy або equivalent для dependencies/images, SBOM/provenance після стабілізації pipeline.

### 0.8. Дані, email security, logging і detection

- Sensitive data categories: персональні дані, фінансові дані не рівня банківських рахунків, клієнтські дані, device data, source code, credentials.
- Sensitive documents/data locations: Google Drive і local disks.
- External sharing відбувається через Google Drive.
- Customer data інколи можуть завантажувати локально.
- Обмежень на copying у personal drives/emails немає.
- Data classification не є прямою поточною потребою, але бажана як best practice.
- DLP для email/Drive/SharePoint, file encryption/sensitivity labels і retention policy бажані.
- GDPR або client data-processing requirements можливі для окремих клієнтів у майбутньому.
- Audit доступу до документів наразі не проводиться як окремий процес, лише автоматичні сигнали і review підозрілих ситуацій.
- Email provider: Google Workspace.
- SPF і DKIM увімкнені; DMARC mode невідомий.
- Phishing incidents історично не відомі.
- Email security / anti-phishing protection невідомий.
- Захист Google Drive/Teams/Slack links від phishing/malware, security awareness training і future domain/brand monitoring бажані.
- Centralized SaaS/admin/security logs відсутні.
- Security alerts не має явно визначеного отримувача.
- Unknown чи помічаються login anomalies, disabled MFA, new admin, GitHub secret leak або cloud root login для всіх сервісів.
- Production monitoring є: Grafana, Prometheus; ELK поступово впроваджується; Coroot тестується.
- Alert routing email/Slack/Telegram/PagerDuty/Opsgenie відсутній.
- SIEM не обговорювався як поточний security tool; endpoint logs, cloud provider logs і predefined detections бажані.
- Мінімальний log retention: щонайменше 30 днів; для internal services audit trail бажаний.

### 0.9. Incident response, backup і compliance

- Incident response plan відсутній.
- Decision maker при incident: команда, але без формалізованої ролі.
- Emergency communication channel, якщо Slack/Google/Microsoft недоступні, відсутній.
- Centralized emergency contact list відсутній.
- Security incidents за останні 12 місяців не відомі.
- Runbooks для compromised account, lost laptop, leaked secret, ransomware, GitHub breach і cloud key leak відсутні.
- Tabletop exercises, forensic procedure, cyber insurance і external IR retainer відсутні або не обговорені.
- Backup coverage відома лише частково: production DB.
- Backup location невідома, ймовірно AWS; локальні PC backups відсутні, якщо користувач не налаштував сам.
- Offline/immutable backups відсутні.
- Restore test за останні 3 місяці невідомий або не зафіксований.
- RPO і RTO не встановлені.
- Backup Google Workspace/Microsoft 365, GitHub/GitLab repositories, password manager/emergency kit і DR runbook відсутні.
- Cross-region/cross-cloud DR бажаний пізніше; DR drills можливі дуже рідко, приблизно раз на рік.
- Клієнти вже питали про security/compliance, але формальні security questionnaires, MFA/SSO/encryption/access review/logging requirements, ISO/SOC/NIST/CIS підготовка, DPA, policy set і risk register відсутні.
- Evidence collection бажана.
- Власник compliance documentation не визначений.

### 0.10. Бюджет, adoption і rollout priorities

- Орієнтовний budget: до $50/user/month, залежить від корисних features і обраного stack.
- Annual commitment зарано приймати без pilot і adoption proof.
- Поточні платні ліцензії: GitHub, Jira, Microsoft Windows.
- Дублюючих ліцензій історично не визначено.
- Найважливіше: мінімальний operational overhead і швидке впровадження.
- Частину сервісів можна замінити, якщо новий stack закриє більше задач.
- Обмежень по оплаті іноземних SaaS немає.
- Cost model на 12/24/36 місяців можливий; порівняння TCO із часом адміністратора бажане пізніше.
- Команда потребує адаптації до MFA/SSO/password manager.
- Спротив проти MDM/device control можливий.
- Культура "скинути пароль у чат" або "дати доступ на хвилинку" існує.
- Керівництво готове enforce-ити правила.
- Security awareness training бажаний.
- Security announcements: Slack не використовується; Discord може бути каналом, але потрібна рекомендація.
- SOP/runbooks можуть писати DevOps разом з іншими спеціалістами, які мають Security expertise.
- Access requests owner не визначений: можливі керівник, DevOps або керівники відділів.
- Security champion model бажана.
- Найбільші поточні болі: хаос з доступами, shared passwords, відсутність MFA, unmanaged devices, production access.
- Чіткого дедлайна немає.
- Must-not-break system: prod environment.
- Quick wins: впровадження IdP, нормалізація production access, централізоване керування видачею/зміною паролів.
- Більшість змін можна робити після узгодження з керівництвом IT-відділу.
- CEO/CTO approval path треба уточнювати після демонстрації варіантів.
- Pilot на 5-7 людей можливий.
- Roadmap краще будувати фазами без жорсткої прив'язки до днів, бо це side track, а не full-time security program.
- Formal target architecture document потрібен.

### 0.11. Gap map для агентів, які досліджують security tools

Першочергово шукати інструменти і patterns, які закривають такі gaps:

- IdP/SSO/MFA: єдиний identity source of truth, group-based access, onboarding/offboarding, SCIM, temporary access expiry, break-glass.
- Password manager: shared vaults, audit, emergency access, offboarding, separation human passwords vs machine secrets.
- Private access layer: SSO/MFA або ZTNA/VPN/access proxy для Jenkins, Argo CD, Grafana, Kibana, MinIO, RabbitMQ, DB admin panels і legacy apps.
- Endpoint baseline: device inventory, disk encryption evidence, screen lock policy, EDR/AV, remote lock/wipe, conditional access для unmanaged devices.
- GitHub baseline: enforced MFA, SSO/SAML if available, branch protection, CODEOWNERS, required review/status checks, secret scanning, dependency alerts.
- CI/CD and supply chain: scoped Jenkins credentials, secret scanning, dependency scanning, image scanning, SBOM, provenance, signing, promotion gates.
- AWS/cloud baseline: IAM Identity Center або equivalent, least privilege, CloudTrail, protected log retention, break-glass, account separation або compensating controls.
- Kubernetes baseline: RBAC, OIDC/SSO або controlled kubeconfig lifecycle, Sealed Secrets, audit logs, NetworkPolicy, Pod Security Admission, backup/restore evidence.
- Logging/detection: alert owner, alert routing, admin/security event collection, endpoint/cloud/Kubernetes logs, мінімальний retention, low-noise detections.
- Incident response: short runbooks для compromised account, leaked secret, lost laptop, GitHub/cloud compromise, ransomware; emergency channel і contact list.
- Backup/DR: production DB restore proof, GitHub/docs/password manager backups, Sealed Secrets controller key backup, RPO/RTO, restore drill evidence.
- Governance: lightweight policy packet, risk register, owners, access review cadence, evidence collection, cost model.

Tool research constraints:

- не починати з heavy SIEM/PAM/Vault/Kubernetes bundle без owner-а і operational capacity;
- пріоритезувати low-overhead stack, який дає швидкий pilot для 5-7 людей;
- не змішувати human password vault і Kubernetes runtime secrets;
- для Kubernetes runtime secrets current approved workflow: Sealed Secrets;
- для vendor/pricing claims обов'язково ставити `Needs verification`, доки немає official quote або durable official source;
- не передавати агентам real secrets, private keys, kubeconfig contents, customer data або raw production logs.

## 1. Бізнес-контекст і межі задачі

- [P0] 1.1. Скільки людей зараз у команді: штатні, contractors, тимчасові, зовнішні підрядники?
- [P0] 1.2. Які ролі є в команді: developers, DevOps, QA, support, sales, finance, management, hardware/embedded, field engineers?
- [P0] 1.3. Яке очікуване зростання за 12 місяців: 20-30 -> 40-50 чи без суттєвого росту?
- [P0] 1.4. Компанія працює повністю remote, hybrid чи переважно офісно?
- [P0] 1.5. Є один офіс чи кілька локацій?
- [P0] 1.6. Чи є співробітники за межами України?
- [P0] 1.7. Яка головна ціль проєкту: security hardening, access governance, compliance, зменшення хаосу, підготовка до аудиту, захист production, контроль звільнень?
- [P1] 1.8. Хто буде власником системи доступів: IT admin, DevOps, security owner, CTO, CEO, office admin?
- [P1] 1.9. Чи є виділена IT/security людина, чи це буде додаткове навантаження на DevOps/адміна?
- [P1] 1.10. Яка толерантність до складності: мінімум інструментів чи дорожче, але enterprise-grade?
- [P1] 1.11. Які найбільші страхи: витік паролів, звільнений співробітник із доступом, злам GitHub, ransomware, фішинг, втрата ноутбука, доступ до production?
- [P2] 1.12. Чи плануєте ISO 27001, SOC 2, NIST CSF, CIS Controls, GDPR або клієнтські security questionnaires?

## 2. Поточний стек: SaaS, інфраструктура, робочі сервіси

- [P0] 2.1. Який основний workspace: Google Workspace, Microsoft 365, інше?
- [P0] 2.2. Які основні комунікації: Slack, Teams, Telegram, email, Discord?
- [P0] 2.3. Які таск-трекери: Jira, Linear, ClickUp, Trello, YouTrack, Azure DevOps?
- [P0] 2.4. Де документація: Notion, Confluence, Google Docs, SharePoint, Obsidian, Git repo?
- [P0] 2.5. Де код: GitHub, GitLab, Bitbucket, Azure DevOps, self-hosted Git?
- [P0] 2.6. Які cloud-провайдери: AWS, Azure, GCP, Hetzner, DigitalOcean, локальні сервери?
- [P0] 2.7. Є Kubernetes? Якщо так: self-hosted, MicroK8s, EKS/AKS/GKE, k3s, інше?
- [P0] 2.8. Є CI/CD: Jenkins, GitHub Actions, GitLab CI, Azure Pipelines, TeamCity?
- [P0] 2.9. Є CD/GitOps: Argo CD, Flux, ручний deploy, Helm вручну?
- [P0] 2.10. Які production/admin-панелі є: Grafana, Kibana, Argo CD, Jenkins, MinIO, RabbitMQ, PostgreSQL admin, Mongo Express, VPN panel?
- [P1] 2.11. Які HR/finance/legal сервіси використовуються?
- [P1] 2.12. Які customer-support сервіси: Zendesk, Intercom, HelpScout, Freshdesk, Jira Service Management?
- [P1] 2.13. Які hardware/IoT/device-management сервіси є, якщо компанія виробляє пристрої?
- [P1] 2.14. Які сторонні vendors мають доступ до ваших систем?
- [P2] 2.15. Є список усіх SaaS-додатків і відповідальних owners?

## 3. Identity Provider, акаунти, SSO

- [P0] 3.1. Чи є зараз єдиний Identity Provider: Microsoft Entra ID, Google Workspace, Okta, JumpCloud, інше?
- [P0] 3.2. Чи всі співробітники мають корпоративні акаунти, чи частина працює з особистих Gmail/Telegram/GitHub?
- [P0] 3.3. Чи ввімкнена MFA для всіх користувачів?
- [P0] 3.4. Який тип MFA: SMS, authenticator app, push, passkeys, hardware keys?
- [P0] 3.5. Чи є SSO для GitHub/GitLab/Jira/Slack/Notion/cloud provider?
- [P0] 3.6. Чи є shared accounts: один логін/пароль на кількох людей?
- [P0] 3.7. Чи є окремі admin accounts, чи адміністратори працюють зі своїх звичайних акаунтів?
- [P0] 3.8. Чи є break-glass account на випадок втрати доступу до IdP?
- [P1] 3.9. Чи використовуються групи для видачі доступів, чи доступи видаються вручну кожному користувачу?
- [P1] 3.10. Чи є рольова модель: Developer, QA, Support, DevOps, Finance, Management, Contractor?
- [P1] 3.11. Чи є тимчасові доступи з автоматичним expiry?
- [P1] 3.12. Чи є policy: доступ тільки через SSO, локальні паролі заборонені?
- [P1] 3.13. Чи потрібні passkeys / FIDO2 hardware keys для admin/production доступів?
- [P2] 3.14. Чи потрібен SCIM provisioning/deprovisioning для SaaS?
- [P2] 3.15. Чи потрібні access packages / approval workflows / entitlement management?

## 4. Onboarding, offboarding, access lifecycle

- [P0] 4.1. Як зараз видається доступ новій людині: чекліст, вручну в чаті, через HR, через CTO?
- [P0] 4.2. Як зараз відкликається доступ при звільненні?
- [P0] 4.3. Хто підтверджує, що всі доступи відкликані?
- [P0] 4.4. Чи були випадки, коли людина після звільнення ще мала доступ?
- [P0] 4.5. Які системи критично відкликати в перші 15 хвилин після offboarding?
- [P1] 4.6. Чи є окремий процес для contractors?
- [P1] 4.7. Чи є окремий процес для тимчасових доступів до production?
- [P1] 4.8. Чи є manager approval перед видачею доступу?
- [P1] 4.9. Чи потрібно фіксувати business justification для доступу?
- [P1] 4.10. Чи є регулярний access review: щомісяця, щокварталу, ніколи?
- [P2] 4.11. Чи потрібна інтеграція HR-системи з IdP?
- [P2] 4.12. Чи потрібно автоматично переводити людину між групами при зміні ролі?

## 5. Паролі, shared credentials, secrets

- [P0] 5.1. Де зараз зберігаються паролі: браузер, Google Sheets, Notion, Telegram, 1Password, Bitwarden, KeePass, Vault?
- [P0] 5.2. Чи є спільні паролі до legacy-систем?
- [P0] 5.3. Чи є паролі, які неможливо персоналізувати для кожного користувача?
- [P0] 5.4. Чи є пароль до production/server/admin panel, який знають кілька людей?
- [P0] 5.5. Чи є ротація shared passwords після звільнення людини?
- [P0] 5.6. Чи є секрети в Git repositories?
- [P0] 5.7. Чи є `.env` файли в чатах, пошті, Notion або локально на ноутбуках?
- [P1] 5.8. Чи потрібен enterprise password manager: 1Password, Bitwarden, Keeper, Dashlane?
- [P1] 5.9. Чи потрібні vaults по командах: Engineering, DevOps, Finance, Support, Management?
- [P1] 5.10. Чи потрібен audit: хто відкривав/копіював пароль?
- [P1] 5.11. Чи потрібно розділити human passwords і machine secrets?
- [P1] 5.12. Де мають жити production secrets: Kubernetes Secrets, Sealed Secrets, External Secrets, Vault, AWS Secrets Manager, SOPS?
- [P2] 5.13. Чи потрібен privileged access management / session recording для shared legacy-доступів?
- [P2] 5.14. Чи потрібно будувати proxy-доступ до legacy-системи без розкриття реального пароля?
- [P2] 5.15. Чи потрібна автоматична ротація secrets?

## 6. Пристрої: ноутбуки, BYOD, MDM, EDR

- [P0] 6.1. Пристрої корпоративні чи особисті BYOD?
- [P0] 6.2. Які ОС: Windows, macOS, Linux, iOS, Android? Вкажіть приблизну кількість.
- [P0] 6.3. Чи є облік усіх ноутбуків/телефонів?
- [P0] 6.4. Чи ввімкнене disk encryption: BitLocker, FileVault, LUKS?
- [P0] 6.5. Чи є обов'язковий screen lock/password policy?
- [P0] 6.6. Чи є антивірус/EDR: Defender, SentinelOne, CrowdStrike, ESET, Sophos, інше?
- [P0] 6.7. Чи можна віддалено заблокувати або стерти втрачений ноутбук?
- [P1] 6.8. Чи потрібно заборонити доступ до critical SaaS з unmanaged devices?
- [P1] 6.9. Чи потрібні compliance policies: OS version, encryption, EDR active, firewall on?
- [P1] 6.10. Чи потрібна централізована інсталяція софту?
- [P1] 6.11. Чи є локальні admin-права у користувачів?
- [P1] 6.12. Чи потрібно забрати local admin у більшості користувачів?
- [P2] 6.13. Чи потрібен patch management для Windows/macOS/Linux?
- [P2] 6.14. Чи потрібен inventory installed software?
- [P2] 6.15. Чи є специфічні пристрої для hardware/embedded/production testing?

## 7. Remote access, VPN, Zero Trust, internal apps

- [P0] 7.1. Як зараз люди підключаються до внутрішніх сервісів: VPN, public URL, SSH tunnel, RDP, direct IP, Cloudflare, Tailscale?
- [P0] 7.2. Які internal apps зараз доступні з інтернету?
- [P0] 7.3. Чи є admin-панелі без SSO/MFA?
- [P0] 7.4. Чи є allowlist по IP?
- [P0] 7.5. Чи є remote access до офісних/локальних серверів?
- [P0] 7.6. Чи є SSH-доступ до Linux-серверів? Як він контролюється?
- [P0] 7.7. Чи є RDP-доступ до Windows-серверів?
- [P1] 7.8. Чи потрібно замінити VPN на Zero Trust Access?
- [P1] 7.9. Чи потрібно device posture перед доступом: тільки managed + encrypted + EDR active?
- [P1] 7.10. Чи потрібен доступ для зовнішніх contractors без VPN?
- [P1] 7.11. Чи потрібні короткоживучі SSH-сертифікати замість статичних SSH-ключів?
- [P2] 7.12. Чи потрібен session recording для privileged access?
- [P2] 7.13. Чи потрібен bastion host / Teleport / Boundary / strongDM-подібна модель?

## 8. Cloud, servers, Kubernetes, production-доступи

- [P0] 8.1. Де production: AWS/Azure/GCP/Hetzner/on-prem/Kubernetes?
- [P0] 8.2. Скільки людей мають доступ до production?
- [P0] 8.3. Хто має admin/root доступ до cloud accounts?
- [P0] 8.4. Чи є окремі environments: dev/stage/prod?
- [P0] 8.5. Чи розділені доступи до dev/stage/prod?
- [P0] 8.6. Чи є окремі cloud accounts/subscriptions/projects для prod і non-prod?
- [P0] 8.7. Чи використовується IAM least privilege чи широкі admin-доступи?
- [P0] 8.8. Чи є MFA для cloud root/admin accounts?
- [P0] 8.9. Чи є break-glass доступ до cloud?
- [P1] 8.10. Чи використовується Infrastructure as Code: Terraform, Pulumi, CloudFormation, Ansible?
- [P1] 8.11. Чи є manual changes у production через web console?
- [P1] 8.12. Чи є audit logs: CloudTrail, Azure Activity Logs, GCP Audit Logs?
- [P1] 8.13. Чи є Kubernetes RBAC?
- [P1] 8.14. Чи є доступ до Kubernetes через персональні kubeconfig, shared kubeconfig чи SSO/OIDC?
- [P1] 8.15. Чи є Argo CD/Jenkins/Grafana protected by SSO/MFA?
- [P2] 8.16. Чи потрібна модель Just-in-Time access до production?
- [P2] 8.17. Чи потрібна approval-based elevation: DevOps отримує prod-admin на 2 години?
- [P2] 8.18. Чи потрібна policy-as-code: OPA/Gatekeeper/Kyverno?

## 9. GitHub/GitLab, CI/CD, supply chain

- [P0] 9.1. Де зберігається код: GitHub/GitLab/Bitbucket/Azure DevOps?
- [P0] 9.2. Чи ввімкнена MFA для всіх contributors?
- [P0] 9.3. Чи є SSO/SAML для GitHub/GitLab?
- [P0] 9.4. Хто має Owner/Admin права в organization?
- [P0] 9.5. Чи є external collaborators?
- [P0] 9.6. Чи є branch protection для main/master?
- [P0] 9.7. Чи потрібні code owners / mandatory review?
- [P0] 9.8. Де зберігаються CI/CD secrets?
- [P0] 9.9. Хто може змінювати CI/CD pipelines?
- [P1] 9.10. Чи є secret scanning?
- [P1] 9.11. Чи є dependency scanning/SCA?
- [P1] 9.12. Чи є container image scanning?
- [P1] 9.13. Чи потрібен SBOM?
- [P1] 9.14. Чи підписуються container images?
- [P1] 9.15. Чи є provenance/SLSA-вимоги?
- [P2] 9.16. Чи потрібні GitHub Enterprise / GitLab Premium features?
- [P2] 9.17. Чи потрібен окремий supply-chain security tool?

## 10. Дані, класифікація, DLP

- [P0] 10.1. Які типи чутливих даних є: персональні дані, фінансові, клієнтські, telemetry, security logs, device data, source code, credentials?
- [P0] 10.2. Де зберігаються чутливі документи: Google Drive, SharePoint, Notion, local disks, NAS?
- [P0] 10.3. Чи є зовнішній sharing документів?
- [P0] 10.4. Чи можна співробітникам завантажувати customer data локально?
- [P0] 10.5. Чи є обмеження на копіювання даних у personal drives/emails?
- [P1] 10.6. Чи потрібна data classification: Public/Internal/Confidential/Restricted?
- [P1] 10.7. Чи потрібен DLP для email/Drive/SharePoint?
- [P1] 10.8. Чи потрібне шифрування файлів або sensitivity labels?
- [P1] 10.9. Чи є retention policy для документів, логів, пошти?
- [P2] 10.10. Чи потрібно відповідати GDPR або клієнтським data-processing вимогам?
- [P2] 10.11. Чи потрібен audit доступу до документів?

## 11. Email security, phishing, domain security

- [P0] 11.1. Який email-провайдер: Google Workspace, Microsoft 365, інше?
- [P0] 11.2. Чи ввімкнені SPF, DKIM, DMARC?
- [P0] 11.3. DMARC у режимі none, quarantine чи reject?
- [P0] 11.4. Чи були phishing-інциденти?
- [P0] 11.5. Чи є email security / anti-phishing protection?
- [P1] 11.6. Чи потрібно захищати Teams/Slack/Google Drive links від phishing/malware?
- [P1] 11.7. Чи потрібне security awareness training?
- [P1] 11.8. Чи потрібні simulated phishing campaigns?
- [P2] 11.9. Чи є домени, які треба захищати від spoofing?
- [P2] 11.10. Чи потрібен brand/domain monitoring?

## 12. Logging, monitoring, detection

- [P0] 12.1. Чи є централізовані логи для SaaS/admin/security events?
- [P0] 12.2. Хто отримує security alerts?
- [P0] 12.3. Які події зараз точно помітите: login from new country, impossible travel, disabled MFA, new admin, GitHub secret leak, cloud root login?
- [P0] 12.4. Чи є monitoring production infra/apps: Grafana, Prometheus, ELK, Datadog, Coroot, Zabbix?
- [P0] 12.5. Чи є alert routing: email, Slack, Telegram, PagerDuty, Opsgenie?
- [P1] 12.6. Чи потрібен SIEM: Microsoft Sentinel, Wazuh, Elastic, Google SecOps, інше?
- [P1] 12.7. Чи потрібно збирати logs з endpoints?
- [P1] 12.8. Чи потрібно збирати logs з cloud provider?
- [P1] 12.9. Чи потрібні predefined detections: suspicious login, malware, privilege escalation, data exfiltration?
- [P2] 12.10. Скільки часу треба зберігати security logs: 30/90/180/365 днів?
- [P2] 12.11. Чи є вимоги клієнтів до audit trail?

## 13. Incident response

- [P0] 13.1. Чи є incident response plan?
- [P0] 13.2. Хто приймає рішення при security incident?
- [P0] 13.3. Де emergency communication channel, якщо Slack/Google/Microsoft недоступні?
- [P0] 13.4. Чи є список контактів: CEO/CTO/DevOps/Legal/PR/vendors?
- [P0] 13.5. Чи були security incidents за останні 12 місяців?
- [P1] 13.6. Чи є runbooks: compromised account, lost laptop, leaked secret, ransomware, GitHub breach, cloud key leak?
- [P1] 13.7. Чи є tabletop exercises?
- [P1] 13.8. Чи є процедура форензики: що не чіпати, що збирати, кого залучати?
- [P1] 13.9. Чи є cyber insurance?
- [P2] 13.10. Чи потрібен external incident response retainer?

## 14. Backup, restore, disaster recovery

- [P0] 14.1. Що у вас backup-иться: production DB, Git, cloud configs, SaaS docs, emails, Notion, Jira, Kubernetes manifests?
- [P0] 14.2. Де зберігаються backups?
- [P0] 14.3. Чи є offline/immutable backups?
- [P0] 14.4. Чи тестували restore за останні 3 місяці?
- [P0] 14.5. Який прийнятний RPO: скільки даних можна втратити?
- [P0] 14.6. Який прийнятний RTO: скільки часу можна відновлюватися?
- [P1] 14.7. Чи є backup Google Workspace / Microsoft 365 окремим інструментом?
- [P1] 14.8. Чи є backup GitHub/GitLab repositories?
- [P1] 14.9. Чи є backup password manager / emergency kit?
- [P1] 14.10. Чи є DR runbook?
- [P2] 14.11. Чи потрібен cross-region / cross-cloud DR?
- [P2] 14.12. Чи потрібні регулярні DR drills?

## 15. Compliance, клієнтські вимоги, аудит

- [P0] 15.1. Чи клієнти вже питають про security/compliance?
- [P0] 15.2. Чи треба заповнювати security questionnaires?
- [P0] 15.3. Чи є вимоги до MFA, SSO, encryption, access review, logging?
- [P1] 15.4. Чи потрібна підготовка до ISO 27001/SOC 2/NIST/CIS?
- [P1] 15.5. Чи є data processing agreements з клієнтами?
- [P1] 15.6. Чи є політики: Access Control Policy, Password Policy, Acceptable Use, Incident Response, Backup Policy?
- [P1] 15.7. Чи є risk register?
- [P2] 15.8. Чи потрібна evidence collection: screenshots, exports, audit logs, policy approvals?
- [P2] 15.9. Хто буде підтримувати compliance-документацію?

## 16. Legacy-системи та один пароль для всіх

- [P0] 16.1. Які legacy-системи не підтримують персональні акаунти?
- [P0] 16.2. Які legacy-системи не підтримують MFA?
- [P0] 16.3. Які legacy-системи мають один shared password?
- [P0] 16.4. Хто зараз знає ці паролі?
- [P0] 16.5. Чи можна змінювати ці паролі без простою?
- [P0] 16.6. Чи можна обмежити доступ до legacy-системи мережею/VPN/proxy?
- [P1] 16.7. Чи можна поставити перед legacy-системою reverse proxy з SSO/MFA?
- [P1] 16.8. Чи можна зробити доступ через bastion/jump host?
- [P1] 16.9. Чи потрібен session recording?
- [P1] 16.10. Чи потрібен check-in/check-out пароля через password manager?
- [P2] 16.11. Чи є план заміни legacy-системи?
- [P2] 16.12. Який максимальний прийнятний ризик для legacy-доступів?

## 17. Фінанси, бюджет, ліцензії

- [P0] 17.1. Який бюджет на користувача на місяць прийнятний: $5-10, $10-25, $25-50, $50+?
- [P0] 17.2. Чи готова компанія платити annual commitment, якщо це дешевше?
- [P0] 17.3. Чи вже є платні ліцензії Microsoft/Google/Slack/GitHub/Jira/Notion?
- [P0] 17.4. Чи є ліцензії, які дублюють одна одну?
- [P1] 17.5. Що важливіше: мінімальна ціна чи мінімальний operational overhead?
- [P1] 17.6. Чи можна замінити частину сервісів, якщо новий стек закриє більше задач?
- [P1] 17.7. Чи є обмеження по оплаті іноземних SaaS?
- [P2] 17.8. Чи потрібен cost model на 12/24/36 місяців?
- [P2] 17.9. Чи потрібно порівняти total cost із зарплатою/часом адміна?

## 18. Людський фактор і adoption

- [P0] 18.1. Наскільки команда готова до MFA/SSO/password manager?
- [P0] 18.2. Чи буде спротив проти MDM/контролю пристроїв?
- [P0] 18.3. Чи є культура скинути пароль у чат або дати доступ на хвилинку?
- [P0] 18.4. Чи готове керівництво enforce-ити правила?
- [P1] 18.5. Чи потрібне навчання для співробітників?
- [P1] 18.6. Який канал найкращий для security announcements: Slack, email, meeting, Notion?
- [P1] 18.7. Хто буде писати SOP/runbooks?
- [P1] 18.8. Хто буде обробляти access requests?
- [P2] 18.9. Чи потрібна внутрішня security champion модель?

## 19. Пріоритети впровадження

- [P0] 19.1. Що болить найбільше прямо зараз: хаос з доступами, shared passwords, відсутність MFA, unmanaged devices, production access, legacy-системи?
- [P0] 19.2. Який дедлайн: 2 тижні, 1 місяць, 3 місяці, 6 місяців?
- [P0] 19.3. Чи є must-not-break системи, де не можна ризикувати змінами?
- [P0] 19.4. Які quick wins потрібні першими?
- [P1] 19.5. Які зміни можна зробити без погодження з усією компанією?
- [P1] 19.6. Які зміни потребують approval CEO/CTO?
- [P1] 19.7. Чи можна запускати пілот на 5-7 людях?
- [P2] 19.8. Чи потрібна phased roadmap: 30/60/90 днів?
- [P2] 19.9. Чи потрібен formal target architecture документ?
