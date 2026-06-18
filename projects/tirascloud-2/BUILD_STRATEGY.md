# Build strategy для TirasCloud-2

Цей документ фіксує рекомендований напрям build-технології для TirasCloud Dev. Він не означає, що поточний Jenkins pipeline вже змінений.

## Поточний стан

Поточний delivery path:

```text
Jenkins -> npm ci/test -> Kaniko build -> Docker Hub image -> GitOps newTag -> Argo CD -> microk8s dev
```

Jenkins бере selected service, запускає root dependency install і service test, збирає image через Kaniko, пушить image у registry і змінює тільки `images[].newTag` у dev overlay GitOps repo.

Цей flow уже корисний як migration slice, але Kaniko не варто закріплювати як довгостроковий стандарт без POC альтернативи.

## Факти по codebase

- TirasCloud-2 є Node.js-heavy codebase з багатьма service modules.
- Більшість services має власні `package.json`, `package-lock.json`, `Dockerfile` і `start=node index.js`.
- Dockerfiles збираються з repository root context і часто копіюють shared modules: `modules/common`, `modules/tirasmq`, інколи `config.json`.
- `v2web` і `support` мають frontend/Vite build stage і складніший runtime package flow.
- `logger` є добрим representative validation slice, бо має runtime nuance: PVC-backed file logs і Filebeat sidecar у GitOps.

## Рекомендація

Рекомендований напрям:

```text
Primary build candidate: Docker BuildKit / buildx
Поточна execution boundary: Jenkins
Майбутня execution shape: BuildKit Kubernetes builder, бажано rootless
Поточний registry: Docker Hub
Майбутній registry candidate: Harbor, GHCR або GitLab Registry окремим рішенням
```

BuildKit/buildx треба перевірити через POC до зміни standard pipeline. POC має довести, що BuildKit може замінити Kaniko без зміни GitOps contract: Jenkins оновлює тільки `images[].newTag`, а Argo CD робить deployment.

kpack/Cloud Native Buildpacks не варто брати як основний шлях зараз. Він може бути корисним пізніше, якщо services стануть більш self-contained packages без custom copy shared modules у Dockerfile.

## Що дає BuildKit

### Cache

BuildKit може зберігати build cache в registry або у BuildKit pod PVC.

Практичний ефект: якщо `package-lock.json` не змінився, dependency layer з `npm ci --omit=dev` можна перевикористати. Повторні builds мають бути швидшими, особливо для source-only змін.

Приклад POC-команди:

```powershell
docker buildx build `
  --push `
  --file modules/logger/Dockerfile `
  --tag docker.io/<namespace>/tirascloud-logger:<tag> `
  --cache-from type=registry,ref=docker.io/<namespace>/tirascloud-logger:buildcache `
  --cache-to type=registry,ref=docker.io/<namespace>/tirascloud-logger:buildcache,mode=max `
  .
```

### Safer execution path

BuildKit можна запускати без прив'язки до long-lived Docker daemon або Docker socket як стратегічної залежності. Найпростіший POC може бути Jenkins-compatible, але цільова форма має рухатися до Kubernetes BuildKit builder і rootless execution.

Це зменшує ризик, що CI job зможе впливати на build host ширше, ніж потрібно для build/push.

### SBOM і provenance

Після стабілізації BuildKit path можна додати:

```text
--sbom=true
--provenance=mode=max
```

SBOM відповідає на питання: які OS/npm components є в image.

Provenance відповідає на питання: хто, коли, з якого commit і яким builder зібрав image.

Це nice-to-have після стабільного pipeline, але важлива основа для майбутнього supply-chain security.

### Future signing

Після SBOM/provenance можна окремо додати cosign signing. Це дозволить у майбутньому перейти до policy: запускати в Kubernetes тільки images, які підписані довіреним CI.

Це не входить у перший POC.

## Альтернативи

| Варіант | Переваги | Недоліки | Оцінка для TirasCloud |
|---|---|---|---|
| BuildKit/buildx | Dockerfile-compatible, cache, Kubernetes builder path, SBOM/provenance-ready | Потрібен POC і builder/cache setup | Найкращий primary candidate |
| Поточний Kaniko | Уже працює в Jenkins, daemonless | Не варто фіксувати як довгостроковий standard без cache/support strategy | Залишити baseline до POC |
| Buildah/Podman | Daemonless OCI build, сильний для Red Hat/OpenShift | Більше Kubernetes storage/securityContext нюансів | Запасний варіант |
| kpack/Buildpacks | Менше Dockerfiles, source-to-image, SBOM-friendly | Поточні services не self-contained; shared modules/custom stages ускладнюють перехід | Фаза 2 після packaging normalization |
| Docker-in-Docker | Простий і знайомий | Privileged/Docker socket risk | Не брати як strategic default |
| Kaniko fork | Найменший diff від current flow | Менше strategic upside, залежність від fork governance | Тільки fallback |

## POC checklist

- [ ] Обрати representative service після або поруч із `logger` baseline validation.
- [ ] Зібрати image через BuildKit/buildx без Kaniko.
- [ ] Запушити image з tag rule `b${BUILD_NUMBER}-g${SHA12}`.
- [ ] Перевірити registry cache або явно зафіксувати, чому cache не увімкнений у POC.
- [ ] Перевірити, що GitOps diff змінює тільки `images[].newTag`.
- [ ] Перевірити Argo CD `Synced` і `Healthy`.
- [ ] Перевірити pod readiness/events/log tail без копіювання sensitive data.

## Acceptance criteria

BuildKit можна рекомендувати як accepted standard тільки якщо:

- BuildKit build/push проходить для representative service.
- GitOps contract лишається незмінним.
- Argo CD deployment успішний.
- Cache behavior зрозумілий і повторюваний.
- Є чіткий план, як не тримати Docker socket/privileged mode як довгостроковий борг.

## Документаційні наступні кроки

- Після POC оновити цей документ фактичними результатами.
- Оновити `CI_CD_PIPELINE.md`, якщо Jenkinsfile реально перейде з Kaniko на BuildKit.
- Окремо створити registry strategy note, якщо Docker Hub перестане бути прийнятним default registry.
- Для rollback GitOps/Kubernetes deployment використовувати загальний runbook: `archive/2026-05-11/deployment-rollback-runbook.md`.

## Supply-chain guardrails

Детальний shared baseline: `projects/shared/SoftwareSupplyChainSecurity.md`.

Для цього project не вважати SBOM/provenance/signing першим POC blocker. Порядок:

1. Stable BuildKit/buildx build and push.
2. Unchanged GitOps tag update contract.
3. Repeatable cache behavior.
4. Image scanning.
5. SBOM/provenance.
6. Signing and policy enforcement.

Будь-який future signing gate має мати задокументований emergency rollback path і не має покладатися на personal credentials.
