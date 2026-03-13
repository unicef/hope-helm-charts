# Changelog

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