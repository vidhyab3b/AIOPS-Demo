#! /bin/bash
echo "Installing nginx in the `hostname`"
sudo yum install nginx -y

# Change nginx listen port to 8080 (IPv4 and IPv6)
sudo sed -i 's/listen\s\+80\(\s\+default_server\)\?;/listen 8080\1;/' /etc/nginx/nginx.conf
sudo sed -i 's/listen\s\+\[::\]:80\(\s\+default_server\)\?;/listen [::]:8080\1;/' /etc/nginx/nginx.conf
echo "Configured nginx to listen in port 8080 in the `hostname`"

sudo systemctl start nginx
sudo systemctl enable nginx
echo "Started & enabled nginx in systemctl"
