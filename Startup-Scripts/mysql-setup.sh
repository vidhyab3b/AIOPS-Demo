#!/bin/bash

source  aiops_demojam.env

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USERNAME@$BASTION_HOST" bash -s <<EOF
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
read -p "Enter the OCP Password: " OCP_PASSWORD
while [[ -z "$OCP_PASSWORD" ]]; do
    read -p "Enter the OCP Password: " OCP_PASSWORD
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
oc new-project aiops

EOF
