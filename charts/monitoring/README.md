# monitoring

Observability components for HOPE clusters: metric exporters, plus the scrape
configuration Azure Monitor managed Prometheus needs to pick them up.

Everything is disabled by default — enable per environment from
`hope-deployment/helmfile/values/hope/<env>.yaml`.

| Value | Purpose |
|---|---|
| `dcgm-exporter.enabled` | NVIDIA GPU metrics. Only where a GPU node pool exists. |
| `scrape.enabled` | Emit `azmonitoring.coreos.com/v1` ServiceMonitors. Needs `ama-metrics` on the cluster. |

Grafana dashboards are **not** part of this chart — there is no self-hosted
Grafana. They live in `hope-deployment/monitoring/dashboards/` and are published
into Azure Managed Grafana with `az grafana dashboard update`.

## Notes

`dcgm-exporter` must not request `nvidia.com/gpu`. Where the device plugin runs
time-slicing with `failRequestsGreaterThanOne: true`, every replica is already
claimed by the workload, so requesting one would fail to schedule or displace a
pod. It reads the driver through `NVIDIA_VISIBLE_DEVICES=all`, which needs no
allocation.

The ServiceMonitor uses `azmonitoring.coreos.com/v1`, not
`monitoring.coreos.com`. Azure Monitor managed Prometheus ships its own
PodMonitor/ServiceMonitor CRDs and ignores the prometheus-operator ones.
