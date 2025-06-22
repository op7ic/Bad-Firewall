#!/bin/bash
# This script should be deployed on the box you want to protect from various attacks
# Tested on Debian/Ubuntu/CentOS
# Author: Jerzy 'Yuri' Kramarz (op7ic) 
# Version: 1.6
# Homepage: https://github.com/op7ic/Bad-Firewall
echo ===== Detecting system IPs for automatic whitelisting =====
# Get all system IPs (IPv4 and IPv6)
SYSTEM_IPS=$(ip addr show | grep -oE 'inet6? [^ ]+' | awk '{print $2}' | cut -d/ -f1 | grep -v '^127\.' | grep -v '^::1' | grep -v '^fe80:')
echo [!] Found system IPs to whitelist:
echo "$SYSTEM_IPS" | sed 's/^/    /'

# Get external IP (in case behind NAT)
EXTERNAL_IP=$(curl -s -4 https://ifconfig.me 2>/dev/null || curl -s -4 https://api.ipify.org 2>/dev/null || echo "")
if [[ -n "$EXTERNAL_IP" ]]; then
   echo [!] External IPv4: $EXTERNAL_IP
   SYSTEM_IPS="$SYSTEM_IPS"$'\n'"$EXTERNAL_IP"
fi

echo ===== Updating box, downloading prerequisites and setting up base folder  =====
if VERB="$( which apt-get )" 1> /dev/null 2> /dev/null; then
   apt-get -y update 1> /dev/null 2> /dev/null
   apt-get install -y ipset iptables curl bzip2 wget 1> /dev/null 2> /dev/null
elif VERB="$( which yum )" 1> /dev/null 2> /dev/null; then
   yum -y update 1> /dev/null 2> /dev/null
   yum -y install ipset iptables curl bzip2 wget 1> /dev/null 2> /dev/null
fi
TEMP_FOLDER_DATE=`date +%d"-"%m"-"%Y`
OUTPUT_DIR="bad-firewall-${TEMP_FOLDER_DATE}"
echo [+] Creating Temp Directory $OUTPUT_DIR
mkdir $OUTPUT_DIR
cd $OUTPUT_DIR
declare -A array
# Updated and verified blocklists - June 2025
array["blocklist_de_all"]="https://lists.blocklist.de/lists/all.txt"
array["blocklist_de_ssh"]="https://lists.blocklist.de/lists/ssh.txt"
array["blocklist_de_mail"]="https://lists.blocklist.de/lists/mail.txt"
array["blocklist_de_apache"]="https://lists.blocklist.de/lists/apache.txt"
array["blocklist_de_bots"]="https://lists.blocklist.de/lists/bots.txt"
array["blocklist_de_bruteforce"]="https://lists.blocklist.de/lists/bruteforcelogin.txt"
array["emergingthreats_compromised"]="https://rules.emergingthreats.net/blockrules/compromised-ips.txt"
array["emergingthreats_blocks"]="https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt"
array["binarydefense"]="https://www.binarydefense.com/banlist.txt"
array["cinsscore"]="http://cinsscore.com/list/ci-badguys.txt"
array["greensnow"]="http://blocklist.greensnow.co/greensnow.txt"
array["feodotracker"]="https://feodotracker.abuse.ch/downloads/ipblocklist.txt"
array["firehol_level1"]="https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset"
array["firehol_level2"]="https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset"
array["firehol_level3"]="https://github.com/firehol/blocklist-ipsets/blob/master/firehol_level3.netset"
array["firehol_botscout"]="https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/botscout_7d.ipset"
array["firehol_darklist"]="https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/darklist_de.netset"
array["tor_exit_nodes"]="https://check.torproject.org/exit-addresses"
array["danme_tor"]="https://www.dan.me.uk/torlist/"
array["threatview_ioc_twitter"]="https://threatview.io/Downloads/Experimental-IOC-Tweets.txt"

echo ===== Downloading IP blocks =====
for i in "${!array[@]}"
  do
  echo "[+] Downloading IPs for $i blocklist from '${array[$i]}'"
  outputvar=$(curl -s -L -A "Mozilla/5.0" --connect-timeout 30 --max-time 60 ${array[$i]} || wget -qO- --user-agent="Mozilla/5.0" --timeout=30 ${array[$i]} || echo "")
  # Extract IPv4 addresses to individual files
  echo "$outputvar" | \
    grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?\b' | \
    grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?$' | \
    grep -v '^127\.' | grep -v '^0\.' | \
    grep -v '^10\.' | grep -v '^172\.(1[6-9]|2[0-9]|3[0-1])\.' | grep -v '^192\.168\.' | \
    sort -u > ${i}_ipv4.txt
  # Extract IPv6 addresses to individual files
  echo "$outputvar" | \
    grep -oEi '(([0-9a-f]{0,4}:){1,7}[0-9a-f]{0,4}|::|([0-9a-f]{0,4}:){1,6}:|:([0-9a-f]{0,4}:){1,6}[0-9a-f]{0,4})(/[0-9]{1,3})?' | \
    grep -vE '^(::1|fe80:|::)' | \
    sort -u > ${i}_ipv6.txt
done

echo ===== Removing duplicates across blocklists =====
# Create tracking files for already seen IPs
> seen_ipv4.txt
> seen_ipv6.txt

# Process each blocklist in order, removing IPs that have been seen before
total_dups_v4=0
total_dups_v6=0
for i in "${!array[@]}"
do
   # Process IPv4
   if [[ -s ${i}_ipv4.txt ]]; then
      # Count original
      original_count=$(wc -l < ${i}_ipv4.txt)
      # Remove IPs we've already seen
      grep -vxFf seen_ipv4.txt ${i}_ipv4.txt > ${i}_ipv4_dedup.txt 2>/dev/null || cp ${i}_ipv4.txt ${i}_ipv4_dedup.txt
      # Count after dedup
      dedup_count=$(wc -l < ${i}_ipv4_dedup.txt)
      dups=$((original_count - dedup_count))
      total_dups_v4=$((total_dups_v4 + dups))
      if [[ $dups -gt 0 ]]; then
         echo "[+] Removed $dups IPv4 duplicates from $i"
      fi
      # Add these IPs to seen list
      cat ${i}_ipv4_dedup.txt >> seen_ipv4.txt
      # Replace original with deduplicated
      mv ${i}_ipv4_dedup.txt ${i}_ipv4.txt
   fi
   
   # Process IPv6
   if [[ -s ${i}_ipv6.txt ]]; then
      # Count original
      original_count=$(wc -l < ${i}_ipv6.txt)
      # Remove IPs we've already seen
      grep -vxFf seen_ipv6.txt ${i}_ipv6.txt > ${i}_ipv6_dedup.txt 2>/dev/null || cp ${i}_ipv6.txt ${i}_ipv6_dedup.txt
      # Count after dedup
      dedup_count=$(wc -l < ${i}_ipv6_dedup.txt)
      dups=$((original_count - dedup_count))
      total_dups_v6=$((total_dups_v6 + dups))
      if [[ $dups -gt 0 ]]; then
         echo "[+] Removed $dups IPv6 duplicates from $i"
      fi
      # Add these IPs to seen list
      cat ${i}_ipv6_dedup.txt >> seen_ipv6.txt
      # Replace original with deduplicated
      mv ${i}_ipv6_dedup.txt ${i}_ipv6.txt
   fi
done

echo "[+] Total duplicates removed: $total_dups_v4 IPv4, $total_dups_v6 IPv6"

# Remove system IPs from all blocklists
echo ===== Removing system IPs from all blocklists =====
FOUND_IN_BLOCKLIST=0
for ip in $SYSTEM_IPS; do
   if [[ -n "$ip" ]]; then
      for list in *_ipv4.txt *_ipv6.txt; do
         if [[ -f "$list" ]] && grep -q "^$ip\$" "$list" 2>/dev/null; then
            echo "[!] WARNING: Your IP $ip was found in $list"
            FOUND_IN_BLOCKLIST=1
            grep -v "^$ip\$" "$list" > "${list}.tmp" && mv "${list}.tmp" "$list"
         fi
      done
   fi
done

if [[ $FOUND_IN_BLOCKLIST -eq 1 ]]; then
   echo "[!] Your IPs have been removed from blocklists and will be whitelisted"
fi

echo ===== Setting up IP blocks =====
# Create whitelist first and add system IPs
echo "[+] Creating whitelist ipsets and adding system IPs"
ipset create whitelist hash:net 2> /dev/null || ipset flush whitelist 2> /dev/null
ipset create whitelist_v6 hash:net family inet6 2> /dev/null || ipset flush whitelist_v6 2> /dev/null

# Add system IPs to whitelist
while IFS= read -r ip; do
   if [[ -n "$ip" ]]; then
      if echo "$ip" | grep -q ':'; then
         # IPv6
         ipset -exist add whitelist_v6 $ip 2>/dev/null && echo "[+] Whitelisted IPv6: $ip"
      else
         # IPv4
         ipset -exist add whitelist $ip 2>/dev/null && echo "[+] Whitelisted IPv4: $ip"
      fi
   fi
done <<< "$SYSTEM_IPS"

# Add whitelist rules (MUST be before DROP rules)
iptables -C INPUT -m set --match-set whitelist src -j ACCEPT 2>/dev/null || iptables -I INPUT -m set --match-set whitelist src -j ACCEPT
ip6tables -C INPUT -m set --match-set whitelist_v6 src -j ACCEPT 2>/dev/null || ip6tables -I INPUT -m set --match-set whitelist_v6 src -j ACCEPT

# Create individual ipsets for each blocklist
echo "[+] Creating individual ipsets for each blocklist..."
ipset_count=0
for i in "${!array[@]}"
do
   # IPv4 ipset
   if [[ -s ${i}_ipv4.txt ]]; then
      count=$(wc -l < ${i}_ipv4.txt)
      echo "[+] Creating IPv4 ipset '$i' with $count IPs"
      ipset create $i hash:net hashsize 16384 maxelem 262144 2> /dev/null || ipset flush $i 2> /dev/null
      while read line; do ipset -exist add $i $line; done < ${i}_ipv4.txt 2>/dev/null
      iptables -C INPUT -m set --match-set $i src -j DROP 2>/dev/null || iptables -I INPUT -m set --match-set $i src -j DROP 2>/dev/null
      ((ipset_count++))
   fi
   rm -f ${i}_ipv4.txt
   
   # IPv6 ipset
   if [[ -s ${i}_ipv6.txt ]]; then
      count=$(wc -l < ${i}_ipv6.txt)
      echo "[+] Creating IPv6 ipset '${i}_v6' with $count IPs"
      ipset create ${i}_v6 hash:net family inet6 hashsize 16384 maxelem 262144 2> /dev/null || ipset flush ${i}_v6 2> /dev/null
      while read line; do ipset -exist add ${i}_v6 $line; done < ${i}_ipv6.txt 2>/dev/null
      ip6tables -C INPUT -m set --match-set ${i}_v6 src -j DROP 2>/dev/null || ip6tables -I INPUT -m set --match-set ${i}_v6 src -j DROP
      ((ipset_count++))
   fi
   rm -f ${i}_ipv6.txt
done

echo ===== Cleanup and exit =====
# Count IPs before deleting the files
IPV4_COUNT=$(wc -l < seen_ipv4.txt 2>/dev/null || echo 0)
IPV6_COUNT=$(wc -l < seen_ipv6.txt 2>/dev/null || echo 0)

echo [+] Full list of blocked ranges is in $(pwd)/blockedranges.txt
ipset list > blockedranges.txt
echo [+] Saving full firewall block list to /etc/ipset.conf
ipset save > /etc/ipset.conf
echo [!] Created ipsets summary:
echo "    Whitelist ipsets: 2 (whitelist, whitelist_v6)"
echo "    Blocklist ipsets: $ipset_count"
echo "    Total unique IPv4 IPs: $IPV4_COUNT"
echo "    Total unique IPv6 IPs: $IPV6_COUNT"

# Clean up temporary files
rm -f seen_ipv4.txt seen_ipv6.txt *_ipv4.txt *_ipv6.txt
echo "[+] All temp files have been processed and removed"

echo "[!] To check which blocklist is blocking an IP, use: ipset test <blocklist_name> <IP_ADDRESS>"
echo "[!] To list all IPs in a specific blocklist: ipset list <blocklist_name>"
echo "[!] To add more IPs to whitelist: ipset add whitelist YOUR_IP"
echo "[!] Please remove $(pwd) folder if no longer needed"