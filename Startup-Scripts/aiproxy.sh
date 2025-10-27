#!/bin/bash

oc import-image nodejs:18 --from=registry.access.redhat.com/ubi8/nodejs-18 --confirm -n aiops
echo "Imported the image for AIOps Proxy"

oc new-app --name aiproxy https://github.com/vidhyab3b/AIOPS.git --strategy=Docker --context-dir=aiproxy
oc patch bc aiproxy -p '{
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

echo "Starting the build of AIOps Proxy after setting the resources"
oc cancel-build aiproxy-1
oc start-build aiproxy --follow

echo "Set the resource limits for the deployment"
oc set resources deployment/aiproxy \
  --limits=cpu=300m,memory=512Mi \
  --requests=cpu=250m,memory=256Mi

oc rollout restart deployment/aiproxy

oc patch svc aiproxy -n aiops --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/port", "value": 443}]'
oc expose svc aiproxy









