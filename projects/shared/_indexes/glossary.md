# Глосарій

Статус: канонічний індекс

| Термін | Значення |
| --- | --- |
| GitOps | Operating model, у якій Git є source of truth для desired Kubernetes state. |
| Argo CD Application | Об'єкт Argo CD, який reconciles Git path у cluster. |
| ApplicationSet | Генератор Argo CD, який створює Applications із templates. |
| RBAC | Role-Based Access Control. Kubernetes authorization model для users, groups і service accounts. |
| `AlwaysAllow` | Kubernetes authorizer mode, який дозволяє всі requests. Вважати production blocker, якщо він не ізольований навмисно для testing. |
| IdP | Identity Provider: source of truth для users, groups, SSO і MFA. |
| OIDC | OpenID Connect: identity layer поверх OAuth 2.0, часто використовується для SSO в Kubernetes-adjacent tools. |
| SSO | Single Sign-On: єдиний login path для кількох systems через IdP. |
| MFA | Multi-Factor Authentication: перевірка login більше ніж одним фактором. |
| Conditional Access | Policy, яка дозволяє або блокує доступ залежно від user, group, device, location, risk або MFA state. |
| PIM | Privileged Identity Management: Microsoft Entra capability для eligible/time-bound privileged role activation, approvals, justification і audit history. |
| Entra Private Access | Microsoft Entra / Global Secure Access capability для identity-aware private app access через connectors/client path; не замінює app-native RBAC. |
| Global Secure Access | Microsoft SSE/ZTNA family, яка включає Private Access і Internet Access scenarios. |
| Intune | Microsoft endpoint management platform для device enrollment, compliance policies, configuration і Conditional Access signals. |
| Microsoft Sentinel | Microsoft cloud-native SIEM/SOAR; у цьому knowledge base розглядається як вузький evidence layer, не full log lake by default. |
| Defender for Cloud | Microsoft cloud security posture / workload protection platform для Azure, AWS, GCP і selected Kubernetes/container scenarios. |
| Azure Arc-enabled Kubernetes | Azure Arc onboarding model для Kubernetes clusters outside Azure; може давати inventory, extensions, policy/monitoring/security integrations через outbound agents. |
| GitHub Secret Protection | GitHub Advanced Security capability для secret scanning і push protection, особливо для private/internal repos із paid licensing. |
| GitHub Code Security / CodeQL | GitHub Advanced Security code scanning capability; CodeQL аналізує code paths і показує findings у developer workflow. |
| Pod Security Admission | Вбудований Kubernetes admission controller для enforcement Pod Security Standards через namespace labels. |
| ValidatingAdmissionPolicy | Native Kubernetes policy mechanism на CEL для validation API requests без окремого webhook engine. |
| Policy-as-code | Опис security або governance правил як versioned manifests/policies, які можна review і apply через GitOps. |
| Break-glass | Аварійний admin access path на випадок втрати normal SSO/control-plane access; має бути logged, reviewed і rotated після використання. |
| Offboarding | Процес відкликання доступів при звільненні або зміні ролі: IdP, GitHub, cloud, VPN, devices, admin panels і password vault. |
| SealedSecret | Encrypted Kubernetes Secret manifest, який можна зберігати в Git і decrypted лише cluster controller. |
| ExternalSecret | Kubernetes object, який syncs secret material із external secret store. |
| SOPS | File encryption tool, який часто використовують для GitOps secrets. |
| Vault / OpenBao | Secret-management systems для static і dynamic secrets. |
| Password vault | Кероване сховище human/shared secrets із owners, groups, audit і recovery process. |
| ZTNA | Zero Trust Network Access: доступ до private apps через identity/device-aware broker замість прямого public exposure. |
| MDM | Mobile Device Management / endpoint management для inventory, policy enforcement, disk encryption і remote wipe. |
| CloudTrail | AWS audit service, який записує account/API activity для investigation і compliance evidence. |
| Branch protection | GitHub rules, які захищають critical branches через pull request, review, status checks і заборону force push. |
| CODEOWNERS | GitHub file, який призначає owners для paths і може вимагати review від відповідальних команд. |
| Runtime detection | Виявлення suspicious process, file, network або syscall behavior під час виконання workload, наприклад через Falco, Tetragon, Kubescape runtime або NeuVector. |
| SBOM | Software Bill of Materials: структурований dependency inventory для software artifacts. |
| Provenance | Build attestation, який описує, що built artifact, з якого source і під яким builder. |
| Cosign | Tool, який часто використовують для signing container images і attestations. |
| NodePort | Kubernetes Service type, який відкриває port на cluster nodes. |
| LoadBalancer | Kubernetes Service type, який просить external або bare-metal load balancer expose traffic. |
| MetalLB | Bare-metal LoadBalancer implementation for Kubernetes. |
| Ingress | Kubernetes HTTP/HTTPS routing API; не підходить для raw UDP device routing. |
| Gateway API | Новіший Kubernetes networking API для Gateway і Route objects. UDP support maturity треба перевіряти перед production use. |
| `externalTrafficPolicy: Local` | Kubernetes Service setting, який часто використовують, коли важливо preserve client source IP. |
| NetworkPolicy | Kubernetes L3/L4 traffic policy. Потребує CNI enforcement, наприклад Calico. |
| TMQ | TirasCloud message broker/channel layer used by services. |
| LAS | Service Center / oLoader gateway protocol path through SCNode and RabbitMQ. |
| RocksDB native addon | Native binary, який завантажують selected Node.js services; має відповідати Node ABI, libc і runtime libraries. |
| Synthetic example | Вручну переписаний example, який зберігає проблему без company secrets, customer data або internal identifiers. |
