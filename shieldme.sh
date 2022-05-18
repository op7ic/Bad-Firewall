#!/bin/bash
# This script should be deployed the box you want to protect from various attacks
# Tested on Debian/Centos
# Author: Jerzy 'Yuri' Kramarz (op7ic) 

echo ===== Updating box and downloading prerequisites =====
if VERB="$( which apt-get )" 2> /dev/null; then
   apt-get -y update 1> /dev/null 2> /dev/null
   apt-get install -y ipset iptables curl bzip2 wget 1> /dev/null 2> /dev/null
elif VERB="$( which yum )" 2> /dev/null; then
   yum -y update 1> /dev/null 2> /dev/null
   yum -y install ipset iptables curl bzip2 wget 1> /dev/null 2> /dev/null
fi

echo [+] Creating Temp Directory
mkdir /tmp/fw-update
cd /tmp/fw-update

declare -A array
array["DNSBL"]="https://gist.githubusercontent.com/BBcan177/bf29d47ea04391cb3eb0/raw/01757cd346cd6080ce12cbc79c172cd3b585ab04/MS-1"
array["blocklist1"]="https://lists.blocklist.de/lists/all.txt"
array["blocklist2"]="https://www.blocklist.de/downloads/export-ips_all.txt"
array["blocklist3"]="https://lists.blocklist.de/lists/bruteforcelogin.txt"
array["CI_BAD_GUYS"]="http://cinsscore.com/list/ci-badguys.txt"
array["compromised_ips"]="https://rules.emergingthreats.net/blockrules/compromised-ips.txt"
array["feodo"]="https://feodotracker.abuse.ch/blocklist/?download=ipblocklist"
array["darklist"]="http://www.darklist.de/raw.php"
array["GreenSnow"]="http://blocklist.greensnow.co/greensnow.txt"
array["VoipBL"]="http://www.voipbl.org/update/"
array["firehol"]="https://iplists.firehol.org/files/firehol_level1.netset"
array["emergingthreats_compromised"]="https://rules.emergingthreats.net/blockrules/compromised-ips.txt"
array["threatview_high_confidence_list"]="https://threatview.io/Downloads/IP-High-Confidence-Feed.txt"

echo ===== Downloading IP blocks =====

for i in "${!array[@]}"
  do
  echo [+] Downloading IPs for current $i blocklist from "${array[$i]}"
  curl -s -A "Firefox" ${array[$i]} | grep -v "\#" | sort | uniq > $i.txt 2> /dev/null
done

echo [+] Downloading IPs for current dshield blocklist from https://iplists.firehol.org/files/dshield.netset
curl -s -A "Firefox" https://iplists.firehol.org/files/dshield.netset | grep -v "\#" | sort | uniq  > dshield.txt 2> /dev/null

echo [+] Downloading IPs for current ssh dict attacks blocklist from http://charles.the-haleys.org/ssh_dico_attack_hdeny_format.php/hostsdeny.txt
curl -s -A "Firefox" http://charles.the-haleys.org/ssh_dico_attack_hdeny_format.php/hostsdeny.txt | awk -F ": " '{print $2}'  | sort | uniq > ssh.txt 2> /dev/null

echo [+] Downloading IPs for current alienvault blocklist from http://reputation.alienvault.com/reputation.data
curl -s -A "Firefox" http://reputation.alienvault.com/reputation.data | awk -F "#" '{print $1}' | sort | uniq > alienvault.txt 2> /dev/null

echo [+] Downloading IPs for current tor exit nodes blocklist from https://check.torproject.org/exit-addresses
curl -s -A "Firefox" https://check.torproject.org/exit-addresses | grep ExitAddress | awk '{print $2}' | sort | uniq > tor_current_nodes.txt 2> /dev/null

echo [+] Downloading IPs for current tor exit nodes blocklist from https://www.dan.me.uk/torlist/
curl -s -A "Firefox" https://www.dan.me.uk/torlist/ | sort | uniq > tor_current_nodes_torlist.txt 2> /dev/null

echo [+] Downloading IPs for current Talos blocklist from http://www.talosintelligence.com/documents/ip-blacklist
wget -q --user-agent "Firefox" http://www.talosintelligence.com/documents/ip-blacklist -O ip-blacklist.txt && cat ip-blacklist.txt | sort | uniq > Talos.txt 2> /dev/null

