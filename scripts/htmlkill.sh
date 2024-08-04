#!/bin/bash
iptables -A INPUT -p tcp -m tcp --dport 80 -m string --string "TRACE" --algo bm --to 65535 -j DROP
iptables -A INPUT -p tcp -m tcp --dport 80 -m string --string "POST" --algo bm --to 65535 -j DROP
iptables -A INPUT -p tcp --dport 80 -m string --string "MySQL dump" --algo bm --to 65535 -j DROP
iptables -A INPUT -p tcp --dport 80 -m string --string "/dev/null" --algo bm --to 65535 -j DROP
iptables -A INPUT -p tcp --dport 80 -m string --string "/var/www" --algo bm --to 65535 -j DROP 
iptables -A INPUT -p tcp --dport 80 -m string --string "audio_mic_list" --algo bm --to 65535 -j DROP
iptables -A INPUT -p tcp --dport 80 -m string --string "sh" --algo bm --to 65535 -j DROP 
iptables -A INPUT -p tcp --dport 80 -m string --string "bash" --algo bm --to 65535 -j DROP
iptables -A INPUT -p tcp --dport 80 -m string --string "os" --algo bm --to 65535 -j DROP 
iptables -A INPUT -p tcp --dport 80 -m string --string "curl" --algo bm --to 65535 -j DROP
iptables -A INPUT -p tcp --dport 80 -m string --string "wget" --algo bm --to 65535 -j DROP
iptables -A OUTPUT -p tcp -m tcp --dport 80 -m string --string "TRACE" --algo bm --to 65535 -j DROP
iptables -A OUTPUT -p tcp -m tcp --dport 80 -m string --string "POST" --algo bm --to 65535 -j DROP
iptables -A OUTPUT -p tcp --dport 80 -m string --string "MySQL dump" --algo bm --to 65535 -j DROP
iptables -A OUTPUT -p tcp --dport 80 -m string --string "/dev/null" --algo bm --to 65535 -j DROP
iptables -A OUTPUT -p tcp --dport 80 -m string --string "/var/www" --algo bm --to 65535 -j DROP 
iptables -A OUTPUT -p tcp --dport 80 -m string --string "audio_mic_list" --algo bm --to 65535 -j DROP
iptables -A OUTPUT -p tcp --dport 80 -m string --string "sh" --algo bm --to 65535 -j DROP 
iptables -A OUTPUT -p tcp --dport 80 -m string --string "bash" --algo bm --to 65535 -j DROP
iptables -A OUTPUT -p tcp --dport 80 -m string --string "os" --algo bm --to 65535 -j DROP 
iptables -A OUTPUT -p tcp --dport 80 -m string --string "curl" --algo bm --to 65535 -j DROP
iptables -A OUTPUT -p tcp --dport 80 -m string --string "wget" --algo bm --to 65535 -j DROP