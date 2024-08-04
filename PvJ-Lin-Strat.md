---
title: PvJ Strategy

---

# PvJ Strategy
This document and its contents are the sole property of Martin Roberts. Unauthorized sharing, distribution, or reproduction of any part of this document is strictly prohibited. No consent is granted to share any contents of this document under any circumstances. Any use of the material contained herein without the explicit written permission of Martin Roberts is strictly forbidden and may result in legal action.

© 2024 Martin Roberts. All rights reserved.
## Linux General Box Strategy
- [ ] Do a simple backup of /etc/, /var/www to the /backup directories
    - [ ] `mkdir /backup`
    - [ ] `cp -rp {/var/www,/etc,/home,/opt,/root} /backup`
    - [ ] `chattr +i /backup`

- [ ] Turn off SSH if not a scored service (is this allowed?) `systemctl stop sshd`
- [ ] Stop cron `systemctl stop cron crond at anancron`
- [ ] Remove ssh files `rm -rf /home/*/.ssh` & `rm -rf /root/.ssh`
- [ ] Remove bashrc `rm -rf /home/*/.bashrc` & `rm -rf /root/.bashrc`

- [ ] Remove sudoedit `rm -f $(which sudoedit)`
- [ ] Change permissions on pkexec `chmod 0755 /usr/bin/pkexec`

- [ ] Change sudoers file
    - [ ] *Only this line has to exist in /etc/sudoers* `root    ALL=(ALL:ALL) ALL`
    - [ ] Check for any files in /etc/sudoers.d.

- [ ] Update Linux packages: `apt-get update && apt-get upgrade`
- [ ] Add auditd rules for tracking commands ran (Wazuh recommended rules):
> auditctl -a exit,always -F arch=b64 -F euid=0 -S execve -k  audit-wazuh-c
auditctl -a exit,always -F arch=b32 -F euid=0 -S execve -k  audit-wazuh-c
auditctl -a exit,always -F arch=b64 -F euid!=0 -S execve -k  audit-wazuh-c
auditctl -a exit,always -F arch=b32 -F euid!=0 -S execve -k  audit-wazuh-c

* To view the logs: `ausearch -k audit-wazuh-c | grep argc`
* If logs don't show up, enable auditd `auditctl -e 1`

- [ ] Run package integrity checkers:
    > Redhat: `rpm -Va`
    > Debian Based Distros: `debsums -ac`
    > Arch: `paccheck --md5sum --quiet`

## Linux SSH as a scored service
### 0. Change Local User Passwords (Go back and do root user)

>read -p "Pass: " -s pass && for i in $(cut -d: -f1 /etc/passwd | grep -v root);do echo -e "$pass\n$pass"|passwd $i; done


### 1. Firewalls/IPTables

```
[Inboud Rules]
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -s jumphost_ip -j ACCEPT
iptables -A INPUT -j LOG
iptables -A INPUT -j DROP

[Outbound Rules]
iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A OUTPUT -d jumphost_ip -j ACCEPT
iptables -A OUTPUT -p icmp -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -j LOG
iptables -A OUTPUT -j DROP


[IPV6]
ip6tables -A INPUT -j DROP
ip6tables -A OUTPUT -j DROP

[Save Iptables Rules]
iptables-save >> /backup/rules

```

### 2. Remove keys

If you haven't backed up `/root` and `/home` yet:

```
mkdir /backup
cp -r /home /backup
cp -r /root /backup
```

Remove pre-planted keys:

```
rm -rf /root/.ssh/*
for i in $(ls /home); do rm -rf /home/$i/.ssh/*; done
```

### 3. Reinstall PAM modules

```
apt install --reinstall libpam-modules
```

Figure out what commands are being ran (after installing auditd)

```
cat /var/log/audit/audit.log | grep -i EXECVE
# You should see a bunch of whoami (maybe?)
```


### 4. OpenSSHD Configuration Strategy

Ensure these settings are set:

