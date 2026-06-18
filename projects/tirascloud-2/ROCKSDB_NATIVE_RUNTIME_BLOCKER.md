# RocksDB native runtime blocker для TirasCloud-2 CI/CD

Це blocker note для TirasCloud-2 services, які використовують RocksDB через prebuilt native addon. Це не implementation plan і не зміна pipeline.

## Що знайдено

У коді RocksDB не оформлений як npm dependency. Спільний driver вантажить prebuilt binary:

```text
modules/common/rdbDriver.js -> modules/common/rdb.node
```

`rdb.node` є Linux native addon. Під час inspection знайдені ознаки збірки під Node 22 ABI (`node_register_module_v127`) і glibc-based shared libraries, включно з RocksDB shared library expectation на кшталт `librocksdb.so.5.17`.

Це означає, що `npm ci` і generic file-shape smoke check можуть пройти, але service container впаде тільки під час runtime load native addon-а.

## Чому поточні Dockerfile ризикові

Affected services зараз мають runtime images на `node:18-alpine`. Це небезпечно для `rdb.node` з двох причин:

- Node 18 має інший native addon ABI, ніж binary, який виглядає зібраним під Node 22.
- Alpine використовує musl runtime, тоді як addon очікує glibc-style shared libraries і RocksDB system libraries.

Проста заміна на `node:22.22.0-alpine` не є достатнім підтвердженим рішенням: Node ABI стане ближчим, але musl/glibc і `librocksdb.so.5.17` все ще треба перевірити або забезпечити.

## Affected services

| Service | Runtime path | RocksDB data path |
|---|---|---|
| `auth` | `auth/services/rocksdbStorageService.js` -> `common/rdbDriver.js` | `auth/rdbStorage` |
| `geo` | `geo/storage.js` -> `common/rdbDriver.js` | `geo/gsmStorage` |
| `ip2location` | `ip2location/storage.js` -> `common/rdbDriver.js` | `ip2location/ipStorage` |
| `notifyjournal` | `notifyjournal/storage.js` -> `common/rdbDriver.js` | `notifyjournal/notifyStorage` |
| `storemod` | `storemod/storage.js` -> `common/rdbDriver.js` | `storemod/modulesStorage` |

`firestates` має `storage.js`, але current runtime path не вантажить його, бо підключення RocksDB storage у `firestatesModule.js` закоментоване. Тому `firestates` не входить у active affected list.

## Мінімальні unblock conditions

Перед тим як вважати affected services CI/CD-ready, треба закрити всі умови:

- Runtime: compatible glibc-based Node/RocksDB base image або rebuild native addon під обраний runtime.
- CI: native smoke check має fail before image build/push, якщо `rdb.node` не вантажиться або basic `set/get` не працює.
- GitOps/CD: для кожного RocksDB data path має бути explicit writable mount; якщо дані мають переживати pod restart, потрібен PVC і зрозуміла persistence policy.
- Rollout: affected services не promoted у Dev як healthy тільки на основі generic `ci-service-smoke.js`.

## Operational validation

Після runtime/image/PVC fix використовуй `ROCKSDB_RUNTIME_SMOKE_RUNBOOK.md` як safe post-deploy verification path.

До sanitization не копіювати shell script internals у документацію: source script має credential-like default і має бути очищений або розглядатися як sensitive-review-needed.

