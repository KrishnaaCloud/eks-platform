# Service Level Objectives (SLOs) & Multi-Window Burn Rate Alerting

## Overview

In Phase 3, we implemented production-grade Service Level Objectives (SLOs) and an automated observability pipeline for applications running on Amazon EKS. Rather than relying on static, arbitrary threshold alerts (e.g. CPU > 80% or memory spikes) that generate alert fatigue without reflecting user experience, our alerting strategy is rooted in **Google SRE Service Level Objectives** and **Multi-Window Multi-Burn-Rate Alerting**.

Synthetic blackbox probing via `prometheus-blackbox-exporter` continuously evaluates the health of `dev-sample-app` from within the cluster network path.

---

## Service Level Indicators (SLIs) & SLO Definitions

| Objective | Target (SLO) | Error Budget | SLI Definition | Evaluation Windows |
| :--- | :--- | :--- | :--- | :--- |
| **Availability** | **99.0%** | **1.0%** | Ratio of HTTP 200 responses to total probes | 2m, 5m, 10m, 30m |
| **Latency** | **95.0%** | **5.0%** | Ratio of successful probes completing in < 50ms (0.05s) | 2m, 5m, 10m, 30m |

### 1. Availability SLI Formula
The availability SLI measures whether synthetic HTTP requests to `http://dev-sample-app.dev.svc.cluster.local:80/` succeed:
```promql
# SLI: Probe success ratio over rolling window
avg_over_time(probe_success{job="blackbox-dev-sample-app"}[window])
```
Recording rules:
- `job:sample_app_availability:ratio_rate2m`
- `job:sample_app_availability:ratio_rate5m`
- `job:sample_app_availability:ratio_rate10m`
- `job:sample_app_availability:ratio_rate30m`

### 2. Latency SLI Formula
The latency SLI measures whether requests succeed AND respond within the 50ms latency threshold:
```promql
# SLI: Latency satisfaction ratio (< 50ms) over rolling window
avg_over_time((probe_duration_seconds{job="blackbox-dev-sample-app"} < bool 0.05 and probe_success{job="blackbox-dev-sample-app"} == bool 1)[window:10s])
```
Recording rules:
- `job:sample_app_latency:ratio_rate2m`
- `job:sample_app_latency:ratio_rate5m`
- `job:sample_app_latency:ratio_rate10m`
- `job:sample_app_latency:ratio_rate30m`

---

## Burn Rate & Error Budget Math

### Burn Rate Definition
A **burn rate of 1.0** consumes exactly 100% of the allocated error budget over the reference SLO measurement period.
A **burn rate > 1.0** consumes the error budget faster than planned.

$$\text{Burn Rate} = \frac{1 - \text{SLI}}{1 - \text{SLO Target}} = \frac{\text{Error Rate}}{\text{Total Error Budget}}$$

- For Availability (99.0% SLO, Error Budget = 0.01):
  $$\text{Burn Rate}_{\text{avail}} = \frac{1 - \text{SLI}_{\text{avail}}}{0.01}$$
- For Latency (95.0% SLO, Error Budget = 0.05):
  $$\text{Burn Rate}_{\text{latency}} = \frac{1 - \text{SLI}_{\text{latency}}}{0.05}$$

### Error Budget Remaining (%)
Calculated over a rolling 30-minute window:
```promql
clamp_max(clamp_min((1 - (1 - SLI_ratio_rate30m) / Error_Budget) * 100, 0), 100)
```

---

## Multi-Window Multi-Burn-Rate Alerting Design

Traditional alerting uses a single window and threshold, forcing a compromise between slow alerts (hours to fire during total outages) or high false positive rates (transient dips triggering alerts).

To eliminate false alarms while guaranteeing rapid detection of catastrophic outages, we implement **Multi-Window Multi-Burn-Rate Alerts** across short and long lookback windows:

| Alert Tier | Severity | Burn Rate Threshold | Short Window | Long Window | for Duration | Budget Consumed | Response / Action |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Fast Burn** | `critical` | **14.4x** | 2 minutes | 10 minutes | 1 minute | 2% consumed in 1 hour | Immediate page: system is critically degraded |
| **Slow Burn** | `warning` | **3.0x** | 5 minutes | 30 minutes | 2 minutes | 5% consumed in 6 hours | Ticket / Slack notification: budget eroding steadily |

