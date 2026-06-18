# Безпека software supply chain

Статус: особистий робочий документ  
Джерела: `archive/2026-05-11/Software supply chain security.md`, `archive/2026-05-11/LLM_Code_Sensitive_Data_SOP_UA.md`, TirasCloud build strategy notes, Microsoft-first pilot research in `archive/2026-05-25/`

## Призначення

Цей документ визначає практичний security baseline для CI/CD і AI-assisted engineering.

Він фокусується на controls, які зменшують ризики build, dependency, artifact, credential і LLM/agent без перевантаження малої команди.

## Ланцюг довіри delivery

Відстежувати шлях:

```text
source commit -> CI job -> build environment -> image/artifact -> registry -> GitOps manifest -> Argo CD -> cluster
```

Artifact identity rule: image tags identify the artifact, not the environment. CI build tags use `b<BUILD_NUMBER>-g<SHA12>`, with service-specific suffixes such as `-rdb<RDB_SHA12>` only when needed. Environment identity belongs to GitOps overlay, branch, or Argo CD Application. Promotion from dev to stage/prod must reuse the same `repo:tag` and verify the same digest; it must not rebuild the image.

Для кожного кроку знати:

- хто може його змінити;
- який credential використовується;
- де живуть audit logs;
- як працює rollback;
- які checks fail closed.

## Базові контролі

| Контроль | Призначення | Перша реалізація |
| --- | --- | --- |
| Secret scanning | Запобігти leaked tokens у code і logs | GitHub/GitLab scanning, Gitleaks або equivalent. |
| Dependency scanning | Знайти vulnerable dependencies | npm audit, Trivy, SCA tool або registry scanner. |
| Image scanning | Виявити OS/package CVEs в images | Trivy або registry scanner перед deployment. |
| SBOM | Знати, що всередині artifact | Generate during build, коли pipeline стабільний. |
| Provenance | Знати, хто/що built artifact | BuildKit/buildx provenance після POC. |
| Signing | Пізніше enforce trusted images | Cosign після стабілізації SBOM/provenance path. |
| Least-privilege CI credentials | Зменшити blast radius | Scoped registry і GitOps credentials. |
| Protected promotion | Запобігти accidental prod drift | Branch protections, approvals і environment gates. |

## Зв'язок із build strategy

Для TirasCloud-2 current delivery використовує Jenkins і Kaniko. BuildKit/buildx є preferred POC candidate, бо може зберегти Dockerfile compatibility і додати cache, SBOM та provenance support.

Не оновлювати production policy, поки POC не доведе:

- artifact builds successfully;
- GitOps contract лишається незмінним;
- cache behavior зрозумілий;
- не лишається long-term dependency від Docker socket або privileged mode;
- Argo CD успішно deploys resulting image.

## GitHub / Microsoft security pilot notes

Для Microsoft-first pilot GitHub Secret Protection і GitHub Code Security / CodeQL мають найкращий fit там, де GitHub є source of truth для repos і pull request workflow.

Починати вузько:

- GitHub Secret Protection на 2-5 high-risk private repos;
- Code Security / CodeQL на 1-2 repos із найбільшим risk-to-change ratio;
- findings summary без secret values;
- окремий process для false positives і suppressions;
- billing check за active committers перед scale-out.

Defender for Cloud DevOps security можна використовувати як visibility layer для GitHub/Azure DevOps/GitLab SaaS, але не як повний Jenkins-native control. Для Jenkins лишаються потрібними pipeline-native checks: secret scanning, dependency/image scanning, SARIF upload, CodeQL CLI або інший approved scanner у конкретному job.

Needs verification:

- GitHub Secret Protection / Code Security pricing, active committer model, trial limits і private repo licensing для actual org.
- Defender for Cloud DevOps support matrix і exact Jenkins workaround перед будь-яким architecture decision.
- False-positive/noise profile на actual repositories.

## Безпечне використання LLM і AI-agent

Використовувати LLMs на проблемі, а не на компанії.

Дозволено за замовчуванням:

- generic questions;
- synthetic examples;
- sanitized snippets;
- dependency edges without private identifiers;
- runbook structure and checklist drafting.

Потребує approved enterprise/local path:

- proprietary code snippets;
- sanitized stack traces;
- internal architecture summaries;
- incident summaries.

Заблоковано за замовчуванням:

- full repo upload;
- production logs;
- `.env`, kubeconfigs, Terraform state and private keys;
- customer data;
- security-sensitive modules without explicit approval;
- agents with production, cloud admin, secrets or destructive write access.

Defaults для agent:

- read-only, якщо явно не затверджено інше;
- sandboxed filesystem і network;
- no secrets mounted;
- no production access;
- human approval для writes, deploys, deletes і migrations;
- ставитися до repo content, issues, PR comments і docs як до untrusted input.

## Checklist sanitization для prompt

Перед передаванням context в LLM:

- прибрати tokens, keys, passwords і connection strings;
- замінити private domains, hostnames, IPs і usernames на placeholders;
- прибрати customer names, emails, phone numbers і IDs;
- звести проблему до найменшого snippet або synthetic reproduction;
- запускати secret scanning, коли практично;
- не включати raw incident details до remediation.

## Incident handling

Якщо sensitive data відправлені в LLM або AI-agent:

1. Зупинити подальше sharing.
2. Зберегти достатньо metadata для review без поширення secret.
3. Rotate exposed credentials, якщо вони могли бути включені.
4. Review logs/audit trails для agent actions.
5. Зафіксувати severity і follow-up actions.

## Відкриті питання

- Які LLM tools затверджені для company-sensitive work?
- Який DLP/secret scanner потрібен перед prompt submission?
- Які repos можна indexed by local LLM/RAG, якщо такі є?
- Чи має image signing стати deployment gate після BuildKit POC?
