#!/bin/bash

echo "Installing nginx in the `hostname`"
sudo yum install nginx -y

HTML_DIR="/var/www/html"
NGINX_CONF="/etc/nginx/nginx.conf"

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

chown -R nginx:nginx /var/www/html
chmod -R 755 /var/www/html
semanage fcontext -a -t httpd_sys_content_t "/var/www/html(/.*)?"
restorecon -Rv /var/www/html

nginx -t
systemctl start nginx
systemctl enable nginx

nginx -s reload
echo "Started & enabled nginx in systemctl"
