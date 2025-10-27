#!/bin/bash

oc new-build --allow-missing-images   registry.access.redhat.com/ubi9/openjdk-17~https://github.com/vidhyab3b/AIOPS.git   --context-dir=aiops_q_ms_v2   --name=aiops-qks   --strategy=source
oc patch bc aiops-qks -p '{
  "spec": {
    "resources": {
      "limits": {
        "cpu": "300m",
        "memory": "1Gi"
      },
      "requests": {
        "cpu": "250m",
        "memory": "512Mi"
      }
    }
  }
}'

oc cancel-build aiops-qks-1
echo "Starting the build of AIOps Quarkus after setting the resources"
oc start-build aiops-qks --follow

echo "Deploying the AIOps Quarkus application"
oc new-app aiops-qks:latest --name=aiops-qks

echo "Set the resource limits for the deployment"
oc set resources deployment/aiops-qks \
  --limits=cpu=300m,memory=512Mi \
  --requests=cpu=250m,memory=256Mi
oc rollout restart deployment/aiops-qks

oc patch svc aiops-qks -n aiops --type='json' -p='[
  {
    "op": "remove",
    "path": "/spec/ports/1"
  }
]'
oc expose svc aiops-qks
