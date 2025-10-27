#!/bin/bash

# Prompt for Bastion Node's FQDN
read -p "Enter the Bastion Node's FQDN: " HOST
while [[ -z "$HOST" ]]; do
    read -p "Enter the Bastion Node's FQDN: " HOST
    if [[ -z "$HOST" ]]; then
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

echo "Logging in to the server $HOST"

# Run the SSH command using sshpass
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USERNAME@$HOST" bash -s <<'EOF'
if [ $? -ne 0 ]; then
echo "Verify the credentials and rerun the script"
else
echo "Installing nginx in the $HOST"
sudo yum install nginx -y

# Change nginx listen port to 8080 (IPv4 and IPv6)
sudo sed -i 's/listen\s\+80\(\s\+default_server\)\?;/listen 8080\1;/' /etc/nginx/nginx.conf
sudo sed -i 's/listen\s\+\[::\]:80\(\s\+default_server\)\?;/listen [::]:8080\1;/' /etc/nginx/nginx.conf
echo "Configured nginx to listen in port 8080 in the `hostname`"

sudo systemctl start nginx
sudo systemctl enable nginx
echo "Started & enabled nginx in systemctl"
fi
EOF
