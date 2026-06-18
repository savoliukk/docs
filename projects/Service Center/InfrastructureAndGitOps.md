# Інфраструктура і GitOps Service Center

Статус: особистий робочий документ  
Джерела: `archive/2026-05-11/SC_Infrastructure.md`, `archive/2026-05-11/SC_Infrastructure_recommendations.md`, `C:\work\SCInfrastructure`, `C:\work\SCNet`, `C:\work\SCNode`, `C:\work\SCDocs`

## Поточний feature-контур

Активний Kubernetes-контур Service Center:

```text
SCNet/feature/k8s
  -> Jenkins job SCNet_feature_pipeline_job
  -> Docker Hub images
  -> SCInfrastructure/argocd-feature
  -> Argo CD ApplicationSets
  -> namespace scnet-feature
```

Поточні підтвердження з repo:

- `C:\work\SCInfrastructure\docs\scnet-feature-cicd.md`;
- `C:\work\SCInfrastructure\ci\pipelines\SCNet_feature_pipe.groovy`;
- `C:\work\SCInfrastructure\apps\scnet-feature\app.yaml`;
- `C:\work\SCInfrastructure\apps\scnet-feature\*\charts\values.image.yaml`.

## Services у контурі

Jenkins зараз builds і publishes п'ять feature images:

| Service | Image repository |
| --- | --- |
| ActiveTasksService | `<DOCKER_NAMESPACE>/scnet-feature-activetasksservice` |
| ArchiveTasksService | `<DOCKER_NAMESPACE>/scnet-feature-archivetasksservice` |
| MistoCommunicationService | `<DOCKER_NAMESPACE>/scnet-feature-mistocommunicationservice` |
| MistoGuardObjectsService | `<DOCKER_NAMESPACE>/scnet-feature-mistoguardobjectsservice` |
| StaffService | `<DOCKER_NAMESPACE>/scnet-feature-staffservice` |

SCNode/LAS існує як окремий Node.js gateway і потребує явного deployment/integration decision для feature contour.

Image tag rule for new builds: `<DOCKER_NAMESPACE>/<repo>:b<BUILD_NUMBER>-g<SHA12>`. The tag identifies the artifact, not the environment; feature/dev/stage/prod identity belongs to GitOps branches, overlays, or Argo CD Applications. Promotion must reuse the same `repo:tag` and verify the same digest instead of rebuilding.

## Platform dependencies

Feature stack залежить від наявних platform services:

| Dependency | Призначення |
| --- | --- |
| PostgreSQL | relational persistence для SCNet services |
| RabbitMQ | RPC і async message flow |
| MinIO | file/attachment storage |
| Elasticsearch | archive search і logs backend |
| Logstash | centralized log ingestion |
| Kibana | log inspection |

Використовувати в docs service names і object names, а не credentials або connection-string values.

## Layout Argo CD

`apps/scnet-feature/app.yaml` defines ApplicationSets для:

- feature config app;
- ActiveTasksService;
- ArchiveTasksService;
- MistoCommunicationService;
- MistoGuardObjectsService;
- StaffService.

Feature config app володіє:

- namespace `scnet-feature`;
- ConfigMap;
- runtime Secret object;
- read-only viewer RBAC.

## Runtime configuration

Дозволено документувати:

- `scnet-feature-config`;
- `scnet-feature-secrets`;
- env var names;
- connection string key names;
- service DNS names without credentials.

Не документувати:

- RabbitMQ passwords;
- MinIO access keys or secret keys;
- database passwords;
- token values;
- full connection strings containing credentials.

## Поточний борг по секретах

Feature contour зараз має plaintext Kubernetes Secret manifest у `SCInfrastructure`.

Це відомий temporary debt, який треба замінити перед production-grade PR-preview flow.

Поточний затверджений workflow для цього docs repository: Sealed Secrets.

Documentation може називати object і key names, але не має копіювати values.

## Operator checks

### Jenkins

Перевірити feature job:

```powershell
# Open Jenkins and inspect:
# SCNet_feature_pipeline_job
# build stages
# pushed image tags
```

Очікуваний результат:

- five images are built;
- five images are pushed;
- `values.image.yaml` files are updated in `SCInfrastructure/argocd-feature`.

### Argo CD

Перевірити generated applications:

```powershell
kubectl -n argocd get applications | findstr scnet-feature
```

Очікуваний результат:

- config app is `Synced` and `Healthy`;
- service apps are `Synced` and `Healthy`.

### Kubernetes

Перевірити namespace і pods:

```powershell
kubectl -n scnet-feature get pods -o wide
kubectl -n scnet-feature get svc
kubectl -n scnet-feature get configmap
kubectl -n scnet-feature get secret
```

Не друкуй значення секретів під час документування перевірок.

### Logs

Перевірити app logs:

```powershell
kubectl -n scnet-feature logs deploy/<deployment-name> --tail=200
```

Для centralized logs використовувати Kibana і filter by namespace `scnet-feature`, service, pod або container.

## Кандидати promotion для SCDocs

Потенційні later promotions:

- merge sanitized infrastructure model у `C:\work\SCDocs\SC_Infrastructure.md`;
- тримати `C:\work\SCDocs\SCNet_Feature_Kubernetes_Runbook.md` aligned із `SCInfrastructure\docs\scnet-feature-cicd.md`;
- оновлювати VPN docs лише коли access model змінюється;
- promote secret-management changes лише після того, як plaintext secret debt resolved або чітко documented as temporary.

Promotion до `SCDocs` має бути окремим approved run з exact target files.

## Пов’язані shared-документи

- `projects/shared/KubernetesSecurityHardening.md` для RBAC, audit, NetworkPolicy і Sealed Secrets baseline.
- `projects/shared/MinIOKubernetesInfrastructure.md` для shared MinIO model.
- `projects/shared/KubernetesObservabilityLoggingGitOps.md` для logging verification.
- `projects/shared/SoftwareSupplyChainSecurity.md` для CI/CD і AI/agent safety.

## Відкриті питання

- Чи `SCNode` deployed як частина `scnet-feature`, окремий `las` app або later contour?
- Який secret workflow є approved replacement для plaintext feature secrets?
- Які smoke checks mandatory після кожного feature deploy?
- Коли persistent `scnet-feature` contour переходить до PR-preview environments?
