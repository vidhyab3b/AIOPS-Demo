#!/bin/bash

source  aiops_demojam.env

# Prompt for Bastion Node's FQDN
read -p "Enter the OCP API URL: " OCP_API_URL
while [[ -z "$OCP_API_URL" ]]; do
    read -p "Enter the OCP API URL: " OCP_API_URL
    if [[ -z "$OCP_API_URL" ]]; then
        echo "OCP_API_URL cannot be empty. Please try again."
    fi
done

# Prompt for Bastion Node's FQDN
read -p "Enter the OCP Username: " OCP_USERNAME
while [[ -z "$OCP_USERNAME" ]]; do
    read -p "Enter the OCP Username: " OCP_USERNAME
    if [[ -z "$OCP_USERNAME" ]]; then
        echo "USERNAME cannot be empty. Please try again."
    fi
done

# Prompt for Bastion Node's FQDN
read -p "Enter the OCP Password: " OCP_PASSWORD
while [[ -z "$OCP_PASSWORD" ]]; do
    read -p "Enter the OCP Password: " OCP_PASSWORD
    if [[ -z "$OCP_PASSWORD" ]]; then
        echo "PASSWORD cannot be empty. Please try again."
    fi
done
