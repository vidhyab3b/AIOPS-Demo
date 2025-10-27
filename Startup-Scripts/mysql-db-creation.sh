#!/bin/bash

echo "Installing mysql-shell & jq"
dnf install -y https://dev.mysql.com/get/mysql80-community-release-el8-3.noarch.rpm --nogpgcheck
dnf install -y mysql-shell --nogpgcheck
dnf install jq -y
dnf clean all
