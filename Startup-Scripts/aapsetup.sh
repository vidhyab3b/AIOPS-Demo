#!/bin/bash

source /root/aiops_ocp_demojam.env

# Find the Org ID of ‘Default’ & Create an Inventory ‘RHEL’
ORG_ID=$(curl -sk -u "$AAP_USERNAME:$AAP_PASSWORD" "$CONTROLLER_URL/organizations/" | jq -r '.results[] | select(.name=="Default") | .id')
curl -k -u "$AAP_USERNAME:$AAP_PASSWORD" \
  -H "Content-Type: application/json" \
  -X POST "$CONTROLLER_URL/inventories/" \
  -d "{\"name\": \"RHEL\", \"organization\": $ORG_ID}"
echo; echo; echo "Created an Inventory 'RHEL'"

# Prompt for Bastion Node's Hostname
read -p "Enter the Bastion Node's FQDN: " BASTION_HOST
while [[ -z "$BASTION_HOST" ]]; do
    read -p "Enter the Bastion Node's FQDN: " BASTION_HOST
    if [[ -z "$BASTION_HOST" ]]; then
        echo "FQDN cannot be empty. Please try again."
    fi
done

# Prompt for Bastion Node's Username
read -p "Enter the Bastion Node's Username: " USERNAME
while [[ -z "$USERNAME" ]]; do
    read -p "Enter the Bastion Node's Username: " USERNAME
    if [[ -z "$USERNAME" ]]; then
        echo "Username cannot be empty. Please try again."
    fi
done

# Prompt for Bastion Node's Password (silent input)
read -s -p "Enter the Bastion Node's Password: " PASSWORD
while [[ -z "$PASSWORD" ]]; do
    read -s -p "Enter the Bastion Node's Password: " PASSWORD
    echo  # Move to a new line after password input
    if [[ -z "$PASSWORD" ]]; then
        echo "Password cannot be empty. Please try again."
    fi
done

# Find the Inventory ID of ‘RHEL’ & add a host
INVENTORY_ID=$(curl -sk -u "$AAP_USERNAME:$AAP_PASSWORD" "$CONTROLLER_URL/inventories/?name=RHEL" | jq -r '.results[0].id')
curl -sk -u "$AAP_USERNAME:$AAP_PASSWORD" \
  -H "Content-Type: application/json" \
  -X POST "$CONTROLLER_URL/hosts/" \
  -d "{\"name\": \"Nginx Server\", \"inventory\": $INVENTORY_ID, \"variables\": \"ansible_host: $BASTION_HOST\"}"
echo; echo; echo "Added the Nginx Server to the Inventory 'RHEL'"

# Find the Credential Type of Machine & Create a Credential
CRED_TYPE_ID=$(curl -sk -u "$AAP_USERNAME:$AAP_PASSWORD" "$CONTROLLER_URL/credential_types/?page_size=100" |  jq -r '.results[] | select(.name=="Machine") | .id')
curl -sk -u "$AAP_USERNAME:$AAP_PASSWORD" \
  -H "Content-Type: application/json" \
  -X POST "$CONTROLLER_URL/credentials/" \
  -d "{
    \"name\": \"Nginx Server\",
    \"organization\": $ORG_ID,
    \"credential_type\": $CRED_TYPE_ID,
    \"inputs\": {
        \"username\": \"$USERNAME\",
        \"password\": \"$PASSWORD\",
        \"become_method\": \"sudo\"
    }
}"
echo; echo; echo "Credential 'Nginx Server' created successfully."

# Create the Project
curl -sk -u "$AAP_USERNAME:$AAP_PASSWORD" \
  -H "Content-Type: application/json" \
  -X POST "$CONTROLLER_URL/projects/" \
  -d "{
    \"name\": \"AIOPS REPO\",
    \"description\": \"Project for AIOPS playbooks\",
    \"organization\": $ORG_ID,
    \"scm_type\": \"git\",
    \"scm_url\": \"https://github.com/vidhyab3b/AIOPS-Demo.git\",
    \"scm_branch\": \"main\",
    \"scm_update_on_launch\": true
}"
echo; echo; echo "Created the Project 'AIOPS REPO'"

PROJECT_ID=$(curl -sk -u "$AAP_USERNAME:$AAP_PASSWORD" "$CONTROLLER_URL/projects/" | jq -r '.results[] | select(.name=="AIOPS REPO") | .id')
CREDENTIAL_ID=$(curl -sk -u "$AAP_USERNAME:$AAP_PASSWORD" "$CONTROLLER_URL/credentials/" | jq -r '.results[] | select(.name=="Nginx Server") | .id')
EE_ID=$(curl -sk -u "$AAP_USERNAME:$AAP_PASSWORD" "$CONTROLLER_URL/execution_environments/" | jq -r '.results[] | select(.name=="Default execution environment") | .id')

# Create the Job Template
curl -sk -u "$AAP_USERNAME:$AAP_PASSWORD" \
  -H "Content-Type: application/json" \
  -X POST "$CONTROLLER_URL/job_templates/" \
  -d "{
    \"name\": \"DB Update\",
    \"description\": \"Run DB update playbook\",
    \"organization\": $ORG_ID,
    \"inventory\": $INVENTORY_ID,
    \"project\": $PROJECT_ID,
    \"playbook\": \"insert_error_message.yml\",
    \"credentials\": [{\"id\": $CREDENTIAL_ID}],
    \"execution_environment\": $EE_ID,
    \"job_type\": \"run\",
    \"ask_credential_on_launch\": false,
    \"extra_vars\": \"{\\\"bastion_host\\\": \\\"$BASTION_HOST\\\"}\"
}"

TEMPLATE_ID=$(curl -sk -u "$AAP_USERNAME:$AAP_PASSWORD" "$CONTROLLER_URL/job_templates/?name=DB%20Update" | jq -r '.results[0].id')
curl -sk -u "$AAP_USERNAME:$AAP_PASSWORD" \
  -H "Content-Type: application/json" \
  -X POST "$CONTROLLER_URL/job_templates/$TEMPLATE_ID/credentials/" \
  -d "{
    \"id\": $CREDENTIAL_ID
}"
echo; echo; echo "Created a Job Template 'DB Update'"

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