echo [+] Downloading IPs for current bruteforce hosts blocklist from https://jamesbrine.com.au/csv
curl -s -A "Firefox" https://jamesbrine.com.au/csv | awk -F "," '{print $1}' | sort | uniq | grep -v ipv4 > bruteforce-ips.txt 2> /dev/null

echo [+] Downloading IPs for current abuse.ch URLs and extra IPs blocklist from https://urlhaus.abuse.ch/downloads/text/
curl -s -A "Firefox" https://urlhaus.abuse.ch/downloads/text/ | grep -o -e "\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}" | sort | uniq > urlhausabuse-ips.txt 2> /dev/null

echo [+] Downloading IPs for current abuse.ch blocklist from https://feodotracker.abuse.ch/downloads/ipblocklist.txt
curl -s -A "Firefox" https://feodotracker.abuse.ch/downloads/ipblocklist.txt | grep -o -e "\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}" | sort | uniq > urlhausabuse-ips2.txt 2> /dev/null

echo [+] Downloading IPs for current threatview.io Twitter List blocklist from https://threatview.io/Downloads/Experimental-IOC-Tweets.txt
curl -s -A "Firefox" https://threatview.io/Downloads/Experimental-IOC-Tweets.txt | grep -o -e "\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}" | sort | uniq > threatview_twitterfeed_ips.txt 2> /dev/null

echo [+] Downloading IPs for current threatview.io C2 List blocklist from https://threatview.io/Downloads/High-Confidence-CobaltStrike-C2%20-Feeds.txt
curl -s -A "Firefox" https://threatview.io/Downloads/High-Confidence-CobaltStrike-C2%20-Feeds.txt | grep -o -e "\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}" | grep -v "127\.0\.0\.1" | sort | uniq > threatview_c2feed_ips.txt 2> /dev/null

echo [+] Extracting IPv6 addresses
cat *.txt | grep -Po '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))' > ipv6.txt

echo ===== Setting up to IP blocks =====

echo [+] Setting up blocks for threatview_c2feed from https://threatview.io/Downloads/High-Confidence-CobaltStrike-C2%20-Feeds.txt
ipset create threatview_c2feed hash:net hashsize 32768 maxelem 9999999 2>/dev/null || ipset flush threatview_c2feed 2> /dev/null
while read line; do ipset -exist add threatview_c2feed $line; done < threatview_c2feed_ips.txt 2>/dev/null
iptables -C INPUT -m set --match-set threatview_c2feed src -j DROP 2>/dev/null || iptables -I INPUT -m set --match-set threatview_c2feed src -j DROP

echo [+] Setting up blocks for threatview_twitterfeed from https://threatview.io/Downloads/Experimental-IOC-Tweets.txt
ipset create threatview_twitterfeed hash:net hashsize 32768 maxelem 9999999 2>/dev/null || ipset flush threatview_twitterfeed 2> /dev/null
while read line; do ipset -exist add threatview_twitterfeed $line; done < threatview_twitterfeed_ips.txt 2>/dev/null
iptables -C INPUT -m set --match-set threatview_twitterfeed src -j DROP 2>/dev/null || iptables -I INPUT -m set --match-set threatview_twitterfeed src -j DROP 

echo [+] Setting up blocks for abusechtracker1 from https://urlhaus.abuse.ch/downloads/text/
ipset create abusechtracker1 hash:net hashsize 32768 maxelem 9999999 2>/dev/null || ipset flush abusechtracker1 2> /dev/null
while read line; do ipset -exist add abusechtracker1 $line; done < urlhausabuse-ips.txt 2>/dev/null
iptables -C INPUT -m set --match-set abusechtracker1 src -j DROP 2>/dev/null || iptables -I INPUT -m set --match-set abusechtracker1 src -j DROP

echo [+] Setting up blocks for abusechtracker2 from https://feodotracker.abuse.ch/downloads/ipblocklist.txt
ipset create abusechtracker2 hash:net hashsize 32768 maxelem 9999999 2>/dev/null || ipset flush abusechtracker2 2> /dev/null
while read line; do ipset -exist add abusechtracker2 $line; done < urlhausabuse-ips2.txt 2>/dev/null
iptables -C INPUT -m set --match-set abusechtracker2 src -j DROP 2>/dev/null || iptables -I INPUT -m set --match-set abusechtracker2 src -j DROP

