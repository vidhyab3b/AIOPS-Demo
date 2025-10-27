#!/bin/bash

oc import-image node:latest --from=docker.io/library/node:latest --confirm -n aiops
echo "Imported the image for AIOps UI"
oc new-app --name aiopsui https://github.com/vidhyab3b/AIOPS.git --strategy=Docker --context-dir=AIOPSUI
oc patch bc aiopsui -p '{
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

echo "Starting the build of AIOps UI after setting the resources"
oc cancel-build aiopsui-1
oc start-build aiopsui --follow

echo "Set the resource limits for the deployment"
oc set resources deployment/aiopsui \
  --limits=cpu=300m,memory=512Mi \
  --requests=cpu=250m,memory=256Mi
oc rollout restart deployment/aiopsui

oc patch svc aiopsui -n aiops --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/port", "value": 443}]'
oc expose svc aiopsui
