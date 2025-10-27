#!/bin/bash

# Prompt for username and password
read -p "Enter the Bastion Node's FQDN: " HOST
read -p "Enter the Bastion Node's Username: " USERNAME
read -s -p "Enter the Bastion Node's Password: " PASSWORD
echo

# Run the SSH command using sshpass
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USERNAME@$HOST" bash -s <<'EOF'
sudo yum install nginx -y

# Change nginx listen port to 8080 (IPv4 and IPv6)
sudo sed -i 's/listen\s\+80;/listen 8080;/' /etc/nginx/nginx.conf
sudo sed -i 's/listen\s\+\[::\]:80;/listen [::]:8080;/' /etc/nginx/nginx.conf

sudo systemctl start nginx
sudo systemctl enable nginx
EOF
