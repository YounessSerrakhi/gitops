#!/bin/bash

# Update system
yum update -y

# Install MySQL (Community Edition)
amazon-linux-extras install -y mysql8.0

# Start MySQL service
systemctl enable mysqld
systemctl start mysqld

# Secure MySQL installation
TEMP_ROOT_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')

# MySQL secure installation automated
mysql -h localhost -u root -p"$TEMP_ROOT_PASSWORD" --connect-expired-password <<-EOSQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
CREATE DATABASE ${DB_NAME};
CREATE USER '${DB_USERNAME}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USERNAME}'@'%';
FLUSH PRIVILEGES;
EXIT
EOSQL

# Optional: Configure MySQL to listen on all interfaces
sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/my.cnf

# Restart MySQL to apply changes
systemctl restart mysqld

# Log completion
echo "MySQL setup completed" >> /var/log/mysql-setup.log