#!/bin/bash

# Function to enable PostgreSQL audit logging
enable_audit_logging() {
    echo "Enabling PostgreSQL audit logging..."

    # Check if pgaudit extension is already installed
    if ! psql -U postgres -c "\dx" | grep -q "pgaudit"; then
        # Install the pgaudit extension
        psql -U postgres -c "CREATE EXTENSION pgaudit;"
    fi

    # Enable audit logging in the PostgreSQL configuration
    sudo sed -i "s/#shared_preload_libraries = ''/shared_preload_libraries = 'pgaudit'/" /etc/postgresql/*/main/postgresql.conf
    sudo sed -i "s/#pgaudit.log = 'none'/pgaudit.log = 'all'/" /etc/postgresql/*/main/postgresql.conf

    # Restart PostgreSQL to apply changes
    sudo systemctl restart postgresql
    echo "PostgreSQL audit logging enabled."
}

# Function to create read-only users for each database
create_read_only_users() {
    echo "Creating read-only users for each database..."

    # Get the list of databases
    databases=$(psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;")

    for db in $databases; do
        # Get the list of IP addresses that have connected to this database
        ips=$(psql -U postgres -d $db -t -c "SELECT DISTINCT client_addr FROM pg_stat_activity WHERE datname = '$db' AND client_addr IS NOT NULL;")

        for ip in $ips; do
            # Create a read-only user for this database and IP address
            user="readonly_${db}_${ip//./_}"
            psql -U postgres -c "CREATE USER $user WITH PASSWORD 'secure_password';"
            psql -U postgres -c "GRANT CONNECT ON DATABASE $db TO $user;"
            psql -U postgres -d $db -c "GRANT USAGE ON SCHEMA public TO $user;"
            psql -U postgres -d $db -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO $user;"
            psql -U postgres -d $db -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO $user;"
            echo "Created read-only user '$user' for database '$db' and IP '$ip'."
        done
    done
}

# Enable PostgreSQL audit logging
enable_audit_logging

# Create read-only users for each database
create_read_only_users