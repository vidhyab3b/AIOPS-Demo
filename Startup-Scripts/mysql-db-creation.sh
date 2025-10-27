#!/bin/bash

echo "Installing mysql-shell & jq"
dnf install -y https://dev.mysql.com/get/mysql80-community-release-el8-3.noarch.rpm --nogpgcheck
dnf install -y mysql-shell --nogpgcheck
dnf install jq -y
dnf clean all

nohup oc port-forward deployment/mysql-db 3306:3306 -n aiops > port-forward.log 2>&1 &

mysqlsh --host=127.0.0.1 --user=mysql --password=redhat --port=3306 --sql -e "
USE aiopsdb;
CREATE TABLE Error_Table (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    Server_Name VARCHAR(255),
    Error_Message TEXT,
    Created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Status VARCHAR(50)
);"

mysqlsh --host=127.0.0.1 --user=mysql --password=redhat --port=3306 --sql -e "
USE aiopsdb;
CREATE TABLE Error_RCA (
    id BIGINT PRIMARY KEY,
    errorid BIGINT,
    prompt VARCHAR(1000),
    ai_response MEDIUMTEXT,
    ansible_playbook MEDIUMTEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

mysqlsh --host=127.0.0.1 --user=mysql --password=redhat --port=3306 --sql -e "
USE aiopsdb;
CREATE TABLE Playbook_Status (
    id BIGINT PRIMARY KEY,
    Error_ID BIGINT,
    RCA_ID BIGINT,
    server_Name VARCHAR(255),
    execution_Status VARCHAR(100),
    Created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);"
