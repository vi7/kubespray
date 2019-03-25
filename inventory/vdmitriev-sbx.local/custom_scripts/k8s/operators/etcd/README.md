etcd
====

# Intro

[etcd operator](https://github.com/coreos/etcd-operator) manages k8s based etcd clusters

etcd operator and related resources installation is managed by the corresponding [Helm chart](https://github.com/helm/charts/tree/master/stable/etcd-operator)

# External DNS etcd cluster

etcd cluster used as a backend for CoreDNS + ExternalDNS

**Installation**

```sh
inventory/vdmitriev-sbx.local/custom_scripts/cluster_operations.sh etcd_operator_install
```

**Upgrade**

> CRDs (TPR) update currently doesn't work properly
    
```sh
helm upgrade --namespace extdns \
-f inventory/vdmitriev-sbx.local/custom_scripts/k8s/operators/etcd/values-extdns.yaml \
--version 0.8.3 \
etcd-operator \
stable/etcd-operator
```