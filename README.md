Bad-Firewall
===============

This is a simple firewall shield stopping known bad IPs. 

## Prerequisites for Debian/Ubuntu based installations
The script will execute the following to get necessary packages installed:
```
apt-get -y update
apt-get install -y ipset iptables curl git wget
```

## Prerequisites for Red Hat/Centos based installations
The script will execute the following to get necessary packages installed:
```
yum -y update
yum -y install ipset iptables curl git wget
```

## Installation
```
git clone https://github.com/op7ic/Bad-Firewall.git
cd Bad-Firewall/ && chmod +x shieldme.sh
./shieldme.sh
```

## [shieldme.sh](shieldme.sh) filter rules

The following known IP ranges are currently blocked:

- [Alienvault IP Reputation](http://reputation.alienvault.com/reputation.data)
- [BBcan177 DNSBL](https://gist.githubusercontent.com/BBcan177/bf29d47ea04391cb3eb0/raw/01757cd346cd6080ce12cbc79c172cd3b585ab04/MS-1)
- [Blocklist.de Blocklist](https://lists.blocklist.de/lists/all.txt)
- [Blocklist.de export-all](https://www.blocklist.de/downloads/export-ips_all.txt)
- [CI Bad Guys](http://cinsscore.com/list/ci-badguys.txt)
- [Emerging Threats](https://rules.emergingthreats.net/blockrules/compromised-ips.txt)
- [Darklist](http://www.darklist.de/raw.php)
- [Dictionary SSH Attacks](http://charles.the-haleys.org/ssh_dico_attack_hdeny_format.php/hostsdeny.txt)
- [TOR IPs - dan.me.uk](https://www.dan.me.uk/torlist/)
- [TOR IPs - torproject.org](https://check.torproject.org/exit-addresses)
- [Feodo Tracker](https://feodotracker.abuse.ch/downloads/ipblocklist.txt)
- [GreenSnow Blacklist](http://blocklist.greensnow.co/greensnow.txt)
- [Talos IP Blacklist](http://www.talosintelligence.com/documents/ip-blacklist)
- [VoipBL](http://www.voipbl.org/update/)
- [Dshield](https://iplists.firehol.org/files/dshield.netset)
- [Threatview.IO Twitter Feed](https://threatview.io/Downloads/Experimental-IOC-Tweets.txt)
- [Threatview.IO C2 List](https://threatview.io/Downloads/High-Confidence-CobaltStrike-C2%20-Feeds.txt)
- [Bruteforce IPs](https://jamesbrine.com.au/csv)
- [URL abuse.ch IPs](https://urlhaus.abuse.ch/downloads/text/)


## CRON job

In order to auto-update the blocks, copy the following code into /etc/cron.d/update-badfirewall or add cron entry for specific user to run the script.  

```
0 0 * * 0      root /home/user/BadFirewall/shieldme.sh
```

## Check for dropped packets

Using iptables, you can check how many packets got dropped using the filters:
```
iptables -L INPUT -v --line-numbers # for IPv4
ip6tables -L INPUT -v --line-numbers # for IPv6
```

The table should look similar to this: 

```
Chain INPUT (policy ACCEPT 2111 packets, 126K bytes)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 DROP       all  --  any    any     anywhere             anywhere             match-set feodo src
2        0     0 DROP       all  --  any    any     anywhere             anywhere             match-set DNSBL src
3       12   668 DROP       all  --  any    any     anywhere             anywhere             match-set GreenSnow src
4       20  1200 DROP       all  --  any    any     anywhere             anywhere             match-set compromised_ips src
5        1    40 DROP       all  --  any    any     anywhere             anywhere             match-set darklist src
6       38  1631 DROP       all  --  any    any     anywhere             anywhere             match-set CI_BAD_GUYS src
7        0     0 DROP       all  --  any    any     anywhere             anywhere             match-set blocklist3 src
8        0     0 DROP       all  --  any    any     anywhere             anywhere             match-set blocklist2 src
9        4   240 DROP       all  --  any    any     anywhere             anywhere             match-set blocklist1 src
10       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set emergingthreats_compromised src
11       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set threatview_high_confidence_list src
12       1    40 DROP       all  --  any    any     anywhere             anywhere             match-set firehol src
13       2    88 DROP       all  --  any    any     anywhere             anywhere             match-set VoipBL src
14       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set Talos src
15       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set dshield src
16       1    40 DROP       all  --  any    any     anywhere             anywhere             match-set bruteforce-ips src
17       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set ssh src
18       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set alienvault src
19       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set tor-individual-ip2 src
20       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set tor-individual-ip1 src
21       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set abusechtracker2 src
22       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set abusechtracker1 src
23       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set threatview_twitterfeed src
24       0     0 DROP       all  --  any    any     anywhere             anywhere             match-set threatview_c2feed src
```

## Deleting full chain

If you would like to destory the set and all the associated rules, iptables needs to be cleared first, followed by deletion of ipset rules. 
```
# Clean iptables list for IPv4 or delete individual rulesets using -D option
iptables --flush

# Clean iptables list for Ipv6 or delete individual rulesets using -D option
ip6tables --flush

# Remove all sets from ipset
ipset list | grep Name | awk -F ": " '{print $2}' | xargs -i ipset destroy {}
```

## Modify the blacklists you want to use

Edit [shieldme.sh](shieldme.sh) and add/remove specific lists. You can see URLs which this script feeds from. Simply modify them or comment them out.
If you for some reason want to ban all IP addresses from a certain country, have a look at [IPverse.net's](http://ipverse.net/ipblocks/data/countries/) aggregated IP lists which you can simply add to the list already implemented. 
