#!/bin/bash
# This script should be deployed the box you want to protect from various attacks
# Tested on Debian/Centos
# author: op7ic

# do installation based on which package manager is available.
if VERB="$( which apt-get )" 2> /dev/null; then
   apt-get -y update
   apt-get install -y ipset iptables curl 
elif VERB="$( which yum )" 2> /dev/null; then
   yum -y update
   yum -y install ipset iptables curl bzip2
fi

echo [+] creating temp directory

mkdir /tmp/fw-update
cd /tmp/fw-update

declare -A array
array["badips"]="https://www.badips.com/get/list/any/2"
array["DNSBL"]="https://gist.githubusercontent.com/BBcan177/bf29d47ea04391cb3eb0/raw/01757cd346cd6080ce12cbc79c172cd3b585ab04/MS-1"
array["blocklist1"]="https://lists.blocklist.de/lists/all.txt"
array["blocklist2"]="https://www.blocklist.de/downloads/export-ips_all.txt"
array["Botvrij"]="http://www.botvrij.eu/data/ioclist.ip-dst.raw"
array["Bruteforceblocker"]="http://danger.rulez.sk/projects/bruteforceblocker/blist.php"
array["CI_BAD_GUYS"]="http://cinsscore.com/list/ci-badguys.txt"
array["coinblocker"]="https://zerodot1.gitlab.io/CoinBlockerLists/MiningServerIPList.txt"
array["compromised_ips"]="https://rules.emergingthreats.net/blockrules/compromised-ips.txt"
array["feodo"]="https://feodotracker.abuse.ch/blocklist/?download=ipblocklist"
array["darklist"]="http://www.darklist.de/raw.php"
array["Ransomware_IP"]="https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt"
array["Zeus"]="https://zeustracker.abuse.ch/blocklist.php?download=ipblocklist"
array["GreenSnow"]="http://blocklist.greensnow.co/greensnow.txt"
array["urlvir"]="http://www.urlvir.com/export-ip-addresses/"
array["VoipBL"]="http://www.voipbl.org/update/"
array["firehol"]="https://iplists.firehol.org/files/firehol_level1.netset"


 for i in "${!array[@]}"
  do
   echo [+] downloading blocks for $i addresses from "${array[$i]}"
   curl ${array[$i]} | grep -v "\#" | sort | uniq > $i.txt
  done

echo [+] downloading IPs for current C2 from http://osint.bambenekconsulting.com/feeds/c2-ipmasterlist.txt
curl http://osint.bambenekconsulting.com/feeds/c2-ipmasterlist.txt | awk -F "," '{print $1}' | sort | uniq > C2.txt

echo [+] downloading IPs for current dshield from https://iplists.firehol.org/files/dshield.netset
curl https://iplists.firehol.org/files/dshield.netset | grep -v "\#" | sort | uniq  > dshield.txt

echo [+] downloading IPs for current IPSpamList from http://www.ipspamlist.com/public_feeds.csv
curl http://www.ipspamlist.com/public_feeds.csv | awk -F "," '{print $3}' | sort | uniq > IPSpamList.txt

echo [+] downloading IPs for current malwaredomainlist attacks from http://www.malwaredomainlist.com/mdl.php?search=&colsearch=All&quantity=All
curl "http://www.malwaredomainlist.com/mdl.php?search=&colsearch=All&quantity=All" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sort | uniq > malwarelist.txt

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

echo [+] downloading IPs for tor exit node addresses from http://www.talosintelligence.com/documents/ip-blacklist
wget http://www.talosintelligence.com/documents/ip-blacklist -O ip-blacklist.txt && cat ip-blacklist | sort | uniq > Talos.txt

echo [+] extracting ipv6 addresses
cat *.txt | grep -Po '(?<![[:alnum:]]|[[:alnum:]]:)(?:(?:[a-f0-9]{1,4}:){7}[a-f0-9]{1,4}|(?:[a-f0-9]{1,4}:){1,6}:(?:[a-f0-9]{1,4}:){0,5}[a-f0-9]{1,4})(?![[:alnum:]]:?)' > ipv6.txt

echo [+] setting up to list blocks

ipset create tor-individual-ip1 hash:net hashsize 32768 maxelem 9999999
while read line; do ipset add tor-individual-ip1 $line; done < tor_current_nodes.txt
iptables -I INPUT -m set --match-set tor-individual-ip1 src -j DROP

ipset create tor-individual-ip2 hash:net hashsize 32768 maxelem 9999999
while read line; do ipset add tor-individual-ip2 $line; done < tor_current_nodes_torlist.txt
iptables -I INPUT -m set --match-set tor-individual-ip2 src -j DROP

ipset create alienvault hash:net hashsize 32768 maxelem 9999999
while read line; do ipset add alienvault $line; done < alienvault.txt
iptables -I INPUT -m set --match-set alienvault src -j DROP

ipset create ssh hash:net hashsize 32768 maxelem 9999999
while read line; do ipset add ssh $line; done < ssh.txt
iptables -I INPUT -m set --match-set ssh src -j DROP

ipset create agressive hash:net hashsize 32768 maxelem 16777216
while read line; do ipset add agressive $line; done < agressive.txt
iptables -I INPUT -m set --match-set agressive src -j DROP

ipset create malwarelist hash:net hashsize 32768 maxelem 16777216
while read line; do ipset add malwarelist $line; done < malwarelist.txt
iptables -I INPUT -m set --match-set malwarelist src -j DROP

ipset create IPSpamList hash:net hashsize 32768 maxelem 16777216
while read line; do ipset add IPSpamList $line; done < IPSpamList.txt
iptables -I INPUT -m set --match-set IPSpamList src -j DROP

ipset create dshield hash:net hashsize 32768 maxelem 16777216
while read line; do ipset add dshield $line; done < dshield.txt
iptables -I INPUT -m set --match-set dshield src -j DROP

ipset create Talos hash:net hashsize 32768 maxelem 16777216
while read line; do ipset add Talos $line; done < Talos.txt
iptables -I INPUT -m set --match-set Talos src -j DROP

ipset create C2 hash:net hashsize 32768 maxelem 16777216
while read line; do ipset add C2 $line; done < C2.txt
iptables -I INPUT -m set --match-set C2 src -j DROP

ipset create ipv6 hash:net family inet6 hashsize 32768 maxelem 16777216
while read line; do ipset add ipv6 $line; done < ipv6.txt
ip6tables -I INPUT -m set --match-set ipv6 src -j DROP

for z in "${!array[@]}"
  do
   echo [+] setting up blocks for $z from "${array[$z]}"
   ipset create $z hash:net hashsize 32768 maxelem 999999999
   while read line; do ipset add $z $line; done < $z.txt
   iptables -I INPUT -m set --match-set $z src -j DROP
   rm -f $z.txt
done

echo [+] removing block lists
rm -f *.txt

echo [+] saving full output
ipset save > /etc/ipset.conf

echo [+] Full list of blocked ranges is in blockedranges.txt
ipset list > blockedranges.txt

#No this script is not smart ... you could do loops but hey ho