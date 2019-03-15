#!/bin/bash

# script to cleanup prometheus operator and related resource from the cluster

for n in $(kubectl get namespaces -o jsonpath={..metadata.name})
do
  kubectl delete --all --namespace=$n prometheus,servicemonitor,alertmanager
done

for n in $(kubectl get namespaces -o jsonpath={..metadata.name})
do
  kubectl delete --ignore-not-found --namespace=$n service prometheus-operated alertmanager-operated
done

kubectl delete --ignore-not-found customresourcedefinitions \
  prometheuses.monitoring.coreos.com \
  servicemonitors.monitoring.coreos.com \
  alertmanagers.monitoring.coreos.com \
  prometheusrules.monitoring.coreos.com