# under-the-mat

[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit) [![made-with-bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)

Many services (not all) can be configured with random TCP or UDP ports. But which ports are **safer** than others? This simple script selects *safer* TCP or UDP ports. A *safer* port is defined as:

1. Port number 1024 or higher:  ports from 0 to 1023 are privileged ports and a service needs root permissions to bind to privileged ports. This is insecure, a bug in your service might expose the whole server.

2. Not listed in the [IANA port and services list](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml): many vulnerability scanners such as [OpenVas](https://openvas.org/) can be configured to scan all ports listed in IANA. Hence we avoid those ports.

3. Not part of the [Nmap](https://nmap.org/) top 1000 ports. Nmap is a powerfull port scanner. Without additional options, it will scan the top 1000 most common ports. We avoid those ports.

## Profit

What is gained by using the *safer* ports instead of port numbers found in "Howto" documents or your imagination? Plain and simple:

- Wannabe hackers (script kiddies) will not detect your service, since the commonly used hacking tools (in their standard configuration) do not scan for these ports.
- If you managed to choose a random port used by another service, you might see a surge in connections and attacks if a vulnerability in that other service is detected. You might be an innocent bystander, but you will get hit anyway.
- If an attacker want to exploit a bug in your type of service, he or she will first find and attack servers using the common ports for that service. You might just have bought some time to prepare a defense while criminals are attacking your neighbours.

All this will result in smaller logs and less headaches to monitor your service.

## Security Zealots

Wait, what is this? Do I hear a horde of CISSP or CISA certified consultants shouting that this is **security by obscurity** and does not help? Please get of my lawn, security by obscurity really works. It is only proven not to work in the domain of cryptography.

## Howto

Clone this repository:

   ```bash
   git clone --depth 1 https://github.com/igbuend/under-the-mat.git
   ```
Run the script:

   ```bash
   ./under-the-mat/bin/under-the-mat.sh
   ```
The script will give you five TCP ports by default. You can ask for UDP ports as follows:

   ```bash
   ./under-the-mat/bin/under-the-mat.sh --type=UDP
   ```

If you need more ports:

   ```bash
   ./under-the-mat/bin/under-the-mat.sh --type=UDP --amount=10
   ```

If you need help:

   ```bash
   ./under-the-mat/bin/under-the-mat.sh --help
   ```

## Known issues

- if you choose a rediculous high amount of ports (higher than the total number of ports not listed in Nmap and IANA), the script will go in an infinite loop. I do not plan to fix that. Just don't be an idiot.

- The script uses the Nmap Top 2000 ports instead of the top 1000.  Reason is that at Nmap position 1000 hundreds of ports have the same frequency of occurrence. I could not bother to reverse engineer Nmap to verify how they determine who gets position 1000.  I also did not want to make this script dependant on Nmap.
