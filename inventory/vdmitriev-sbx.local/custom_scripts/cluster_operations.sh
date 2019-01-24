#!/bin/bash

# Custom cluster operations script. See help below for the detaile
#
# MAINTAINERS:
# Vitaliy Dmitriev

########
# VARS #
########

JENKINS_CHART_VER="0.28.9"
JENKINS_RELEASE_NAME="jenkins-sbx"

#############
# FUNCTIONS #
#############

help() {
  echo "
Script should be launched from the kubespray repo root.

`basename $0` prepare_host - run hacks required to prepare VMs for K8S
`basename $0` cluster_admin_create - create cluster admin service account
`basename $0` cluster_admin_token - get cluster admin token
`basename $0` helm_init - create tiller service account and deploy tiller into the cluster
`basename $0` jenkins_install - install jenkins chart into the cluster
`basename $0` jenkins_upgrade - upgrade jenkins chart
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

helm_init() {
  kubectl apply -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/tiller-rbac-config.yaml
  # tiller service account and its permissions are configured by the command above
  helm init --service-account tiller
}

jenkins_install() {
  helm install -n $JENKINS_RELEASE_NAME -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/helm_values/jenkins_sbx/values.yaml --version $JENKINS_CHART_VER stable/jenkins
}

jenkins_upgrade() {
  helm upgrade -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/helm_values/jenkins_sbx/values.yaml --version $JENKINS_CHART_VER $JENKINS_RELEASE_NAME stable/jenkins
}

########
# MAIN #
########

if [ ! -f cluster.yml ] || [ ! -d inventory ]
then
  echo "[ERROR] Please run me from the kubespray repo root!" >&2
  exit 1
fi

$1