```
Protocol 2
Port 22
LoginGraceTime 60
PermitRootLogin no
StrictModes yes
PubKeyAuthentication no
AuthorizedKeys .ssh/authorized_key
UsePrivilegeSeparation yes
MaxAuthTries 3
MaxSessions 3

PasswordAuthentication yes

HostbasedAuthentication no
IgnoreRhosts yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM no

PrintMotd no
PrintLastLog no
X11Forwarding no
AllowTcpForwarding no
PermitTunnel no
TCPKeepAlive no

Banner none
```

Make sure SSHD config is good and restart

```
sshd -tcp
systemctl restart sshd
    OR
service sshd restart
```

Adding User specific configs

```
Match User [username],([usernames])
    [config details]
```

Restricting to IPs
```
Match Address 192.168.0.5,192.172.0.0/24
    [config details]
```

Allowlisting

```
AllowUsers user1
DenyUsers user2
AllowGroups safe
DenyGroups notsafe
```

- Note: These rules are processed by priority, AllowUsers being first, and DenyGroups being last

### 5. Set up Chroot (Optional)

```
groupadd safe
usermod -aG safe root
usermod -aG safe [whitelist]

mkdir /var/chroot/
mkdir /var/chroot/etc
mkdir /var/chroot/usr

cp -R -p /home/ /var/chroot
cp /etc/{passwd,group,nsswitch.conf} /var/chroot/etc/
cp -R /lib* /var/chroot/
cp -R /bin/ /var/chroot/
cp -R /usr/bin/ /var/chroot/usr

Match Group *,!safe
    ChrootDirectory /var/chroot
```
---

## Linux WebApp Security Guide
### 1. Change PHP Functions in /etc/php.ini:
```
disable_functions = “exec, shell_exec, passthru, system, proc_open, pcntl_exec, eval, 
assert, popen, curl_exec, curl_multi_exec, parse_ini_file, show_source”
```

*If you can't find the php.ini file in that path, do `find / -iname "php.ini"`*

### 2. Iptables Rules
    
```
-A INPUT -p tcp -m tcp --dport 80 -m string --string "TRACE" --algo bm --to 65535 -j DROP
-A INPUT -p tcp -m tcp --dport 80 -m string --string "POST" --algo bm --to 65535 -j DROP
-A INPUT -p tcp -m tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m tcp --sport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
-A INPUT -p icmp -m icmp --icmp-type 8 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
-A INPUT -s 127.0.0.0/8 -j ACCEPT
-A INPUT -p tcp -m tcp --sport 3306 -s <our range/24>  -m state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -j LOG
-A INPUT -j DROP

    
-A OUTPUT -p tcp --dport 80 -m owner --gid-owner games -j ACCEPT
-A OUTPUT -p tcp --dport 443 -m owner --gid-owner games -j ACCEPT
-A OUTPUT -p udp --dport 53 -m owner --gid-owner games -j ACCEPT
-A OUTPUT -p tcp -m tcp --sport 80 -j ACCEPT
-A OUTPUT -d 127.0.0.0/8 -j ACCEPT
-A OUTPUT -p icmp -m icmp --icmp-type 0 -j ACCEPT
-A OUTPUT -p tcp -m tcp --sport 22 -j ACCEPT
-A OUTPUT -p tcp -m tcp --sport 80 -j ACCEPT
-A OUTPUT -p tcp -m tcp --dport 3306 -j ACCEPT --uid-owner apache -j ACCEPT
-A OUTPUT -j LOG
-A OUTPUT -j DROP

```
    
### 3. Login to your WebApp via browser, change the user account passwords 

### 4. Find PHP Webshells

`find /var/www/ -iname "*.php" -print -exec grep "(exec|CMD|shell|system|passthru)" -exec mv -t /backups/ {} +`

## Database Security Guide
### MySQL

- [ ] 1. Dump the database 

    - `mysqldump -u root --all-databases > /backup/db.sql` && `chmod 000 /backup/db.sql`

- [ ] 2. Run `mysql_secure_installation`

