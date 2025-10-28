#! /bin/bash

cd /root
read -p "Enter the GIT TOKEN of AIOPS Repo: " GIT_TOKEN
REPO_URL="https://vidhyab3b:"$GIT_TOKEN"@github.com/vidhyab3b/AIOPS.git"
COMMIT_MSG="Modify vite.config.js and store.js"
WORK_DIR="temp_git_repo_$$"

# Clone repo
echo "Cloning repository..."
git clone "$REPO_URL" "$WORK_DIR"
cd "$WORK_DIR"
git remote set-url origin $REPO_URL

echo "Making Changes in vite.config.js"
UI_ROUTE_URL=$(oc get route aiopsui -o jsonpath='{.spec.host}')
sed -i "s|^\s*allowedHosts: \[.*\]|      allowedHosts: ['$UI_ROUTE_URL']|" AIOPSUI/vite.config.js

echo "Making Changes in store.js"
PROXY_ROUTE_URL=$(oc get route aiproxy -o jsonpath='{.spec.host}')
sed -i "s|^\s*baseurl: \".*\"[,]*|    baseurl: \"http://$PROXY_ROUTE_URL\",|" AIOPSUI/src/js/store.js
sed -i "s|^\s*aiproxybaseurl: \".*\"[,]*|    aiproxybaseurl: \"http://$PROXY_ROUTE_URL\",|" AIOPSUI/src/js/store.js


echo "Adding & commiting the changes"
git config --global user.name "Vidhya"
git config --global user.email "vidyavece@gmail.com"

git add .
git commit -m "$COMMIT_MSG"

echo "Pushing to Git Repository"
git push

cd /root; rm -rf "$WORK_DIR"

echo "Building the AIOps UI Deployment with the Changes"
oc start-build aiopsui --follow
