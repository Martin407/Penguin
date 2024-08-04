#!/bin/bash

# Function to enable MySQL audit logging
enable_audit_logging() {
    echo "Enabling MySQL audit logging..."

    # Check if audit plugin is already installed
    if ! mysql -e "SHOW PLUGINS;" | grep -q "audit_log"; then
        # Install the audit plugin
        mysql -e "INSTALL PLUGIN audit_log SONAME 'audit_log.so';"
    fi

    # Enable audit logging
    mysql -e "SET GLOBAL audit_log_policy = 'ALL';"
    echo "MySQL audit logging enabled."
}

# Function to create read-only users for each database
create_read_only_users() {
    echo "Creating read-only users for each database..."

    # Get the list of databases
    databases=$(mysql -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")

    for db in $databases; do
        # Get the list of IP addresses that have connected to this database
        ips=$(mysql -e "SELECT DISTINCT host FROM mysql.general_log WHERE argument LIKE '%$db%';" | grep -v "host")

        for ip in $ips; do
            # Create a read-only user for this database and IP address
            user="readonly_${db}_${ip//./_}"
            mysql -e "CREATE USER '$user'@'$ip' IDENTIFIED BY 'secure_password';"
            mysql -e "GRANT SELECT ON $db.* TO '$user'@'$ip';"
            mysql -e "FLUSH PRIVILEGES;"
            echo "Created read-only user '$user' for database '$db' and IP '$ip'."
        done
    done
}

# Enable MySQL audit logging
enable_audit_logging

# Create read-only users for each database
create_read_only_users

echo "MySQL service secured."