- [ ] 3. Log into database with root and audit MySQL users

    - `mysql -u root -p`
    - `select * from mysql.user;`
    - `select * from mysql.user where Host = '%';`

	**Note: % denotes that this user can log in from any host**

- [ ] 4. Change user passwords
	- 	If MariaDB version is <= 10.1.20 or MySQL version is <= 5.7.5 
`SET PASSWORD FOR 'root'@'localhost' = PASSWORD('Your_new_password');
FLUSH PRIVILEGES;`

	- If MariaDB version is >= 10.1.20 or MySQL version is >= 5.7.6
	`UPDATE mysql.user SET authentication_string = PASSWORD('MY_NEW_PASSWORD') WHERE User = 'root' AND Host = 	localhost';`
	`FLUSH PRIVILEGES;`
 
	- If above instructions don't work, try
	
		`ALTER USER 'root'@'localhost' IDENTIFIED BY 'MyNewPass';`	
		`FLUSH PRIVILEGES;`


- [ ] 5. Find the configuration file to change the database password:

	`grep -irln "[databaseName or database user]"`



- [ ] 6. Drop unneeded users

    - `drop user '[username]'@'[ip]';`
    - `flush privileges;`

- [ ] 7. List databases in database (to give you an idea of what's using it)

    - `show databases;`
    - `use [database];`

- [ ] 8. Create new users
> `create user '[username]'@'[web app ip]' identified by '[newPassword]';`
>`grant [ALL,SELECT,CREATE,DROP,EXECUTE,UPDATE,INSERT] on [db name].* to '[username]'@'[web app ip];`
> If you append `with grant option` to the end, the user has the ability to grant privileges.
> 
> `flush privileges;`

- [ ] 9. Update table values

    - `update [table] set [value] = [new value] where [insert relation];`
        - This can be useful if you need to manually change passwords and stuff

- [ ] 10. Revoking privileges

	```
	REVOKE INSERT ON *.* FROM 'jeffrey'@'localhost';
	REVOKE 'role1', 'role2' FROM 'user1'@'localhost', 'user2'@'localhost';
	REVOKE SELECT ON world.* FROM 'role3';
	```

- [ ] 11. Logging

	* MySQL 5.1.29+
		* Set the following in my.cnf
		
			```
			general_log_file = /path/to/query.log
			general_log = 1
			```
	
		* In MySQL run command: `SET global general_log = 1;`
	
	* MySQL < 5.1.29
	
		* Set the following in my.cnf
	`log = /path/to/query.log`
	
		* In MySQL run command: `SET general_log = 1;`

- [ ] 12. Audit `/etc/my.cnf` and `/etc/my.cnf.d` (don't forget to `systemctl restart`)

### PostgreSQL

- [ ] 1. Dump the database

    - `pg_dump [database name] > dump.sql`

- [ ] 2. Change user passwords

    - Log into postgres database: `su postgres; pgsql postgres postgres`
    - Once logged in: `\password [user]` or `\password` (for yourself)

- [ ] 2. Modify pg_hba.conf

    - For local connections: `local     my_db     my_user     scram-sha-256`
    - For remote connections: `host        my_db     my_user     172.16.253.47/32        [scram-sha-256 or md5]`
    - The "peer" method can only be used for local connections: **DO NOT ALLOW ANY HOSTS TO BE TRUSTED**

- [ ] 3. PostgreSQL Commands

    - Listing databases: `\l`
    - Connecting to a database: `\c [database name]`
    - Listing tables: `\dt`
    - List users and their roles: `\du`
    - Update table: `UPDATE [table] SET column1 = value1 WHERE [insert relation]`
    - Create user: `CREATE USER [username] with encrypted password '[password]';`
    	- `sudo -u postgres createuser [userName]`
    - Granting privileges: `grant all privileges on database [databasename] to [username]`

- [ ] 4. Revoking Permissions

	```sql
	REVOKE privilege | ALL
	ON TABLE table_name |  ALL TABLES IN SCHEMA schema_name
	FROM role_name;
	```
## Bind Server Security
### Disable zone-transfers
    `vim named.conf` or `vim named.conf.options`
    in the zones add: `allow-transfer { "none"; };
## FTP Server Security

* Set up baseline SELinux

```
apt install -y selinux-utils selinux-basics auditd audispd-plugins
```
***WILL REBOOT MACHINE***

```
selinux-activate 
sestatus
grep 'vsftpd' /var/log/audit/audit.log | audit2allow -M vsftpdpol
semodule -i vsftpdpol.pp
setenforce 1
```
* Allow vsftpd to read/write home directories
`setsebool -P ftp_home_dir 1`

* Edit the vsftpd config
```
nano /etc/vsftpd.conf
chroot_local_users=YES
systemctl restart vsftpd
```

## Mail Server Security
* Disable VRFY in POSTfix
`postconf -e disable_vrfy_command=yes`

* Enable HELO
`postconf -e smtpd_helo_required=yes`

* Avoid being an open relay
`postconf -e mynetworks"127.0.0.0/8 <network we are on>`

#### Chroot postfix
- [ ] Find child processes
`ps --ppid <pid of postfix (master)>`
- [ ] For each child
`ls -al /proc/<pid of child>/root`
    - If the output of the above points to `/` it is not chrooted
- [ ] Edit `/etc/postfix/master.cf`
    - Search for the name of the child process
    - Change the chroot column for the child process to `y`


## Jenkins Security

1. Backup Jenkins, path might be `/var/lib/jenkins`
2. Login to the web interface. Jump to the "Configure" section and change the user's password.

	* If the password is unknown it is possible to change the user's password by changing the password for the user at `/var/lib/jenkins/users/[admin user]_*/config.xml` under the `<PasswordHash>` tag.
	* Simply add a created hash from https://www.javainuse.com/onlineBcrypt after `jbcrypt:` and restart jenkins to have it accept the new password.

3. Check what api keys are there, maybe delete them. If something broke, you can restore `/var/lib/jenkins/users/admin_*/config.xml`
4. Consider removing all SSH Keys (copy them to another place to easily restore)
5. Revoke all sessions in case the red team is in
6. Visit the "Manage Jenkins" section. Scroll the the users management section, consider disabling all other users. 
7. In the manage section, go to "Configure Global Security". Uncheck the following:

	* Allow users to sign up
	* Allow anonymous read access
	* Check this box: Prevent Cross Site Request Forgery exploits
	* Disable the Jenkins SSH Server

8. Jump to Manage Plugins. Click "Download now and install after update." Might have to restart for these updates to take place so be sure the service is operating after your previous changes. 
9. Backup Jenkins again to a **new** place


### Create Reverse Proxy and Disable POST
1. `systemctl status jenkins` - Find where Jenkins configures port to listen to
2. Change JENKINS_PORT to 8081 in `/usr/lib/systemd/system/jenkins.service`
3. Run `yum install httpd` Or whatever installs apache2
4. `nano /etc/httpd/conf/httpd.conf`
5. Add The following lines - Note the LoadModule lines might be redundent

```
Listen 8080
ProxyPreserveHost On
ProxyPass / http://localhost:8081/
ProxyPassReverse / http://localhost:8081/
<Location />
    <LimitExcept GET>
        order deny,allow
        deny from all
    </LimitExcept>
</Location>
```
6. `systemctl restart jenkins`
7. `systemctl restart httpd` (Or apache2)
8. If broken run `/usr/sbin/setsebool -P httpd_can_network_connect 1`



## Redis Security
### Redis Configuration file
- [ ] You can require a pass for a user by doing `requirepass securepassword`
#### Stop Dangerous Commands
> Some of the commands that are considered dangerous include: FLUSHDB, FLUSHALL, KEYS, PEXPIRE, DEL, CONFIG, SHUTDOWN, BGREWRITEAOF, BGSAVE, SAVE, SPOP, SREM, RENAME, and DEBUG. This is not a comprehensive list, but renaming or disabling all of the commands in that list is a good starting point for enhancing your Redis server’s security.

```
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command DEBUG ""
```

- [ ] Restart redis: `systemctl restart redis`