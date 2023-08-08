#!/bin/bash

export KUBECONFIG=/Users/abhishekk/Downloads/test-kubeconfig.yaml

helm install netmaker . --set baseDomain=146.190.9.68.nip.io --set server.replicas=3 --set ingress.enabled=true --set ingress.kubernetes.io/ingress.class=nginx --set ingress.cert-manager.io/cluster-issuer="letsencrypt-prod" --set dns.enabled=false --set dns.clusterIP=10.245.75.75 --set dns.RWX.storageClassName=nfs --set postgresql-ha.postgresql.replicaCount=2
