#! /bin/bash

cd /root
read -p "Enter the GIT TOKEN of AIOPS Repo: " GIT_TOKEN
REPO_URL="https://vidhyab3b:"$GIT_TOKEN"@github.com/vidhyab3b/AIOPS.git"
COMMIT_MSG="Modify vite.config.js, store.js and application.properties"
WORK_DIR="temp_git_repo_$$"

# Clone repo
echo; echo "Cloning repository..."
git clone "$REPO_URL" "$WORK_DIR"
cd "$WORK_DIR"
git remote set-url origin $REPO_URL

echo; echo "Making Changes in vite.config.js"
UI_ROUTE_URL=$(oc get route aiopsui -o jsonpath='{.spec.host}')
sed -i "s|^\s*allowedHosts: \[.*\]|      allowedHosts: ['$UI_ROUTE_URL']|" AIOPSUI/vite.config.js
sed -i "s|^quarkus\.http\.cors\.origins=.*|quarkus.http.cors.origins=http://localhost:8000,http://localhost,https://$UI_ROUTE_URL|" aiops_q_ms_v2/src/main/resources/application.properties

echo; echo "Making Changes in store.js"
PROXY_ROUTE_URL=$(oc get route aiproxy -o jsonpath='{.spec.host}')
QKS_ROUTE_URL=$(oc get route aiops-qks -o jsonpath='{.spec.host}')

sed -i "s|^\s*aiproxybaseurl: \".*\"[,]*|    aiproxybaseurl: \"https://$PROXY_ROUTE_URL\",|" AIOPSUI/src/js/store.js
sed -i "s|^\s*baseurl: \".*\"[,]*|    baseurl: \"https://$QKS_ROUTE_URL\",|" AIOPSUI/src/js/store.js

echo; echo "Adding & commiting the changes"
git config --global user.name "Vidhya"
git config --global user.email "vidyavece@gmail.com"

git add .
git commit -m "$COMMIT_MSG"

echo; echo "Pushing to Git Repository"
git push

cd /root; rm -rf "$WORK_DIR"

echo; echo "Setting a secret and redeploying AI Proxy"
oc create secret generic git-secret --from-literal=GIT_TOKEN="$GIT_TOKEN"
oc set env deployment/aiproxy --from=secret/git-secret

echo; echo "Building the AIOps UI Deployment with the Changes"
oc start-build aiopsui --follow

echo; echo "Building the AIOps Quarkus Deployment with the Changes"
oc start-build aiops-qks --follow

NAMESPACE="aiops"
DEPLOYMENT="mysql-db"
LOCAL_PORT=3306
REMOTE_PORT=3306
LOG_FILE="port-forward.log"

# Check if an oc port-forward is already running for this deployment and port
if pgrep -f "oc port-forward deployment/$DEPLOYMENT $LOCAL_PORT:$REMOTE_PORT -n $NAMESPACE" >/dev/null; then
    echo "Port-forward for $DEPLOYMENT:$REMOTE_PORT already running on localhost:$LOCAL_PORT"
else
    echo "Starting port-forward from localhost:$LOCAL_PORT to $DEPLOYMENT:$REMOTE_PORT in namespace $NAMESPACE"
    nohup oc port-forward deployment/$DEPLOYMENT $LOCAL_PORT:$REMOTE_PORT -n $NAMESPACE > $LOG_FILE 2>&1 &
    echo "Port-forward started in background. Logs are in $LOG_FILE"
fi
