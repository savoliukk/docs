# Docs Index And Open Questions Review Memory

Last run: 2026-05-29 10:06:24 +03:00
Mode: read-only health check; canonical docs/indexes/process/archive/SCDocs/code repos не редагувалися, оновлено лише automation memory.

Summary:
- Preflight виконано успішно. docs, SCDocs, ideal-octo-giggle і TirasCloud-2 залишаються dirty; SCNet, SCNode і SCInfrastructure clean.
- process/ містить 2 нові security-governance sources: Entra-Arc-MicroK8s-Access-RBAC-PoC.md і Microsoft Entra vs Google Workspace Cloud Identity.md.
- Preflight знайшов secret-risk wording у цих process files: 53 і 43 hits відповідно. High-confidence patterns для private keys, API tokens або real connection strings у scanned Markdown не знайдено.
- Required indexes існують. project-map.md, resource-register.md, technology-map.md і root README.md мають resolvable projects/*.md refs; explicit archive/*.md backtick refs resolve. Active stale refs на process/ не знайдено.
- Stale/ambiguous refs: projects/tirascloud-2/CI_CD_PIPELINE_REVIEW_SERVICES_2026-05-08.md line 14 досі посилається на старий absolute path довгого Kubernetes exposure doc; Service Center docs мають intentionally external SCDocs/workspace refs, а roadmap artifact names на кшталт ServiceCenterContract.md лишаються planned/missing.
- Open questions delta лишається partial: додати/sync observability data views/masking/retention/dashboards, MinIO bucket/upload/retention/backup/restore, Service Center LAS attachments/MCS/source-doc/tests, TirasCloud GitOps secrets/PVC/promotion/data-migration, RocksDB addon/storage/read-only smoke/source sanitization, Rancher/NeuVector compatibility/licensing/management/audit mode, legacy privileged access, Jira label governance, IaC ownership, DLP/local LLM/signing-gate questions.
- Resource/technology register delta: resource-register.md не покриває частину canonical docs; technology-map.md може додати TMQ, Firebase/FCM, Telegram Bot API, SMSC, Socket.IO/WebSocket, RabbitMQ, SignalR, PostgreSQL, SCNode/LAS і MistoCommunicationService як first-class rows.
- Duplicate signals: exact process/SCDocs duplicates не знайдено; same-name archive <-> SCDocs duplicates лишаються SC_Infrastructure.md і minio-kubernetes-infrastructure-plan.md.
- Recommended future batch: security/governance analyze/apply для 2 process files із sanitized merge/update у Microsoft/security/Kubernetes/access docs та indexes; SCDocs promotion = none.
- Workspace follow-up: не чіпати dirty SCDocs/code/GitOps repos у docs run; окремо переглянути зміни в TirasCloud-2 і ideal-octo-giggle, а також stale external refs у Service Center docs.
