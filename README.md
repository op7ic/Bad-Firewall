# Bad-Firewall

A robust firewall shield that automatically blocks known malicious IP addresses using ipset and iptables. 

## Features

- **Automatic System IP Whitelisting**: Detects and whitelists all system IPs (including external IP) to prevent self-lockout
- **Individual Blocklist Tracking**: Creates separate ipsets for each blocklist provider to identify which list is blocking specific IPs
- **Smart Deduplication**: Removes duplicate IPs across blocklists while maintaining provider attribution
- **IPv4 and IPv6 Support**: Full dual-stack support with separate ipsets
- **Large-scale Protection**: Handles hundreds of thousands of malicious IPs efficiently
- **Cross-distribution Support**: Works on Debian/Ubuntu and RHEL/CentOS systems

## Prerequisites

### Debian/Ubuntu based systems
The script will automatically install required packages:
```bash
apt-get -y update
apt-get install -y ipset iptables curl bzip2 wget
```

### Red Hat/CentOS based systems
The script will automatically install required packages:
```bash
yum -y update
yum -y install ipset iptables curl bzip2 wget
```

## Installation

```bash
# Clone the repository
git clone https://github.com/op7ic/Bad-Firewall.git
cd Bad-Firewall/

# Make the script executable
chmod +x shieldme.sh

# Run the script (requires root/sudo)
sudo ./shieldme.sh
```

## Current Blocklist Sources

The script blocks IPs from the following reputation sources (as of v1.6):