echo [+] Setting up blocks for tor-individual-ip1 from https://check.torproject.org/exit-addresses
ipset create tor-individual-ip1 hash:net hashsize 32768 maxelem 9999999 2>/dev/null || ipset flush tor-individual-ip1 2> /dev/null
while read line; do ipset -exist add tor-individual-ip1 $line; done < tor_current_nodes.txt 2>/dev/null
iptables -C INPUT -m set --match-set tor-individual-ip1 src -j DROP 2>/dev/null || iptables -I INPUT -m set --match-set tor-individual-ip1 src -j DROP

echo [+] Setting up blocks for tor-individual-ip2 from https://www.dan.me.uk/torlist/
ipset create tor-individual-ip2 hash:net hashsize 32768 maxelem 9999999 2>/dev/null || ipset flush tor-individual-ip2 2> /dev/null
while read line; do ipset -exist add tor-individual-ip2 $line; done < tor_current_nodes_torlist.txt 2>/dev/null
iptables -C INPUT -m set --match-set tor-individual-ip2 src -j DROP 2>/dev/null || iptables -I INPUT -m set --match-set tor-individual-ip2 src -j DROP

echo [+] Setting up blocks for alienvault from http://reputation.alienvault.com/reputation.data
ipset create alienvault hash:net hashsize 32768 maxelem 9999999 2>/dev/null || ipset flush alienvault 2> /dev/null
while read line; do ipset -exist add alienvault $line; done < alienvault.txt 2>/dev/null
iptables -C INPUT -m set --match-set alienvault src -j DROP 2>/dev/null || iptables -I INPUT -m set --match-set alienvault src -j DROP

echo [+] Setting up blocks for ssh from http://charles.the-haleys.org/ssh_dico_attack_hdeny_format.php/hostsdeny.txt
ipset create ssh hash:net hashsize 32768 maxelem 9999999 2> /dev/null || ipset flush ssh 2> /dev/null
while read line; do ipset -exist add ssh $line; done < ssh.txt 2>/dev/null
iptables -C INPUT -m set --match-set ssh src -j DROP 2>/dev/null || iptables -I INPUT -m set --match-set ssh src -j DROP

echo [+] Setting up blocks for bruteforce-ips from https://jamesbrine.com.au/csv
ipset create bruteforce-ips hash:net hashsize 32768 maxelem 9999999 2> /dev/null || ipset flush bruteforce-ips 2> /dev/null
while read line; do ipset -exist add bruteforce-ips $line; done < bruteforce-ips.txt 2>/dev/null
iptables -C INPUT -m set --match-set bruteforce-ips src -j DROP 2>/dev/null || iptables -I INPUT -m set --match-set bruteforce-ips src -j DROP

echo [+] Setting up blocks for dshield from https://iplists.firehol.org/files/dshield.netset
ipset create dshield hash:net hashsize 32768 maxelem 9999999 2> /dev/null || ipset flush dshield 2> /dev/null
while read line; do ipset add dshield $line; done < dshield.txt 2>/dev/null
iptables -C INPUT -m set --match-set dshield src -j DROP 2>/dev/null || iptables -I INPUT -m set --match-set dshield src -j DROP

echo [+] Setting up blocks for Talos from http://www.talosintelligence.com/documents/ip-blacklist
ipset create Talos hash:net hashsize 32768 maxelem 9999999 2> /dev/null || ipset flush Talos 2> /dev/null
while read line; do ipset -exist add Talos $line; done < Talos.txt 2>/dev/null
iptables -C INPUT -m set --match-set Talos src -j DROP 2>/dev/null || iptables -I INPUT -m set --match-set Talos src -j DROP

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

echo [+] Removing temp block lists stored locally
rm -f *.txt

echo [+] Saving full firewall block list to /etc/ipset.conf
ipset save > /etc/ipset.conf

echo [+] Full list of blocked ranges is in /tmp/fw-update/blockedranges.txt
ipset list > /tmp/fw-update/blockedranges.txt

echo [!] Please remove /tmp/fw-update folder if no longer needed