### Alert Rules Implementation
#### Critical: Availability Fast Burn
```yaml
- alert: SampleAppAvailabilityFastBurn
  expr: |
    (job:sample_app_availability:burn_rate2m > 14.4)
    and
    (job:sample_app_availability:burn_rate10m > 14.4)
  for: 1m
  labels:
    severity: critical
    slo: availability
  annotations:
    summary: "Critical availability error budget burn rate for dev-sample-app"
    description: "The availability error budget is burning at >14.4x rate across both 2m and 10m windows."
```

#### Warning: Availability Slow Burn
```yaml
- alert: SampleAppAvailabilitySlowBurn
  expr: |
    (job:sample_app_availability:burn_rate5m > 3)
    and
    (job:sample_app_availability:burn_rate30m > 3)
  for: 2m
  labels:
    severity: warning
    slo: availability
  annotations:
    summary: "Elevated availability error budget burn rate for dev-sample-app"
    description: "The availability error budget is burning at >3x rate across both 5m and 30m windows."
```

Corresponding alert rules are identically defined for `SampleAppLatencyFastBurn` and `SampleAppLatencySlowBurn`.

---

## Grafana Dashboard: Sample App SLO Dashboard

An automated ConfigMap (`sample-app-slo-dashboard`) labeled `grafana_dashboard: "1"` is dynamically loaded into Grafana by the k8s-sidecar container, provisioning a production-grade operations dashboard:

1. **Availability SLI Gauge**: Real-time 5-minute availability ratio with thresholds (Green ≥ 99%, Yellow 98-99%, Red < 98%).
2. **Latency SLI Gauge**: Real-time 5-minute percentage of requests under 50ms threshold (Green ≥ 95%, Red < 95%).
3. **Availability Error Budget Remaining Stat**: Percentage of remaining 30m error budget.
4. **Latency Error Budget Remaining Stat**: Percentage of remaining 30m error budget.
5. **Availability Multi-Window Burn Rates Timeseries**: Real-time burn rates across 2m, 5m, 10m, and 30m windows with 14.4x critical and 3.0x warning threshold lines.
6. **Latency Multi-Window Burn Rates Timeseries**: Real-time latency burn rates across evaluation windows.
7. **Raw Blackbox Probe Duration Timeseries**: Probe execution latencies in seconds (typical p95 baseline ~2ms - 7ms).
8. **Current Probe Health Stat**: Real-time binary indicator (UP / DOWN) of synthetic probe status.

---

## Empirical Failure Drill Results

To validate the multi-window burn rate alert pipeline, an active failure drill was executed against `dev-sample-app`.

### Drill Timeline & Measured Data

| Event | Timestamp (UTC) | Elapsed from Action | Observed System Behavior |
| :--- | :--- | :--- | :--- |
| **Workload Scale Down** | 2026-11-23 11:20:03 | 0.0s | `kubectl scale deployment dev-sample-app -n dev --replicas=0` executed. |
| **Synthetic Probe Failure** | 2026-11-23 11:20:13 | +10.0s | Blackbox probe detects connection drop (`probe_success` transitions from `1` to `0`). |
| **Fast Burn Condition Met** | 2026-11-23 11:21:19 | +76.6s | `burn_rate2m` (66.7) and `burn_rate10m` (16.7) both exceed 14.4 threshold. Alert transitions to **`pending`**. |
| **Fast Burn Alert FIRING** | 2026-11-23 11:22:24 | +142.0s (2m 22.0s) | `for: 1m` duration satisfied. Alert transitions to **`firing`** in Prometheus and delivers to Alertmanager. |
| **Workload Scale Up (Restore)** | 2026-11-23 11:23:08 | 0.0s | `kubectl scale deployment dev-sample-app -n dev --replicas=1` executed. |
| **Synthetic Probe Recovery** | 2026-11-23 11:23:32 | +23.5s | Pod reaches `1/1 Running`; blackbox probe succeeds (`probe_success` returns to `1`). |
| **Fast Burn Alert Resolved** | 2026-11-23 11:25:27 | +138.6s (2m 18.6s) | `burn_rate2m` drops below 14.4 as successful probes repopulate the 2m lookback window. Alert clears. |

### Drill Analysis
- **Detection Accuracy**: Probe failure was detected in 10.0 seconds, exactly aligning with the 10-second scrape interval.
- **Alert Timeliness**: The critical fast burn alert fired in **2m 22.0s** (142 seconds), closely matching the theoretical expectation (~2m 26s).
- **Auto-Recovery**: Once the workload was restored, the alert automatically cleared within 2m 18.6s without human intervention or manual acknowledgment.