### [Blocklist.de](https://www.blocklist.de/) Lists
- **[All Attacks](https://lists.blocklist.de/lists/all.txt)** - `blocklist_de_all`: Combined list of all attack types
- **[SSH Attacks](https://lists.blocklist.de/lists/ssh.txt)** - `blocklist_de_ssh`: SSH brute force attempts
- **[Mail Attacks](https://lists.blocklist.de/lists/mail.txt)** - `blocklist_de_mail`: Mail server attacks (SMTP, IMAP, POP3)
- **[Apache Attacks](https://lists.blocklist.de/lists/apache.txt)** - `blocklist_de_apache`: Web server attacks
- **[Bot Attacks](https://lists.blocklist.de/lists/bots.txt)** - `blocklist_de_bots`: Known bot networks
- **[Bruteforce Logins](https://lists.blocklist.de/lists/bruteforcelogin.txt)** - `blocklist_de_bruteforce`: General bruteforce attempts

### [Emerging Threats](https://rules.emergingthreats.net/)
- **[Compromised IPs](https://rules.emergingthreats.net/blockrules/compromised-ips.txt)** - `emergingthreats_compromised`: Known compromised hosts
- **[Block IPs](https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt)** - `emergingthreats_blocks`: General malicious IPs

### Threat Intelligence Feeds
- **[Binary Defense](https://www.binarydefense.com/banlist.txt)** - `binarydefense`: Community threat intelligence
- **[CI Army Bad Guys](http://cinsscore.com/list/ci-badguys.txt)** - `cinsscore`: Collective Intelligence Network Security
- **[GreenSnow](http://blocklist.greensnow.co/greensnow.txt)** - `greensnow`: Blacklisted IPs from honeypot systems
- **[Feodo Tracker](https://feodotracker.abuse.ch/downloads/ipblocklist.txt)** - `feodotracker`: Banking trojan C&C servers

### [FireHOL IP Lists](https://github.com/firehol/blocklist-ipsets)
- **[Level 1](https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset)** - `firehol_level1`: Most dangerous IPs (high confidence)
- **[Level 2](https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset)** - `firehol_level2`: Dangerous IPs (medium confidence)
- **[Level 3](https://github.com/firehol/blocklist-ipsets/blob/master/firehol_level3.netset)** - `firehol_level3`: Suspicious IPs (lower confidence)
- **[BotScout](https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/botscout_7d.ipset)** - `firehol_botscout`: Known bot IPs (7-day list)
- **[Darklist](https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/darklist_de.netset)** - `firehol_darklist`: German blocklist aggregation
- **[VXVault](https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/vxvault.ipset)** - `firehol_vxvault`: Malware distribution sites

### TOR Exit Nodes
- **[Official TOR List](https://check.torproject.org/exit-addresses)** - `tor_exit_nodes`: TOR project's exit node list
- **[Dan.me.uk TOR List](https://www.dan.me.uk/torlist/)** - `danme_tor`: Alternative TOR exit node list

### Other Sources
- **[ThreatView IOC Twitter](https://threatview.io/Downloads/Experimental-IOC-Tweets.txt)** - `threatview_ioc_twitter`: IPs from Twitter threat feeds

## Automatic Updates

### Option 1: Cron Job

Add to root's crontab or create `/etc/cron.d/bad-firewall`:

```bash
# Update blocklists every Sunday at midnight
0 0 * * 0 root /path/to/Bad-Firewall/shieldme.sh

# Or update daily at 3 AM
0 3 * * * root /path/to/Bad-Firewall/shieldme.sh
```

For user crontab (requires sudo privileges in script):
```bash
crontab -e
# Add:
0 0 * * 0 /home/user/Bad-Firewall/shieldme.sh
```

### Option 2: Systemd Service and Timer

Create service file `/etc/systemd/system/bad-firewall.service`:
```ini
[Unit]
Description=Bad-Firewall IP Blocklist Update
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/path/to/Bad-Firewall/shieldme.sh
StandardOutput=journal
StandardError=journal
# Restart on failure with 5 minute delay
Restart=on-failure
RestartSec=300

[Install]
WantedBy=multi-user.target
```

Create timer file `/etc/systemd/system/bad-firewall.timer`:
```ini
[Unit]
Description=Update Bad-Firewall blocklists weekly
Requires=bad-firewall.service

[Timer]
OnCalendar=daily
# Or use one of these alternatives:
# OnCalendar=*-*-* 02:00:00     # Daily at 2 AM
# OnCalendar=*-*-* 00,12:00:00  # Twice daily at midnight and noon
# OnUnitActiveSec=24h           # 24 hours after last run
# OnCalendar=weekly             # Once per week (Mondays at midnight)
# Run 5 minutes after boot if missed
OnBootSec=5min
# Persist timing information
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start the timer:
```bash
sudo systemctl daemon-reload
sudo systemctl enable bad-firewall.timer
sudo systemctl start bad-firewall.timer

# Check timer status
sudo systemctl status bad-firewall.timer
sudo systemctl list-timers --all
```

## Usage and Management

### Check blocked packets
```bash
# IPv4 statistics
sudo iptables -L INPUT -v -n --line-numbers

# IPv6 statistics  
sudo ip6tables -L INPUT -v -n --line-numbers
```

### Test if an IP is blocked
```bash
# Check which blocklist contains an IP
sudo ipset test blocklist_de_ssh 192.168.1.100
sudo ipset test firehol_level1 10.0.0.1
```

### List all IPs in a specific blocklist
```bash
sudo ipset list blocklist_de_ssh
sudo ipset list firehol_level1
```

### Add custom IPs to whitelist
```bash
# IPv4
sudo ipset add whitelist 192.168.1.100

# IPv6
sudo ipset add whitelist_v6 2001:db8::1
```

### View all ipsets
```bash
# List all ipset names
sudo ipset list -n

# Show summary with IP counts
sudo ipset list -t
```

### Persistence across reboots
The script saves configurations to `/etc/ipset.conf`. To ensure rules persist:

For systemd-based systems:
```bash
sudo systemctl enable ipset
```

For older systems, add to `/etc/rc.local`:
```bash
ipset restore < /etc/ipset.conf
```

## Troubleshooting

### Complete removal
To completely remove all firewall rules and ipsets:
```bash
# Clear IPv4 iptables rules
sudo iptables -F INPUT

# Clear IPv6 iptables rules  
sudo ip6tables -F INPUT

# Destroy all ipsets
sudo ipset list -n | xargs -I {} sudo ipset destroy {}
```

### Check logs
```bash
# View recent script runs (if using systemd)
sudo journalctl -u bad-firewall.service

# Check system logs
sudo tail -f /var/log/syslog  # Debian/Ubuntu
sudo tail -f /var/log/messages  # RHEL/CentOS
```

### Memory usage
Monitor ipset memory consumption:
```bash
sudo ipset list -t | grep "Memory size:"
```

## Modify the blacklists you want to use

Edit [shieldme.sh](shieldme.sh) and add/remove specific lists. You can see URLs which this script feeds from. Simply modify them or comment them out.
If you for some reason want to ban all IP addresses from a certain country, have a look at [IPverse.net's](http://ipverse.net/ipblocks/data/countries/) aggregated IP lists which you can simply add to the list already implemented. 


## Important Notes

1. **First Run**: The initial run may take 5-10 minutes depending on your internet connection
2. **Whitelisting**: Always ensure your management IPs are whitelisted before running
3. **TOR Blocking**: Consider implications before blocking TOR exit nodes
4. **False Positives**: Some legitimate services may be blocked - check logs if issues arise
5. **Resource Usage**: Large blocklists can consume significant memory (typically 100-500MB)

## Contributing

Feel free to submit issues, feature requests, and pull requests on the [GitHub repository](https://github.com/op7ic/Bad-Firewall).

## License

See LICENSE file

## Disclaimer

THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


