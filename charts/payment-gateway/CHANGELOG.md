# Changelog

## 0.9.1 (2025-03-13)
* Flower: use ConfigMap for CELERY_BROKER_URL when set in backend.config (shared Redis), fallback to KeyVault for prod

## 0.9.0 (2026-02-11)
* Upgrade Redis to 24.1.8 and PostgreSQL to 13.x.x (OCI)
* Add redis.auth.enabled: false for Redis 24.x compatibility

## 0.6.0 (2025-05-21)
* Replaced Valkey with Redis
