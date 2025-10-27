#!/bin/bash

# Prompt for OCP API URL
read -p "Enter the OCP API URL: " OCP_API_URL
while [[ -z "$OCP_API_URL" ]]; do
    read -p "Enter the OCP API URL: " OCP_API_URL
    if [[ -z "$OCP_API_URL" ]]; then
        echo "OCP_API_URL cannot be empty. Please try again."
    fi
done

# Prompt for OCP Username
read -p "Enter the OCP Username: " OCP_USERNAME
while [[ -z "$OCP_USERNAME" ]]; do
    read -p "Enter the OCP Username: " OCP_USERNAME
    if [[ -z "$OCP_USERNAME" ]]; then
        echo "USERNAME cannot be empty. Please try again."
    fi
done

# Prompt for OCP PAssword
read -s -p "Enter the OCP Password: " OCP_PASSWORD
while [[ -z "$OCP_PASSWORD" ]]; do
    read -s -p "Enter the OCP Password: " OCP_PASSWORD
    if [[ -z "$OCP_PASSWORD" ]]; then
        echo "PASSWORD cannot be empty. Please try again."
    fi
done


sudo echo "export OCP_API_URL=\"$OCP_API_URL\"" > /root/aiops_ocp_demojam.env
sudo echo "export OCP_USERNAME=\"$OCP_USERNAME\"" >> /root/aiops_ocp_demojam.env
sudo echo "export OCP_PASSWORD=\"$OCP_PASSWORD\"" >> /root/aiops_ocp_demojam.env

echo "Logging into the OCP Cluster - $OCP_API_URL"
oc login -u $OCP_USERNAME -p $OCP_PASSWORD $OCP_API_URL

echo "Creating the project aiops"
oc new-project aiops; oc project aiops

# === Configuration ===
APP_NAME="mysql-db"
MYSQL_IMAGE="mysql:5.7"
MYSQL_ROOT_PASSWORD="redhat"
MYSQL_DATABASE="aiopsdb"
MYSQL_USER="mysql"
MYSQL_PASSWORD="redhat"
PVC_NAME="mysql-pvc"
PVC_FILE="pvc.yml"

echo "--- Deploying MySQL in OpenShift ---"

# === Step 1: Create MySQL App ===
echo "Creating new MySQL application..."
oc new-app $MYSQL_IMAGE \
  -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
  -e MYSQL_DATABASE=$MYSQL_DATABASE \
  -e MYSQL_USER=$MYSQL_USER \
  -e MYSQL_PASSWORD=$MYSQL_PASSWORD \
  --name=$APP_NAME || echo "Application already exists, skipping."

# === Step 2: Set resource limits ===
echo "Setting resource requests and limits..."
oc set resources deployment/$APP_NAME \
  --limits=cpu=500m,memory=512Mi \
  --requests=cpu=250m,memory=256Mi

# === Step 3: Create PersistentVolumeClaim YAML ===
echo "Creating PVC definition file..."
cat <<EOF > $PVC_FILE
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PVC_NAME
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF

# === Step 4: Apply PVC ===
echo "Applying PersistentVolumeClaim..."
if oc get pvc $PVC_NAME >/dev/null 2>&1; then
  echo "PVC '$PVC_NAME' already exists. Recreating..."
  oc delete pvc $PVC_NAME --ignore-not-found
fi
oc apply -f $PVC_FILE

# === Step 5: Patch Deployment to use PVC ===
echo "Patching deployment to use persistent storage..."
oc patch deployment $APP_NAME -p "{
  \"spec\": {
    \"template\": {
      \"spec\": {
        \"volumes\": [{
          \"name\": \"mysql-persistent-storage\",
          \"persistentVolumeClaim\": {
            \"claimName\": \"$PVC_NAME\"
          }
        }],
        \"containers\": [{
          \"name\": \"$APP_NAME\",
          \"volumeMounts\": [{
            \"mountPath\": \"/var/lib/mysql\",
            \"name\": \"mysql-persistent-storage\"
          }]
        }]
      }
    }
  }
}"

# === Step 6: Wait for Pods to Start ===
echo "Waiting for MySQL pods to start..."
ATTEMPTS=0
MAX_ATTEMPTS=15

while true; do
    POD_STATUS=$(oc get pods -l app=$APP_NAME -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")

    if [[ "$POD_STATUS" == "Running" ]]; then
        echo "MySQL pod is running."
        break
    elif [[ "$POD_STATUS" == "CrashLoopBackOff" || "$POD_STATUS" == "Error" ]]; then
        echo "MySQL pod failed to start. Gathering details..."
        oc describe pod -l app=$APP_NAME
        oc logs -l app=$APP_NAME --tail=50
        exit 1
    elif [[ "$POD_STATUS" == "Pending" || "$POD_STATUS" == "ContainerCreating" ]]; then
        echo "Pod is still starting... (Attempt $ATTEMPTS/$MAX_ATTEMPTS)"
        sleep 10
    else
        echo "Pod status: $POD_STATUS. Retrying..."
        sleep 5
    fi

    ((ATTEMPTS++))
    if [[ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]]; then
        echo "Timeout: Pod did not reach running state within expected time."
        exit 1
    fi
done

# === Step 7: Final Status ===
echo "Deployment complete! Current status:"
oc get pods
oc get pvc "$PVC_NAME"
oc get deployment "$APP_NAME"

echo "-- MySQL ($APP_NAME) deployed successfully with persistent storage. ---"
