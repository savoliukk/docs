# Kubernetes observability і logging з GitOps

Статус: особистий робочий документ  
Джерела: `archive/2026-05-11/kubernetes-observability-logging-gitops-guide.md`, наявні platform docs TirasCloud і Service Center

## Призначення

Цей документ визначає прагматичний Kubernetes observability baseline для малих platform teams, які використовують GitOps.

Він фокусується на повторюваних operator checks, а не на повній observability platform strategy.

## Базовий stack

| Шар | Роль |
| --- | --- |
| Application logs | Надавати перевагу `stdout`/`stderr`; file logs потребують явного sidecar/tailer design. |
| Filebeat | Збирає container logs або вибрані file logs. |
| Logstash | Parse, enrich і forward events. |
| Elasticsearch | Searchable log storage. |
| Kibana | Operator UI для log search і incident review. |
| Coroot / Prometheus | Service health, resource usage, latency і dependency visibility. |

## GitOps rules

- Operators, CRDs і runtime resources мають бути представлені в GitOps.
- Environment-specific values мають бути в overlays або Helm values, а не в скопійованих manifests.
- Не зберігати secret values у logging pipeline manifests.
- Logging resources мають мати owner labels і namespace labels, які роблять Kibana filtering передбачуваним.
- Великі зміни Elasticsearch, ClickHouse або PVCs потребують maintenance window і rollback notes.

## Контракт application logging

Для кожного service document:

- log destination: stdout, stderr, file, sidecar, or custom endpoint;
- service label and namespace;
- expected index/data view;
- fields useful for filtering: service, pod, container, namespace, request id, trace id if available;
- відомі sensitive fields, які треба drop або mask.

Не відправляти в logs raw tokens, credentials, customer PII, full request bodies або full connection strings.

## Operator checks

Безпечні cluster checks:

```powershell
kubectl get ns
kubectl -n <logging-namespace> get pods
kubectl -n <logging-namespace> get events --sort-by=.lastTimestamp
kubectl -n <logging-namespace> logs deploy/<component> --tail=200
```

Workload log checks:

```powershell
kubectl -n <app-namespace> logs deploy/<deployment> --all-containers --tail=200
kubectl -n <app-namespace> logs deploy/<deployment> --previous --all-containers --tail=200
```

Для GitOps-managed resources:

```powershell
kubectl -n argocd get applications
kubectl -n argocd get app <app-name>
```

## Потік перевірки

1. Підтвердити, що application pod пише log line.
2. Підтвердити, що Filebeat або налаштований collector бачить source.
3. Підтвердити, що Logstash отримує і forwards event.
4. Підтвердити, що Elasticsearch indexes event.
5. Підтвердити, що Kibana може filter by namespace, service, pod and message.
6. Записати missing fields або parsing errors як backlog tasks.

## Нотатки TirasCloud

- `logger` має file-log behavior і використовує PVC-backed path плюс Filebeat sidecar.
- TirasCloud platform docs мають посилатися сюди для shared logging behavior і залишати локально лише service-specific details.
- Потребує перевірки: canonical Kibana data view names і required labels для кожного service.

## Нотатки Service Center

- SCNet services і SCNode/LAS мають exposing logs, які можна filter by namespace and service.
- Service Center runbooks мають вказувати, чи logs є лише в Kubernetes, у centralized logging, або в обох місцях.
- Потребує перевірки: mandatory post-deploy smoke checks і expected log lines.

## Відкриті питання

- Які data views є canonical для кожного environment?
- Які fields треба mask на рівні Logstash або application?
- Який retention прийнятний для Dev, Етап і Prod?
- Які dashboards потрібні перед production readiness?
