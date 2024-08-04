#!/bin/bash

# Function to update Apache configurations
update_apache_configs() {
    APACHE_CONFIG_DIR="/etc/apache2"  # Adjust this path if necessary

    # Find all Apache configuration files
    find $APACHE_CONFIG_DIR -type f -name "*.conf" | while read -r config_file; do
        # Check if the file contains the Directory directive
        if grep -q "<Directory" "$config_file"; then
            # Add the LimitExcept directive to disable anything but GET requests
            sed -i '/<Directory /,/<\/Directory>/ s|</Directory>| <LimitExcept GET>\n    order deny,allow\n    Deny from all\n </LimitExcept>\n</Directory>|' "$config_file"
        fi
    done

    # Restart Apache to apply changes
    sudo systemctl restart apache2
}

# Function to update php.ini files
update_php_ini() {
    DISABLE_FUNCTIONS="exec, shell_exec, passthru, system, proc_open, pcntl_exec, eval, assert, popen, curl_exec, curl_multi_exec, parse_ini_file, show_source"

    # Find all php.ini files
    find / -type f -name "php.ini" 2>/dev/null | while read -r php_ini; do
        # Check if disable_functions is already set
        if grep -q "^disable_functions" "$php_ini"; then
            # Update the disable_functions line
            sed -i "s|^disable_functions.*|disable_functions = \"$DISABLE_FUNCTIONS\"|" "$php_ini"
        else
            # Add the disable_functions line
            echo "disable_functions = \"$DISABLE_FUNCTIONS\"" >> "$php_ini"
        fi
    done

    # Restart PHP service to apply changes
    if command -v systemctl &> /dev/null; then
        sudo systemctl restart php*-fpm
    elif command -v service &> /dev/null; then
        sudo service php*-fpm restart
    else
        echo "Unable to restart PHP service. Please restart it manually."
    fi
}

# Execute the functions
update_apache_configs
update_php_ini

echo "Apache and PHP configurations have been updated."