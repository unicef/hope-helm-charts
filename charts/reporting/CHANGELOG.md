# Changelog

## 0.14.6 (unreleased)
* Add optional `pqRunner`: a dedicated Celery worker Deployment for user Python code, disabled by default (no manifests change while `pqRunner.enabled: false`)
* `pqRunner` gets its own ConfigMap (allowlisted `backend.config` keys + `pqRunner.config`), its own Key Vault SecretProviderClass and Secret, and its own ServiceAccount; it never mounts the backend Secret or ConfigMap
* Security context fixed in the template (non-root, read-only root filesystem, no privilege escalation, not privileged, all capabilities dropped, RuntimeDefault seccomp); only the UID/GID/fsGroup (default 1030) are configurable
* No ServiceAccount token; writable `/tmp` via `emptyDir`; `extraVolumes` limited to `emptyDir`
* Optional KEDA ScaledObject for `pqRunner` (`pqRunner.keda`), inheriting the Redis address, database index and TLS setting from `celery.keda`
* `helm template` fails on missing runner settings and on Mailjet/Azure/storage/Flower credentials passed to the runner; the backend's database and `SECRET_KEY` Key Vault objects can be reused
* Always (even with `pqRunner.enabled: false`): an active `POWER_QUERY_RUNNER` in `backend.config`, or any `POWER_QUERY_RUNNER` mapping in `keyvault.envMappings`, fails `helm template` and `helm lint` (new `values.schema.json` constrains only these keys)

## 0.14.5 (2026-10-05)
* Add KEDA ScaledObject for the celery worker (`celery.keda`), disabled by default
* Add `celery.terminationGracePeriodSeconds`

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
