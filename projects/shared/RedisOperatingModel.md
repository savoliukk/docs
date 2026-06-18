# Operating model Redis

Статус: особистий робочий документ  
Джерела: Redis research files у `archive/2026-05-11/`, platform notes TirasCloud

## Призначення

Цей документ фіксує placement і operating model Redis/Valkey для Kubernetes і GitOps environments.

Він сам по собі не ухвалює production topology. Поточний затверджений напрям після Dev: **Sentinel або Cluster**, фінальний вибір лишається відкритим.

## Класифікація workloads

| Сценарій використання | Типова вимога | Нотатки |
| --- | --- | --- |
| Cache | Низька durability, rebuildable state, TTL і eviction прийнятні | Надавати перевагу simple topology, якщо cache loss не створює incident-level impact. |
| Session store | Вища availability і безпечніша persistence | Визначити RPO/RTO перед вибором topology. |
| Queue-like state | Обережна durability і retry behavior | Перевірити, чи Redis є правильним system of record. |
| Presence/online state | Швидкі updates, допускає partial rebuild | Потребує чіткої behavior після restart/failover. |

## Варіанти placement

| Варіант | Найкраще підходить для | Головний ризик |
| --- | --- | --- |
| Managed Redis/Valkey | Production teams, які хочуть нижчий operational burden | Cost, provider lock-in, network dependency. |
| In-cluster standalone | Dev і low-criticality workloads | Single point of failure. |
| In-cluster Sentinel | Помірний HA зі звичною Redis semantics | Operational complexity і client compatibility. |
| Redis Cluster | Sharding і вищий scale | Client support, redirects, resharding і operational complexity. |
| External self-hosted VM | Простіша Kubernetes boundary | Ручна HA/backup/security work. |

## Поточна рекомендація

Для Dev:

- тримати GitOps-managed Redis baseline простим;
- документувати persistence, storage class і Secret names;
- не зберігати Redis credentials у plaintext Git;
- додати smoke checks для connection, basic set/get і app-specific behavior.

Після Dev:

- обрати Sentinel, коли головна потреба — failover для moderate-size session/cache workload і clients підтримують Sentinel;
- обрати Cluster, коли horizontal scaling, sharding або large keyspace pressure є реальною вимогою і clients підтримують Cluster redirects;
- використовувати managed Redis/Valkey, якщо operational ownership стає дорожчим за provider cost.

## Специфічні нотатки TirasCloud

Raw Redis key audit у `archive/2026-05-11/Дослідження поточного стану Redis.md` є internal-only. Він показує, що Redis зберігає категорії state, пов'язані з auth/session/presence/push. Не публікувати конкретні key counts як external material.

Потребує перевірки:

- Які services залежать від Redis для user-facing session behavior?
- Які keys є rebuildable, а які incident-critical?
- Який RPO/RTO прийнятний для session state?
- Чи client stack повністю підтримує Sentinel або Cluster?

## GitOps requirements

- Secret object і key names можна документувати; values не можна.
- Persistence settings мають бути explicit.
- Resource requests/limits мають бути видимі в GitOps.
- Alerts мають покривати memory pressure, evictions, persistence failures, restarts і replication/failover health.
- Backup/restore потрібний, якщо Redis тримає non-rebuildable state.

## Smoke checks

Використовувати безпечні, non-sensitive checks:

```powershell
kubectl -n <namespace> get pod,svc,pvc | findstr redis
kubectl -n <namespace> logs deploy/<redis-operator-or-redis> --tail=100
```

Application smoke має використовувати synthetic keys і короткі TTLs. Не друкувати passwords або full connection strings.

## Відкриті питання

- Sentinel чи Cluster як перша post-Dev ціль?
- Redis чи Valkey як long-term implementation?
- Які product flows visibly fail, якщо Redis state втрачений?
- Які backups або snapshots потрібні для вибраного mode?
