# Simple/generic functions
show_menu()
# TODO remove number from last option
{
	declare -a arrMenuOptions=()
	declare -a arrMenuActions=()
	arg1=$1[@]
	arrFull=("${!arg1}")	
	for item in "${arrFull[@]}"; do # Populate Prompt/Action arrays from Full array
		arrMenuOptions+=("$(echo $item | cut -f 1 -d '#')")
		arrMenuActions+=("$(echo $item | cut -f 2 -d '#')")
	done
	while true; do # Print menu
		clear
		ind=0
		for opt in "${arrMenuOptions[@]}"; do
			if [[ $ind -eq 0 ]]
			then				
				underline "${arrMenuOptions[0]}" # Print underlined title
    				${arrMenuActions[$ind]}
			else
				printf "%s\n" "$ind - $opt" # Print numbered menu option
			fi
			((ind=ind+1))
		done
		read -p "Select option: " inp
		# Process input
		if [[ ${#inp} -eq 0 ]]
		then # user pressed enter or space
			read -p "No option selected, press enter to continue"
		else
  			if [[ ${inp,} = "q" ]] || [[ ${inp,} = "b" ]] # Q/q or B/b selected - last menu item
     			then
				break 2
			else
				if [[ "$inp" =~ ^[0-9]+$ ]] && [[ "$inp" -ge 1 ]] && [[ "$inp" -lt ${#arrMenuOptions[@]} ]]
				then # integer in menu range
					${arrMenuActions[$inp]}
				else
					read -p "Invalid option $inp, press enter to continue"
     				fi
			fi
		fi	
	done
}

underline() # Print line with configurable underline character (defaults to "=")
{
	echo $1; for (( i=0; $i<${#1}; i=$i+1)); do printf "${2:-=}"; done; printf "\n";
}

show_system_summary()
{
	clear
	underline "System summary - $(hostname)" # Print underlined title
	printf "\nModel: $pimodel \n"
	printf "Revision: $pirev \n"
	printf "Architecture: $osarch \n"
	printf "Firmware: $(rpi-eeprom-update) \n"
	printf "\nMemory:\n$(free -mt) \n"
 	udevadm trigger
	printf "\nStorage:\n$(lsblk) \n"
	printf "\nDrive usage:\n"
 	df -h
  	printf "\nNetwork:\n$(nmcli dev status)\n"
	printf "\nFirewall\n"
	ufw status
	read -p "Press enter to return to menu"
}

# Pull git updates and return to working directory
git_pull_setup()
{
	cd /home/$usrname/.pisetup/$repo
	git pull https://github.com/cms66/$repo
	cd $OLDPWD
	read -p "Finished setup update, press enter to return to menu"
}

# Update system
update_system()
{
	apt-get -y update
	apt-get -y full-upgrade
 	update_firmware
	read -p "Finished System update, press enter to return to menu"
}

check_package_status() # Takes package name and install (if needed) as arguments
{
	if [[ "$(dpkg -l | grep $1 | cut --fields 1 -d " ")" = "" ]] # Not installed
	then
		if [[ $2 -eq "y" ]] # Do install
		then
  			printf "%s\n" "Installing $1"
			apt-get install -y -q $1
   			read -p "$1 install done, press enter to continue"
		else
			read -p "$1 not installed - not installing, press enter to continue"
		fi
	else
		read -p "$1 already installed, press enter to continue"
	fi
}

get_subnet_cidr()
{
	wired="$(nmcli -t connection show --active | grep ethernet | cut -f 4 -d ":")"
	wifi="$(nmcli -t connection show --active | grep wireless | cut -f 4 -d ":")"
 	if [[ $wifi ]] && [[ $wired ]] # Multiple connections
	then
		read -p "Use ethernet or wifi for setup? (e/w): " inp
		if [[ ${inp,} = "e" ]]
		then
			dev=$wired
		elif [[ ${inp,} = "w" ]]
		then
			dev=$wifi
		else
			printf "invalid option"
		fi
	else # Single connection
		dev="$wifi$wired" 
	fi
 	export localnet=$(nmcli -t device show $dev | grep "ROUTE\[1\]" | cut -f 2 -d "=" | tr -d '[:blank:]' | sed "s/,nh//")
	printf "Device = $dev | localnet = $localnet\n"
}

update_firmware()
{
	if [[ $pimodelnum = "4" ]] || [ $pimodelnum = "5" ]; then # Model has firmware
		printf "Model has firmware\n"
		updfirm=$(sudo rpi-eeprom-update | grep BOOTLOADER | cut -d ":" -f 2 | tr -d '[:blank:]') # Check for updates
		printf "Update status: $updfirm\n"
 		if ! [ $updfirm = "uptodate" ]; then # Update available - TODO - test when updates are available
 			printf "Update available\n"
 			rpi-eeprom-update -a
    	 else
     		printf "Firmware is up to date\n"
     	fi
	else
		printf "No firmware\n"
	fi
}

install_server()
{
	read -p "TODO check exports + firewall"
}

# SSH
create_user_ssh_keys()
{
	# Create keys for user
	runuser -l  $usrname -c "ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -P \"\"" # Works including creates .ssh directory
	echo "HostKey $usrpath/.ssh/id_ed25519" >> /etc/ssh/sshd_config
	service sshd restart # Works
	systemctl is-active sshd
 	read -p "Server keys generated for $usrname, press enter to return to menu" input
}

copy_user_ssh_keys()
{
	read -p "TODO run ssh-copy-id $usrname@$remnode as $usrname"
}
