#!/bin/bash

# Custom cluster operations script. See help below for the detaile
#
# MAINTAINERS:
# Vitaliy Dmitriev

help() {
  echo "

`basename $0` prepare_host - run hacks required to prepare VMs for K8S
`basename $0` cluster_admin_create - create cluster admin service account
`basename $0` cluster_admin_token - get cluster admin token
`basename $0` tiller_deploy - create tiller service account and deploy tiller into the cluster

  "
}

prepare_host() {
  ansible-playbook -i inventory/vdmitriev-sbx.local/hosts.ini inventory/vdmitriev-sbx.local/custom_scripts/prepare_host.yml -b
}

cluster_admin_create() {
  kubectl apply -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/cluster-admin-user.yaml 
}

cluster_admin_token() {
  echo "=============================================="
  kubectl -n kube-system get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='cluster-admin-user')].data.token}" | base64 -d
  echo -e "\n=============================================="
}

tiller_deploy() {
  kubectl apply -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/tiller-rbac-config.yaml
  # tiller service account and its permissions are configured by the command above
  helm init --service-account tiller
}

# MAIN

$1