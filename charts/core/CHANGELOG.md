# Changelog

## 0.14.5 (2026-06-23)
* Add `volume-permissions` initContainer to `x-es9-nodegroup`: chowns `/bitnami/elasticsearch/data` to `1000:0` so the official ES image (runAsUser 1000) can write its data dir
* Set `coordinating.replicaCount: 0` in `x-es9-base`: Bitnami chart defaults to 2 coordinating pods; all-roles master design needs none
* Each ES9 cluster runs master-only nodes with all roles; scale `master.replicaCount` per env (1 for dev/eph, 3 for stg/prd)
* Add `es-master-services.yaml`: non-headless ClusterIP services `<release>-es-search-master` and `<release>-es-index-master` targeting master pods (Bitnami's built-in ClusterIP targets coordinating-only, which is empty in all-roles master topology)
* Fix `ELASTICSEARCH_HOST` pod env reference: check `es-search.enabled` alongside `elasticsearch.enabled`
* Fix `ELASTICSEARCH_HOST` fallback in backend secret: use `<release>-es-search-master:9200`
* Add `ELASTICSEARCH_INDEX_HOST` auto-construct in backend secret and pod env when `es-index.enabled: true`
* Rename sub-chart aliases `es-hope-search` → `es-search` and `es-hope-index` → `es-index` (avoids double "hope" in pod names)

## 0.14.4 (2026-06-18)
* Fix `network.host: 0.0.0.0` in `x-es9-base` shared config — ES 9 defaults to `127.0.0.1` when security is disabled, causing startup probe to fail with connection refused on the pod IP. Affects both `es-hope-search` and `es-hope-index`.

## 0.14.3 (2026-06-10)
* Add `es-hope-search` and `es-hope-index` ES 9 clusters (Bitnami chart 22.1.6, image `docker.elastic.co/elasticsearch/elasticsearch:9.0.1`); disabled by default, enable per env during migration
* Bump cluster A Bitnami elasticsearch chart 21.4.8 → 22.1.6 (image unchanged: `bitnamilegacy/elasticsearch:8.18.0`)
* Add `elasticsearch.hostOverride` to cut over `ELASTICSEARCH_HOST` to `es-hope-search` during migration
* Add `elasticsearch.indexHost` to expose `ELASTICSEARCH_INDEX_HOST` for the reindex playbook

## 0.14.2 (2026-06-10)
* Upgrade Elasticsearch image from `8.17.3-debian-12-r0` to `8.18.0` (bitnamilegacy)

## 0.14.1 (2026-05-28)
* Add `backend.constanceUseDatabase` flag (default: `false`). When `true`, omits `CONSTANCE_REDIS_CONNECTION` from the backend secret and pod env — use when Constance is configured with `DatabaseBackend`.

## 0.14.0 (2026-04-29)
* Add optional `redis-celery` subchart dependency (disabled by default) to support a dedicated Celery broker Redis instance separate from the cache Redis

## 0.13.0 (2026-04-24)
* Split celery worker into two separate deployments: `celery-worker-default` (`-Q default`) and `celery-worker-periodic` (`-Q periodic`)
* Renamed `celery.replicaCount` to `celery.defaultWorker.replicaCount`; added `celery.periodicWorker.replicaCount`

## 0.12.7 (2026-03-26)
* Ingress: support `ingress.hosts` (list of hostnames); when unset, `ingress.host` (single) remains supported for backward compatibility

## 0.12.6 (2026-03-12)
* Redis: use official `redis:8` with custom ConfigMap

## 0.12.5 (2026-03-12)
* Flower: use `flower.secret.FLOWER_BASIC_AUTH` when set instead of KeyVault (fixes eph envs without KeyVault secret)

## 0.12.4 (2025-03-12)
* Support Redis vars from `backend.config` when using shared Redis with KeyVault
* Init container (checkingContainer) uses `envFrom` ConfigMap when `CELERY_BROKER_URL` is in `backend.config`
* Flower uses ConfigMap for `CELERY_BROKER_URL` when set in `backend.config`, falling back to KeyVault for prod

## 0.12.3 (2025-03-10)
* Bind images to bitnamilegacy

## 0.12.2 (2025-03-10)
* Set global.security.allowInsecureImages for Bitnami subcharts to accept bitnamilegacy images

## 0.12.1 (2025-03-10)
* Switch Bitnami subchart images to bitnamilegacy registry (postgresql, redis, elasticsearch, os-shell)

## 0.12.0 (2025-02-11)
* Upgrade Redis dependency to 24.1.8 (OCI)

## 0.11.0 (2025-11-11)
* removed hct_mis_api references

## 0.10.0 (2025-06-30)
* Updated celery configuration with just 1 container and 1 task queue

## 0.9.0 (2025-06-10)
* Added value to enable/disable Redis Prometheus Exporter 
* Removed database SSL certificates

## 0.8.0 (2025-06-02)
* Added value to toggle monitoring resources creation

## 0.7.0 (2025-05-21)
* Replaced Valkey with Redis
* Added Redis Exporter dependency