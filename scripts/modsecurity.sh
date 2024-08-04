#!/bin/bash

# Function to install and configure ModSecurity for Apache on Ubuntu
install_modsecurity_ubuntu() {
    echo "Installing ModSecurity for Apache on Ubuntu..."

    # Install necessary package
    sudo apt update
    sudo apt install -y libapache2-mod-security2

    # Enable ModSecurity module
    sudo a2enmod security2
    sudo systemctl restart apache2

    # Configure ModSecurity
    sudo mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
    sudo sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/modsecurity/modsecurity.conf
    sudo sed -i 's/SecAuditLogParts ABDEFHIJZ/SecAuditLogParts ABCEFHJKZ/' /etc/modsecurity/modsecurity.conf

    # Download and setup Core Rule Set (CRS)
    wget https://github.com/coreruleset/coreruleset/archive/refs/tags/v3.3.2.tar.gz
    tar -xvf v3.3.2.tar.gz
    sudo mkdir /etc/apache2/modsecurity-crs/
    sudo mv coreruleset-3.3.2/ /etc/apache2/modsecurity-crs/
    cd /etc/apache2/modsecurity-crs/
    sudo mv crs-setup.conf.example crs-setup.conf

    # Update Apache configuration to include CRS
    sudo sed -i 's|IncludeOptional /usr/share/modsecurity-crs/\*.load|IncludeOptional /etc/apache2/modsecurity-crs/coreruleset-3.3.2/crs-setup.conf\nIncludeOptional /etc/apache2/modsecurity-crs/coreruleset-3.3.2/rules/\*.conf|' /etc/apache2/mods-enabled/security2.conf

    # Restart Apache to apply changes
    sudo systemctl restart apache2

    echo "ModSecurity installation and configuration for Apache on Ubuntu is complete."
}

# Function to install and configure ModSecurity for Apache on CentOS
install_modsecurity_centos() {
    echo "Installing ModSecurity for Apache on CentOS..."

    # Install necessary packages
    sudo yum install -y mod_security mod_security_crs git httpd

    # Configure ModSecurity
    sudo mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
    sudo sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/modsecurity/modsecurity.conf
    sudo sed -i 's/SecResponseAccess On/SecResponseAccess Off/' /etc/modsecurity/modsecurity.conf

    # Restart Apache to apply changes
    sudo systemctl restart httpd

    echo "ModSecurity installation and configuration for Apache on CentOS is complete."
}

# Function to install and configure ModSecurity for Bitnami Apache
install_modsecurity_bitnami() {
    echo "Installing ModSecurity for Bitnami Apache..."

    # Configure ModSecurity
    sudo sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /opt/bitnami/apache2/conf/modsecurity.conf
    sudo sed -i 's/SecAuditLogParts ABDEFHIJZ/SecAuditLogParts ABCEFHJKZ/' /opt/bitnami/apache2/conf/modsecurity.conf

    # Update Bitnami Apache configuration
    sudo sed -i '/#LoadModule unique_id_module modules\/mod_unique_id.so/a LoadModule unique_id_module modules/mod_unique_id.so\nLoadModule security2_module modules/mod_security2.so' /opt/bitnami/apache2/conf/httpd.conf
    echo 'Include "/opt/bitnami/apache2/conf/modsecurity.conf"' | sudo tee -a /opt/bitnami/apache2/conf/httpd.conf
    echo 'IncludeOptional "/opt/bitnami/apache2/modsecurity-crs/*.conf"' | sudo tee -a /opt/bitnami/apache2/conf/httpd.conf
    echo 'IncludeOptional "/opt/bitnami/apache2/modsecurity-crs/rules/*.conf"' | sudo tee -a /opt/bitnami/apache2/conf/httpd.conf

    # Download and setup Core Rule Set (CRS)
    wget https://github.com/coreruleset/coreruleset/archive/refs/tags/v3.3.2.tar.gz
    tar -xvf v3.3.2.tar.gz
    sudo mkdir /opt/bitnami/apache2/modsecurity-crs/
    sudo mv coreruleset-3.3.2/* /opt/bitnami/apache2/modsecurity-crs/
    cd /opt/bitnami/apache2/modsecurity-crs/
    sudo mv crs-setup.conf.example crs-setup.conf

    # Restart Bitnami Apache to apply changes
    sudo /opt/bitnami/ctlscript.sh restart apache

    echo "ModSecurity installation and configuration for Bitnami Apache is complete."
}

# Determine the system type and install ModSecurity accordingly
if command -v apt &> /dev/null; then
    install_modsecurity_ubuntu
elif command -v yum &> /dev/null; then
    install_modsecurity_centos
elif [ -d "/opt/bitnami" ]; then
    install_modsecurity_bitnami
else
    echo "Unsupported system. This script supports Ubuntu, CentOS, and Bitnami Apache."
    exit 1
fi