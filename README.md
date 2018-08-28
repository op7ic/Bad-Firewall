Bad-Firewall
===============

Protecting your infrastructure with firewall shield stopping known Bad IPs. 

## Prerequisites for Debian/Ubuntu based installations
The script will execute the following to get necessary packages installed:
```
apt-get -y update
apt-get install -y ipset iptables curl fontconfig libfontconfig
```

## Prerequisites for Red Hat/Centos based installations
The script will execute the following to get necessary packages installed:
```
yum -y update
yum -y install ipset iptables curl fontconfig libfontconfig bzip2
```

## Installation
```
git clone https://github.com/op7ic/Bad-Firewall.git
chmod +x shieldme.sh
./shieldme.sh
```

## [shieldme.sh](shieldme.sh) filter rules

The following known IP ranges are currently blocked:

- [Alienvault IP Reputation](http://reputation.alienvault.com/reputation.data)
- [Bad IPs](https://www.badips.com/get/list/any/2)
- [BBcan177 DNSBL](https://gist.githubusercontent.com/BBcan177/bf29d47ea04391cb3eb0/raw/01757cd346cd6080ce12cbc79c172cd3b585ab04/MS-1)
- [Blocklist.de Blocklist](https://lists.blocklist.de/lists/all.txt)
- [Blocklist.de explort-all](https://www.blocklist.de/downloads/export-ips_all.txt)
- [Botvrij.eu - ips](http://www.botvrij.eu/data/ioclist.ip-dst.raw)
- [Brute Force Blocker](http://danger.rulez.sk/projects/bruteforceblocker/blist.php)
- [C&C IPs](http://osint.bambenekconsulting.com/feeds/c2-ipmasterlist.txt)
- [CI Bad Guys](http://cinsscore.com/list/ci-badguys.txt)
- [CoinBlocker IPs](https://zerodot1.gitlab.io/CoinBlockerLists/MiningServerIPList.txt)
- [Compromised IPs](https://rules.emergingthreats.net/blockrules/compromised-ips.txt)
- [Cridex IPs](https://feodotracker.abuse.ch/blocklist/?download=ipblocklist)
- [Darklist](http://www.darklist.de/raw.php)
- [Dictionary SSH Attacks](http://charles.the-haleys.org/ssh_dico_attack_hdeny_format.php/hostsdeny.txt)
- [Dyre Botnet IPs](https://sslbl.abuse.ch/blacklist/dyre_sslipblacklist_aggressive.csv)
- [malwaredomainlist.com](http://www.malwaredomainlist.com/mdl.php?search=&colsearch=All&quantity=All)
- [TOR IPs - dan.me.uk](https://www.dan.me.uk/torlist/)
- [TOR IPs - torproject.org](https://check.torproject.org/exit-addresses)
- [Feodo Tracker](https://feodotracker.abuse.ch/blocklist/?download=ipblocklist)
- [Ransomware IP Blocklist](https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt)
- [Zeus IP Blocklist](https://zeustracker.abuse.ch/blocklist.php?download=ipblocklist)
- [GreenSnow Blacklist](http://blocklist.greensnow.co/greensnow.txt)
- [IPSpamList](http://www.ipspamlist.com/public_feeds.csv)
- [Malicious EXE IPs](http://www.urlvir.com/export-ip-addresses/)
- [Talos IP Blacklist](http://www.talosintelligence.com/documents/ip-blacklist)
- [VoipBL](http://www.voipbl.org/update/)
- [Dshield](https://iplists.firehol.org/files/dshield.netset)
- [FireHol](https://iplists.firehol.org/files/firehol_level1.netset)

## CRON job

In order to auto-update the blocks, copy the following code into /etc/cron.d/update-badfirewall. Once a week should be sufficient but feel free to change this. 
```
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root
0 0 * * 0      root /tmp/Bad-Firewall/shieldme.sh
```

## Check for dropped packets
Using iptables, you can check how many packets got dropped using the filters:
```
iptables -L INPUT -v --line-numbers # for IPv4
ip6tables -L INPUT -v --line-numbers # for IPv6
```

The table should look similar to this: 

```
Chain INPUT (policy ACCEPT 1548 packets, 70960 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1        2    80 DROP       all  --  any    any     anywhere             anywhere             match-set firehol src
2        0     0 DROP       all  --  any    any     anywhere             anywhere             match-set feodo src
3        6   516 DROP       all  --  any    any     anywhere             anywhere             match-set blocklist2 src
4        8   488 DROP       all  --  any    any     anywhere             anywhere             match-set blocklist1 src
5        0     0 DROP       all  --  any    any     anywhere             anywhere             match-set darklist src
6        0     0 DROP       all  --  any    any     anywhere             anywhere             match-set coinblocker src
7        4   572 DROP       all  --  any    any     anywhere             anywhere             match-set CI_BAD_GUYS src
8        0     0 DROP       all  --  any    any     anywhere             anywhere             match-set compromised_ips src
9        0     0 DROP       all  --  any    any     anywhere             anywhere             match-set VoipBL src
10       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set Botvrij src
11       9  1028 DROP       all  --  any    any     anywhere             anywhere             match-set badips src
12      17  2255 DROP       all  --  any    any     anywhere             anywhere             match-set GreenSnow src
13       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set Zeus src
14       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set DNSBL src
15       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set urlvir src
16       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set Ransomware_IP src
17       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set Bruteforceblocker src
18       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set C2 src
19       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set Talos src
20       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set dshield src
21       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set IPSpamList src
22       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set malwarelist src
23       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set agressive src
24       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set ssh src
25       5   204 DROP       all  --  any    any     anywhere             anywhere             match-set alienvault src
26       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set tor-individual-ip2 src
27       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set tor-individual-ip1 src
```

## Modify the blacklists you want to use

Edit [shieldme.sh](shieldme.sh) and add/remove specific lists. You can see URLs which this script feeds from. Simply modify them or comment them out.
If you for some reason want to ban all IP addresses from a certain country, have a look at [IPverse.net's](http://ipverse.net/ipblocks/data/countries/) aggregated IP lists which you can simply add to the list already implemented. 
