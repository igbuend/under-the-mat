#!/usr/bin/env bash
#
# This script will output five (5) random TCP or UDP ports.
#
#   - none under port 1024 since for transport protocols such as TCP and UDP ports 1 to 1023 are by default privileged ports.
#     To bind to a privileged port, a process must be running with root permissions. Ports that are greater than 1023 are by
#     default non-privileged. For security reasons it is preferable that your service does not need root privileges.
#   - none listed in IANA ports. Many vulnerability scanners such as OpenVas can be configured to scan all ports listed in IANA,
#     hence we avoid those ports.
#   - none in the top 1000 nmap ports. Nmap is a powerfull port scanner. Without additional options, it will scan the top 1000
#     most common ports. We avoid those ports. 

# exit when any command fails
set -e

readonly TEMP_DIR="$(mktemp -q -d)"

# https://stackoverflow.com/questions/3685970/check-if-a-bash-array-contains-a-value
function inArray () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

# https://unix.stackexchange.com/questions/177138/how-do-i-test-if-an-item-is-in-a-bash-array
function inAssocArray # ( keyOrValue, arrayKeysOrValues ) 
{
  local e
  for e in "${@:2}"; do 
    [[ "$e" == "$1" ]] && return 0; 
  done
  return 1
}

# return nonzero unless $1 contains only digits, leading zeroes not allowed
function is_numeric() {
    case "$1" in
        "" | *[![:digit:]]* | 0[[:digit:]]* ) return 1 ;;
    esac
}

# based on http://fitnr.com/showing-a-bash-spinner.html
function spinner() {
    local pid=$!
    local delay=0.50
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# usage function
function usage(){
    cat << HEREDOC

   Usage: $progname [--amount number] [--type] [--help]
   
   optional arguments:
     -h, --help               show this help message and exit
     -a, --amount             numer of ports (default 3)
     -t, --type               UDP or TCP (default)

HEREDOC
}

if ! [ -x "$(command -v curl)" ]; then
    echo ""
    echo 'Error: curl is not installed.' >&2
    echo ""
    rm -rf "$TEMP_DIR" || true; exit 1
fi

# initialise variables
progname="$(basename "$0")"
amount=5
type="TCP"

# use getopt and store the output into $OPTS
# note the use of -o for the short options, --long for the long name options
# and a : for any option that takes a parameter

if ! OPTS=$(getopt -o "a:t:h" --long "amount:,type:,help" -n "$progname" -- "$@"); then
    echo "Error in command line arguments." >&2 ; rm -rf "$TEMP_DIR" || true; usage; exit 1 ;
fi

eval set -- "$OPTS"
while true; do
    case "$1" in
        -h | --help ) usage; exit; ;;
        -a | --amount ) amount="$2"; shift 2 ;;
        -t | --type ) type="$2"; shift 2 ;; 
        -- ) shift; break ;;
        * ) break ;;
    esac
done

if ! is_numeric "$amount" ;then
    echo "  Invalid number of ports. Please try again."
    rm -rf "$TEMP_DIR" || true; usage; exit 1
fi

echo -n "  Getting IANA list of port numbers"
( curl -s --retry 5 -o "$TEMP_DIR"/iana.csv https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.csv ) & spinner $!
echo ". Done."
echo -n "  Getting Nmap list of common port numbers"
( curl -s --retry 5 -o "$TEMP_DIR"/nmap.lst https://raw.githubusercontent.com/nmap/nmap/master/nmap-services ) & spinner $!
echo ". Done."

# remove first line
sed -i '1d' "$TEMP_DIR"/iana.csv
# remove all lines starting with space
sed -i '/^ /d' "$TEMP_DIR"/iana.csv
# remove lines with 'Unassigned'
sed -i '/Unassigned/d'  "$TEMP_DIR"/iana.csv
# remove lines without ,
sed -i '/,/!d' "$TEMP_DIR"/iana.csv
# remove lines not containing udp/tcp
sed -i '/,tcp,\|,udp,/!d' "$TEMP_DIR"/iana.csv
# remove lines without portnumbers
awk -F',' '$2!=""' "$TEMP_DIR"/iana.csv > "$TEMP_DIR"/iana.lst
# remove comments
sed -i '/^#/d' "$TEMP_DIR"/nmap.lst
# sort on frequency
sort -r -b -g -k 3,3 -o "$TEMP_DIR"/nmap.lst "$TEMP_DIR"/nmap.lst
# split /
sed -i 's/\//\'$'\t/g' "$TEMP_DIR"/nmap.lst

# create tcp/udp unsafe list
declare -a unsafe
if [ ${type^^}=="TCP" ]; then
    awk -F ',' '$3=="tcp" {print $2}' "$TEMP_DIR"/iana.lst > "$TEMP_DIR"/tcp1
    awk -F '\t' '$3=="tcp" {print $2}' "$TEMP_DIR"/nmap.lst > "$TEMP_DIR"/tcp2
    sed -i '2001,$ d' "$TEMP_DIR"/tcp2
    sort -u -n "$TEMP_DIR"/tcp[1,2] > "$TEMP_DIR"/unsafe.lst
else
    awk -F ',' '$3=="udp" {print $2}' "$TEMP_DIR"/iana.lst > "$TEMP_DIR"/udp1
    awk -F '\t' '$3=="udp" {print $2}' "$TEMP_DIR"/nmap.lst > "$TEMP_DIR"/udp2
    sed -i '2001,$ d' "$TEMP_DIR"/udp2
    sort -u -n "$TEMP_DIR"/udp[1,2] > "$TEMP_DIR"/unsafe.lst
fi

mapfile -t unsafe < "$TEMP_DIR"/unsafe.lst

declare -A safe_ports
while [ ${#safe_ports[@]} -lt $amount ]; do
    myport=$(shuf -i 1024-65535 -n 1)
    if ! inArray "$myport" "${unsafe[@]}"; then
       safe_ports[$myport]=$myport
    fi
done

echo "  Recommended ${type^^} ports are:"
echo ""
printf "    %s\n" "${safe_ports[@]}"
echo ""

rm -rf "$TEMP_DIR" || true
