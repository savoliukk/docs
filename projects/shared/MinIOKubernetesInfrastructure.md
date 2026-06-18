# Kubernetes-інфраструктура MinIO

Статус: особистий робочий документ  
Джерела: `archive/2026-05-11/minio-kubernetes-infrastructure-plan.md`, platform runbooks

## Призначення

Цей документ визначає shared MinIO operating model для application files, attachments і object-like data, розміщених у Kubernetes.

Product-specific docs мають посилатися сюди і додавати лише bucket names, owners і service contracts.

## Core model

| Шар | Відповідальність |
| --- | --- |
| Operator | Керує MinIO tenant lifecycle. |
| Tenant | Environment або platform-level boundary для MinIO deployment. |
| Bucket | Product або service data boundary. |
| Prefix | Логічна організація всередині bucket. |
| User/service account | Least-privilege access для service. |
| Policy | Дозволені operations і scope. |

## Правила

- Applications не мають використовувати root credentials.
- Root credentials — лише для break-glass/platform-admin.
- Документувати bucket names, policy names, Secret object names і key names; ніколи не документувати secret values.
- Надавати перевагу одній service identity на product/service boundary.
- Визначити lifecycle, retention і backup expectations перед зберіганням production data.
- Тримати public object access вимкненим за замовчуванням; використовувати signed URLs або application-mediated access за потреби.

## GitOps shape

Документувати в GitOps:

- tenant resource;
- bucket requests if managed declaratively;
- service account or policy resources where supported;
- SealedSecret references for credentials;
- NetworkPolicy for MinIO access;
- backup/restore jobs or external backup integration.

Не commit plaintext access keys, secret keys або full connection strings.

## Нотатки Service Center

Service Center використовує MinIO для files і attachments. Team-facing promotion у `SCDocs` має відбуватися лише через окремий approved run.

Потребує перевірки:

- Які buckets потрібні для active tasks, archive tasks і imports?
- Чи mobile uploads proxied через LAS/MCS, чи виконуються через signed URLs?
- Який retention застосовується до completed/deleted task attachments?

## Нотатки TirasCloud

TirasCloud platform docs мають розглядати MinIO як platform service і уникати дублювання цієї shared model.

Потребує перевірки:

- Яким TirasCloud services потрібен MinIO напряму?
- MinIO є Dev-only чи майбутньою Етап/Prod dependency?

## Operator checks

```powershell
kubectl -n <minio-namespace> get pods,svc,pvc
kubectl -n <minio-namespace> get events --sort-by=.lastTimestamp
kubectl -n <app-namespace> get secret <minio-secret-name>
```

Уникати команд, які друкують Secret values.

## Відкриті питання

- Shared platform MinIO чи product-specific tenants?
- Який backup target затверджений?
- Який restore test cadence?
- Які data є customer-sensitive і потребують stricter access/audit?
