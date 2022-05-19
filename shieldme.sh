#!/bin/bash
# This script should be deployed the box you want to protect from various attacks
# Tested on Debian/Centos
# Author: Jerzy 'Yuri' Kramarz (op7ic) 
# Version: 1.1
# Homepage: https://github.com/op7ic/Bad-Firewall
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
array["DNSBL"]="https://gist.githubusercontent.com/BBcan177/bf29d47ea04391cb3eb0/raw/01757cd346cd6080ce12cbc79c172cd3b585ab04/MS-1"
array["blocklist1"]="https://lists.blocklist.de/lists/all.txt"
array["blocklist2"]="https://www.blocklist.de/downloads/export-ips_all.txt"
array["bruteforcelogin"]="https://lists.blocklist.de/lists/bruteforcelogin.txt"
array["CI_BAD_GUYS"]="http://cinsscore.com/list/ci-badguys.txt"
array["compromised_ips"]="https://rules.emergingthreats.net/blockrules/compromised-ips.txt"
array["darklist"]="http://www.darklist.de/raw.php"
array["GreenSnow"]="http://blocklist.greensnow.co/greensnow.txt"
array["VoipBL"]="http://www.voipbl.org/update/"
array["firehol"]="https://iplists.firehol.org/files/firehol_level1.netset"
array["emergingthreats_compromised"]="https://rules.emergingthreats.net/blockrules/compromised-ips.txt"
array["threatview_high_confidence_list"]="https://threatview.io/Downloads/IP-High-Confidence-Feed.txt"
array["emergingthreats_blocks"]="https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt"
array["binarydefense"]="https://www.binarydefense.com/banlist.txt"
array["firehol"]="https://iplists.firehol.org/files/dshield.netset"
array["sshblocklist"]="http://charles.the-haleys.org/ssh_dico_attack_hdeny_format.php/hostsdeny.txt"
array["alienvault"]="http://reputation.alienvault.com/reputation.data"
array["tor-exit1"]="https://check.torproject.org/exit-addresses"
array["tor-exit2"]="https://www.dan.me.uk/torlist/"
array["Talos"]="http://www.talosintelligence.com/documents/ip-blacklist"
array["bruteforce-hosts"]="https://jamesbrine.com.au/csv"
array["feodotracker"]="https://feodotracker.abuse.ch/downloads/ipblocklist.txt"
array["twitter-threatview"]="https://threatview.io/Downloads/Experimental-IOC-Tweets.txt"
array["c2-threatview"]="https://threatview.io/Downloads/High-Confidence-CobaltStrike-C2%20-Feeds.txt"
array["cybercrime-tracker"]="https://cybercrime-tracker.net/all.php"
array["sans-attack"]="https://isc.sans.edu/api/sources/attacks/"
array["honeypot"]="https://www.projecthoneypot.org/list_of_ips.php?rss=1"
echo ===== Downloading IP blocks =====
for i in "${!array[@]}"
  do
  echo [+] Downloading IPs for current $i blocklist from "${array[$i]}". Extracting both IPv4 and IPv6
  outputvar=$(curl -s -L -A "Firefox" ${array[$i]})
  echo $outputvar | grep -o -E '([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?' | grep -v "127\.0\.0\.1" | sort | uniq > $i.txt 2> /dev/null
  echo $outputvar | grep -o -P '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))'  | sort | uniq >> ipv6.txt 2> /dev/null
done
echo ===== Setting up to IP blocks =====
echo [+] Setting up blocks for IPv6 IPs in all block lists
ipset -exist create ipv6 hash:net family inet6 hashsize 32768 maxelem 9999999 2> /dev/null | ipset flush ipv6 2> /dev/null
while read line; do ipset -exist add ipv6 $line; done < ipv6.txt 2>/dev/null
iptables -C INPUT -m set --match-set ipv6 src -j DROP 2>/dev/null || ip6tables -I INPUT -m set --match-set ipv6 src -j DROP
for z in "${!array[@]}"
  do
   echo [+] Setting up blocks for $z from "${array[$z]}"
   ipset create $z hash:net hashsize 32768 maxelem 999999999 2> /dev/null || ipset flush $z 2> /dev/null
   while read line; do ipset -exist add $z $line; done < $z.txt 2>/dev/null
   iptables -C INPUT -m set --match-set $z src -j DROP 2>/dev/null || iptables -I INPUT -m set --match-set $z src -j DROP 2>/dev/null
   rm -f $z.txt
done
echo ===== Cleanup and exit =====
echo [+] Removing temp block lists stored locally
rm -f *.txt
echo [+] Full list of blocked ranges is in $OUTPUT_DIR/blockedranges.txt
ipset list > $OUTPUT_DIR/blockedranges.txt
echo [+] Saving full firewall block list to /etc/ipset.conf
ipset save > /etc/ipset.conf
echo [!] Please remove $OUTPUT_DIR folder if no longer needed