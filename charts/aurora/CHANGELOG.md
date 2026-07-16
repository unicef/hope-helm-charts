# Changelog

## 0.2.2 (2026-07-14)
* Add `celery.resources` and `celery.beatResources` values (both `{}` by default). Celery worker resources fall back `celery.resources | default resources`; celery beat falls back `celery.beatResources | default celery.resources | default resources`

## 0.2.1 (2026-04-07)
* Fix celery worker/beat to use `args: ["run"]` with `START_WORKER`/`START_CRON` env vars (circusd entrypoint)

## 0.2.0 (2026-04-07)
* Add optional Celery worker and beat deployments (`celery.enabled`, `celery.replicaCount`)

## 0.1.3 (2026-03-12)
* Redis: use official `redis:8` with custom ConfigMap

## 0.1.2 (2026-02-10)
* Redis: pin to standalone (master only)

## 0.1.1 (2026-02-10)
* Upgrade redis dependency to 24.1.8 (Bitnami)

## 0.1.0 (2025-07-17)
* Initial release
