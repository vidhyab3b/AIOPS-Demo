#!/bin/bash

echo "Installing nginx in the `hostname`"
sudo yum install nginx -y

HTML_DIR="/var/www/html"
NGINX_CONF="/etc/nginx/nginx.conf"

# Change nginx listen port to 8080 (IPv4 and IPv6)
sudo sed -i 's/listen\s\+80\(\s\+default_server\)\?;/listen 8080\1;/' $NGINX_CONF
sudo sed -i 's/listen\s\+\[::\]:80\(\s\+default_server\)\?;/listen [::]:8080\1;/' $NGINX_CONF
echo "Configured nginx to listen in port 8080 in the `hostname`"

mkdir -p "$HTML_DIR"

cat > "$HTML_DIR/index.html" <<'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>Nginx Test Page</title>
</head>
<body>
  <h1>Nginx is running</h1>
  <p>This page is served from /var/www/html/index.html</p>
</body>
</html>
EOF

sed -i '/server_name  _;/a \
    root /var/www/html;\n    index index.html;\n' "$NGINX_CONF"

sed -i '/proxy_pass/d' "$NGINX_CONF"
sed -i '/return 200/d' "$NGINX_CONF"

nginx -t
sudo systemctl start nginx
sudo systemctl enable nginx

echo "Started & enabled nginx in systemctl"
