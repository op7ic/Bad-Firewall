#!/bin/bash
# This script should be deployed the box you want to protect from various attacks
# Tested on Debian/Centos
# author: op7ic

# do installation based on which package manager is available.
if VERB="$( which apt-get )" 2> /dev/null; then
   apt-get -y update
   apt-get install -y ipset iptables curl fontconfig libfontconfig
elif VERB="$( which yum )" 2> /dev/null; then
   yum -y update
   yum -y install ipset iptables curl fontconfig libfontconfig bzip2
fi



declare -A array
array["badips"]="https://www.badips.com/get/list/any/2"
array["DNSBL"]="https://gist.githubusercontent.com/BBcan177/bf29d47ea04391cb3eb0/raw/01757cd346cd6080ce12cbc79c172cd3b585ab04/MS-1"
array["blocklist1"]="https://lists.blocklist.de/lists/all.txt"
array["blocklist2"]="https://www.blocklist.de/downloads/export-ips_all.txt"
array["Botvrij"]="http://www.botvrij.eu/data/ioclist.ip-dst.raw"
array["Bruteforceblocker"]="http://danger.rulez.sk/projects/bruteforceblocker/blist.php"
array["C2"]="http://osint.bambenekconsulting.com/feeds/c2-ipmasterlist.txt"
array["CI_BAD_GUYS"]="http://cinsscore.com/list/ci-badguys.txt"
array["coinblocker"]="https://zerodot1.gitlab.io/CoinBlockerLists/MiningServerIPList.txt"
array["compromised-ips"]="https://rules.emergingthreats.net/blockrules/compromised-ips.txt"
array["feodo"]="https://feodotracker.abuse.ch/blocklist/?download=ipblocklist"
array["darklist"]="http://www.darklist.de/raw.php"
array[""]=""
array[""]=""
array[""]=""
array[""]=""
array[""]=""
array[""]=""
array[""]=""
array[""]=""
array[""]=""
array[""]=""
array[""]=""
array[""]=""
array[""]=""
array[""]=""
array[""]=""
array[""]=""
array[""]=""

echo [+] downloading IPs for current dyre_sslipblacklist attacks from https://sslbl.abuse.ch/blacklist/dyre_sslipblacklist_aggressive.csv
curl https://sslbl.abuse.ch/blacklist/dyre_sslipblacklist_aggressive.csv | awk -F "," '{print $1}' | grep -v "\#" > agressive.txt

echo [+] downloading IPs for current ssh dict attacks from  http://charles.the-haleys.org/ssh_dico_attack_hdeny_format.php/hostsdeny.txt
curl http://charles.the-haleys.org/ssh_dico_attack_hdeny_format.php/hostsdeny.txt | awk -F ": " '{print $2}'  | sort | uniq > ssh.txt

echo [+] downloading IPs for current alienvault addresses from http://reputation.alienvault.com/reputation.data
curl http://reputation.alienvault.com/reputation.data | awk -F "#" '{print $1}' | sort | uniq > alienvault.txt

echo [+] downloading IPs for current tor exit node addresses from https://check.torproject.org/exit-addresses
curl https://check.torproject.org/exit-addresses | grep ExitAddress | awk '{print $2}' | sort | uniq > tor_current_nodes.txt

echo [+] downloading IPs for tor exit node addresses from https://www.dan.me.uk/torlist/
curl https://www.dan.me.uk/torlist/ | sort | uniq > tor_current_nodes_torlist.txt

echo [+] setting up to list blocks

ipset create tor-individual-ip1 hash:ip
while read line; do ipset add tor-individual-ip1 $line; done < tor_current_nodes.txt
iptables -I INPUT -m set --match-set tor-individual-ip1 src -j DROP

ipset create tor-individual-ip2 hash:ip
while read line; do ipset add tor-individual-ip2 $line; done < tor_current_nodes_torlist.txt
iptables -I INPUT -m set --match-set tor-individual-ip2 src -j DROP

ipset create alienvault hash:ip
while read line; do ipset add alienvault $line; done < alienvault.txt
iptables -I INPUT -m set --match-set alienvault src -j DROP

ipset create ssh hash:ip
while read line; do ipset add ssh $line; done < ssh.txt
iptables -I INPUT -m set --match-set ssh src -j DROP

ipset create agressive hash:ip
while read line; do ipset add agressive $line; done < agressive.txt
iptables -I INPUT -m set --match-set agressive src -j DROP



echo [+] removing block lists
rm -f tor_current_nodes.txt
rm -f tor_current_nodes_torlist.txt
rm -f alienvault.txt
rm -f ssh.txt
rm -f agressive.txt


echo [+] saving full output
ipset save > /etc/ipset.conf

echo [+] Full list of blocked ranges is in blockedranges.txt
ipset list > blockedranges.txt

#No this script is not smart ... you could do loops but hey ho