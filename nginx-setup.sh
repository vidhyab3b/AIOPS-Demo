#!/bin/bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "root@node1" bash -s <<'EOF'
sudo yum install nginx -y
# Change nginx listen port to 8080 (IPv4 and IPv6)
sudo sed -i 's/listen\s\+80;/listen 8080;/' /etc/nginx/nginx.conf
sudo sed -i 's/listen\s\+\[::\]:80;/listen [::]:8080;/' /etc/nginx/nginx.conf
sudo systemctl start nginx; sudo systemctl enable nginx
EOF
