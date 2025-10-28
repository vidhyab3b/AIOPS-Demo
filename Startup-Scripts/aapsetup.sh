#!/bin/bash

read -p "Enter the AAP Console URL: " CONSOLE_URL
while [[ -z "$CONSOLE_URL" ]]; do
    read -p "Enter the AAP Controller URL: " CONSOLE_URL
    if [[ -z "$CONSOLE_URL" ]]; then
        echo "AAP CONSOLE URL cannot be empty. Please try again."
    fi
done
CONTROLLER_URL="$CONSOLE_URL/api/controller/v2"

read -p "Enter the AAP Username: " AAP_USERNAME
while [[ -z "$AAP_USERNAME" ]]; do
    read -p "Enter the Bastion Node's Username: " AAP_USERNAME
    if [[ -z "$AAP_USERNAME" ]]; then
        echo "Username cannot be empty. Please try again."
    fi
done

read -s -p "Enter the AAP Password: " AAP_PASSWORD
while [[ -z "$AAP_PASSWORD" ]]; do
    read -s -p "Enter the AAP Password: " AAP_PASSWORD
    echo
    if [[ -z "$AAP_PASSWORD" ]]; then
        echo "Password cannot be empty. Please try again."
    fi
done

# Find the Org ID of ‘Default’ & Create an Inventory ‘RHEL’
ORG_ID=$(curl -sk -u "$AAP_USERNAME:$AAP_PASSWORD" "$CONTROLLER_URL/organizations/" | jq -r '.results[] | select(.name=="Default") | .id')
curl -k -u "$AAP_USERNAME:$AAP_PASSWORD" \
  -H "Content-Type: application/json" \
  -X POST $CONTROLLER_URL/inventories/ \
  -d '{"name": "RHEL", "organization": 1}'
echo; echo "Created an Inventory 'RHEL'"

read -p "Enter the Bastion Node's FQDN: " BASTION_HOST
while [[ -z "$BASTION_HOST" ]]; do
    read -p "Enter the Bastion Node's FQDN: " BASTION_HOST
    if [[ -z "$BASTION_HOST" ]]; then
        echo "FQDN cannot be empty. Please try again."
    fi
done

# Find the Inventory ID of ‘RHEL’ & add a host
INVENTORY_ID=$(curl -sk -u "$AAP_USERNAME:$AAP_PASSWORD" "$CONTROLLER_URL/inventories/?name=RHEL" | jq -r '.results[0].id')
curl -sk -u "$AAP_USERNAME:$PASSWORD" \
  -H "Content-Type: application/json" \
  -X POST "$CONTROLLER_URL/hosts/" \
  -d "{\"name\": \"$BASTION_HOST\", \"inventory\": $INVENTORY_ID}"
echo; echo "Added an host to the Inventory 'RHEL'"

# Find the Credential ID
// CRED_ID=$(curl -sk -u "$AAP_USERNAME:$AAP_PASSWORD" \
  // "$CONTROLLER_URL/credentials/?name=lab-credential" | \
  // jq -r '.results[0].id')

// echo; echo "Configured the credentials"
