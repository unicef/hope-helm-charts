# Changelog

## 0.14.4 (2026-07-23)
* Fix backend `HorizontalPodAutoscaler`

## 0.14.3 (2026-07-14)
* Add celery `resources` and `beatResources` values (both `{}` by default); celery beat uses `beatResources | default resources`, worker uses `celery.resources`
* Set celery worker `replicas` to `1` (removed the `autoscaling.enabled` replica guard)

## 0.14.2 (2026-03-17)
* Redis: fix replica missing command/args/volumeMount defaults (same as master)

## 0.14.1 (2026-03-12)
* Redis: use official `redis:8` with custom ConfigMap

## 0.14.0 (2026-02-11)
* Upgrade Redis to 24.1.8 and PostgreSQL to 13.x.x (OCI)

## 0.12.0 (2025-06-12)
* Changed path of image pull policy values from `image.pullPolicy` to `global.imagePullPolicy`

## 0.11.0 (2025-05-21)
* Replaced Valkey with Redis
