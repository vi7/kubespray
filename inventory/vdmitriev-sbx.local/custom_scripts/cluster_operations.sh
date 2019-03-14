#!/bin/bash

# Custom cluster operations script. See help below for the details
#
# MAINTAINERS:
# Vitaliy Dmitriev

set -e

########
# VARS #
########

CLUSTER_NAME="vdmitriev-sbx.local"

METALLB_CHART_VER="0.8.4"
METALLB_RELEASE_NAME="metallb"
HAPROXY_CHART_VER="0.0.9"
HAPROXY_RELEASE_NAME="haproxy-ingress"
JENKINS_CHART_VER="0.32.9"
JENKINS_RELEASE_NAME="jenkins-sbx"

#############
# FUNCTIONS #
#############

help() {
  echo "
Script should be launched from the kubespray repo root.

`basename $0` start_cluster - launch cluster from scratch or update config of the existing one (e.g. adding masters or etcd nodes)
`basename $0` add_node - add worker node to the cluster
`basename $0` remove_node <node list> - remove worker node from the cluster, <node list> - comma-separated list of node names
`basename $0` prepare_host - run hacks required to prepare VMs for K8S
`basename $0` gluster_cleanup - cleanup nodes from GlusterFS/Heketi leftovers not cleaned up properly by the heketi-tear-down.yml
`basename $0` cluster_admin_create - create cluster admin service account
`basename $0` cluster_admin_token - get cluster admin token
`basename $0` anonymous_service_access - create cluster role which enables anonymous access to the k8s service endpoints via API
`basename $0` helm_init - create tiller service account and deploy tiller into the cluster
`basename $0` helm_kill - remove tiller service account and tiller from the cluster
`basename $0` metallb_install - install MetalLB chart into the cluster
`basename $0` metallb_upgrade - upgrade MetalLB chart
`basename $0` haproxy_ing - install/upgrade haproxy-ingress chart
`basename $0` jenkins_install - install jenkins chart into the cluster
`basename $0` jenkins_upgrade - upgrade jenkins chart
  "
}

start_cluster() {
  export ANSIBLE_REMOTE_TMP="/tmp"

  pip install -r requirements.txt
  prepare_host
  ansible-playbook -i inventory/$CLUSTER_NAME/hosts.yml cluster.yml -b -v
}

add_node() {
  export ANSIBLE_REMOTE_TMP="/tmp"

  prepare_host
  ansible-playbook -i inventory/$CLUSTER_NAME/hosts.yml scale.yml -b -v
}

# params:
# $1 - comma-separated list of node names to remove
remove_node() {
  export ANSIBLE_REMOTE_TMP="/tmp"

  if [ "x$1" == "x" ]
  then
    echo "[ERROR] node list is empty. Please provide comma-separated list of the node names to remove" >&2
    exit 1
  fi

  echo "[WARN] The following nodes will be removed: $1"

  prepare_host
  ansible-playbook -i inventory/$CLUSTER_NAME/hosts.yml remove-node.yml -b -v \
  --extra-vars "node=$1"
}

prepare_host() {
  export ANSIBLE_REMOTE_TMP="/tmp"

  ansible-playbook -i inventory/$CLUSTER_NAME/hosts.yml inventory/$CLUSTER_NAME/custom_scripts/prepare_host.yml -b -v
}

gluster_cleanup() {
  export ANSIBLE_REMOTE_TMP="/tmp"

  ansible-playbook -i inventory/$CLUSTER_NAME/hosts.yml inventory/$CLUSTER_NAME/custom_scripts/gluster_cleanup.yml -b -v
}

cluster_admin_create() {
  kubectl apply -f inventory/$CLUSTER_NAME/custom_scripts/k8s/cluster-admin-user.yml
}

cluster_admin_token() {
  echo "=============================================="
  kubectl -n kube-system get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='cluster-admin-user')].data.token}" | base64 -d
  echo -e "\n=============================================="
}

anonymous_service_access() {
  kubectl apply -f inventory/$CLUSTER_NAME/custom_scripts/k8s/cluster-anonymous-service-proxy-rbac.yml
}

helm_init() {
  # tiller service account and permissions
  kubectl apply -f inventory/$CLUSTER_NAME/custom_scripts/k8s/tiller-rbac-config.yml

  # tiller.installation with selector and NoSchedule toleration for master nodes, all other tolerations are helm defaults needed for a proper override
  helm init --service-account tiller \
--node-selectors=node-role.kubernetes.io/master= \
--override "spec.template.spec.tolerations[0].effect"="NoSchedule" \
--override "spec.template.spec.tolerations[0].key"="node-role\.kubernetes\.io/master" \
--override "spec.template.spec.tolerations[1].effect"="NoExecute" \
--override "spec.template.spec.tolerations[1].key"="node\.kubernetes\.io/not-ready" \
--override "spec.template.spec.tolerations[1].operator"="Exists" \
--override "spec.template.spec.tolerations[1].tolerationSeconds"="300" \
--override "spec.template.spec.tolerations[2].effect"="NoExecute" \
--override "spec.template.spec.tolerations[2].key"="node\.kubernetes\.io/unreachable" \
--override "spec.template.spec.tolerations[2].operator"="Exists" \
--override "spec.template.spec.tolerations[2].tolerationSeconds"="300"
}

helm_kill() {
  kubectl -n kube-system delete deploy -l name=tiller
  kubectl delete -f inventory/$CLUSTER_NAME/custom_scripts/k8s/tiller-rbac-config.yml
}

metallb_install() {
  helm install -n $METALLB_RELEASE_NAME -f inventory/$CLUSTER_NAME/custom_scripts/k8s/helm_values/metallb/values.yaml --version $METALLB_CHART_VER stable/metallb
}

metallb_upgrade() {
  helm upgrade -f inventory/$CLUSTER_NAME/custom_scripts/k8s/helm_values/metallb/values.yaml --version $METALLB_CHART_VER $METALLB_RELEASE_NAME stable/metallb
}

haproxy_ing() {
  helm upgrade --install --namespace kube-system -f inventory/$CLUSTER_NAME/custom_scripts/k8s/helm_values/haproxy-ingress/values.yaml --version $HAPROXY_CHART_VER $HAPROXY_RELEASE_NAME incubator/haproxy-ingress
}

jenkins_install() {
  helm install -n $JENKINS_RELEASE_NAME -f inventory/$CLUSTER_NAME/custom_scripts/k8s/helm_values/jenkins_sbx/values.yaml --version $JENKINS_CHART_VER stable/jenkins
}

jenkins_upgrade() {
  while :
  do
    echo -e "\nEnter Jenkins admin password"
    echo "[WARN] provided password will overwrite your exsting one!"
    read -r JENKINS_ADMIN_PASS
    if [ "x$JENKINS_ADMIN_PASS" != "x" ]
    then
      break
    else
      echo "[ERROR] admin password should not be empty!" >&2
      continue
    fi
  done
  helm upgrade -f inventory/$CLUSTER_NAME/custom_scripts/k8s/helm_values/jenkins_sbx/values.yaml --set Master.AdminPassword="$JENKINS_ADMIN_PASS" --version $JENKINS_CHART_VER $JENKINS_RELEASE_NAME stable/jenkins
}

########
# MAIN #
########

if [ ! -f cluster.yml ] || [ ! -d inventory ]
then
  echo "[ERROR] Please run me from the kubespray repo root!" >&2
  exit 1
fi

if [ "x$1" == "x" ]
then
  echo -e "[ERROR] provide action!\n" >&2
  help
  exit 1
fi

$1 $2
