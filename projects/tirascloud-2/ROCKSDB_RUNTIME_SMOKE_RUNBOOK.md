# Runtime smoke runbook RocksDB

Статус: особистий робочий документ  
Джерела: `archive/2026-05-11/tirascloud-rocksdb-runtime-smoke.md`, `archive/2026-05-11/rocksdb-runtime-smoke.sh`, `ROCKSDB_NATIVE_RUNTIME_BLOCKER.md`

## Призначення

Цей runbook описує безпечний post-deploy smoke check для TirasCloud-2 services, які завантажують `modules/common/rdb.node` через shared RocksDB driver.

Ціль — довести, що current image/runtime може load native addon, бачити expected RocksDB metadata, write to expected mount path і тримати pod stable.

Не копіювати default passwords, connection strings, kubeconfigs або script internals у docs.

## Affected services

| Service | Runtime storage path | Ризик |
| --- | --- | --- |
| `auth` | service-local RocksDB storage | Потрібні native addon runtime і writable mount. |
| `geo` | service-local RocksDB storage | Потрібні native addon runtime і writable mount. |
| `ip2location` | service-local RocksDB storage | Dataset size може зробити copy-based checks повільними. |
| `notifyjournal` | service-local RocksDB storage | Використовувати safe read-only smoke; known code issues не мають ставати write tests. |
| `storemod` | service-local RocksDB storage | Потрібні writable path і service-level read-only smoke. |

`firestates` не входить в active affected list, якщо code paths, які load RocksDB, не re-enabled.

## Safety rules

- Не delete або recreate PVCs.
- Не запускати business write/import actions як smoke test.
- Не print Secret values.
- Не paste kubeconfig contents у docs або chat.
- Persistence restart check має бути explicit, а не default.
- Вважати source shell script `sensitive-review-needed`, доки hardcoded credential-like defaults не removed.

## Що smoke має verify

1. Argo CD app exists and is `Synced` / `Healthy`.
2. Deployment image and strategy are expected.
3. PVC is `Bound`.
4. Pod is `Ready`.
5. Node runtime and native addon metadata match the expected contract.
6. Required runtime library для RocksDB resolved.
7. Mount path is writable.
8. RocksDB metadata files are visible.
9. Temporary native smoke can run outside live keyspace.
10. Service-level read-only smoke responds.
11. Restart count does not grow.
12. Logs/events do not show native/runtime/PVC critical patterns.

## Pass criteria

Pass лише коли:

- app is synced and healthy;
- deployment has expected image, PVC and mount path;
- native addon loads in the runtime;
- mount is writable;
- temporary native smoke passes;
- read-only service smoke passes;
- pod remains ready;
- no critical runtime errors appear.

## Fail conditions

Fail у випадку:

- Argo CD app not synced/healthy;
- PVC not bound;
- wrong mount path or missing writable path;
- native addon ABI/library mismatch;
- RocksDB metadata missing where expected;
- read-only smoke timeout/error;
- restart count growth;
- critical logs such as native crash, corruption, permission denied or unresolved library.

## Інтеграція з blocker note

Цей runbook не знімає blocker. Це verification path після того, як runtime image, native addon compatibility і PVC model fixed.

Тримати `ROCKSDB_NATIVE_RUNTIME_BLOCKER.md` як concise decision note і посилати цей runbook для operational validation.

## Потребує перевірки

- Який exact glibc-based Node runtime accepted?
- Native addon rebuilt чи reused?
- Який storage class використовується per service?
- Які smoke actions guaranteed read-only для кожного service?
- Чи source script sanitized, щоб remove credential-like defaults?
