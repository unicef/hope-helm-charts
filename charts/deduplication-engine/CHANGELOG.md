# Changelog

## 0.14.4 (2026-04-20)
* Increased memory to 4gGb

## 0.14.3 (2026-04-15)
* Add configurable `modelPvc.mountPath` (default: `/dde-model`) for model data volume across all workloads; also expose `modelPvc.size` and `modelPvc.storageClassName` in values

## 0.14.2 (2026-03-12)
* Redis: use official `redis:8` with custom ConfigMap

## 0.14.1 (2026-03-12)
* Flower: use backend.config CELERY_BROKER_URL when set instead of KeyVault (fixes shared Redis envs)

## 0.14.0 (2026-03-06)
* Add optional `flower.celeryBrokerUrl` to override CELERY_BROKER_URL from values (e.g. when Redis has no auth and Key Vault has password in URL)

## 0.13.0 (2026-02-12)
* Update bitnami dependencies

## 0.12.0 (2026-02-11)
* Add optional `dataPvc` for persistent data mounted at `/var/data`
* Upgrade Redis to 24.1.8 (OCI); add redis.auth.enabled: false for Redis 24.x compatibility

## 0.9.0 (2025-05-21)
* Replaced Valkey with Redis
