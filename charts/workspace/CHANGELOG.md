# Changelog

## 0.5.4 (2026-07-14)
* Add backend `HorizontalPodAutoscaler` template (`autoscaling/v2`), gated on `autoscaling.enabled`, with optional CPU and memory utilization targets
* Add backend `autoscaling` values (enabled false, minReplicas 1, maxReplicas 3, targetCPUUtilizationPercentage 80) and backend `resources: {}`
* Add celery `resources` / `beatResources` values; celery beat uses `beatResources | default resources`, worker uses `celery.resources`

## 0.5.3 (2026-03-17)
* Redis: fix replica missing command/args/volumeMount defaults (same as master)

## 0.5.2 (2026-03-12)
* Redis: use official `redis:8` with custom ConfigMap

## 0.5.1 (2026-03-12)
* Flower: fix envFrom order so backend.config overrides KeyVault (shared Redis envs)

## 0.5.0 (2026-02-11)
* Upgrade Redis to 24.1.8 (OCI)
* Add redis.auth.enabled: false for Redis 24.x compatibility

## 0.3.0 (2025-05-21)
* Replaced Valkey with Redis
