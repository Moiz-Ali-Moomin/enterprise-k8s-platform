#!/bin/bash
# setup-security.sh - Loads OpenSearch Security Configs into K8s Secrets

echo "Generating Security Secrets..."

# 1. Security Config
kubectl create secret generic security-config -n monitoring \
  --from-file=config.yml=./security/security-config.yml \
  --dry-run=client -o yaml | kubectl apply -f -

# 2. ISM Policies (Applied via API after cluster is ready)
echo "Note: Apply ISM Policies via Curl once cluster is up:"
echo "curl -XPUT -u 'admin:password' https://localhost:9200/_plugins/_ism/policies/retention_policy -H 'Content-Type: application/json' -d @policies/ism-policy.json"

# 3. Logstash Pipeline
kubectl create configmap logstash-pipeline -n monitoring \
  --from-file=logstash.conf=./pipeline/logstash.conf \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Security artifacts deployed."
