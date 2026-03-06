# Changelog

## 0.14.0 (2026-03-06)
* Add optional `flower.celeryBrokerUrl` to override CELERY_BROKER_URL from values (e.g. when Redis has no auth and Key Vault has password in URL)

## 0.13.0 (2026-02-12)
* Update bitnami dependencies

## 0.12.0 (2026-02-11)
* Add optional `dataPvc` for persistent data mounted at `/var/data`
* Upgrade Redis to 24.1.8 (OCI); add redis.auth.enabled: false for Redis 24.x compatibility

## 0.9.0 (2025-05-21)
* Replaced Valkey with Redis
