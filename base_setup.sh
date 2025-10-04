# Base setup
# TODO
# - Disable IPv6 without reboot (will be moved to SDM imaging)
# - Move bash setup to SDM imaging
# Error handling
set -e
# Error handler
handle_error()
{
	echo "Error: $(caller) : ${BASH_COMMAND}"
}
# Set the error handler to be called when an error occurs
trap handle_error ERR

# Variables
usrname=$(logname) # Script runs as root
piname=$(hostname)
repo="rpi-trixie"
repobranch="main"
pimodelnum=$(cat /sys/firmware/devicetree/base/model | cut -d " " -f 3)

disable_ipv6()
{
	echo "127.0.0.1       localhost" > /etc/hosts
	echo " ipv6.disable=1" >> /boot/firmware/cmdline.txt
	echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
	sysctl -p
}

set_default_shell()
{
	dpkg-divert --remove --no-rename /usr/share/man/man1/sh.1.gz
	dpkg-divert --remove --no-rename /bin/sh
	ln -sf bash.1.gz /usr/share/man/man1/sh.1.gz
	ln -sf bash /bin/sh
	dpkg-divert --add --local --no-rename /usr/share/man/man1/sh.1.gz
	dpkg-divert --add --local --no-rename /bin/sh
}

# Install/update software
update_system_base()
{
	printf "%s\n" "Updating system"
	apt-get -y update
	apt-get -y full-upgrade
	apt-get -y install python3-dev gcc g++ gfortran libdtovl0 libomp-dev git build-essential cmake pkg-config make screen htop stress-ng zip bzip2 fail2ban ufw ntpsec-ntpdate pkgconf openssl libmunge-dev munge python3-setuptools libgpiod-dev mmc-utils smartmontools
 	# Remove local SDM
  rm -rf /usr/local/sdm
 	rm -rf /usr/local/bin/sdm
  rm -rf /etc/sdm
  # Create Bash shortcuts
  echo "alias spo=\"sudo poweroff\"" >> /home/$usrname/.bashrc
	echo "alias spr=\"sudo reboot\"" >> /home/$usrname/.bashrc
 	echo "alias lsb=\"sudo udevadm trigger; lsblk\"" >> /home/$usrname/.bashrc
  printf "%s\n" "System update complete"
}

setup_ntp()
{
	printf "%s\n" "Configuring ntp"
 	sed -i "s/#FallbackNTP/FallbackNTP/g" /etc/systemd/timesyncd.conf # Setup NTP
  printf "%s\n" "ntp setup complete"
}

# Git setup
setup_git()
{
	printf "%s\n" "Setting up Git"
	mkdir /home/$usrname/.pisetup
	cd /home/$usrname/.pisetup
	git clone https://github.com/cms66/$repo.git
	printf "# Setup - Custom configuration\n# --------------------\n\
	repo = $repo\n\
	repobranch = $repobranch\n" > /home/$usrname/.pisetup/custom.conf
	chown -R $usrname:$usrname /home/$usrname/.pisetup
	# Create Bash shortcuts for setup and test menu
	echo "alias mbs=\"sudo bash ~/.pisetup/$repo/setup_main.sh\"" >> /home/$usrname/.bashrc
	echo "alias mbt=\"sudo bash ~/.pisetup/$repo/test_main.sh\"" >> /home/$usrname/.bashrc
	echo "alias mps=\"sudo python ~/.pisetup/$repo/setup_main.py\"" >> /home/$usrname/.bashrc 	
	echo "alias mpt=\"sudo python ~/.pisetup/$repo/test_main.py\"" >> /home/$usrname/.bashrc
}

# - Create python Virtual Environment (with access to system level packages) and bash alias for activation
create_venv()
{
	printf "%s\n" "Creating python Virtual Environment"
	python -m venv --system-site-packages /home/$usrname/.venv
  # Create Bash shortcuts to activate/deactivate Virtual Envirnment
	echo "alias mvp=\"source ~/.venv/bin/activate\"" >> /home/$usrname/.bashrc
	echo "alias dvp=\"deactivate\"" >> /home/$usrname/.bashrc
	chown -R $usrname:$usrname /home/$usrname/.venv
}

# Configure fail2ban
setup_fail2ban()
{
	printf "%s\n" "Configuring fail2ban"
	cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
	cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
 	# Setup ssh rules
	strssh="filter	= sshd\n\
banaction = iptables-multiport\n\
bantime = -1\n\
maxretry = 3\n\
findtime = 24h\n\
backend = systemd\n\
journalmatch = _SYSTEMD_UNIT=ssh.service + _COMM=sshd\n\
enabled = true\n"
	sed -i "s/backend = %(sshd_backend)s/$strssh/g" /etc/fail2ban/jail.local
}

# Configure firewall (ufw)
setup_firewall()
{
	printf "%s\n" "Configuring firewall"
	# Allow SSH from local subnet only, unless remote access needed
	read -rp "Allow remote ssh acces (y/n): " inp </dev/tty
	if [ X$inp = X"y" ] # TODO - not case insensitive
	then # Remote
 		yes | sudo ufw allow ssh
	else # Local
		yes | sudo ufw allow from $localnet to any port ssh
	fi
	sudo ufw logging on
	yes | sudo ufw enable
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

disable_ipv6
set_default_shell
update_system_base
setup_ntp
setup_git
create_venv
setup_fail2ban
get_subnet_cidr
setup_firewall
