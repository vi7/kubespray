Prometheus monitoring
=====================

# Table of contents

- [Intro](#intro)
- [Installation](#installation)
- [Monitoring](#monitoring)
  * [Cluster monitoring](#cluster-monitoring)
  * [Alertmanager](#alertmanager)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

# Intro

[Prometheus operator](https://coreos.com/operators/prometheus/docs/latest/) manages Prometheus installation and configuration.

Up to date version of the operator and its quickstart steps are in the [Prometheus Operator repo](https://github.com/coreos/prometheus-operator).

Most of the manifests used in this guide are based on those located here: https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus

Guidelines below will help to setup basic Prometheus into the k8s cluster and configure it for cluster and user services monitoring.

# Installation

The following steps describe deployment of the Prometheus operator and instance of the Prometheus itself. Check yaml manifests mentioned below for the details

1. Create NS:
    ```sh
    kubectl create ns monitoring
    ```

2. Deploy Prometheus resources:
    ```sh
    # operator
    kubectl apply -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/operators/prometheus/bundle.yml
    # prometheus pods rbac which provides access to ALL NS's
    kubectl apply -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/operators/prometheus/prometheus-rbac-config.yml
    # deploy prometheus limited to the "team=sre" labelled ServiceMonitors and expose it
    kubectl apply -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/operators/prometheus/prometheus-sre.yml
    ```

3. Get Prometheus web UI URL:
    ```sh
    PORT=`kubectl -n monitoring get svc prometheus-sre -o jsonpath="{.spec.ports[?(@.name=='web')].port}"`
    IP=`kubectl -n monitoring get svc prometheus-sre -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
    echo "Prometheus Web UI is at: http://$IP:$PORT"
    ```

*OPTIONAL* Test setup above by deploying sample app and ServiceMonitor:
```sh
# launch example app
kubectl apply -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/operators/prometheus/example-app.yml
# add prometheus servicemonitor for the app to the same NS where prometheus lives
kubectl -n monitoring apply -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/operators/prometheus/example-app-servicemonitor.yml
```

# Monitoring

Corresponding ServiceMonitor resources should be created in order for Prometheus to discover services which should be monitored. Obviously everything you'd want to monitor should be exposed as a Service first.

See the "example-app" manifests from the [Installation](#Installation) block above as an example

## Cluster monitoring

Based on this guide: https://coreos.com/operators/prometheus/docs/latest/user-guides/cluster-monitoring.html

K8S API server and Kubelets are already exposed via Service resources (at the default and kube-system NS's respectively) so we just need ServiceMonitor resources for them (will be deployed further below).

Deploy Service resources for K8S components that run in Pod:
```sh
kubectl apply -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/operators/prometheus/cluster-monitoring-components-svc.yml
```

Deploy exporters for K8S and OS resources monitoring metrics and their respective Service resources
```sh
# node_exporter
kubectl apply -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/operators/prometheus/cluster-monitoring-node-exporter.yml
# kube-state-metrics with the access to ALL cluster resources across ALL namespaces
kubectl apply -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/operators/prometheus/cluster-monitoring-kube-state-metrics.yml
```

Deploy ServiceMonitor resources for all from above
```sh
kubectl apply -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/operators/prometheus/cluster-monitoring-servicemonitors.yml
```

## Alertmanager

Deploy AlertManager (and its ServiceMonitor if you'd like it to be monitored by Prometheus as well)
```sh
kubectl apply -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/operators/prometheus/alertmanager-main.yaml
kubectl apply -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/operators/prometheus/alertmanager-main-servicemonitor.yaml
```

Get AlertManager web UI URL:
```sh
PORT=`kubectl -n monitoring get svc alertmanager-main -o jsonpath="{.spec.ports[?(@.name=='web')].port}"`
IP=`kubectl -n monitoring get svc alertmanager-main -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
echo "AlertManager Web UI is at: http://$IP:$PORT"
```
