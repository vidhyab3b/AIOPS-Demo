#!/bin/bash

source /root/aiops_ocp_demojam.env

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
  echo "PVC '$PVC_NAME' already exists. Skipping the creation..."
else
oc apply -f $PVC_FILE
fi

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
sleep 30s

# === Configuration ===
CLEANER_POD_NAME="mysql-cleaner"
PVC_NAME="mysql-pvc"
YAML_FILE="cleaner.yml"

echo "--- Creating MySQL cleaner pod definition ---"

# === Step 1: Generate the YAML ===
cat <<EOF > $YAML_FILE
apiVersion: v1
kind: Pod
metadata:
  name: $CLEANER_POD_NAME
spec:
  restartPolicy: Never
  containers:
  - name: cleaner
    image: registry.access.redhat.com/ubi9/ubi
    command: ["/bin/bash", "-c", "rm -rf /var/lib/mysql/* && echo 'Volume cleaned successfully' && sleep 10"]
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "128Mi"
        cpu: "100m"
    volumeMounts:
    - name: mysql-persistent-storage
      mountPath: /var/lib/mysql
  volumes:
  - name: mysql-persistent-storage
    persistentVolumeClaim:
      claimName: $PVC_NAME
EOF

# === Step 2: Apply the YAML ===
echo "--- Deploying MySQL cleaner pod ---"
oc apply -f $YAML_FILE

# === Step 3: Wait for the pod to complete ===
echo "--- Waiting for the cleaner pod to finish ---"
oc wait pod/$CLEANER_POD_NAME --for=condition=Succeeded --timeout=120s || {
  echo "Cleaner pod did not succeed within timeout. Checking status..."
  oc get pod/$CLEANER_POD_NAME
  oc logs $CLEANER_POD_NAME || true
}

# === Step 4: Cleanup the cleaner pod ===
echo "--- Deleting the cleaner pod ---"
oc delete pod $CLEANER_POD_NAME --ignore-not-found
echo; echo "--- MySQL volume cleanup completed successfully ---"

oc rollout restart deployment/$APP_NAME

# === Step 6: Wait for Pods to Start ===
echo "Waiting for MySQL pods to start..."
ATTEMPTS=0
MAX_ATTEMPTS=20

while true; do
    POD_STATUS=$(oc get pods -l deployment=$APP_NAME -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")

    if [[ "$POD_STATUS" == "Running" ]]; then
        echo "MySQL pod is running."
        break
    elif [[ "$POD_STATUS" == "CrashLoopBackOff" || "$POD_STATUS" == "Error" ]]; then
        echo "MySQL pod failed to start. Gathering details..."
        oc describe pod -l deployment=$APP_NAME
        oc logs -l deployment=$APP_NAME --tail=50
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
        break
    fi
done

oc patch svc mysql-db -p '{"spec": {"type": "NodePort"}}' -n aiops

echo "Installing mysql-shell & jq"
dnf install -y https://dev.mysql.com/get/mysql80-community-release-el8-3.noarch.rpm --nogpgcheck
dnf install -y mysql-shell --nogpgcheck
dnf install jq -y
dnf clean all

nohup oc port-forward deployment/mysql-db 3306:3306 -n aiops > port-forward.log 2>&1 &

echo "Creating Tables"
mysqlsh --host=127.0.0.1 --user=mysql --password=redhat --port=3306 --sql -e "
USE aiopsdb;
CREATE TABLE Error_Table (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    Server_Name VARCHAR(255),
    Error_Message TEXT,
    Created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Status VARCHAR(50)
);"

mysqlsh --host=127.0.0.1 --user=mysql --password=redhat --port=3306 --sql -e "
USE aiopsdb;
CREATE TABLE Error_RCA (
    id BIGINT PRIMARY KEY,
    errorid BIGINT,
    prompt VARCHAR(1000),
    ai_response MEDIUMTEXT,
    ansible_playbook MEDIUMTEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

mysqlsh --host=127.0.0.1 --user=mysql --password=redhat --port=3306 --sql -e "
USE aiopsdb;
CREATE TABLE Playbook_Status (
    id BIGINT PRIMARY KEY,
    Error_ID BIGINT,
    RCA_ID BIGINT,
    server_Name VARCHAR(255),
    execution_Status VARCHAR(100),
    Created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);"

mysqlsh --host=127.0.0.1 --user=mysql --password=redhat --port=3306 --sql -e "
USE aiopsdb;
DROP TABLE IF EXISTS Error_RCA_SEQ;
CREATE TABLE Error_RCA_SEQ (
   next_val bigint(20) NOT NULL,
   id bigint(20) NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=latin1;"

mysqlsh --host=127.0.0.1 --user=mysql --password=redhat --port=3306 --sql -e "
USE aiopsdb;
INSERT INTO Error_RCA_SEQ (next_val, id) VALUES (51,	1);"
