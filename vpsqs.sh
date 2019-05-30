#!/bin/bash
# Script to Harden Security on VPS server with CentOS 7
# This VPS Server Hardening script is designed to be run on new VPS deployments to simplify a lot of the
# basic hardening that can be done to protect your server. I assimilated several design ideas from AMega's
# VPS hardening script which I found on Github seemingly abandoned. I am very happy to finish it.

function akguy_banner() {
cat << "EOF"
░▀░ █▀▀▄ █▀▀ ▀▀█▀▀ █▀▀█ █░░ █░░   █▀▀ █▀▀█ █▀▄▀█ █▀▀   █▀▀ ▀▀█▀▀ █░░█ █▀▀ █▀▀
▀█▀ █░░█ ▀▀█ ░░█░░ █▄▄█ █░░ █░░   ▀▀█ █░░█ █░▀░█ █▀▀   ▀▀█ ░░█░░ █░░█ █▀▀ █▀▀
▀▀▀ ▀░░▀ ▀▀▀ ░░▀░░ ▀░░▀ ▀▀▀ ▀▀▀   ▀▀▀ ▀▀▀▀ ▀░░░▀ ▀▀▀   ▀▀▀ ░░▀░░ ░▀▀▀ ▀░░ ▀░░
EOF
}
	 
# ###### SECTIONS ######
# 1. CREATE SWAP / if no swap exists, create 1 GB swap
# 2. UPDATE AND UPGRADE / update operating system & pkgs
# 3. INSTALL FAVORED PACKAGES / useful tools & utilities
# 4. INSTALL CRYPTO PACKAGES / common crypto packages
# 5. USER SETUP / add new sudo user, copy SSH keys
# 6. SSH CONFIG / change SSH port, disable root login
# 7. UFW CONFIG / UFW - add rules, harden, enable firewall
# 8. HARDENING / before rules, secure shared memory, etc
# 9. KSPLICE INSTALL / automatically update without reboot
# 10. MOTD EDIT / replace boring banner with customized one
# 11. RESTART SSHD / apply settings by restarting systemctl
# 12. INSTALL COMPLETE / display new SSH and login info

# Add to log command and display output on screen
# echo " `date +%d.%m.%Y" "%H:%M:%S` : $MESSAGE"
# Add to log command and do not display output on screen
# echo " `date +%d.%m.%Y" "%H:%M:%S` : $MESSAGE"

# write to log only, no output on screen # echo  -e "---------------------------------------------------- "
# write to log only, no output on screen # echo  -e "    ** This entry gets written to the log file directly. **"
# write to log only, no output on screen # echo  -e "---------------------------------------------------- \n"

function setup_environment() {
### add colors ###
lightred='\033[1;31m'  # light red
red='\033[0;31m'  # red
lightgreen='\033[1;32m'  # light green
green='\033[0;32m'  # green
lightblue='\033[1;34m'  # light blue
blue='\033[0;34m'  # blue
lightpurple='\033[1;35m'  # light purple
purple='\033[0;35m'  # purple
lightcyan='\033[1;36m'  # light cyan
cyan='\033[0;36m'  # cyan
lightgray='\033[0;37m'  # light gray
white='\033[1;37m'  # white
brown='\033[0;33m'  # brown
yellow='\033[1;33m'  # yellow
darkgray='\033[1;30m'  # dark gray
black='\033[0;30m'  # black
nocolor='\033[0m'    # no color

# Used this while testing color output
# printf " ${lightred}Light Red${nocolor}\n"
# printf " ${red}Red${nocolor}\n"
# printf " ${lightgreen}Light Green${nocolor}\n"
# printf " ${green}Green${nocolor}\n"
# printf " ${lightblue}Light Blue${nocolor}\n"
# printf " ${blue}Blue${nocolor}\n"
# printf " ${lightpurple}Light Purple${nocolor}\n"
# printf " ${purple}Purple${nocolor}\n"
# printf " ${lightcyan}Light Cyan${nocolor}\n"
# printf " ${cyan}Cyan${nocolor}\n"
# printf " ${lightgray}Light Gray${nocolor}\n"
# printf " ${white}White${nocolor}\n"
# printf " ${lightbrown}Brown${nocolor}\n"
# printf " ${yellow}Yellow${nocolor}\n"
# printf " ${darkgray}Dark Gray${nocolor}\n"
# printf " ${black}Black${nocolor}\n"
# figlet " hello $(whoami)" -f small

printf "${lightred}"
printf "${red}"
printf "${lightgreen}"
printf "${green}"
printf "${lightblue}"
printf "${blue}"
printf "${lightpurple}"
printf "${purple}"
printf "${lightcyan}"
printf "${cyan}"
printf "${lightgray}"
printf "${white}"
printf "${brown}"
printf "${yellow}"
printf "${darkgray}"
printf "${black}"
printf "${nocolor}"
clear

# Set Vars
LOGFILE='/var/log/server_hardening.log'
SSHDFILE='/etc/ssh/sshd_config'
}

function begin_log() {
# Create Log File and Begin
printf "${lightcyan}"
echo -e "---------------------------------------------------- "
echo -e " `date +%m.%d.%Y_%H:%M:%S` : SCRIPT STARTED SUCCESSFULLY "
echo -e "---------------------------------------------------- "
echo -e "------- install some stuff VPS Hardening Script --------- "
echo -e "---------------------------------------------------- \n"
printf "${nocolor}"
sleep 2
}


#########################
## CHECK & CREATE SWAP ##
#########################




function create_swap() {
# Check for and create swap file if necessary
	printf "${yellow}"
	echo -e "------------------------------------------------- "
	echo -e " `date +%m.%d.%Y_%H:%M:%S` : CHECK FOR AND CREATE SWAP "
	echo -e "------------------------------------------------- \n"
	printf "${white}"
	
	# Check for swap file - if none, create one
swaponState=$(swapon -s)
if [[ -n $swaponState ]]
then
clear
		printf "${lightred}"
		echo -e "---------------------------------------------------- "
		echo -e " `date +%m.%d.%Y_%H:%M:%S` : Swap exists- No changes made "
		echo -e "---------------------------------------------------- \n" 
		sleep 2
		printf "${nocolor}"
		sleep 2
	else
	    

echo 'This script will create swap file on your server'
echo '------------------------------------------------'
read -p "Swap size (Mb): " swapSizeValue
read -p "Swappiness value (1-100): " swappinessValue

clear
echo 'Enabling swap file in progress..Please wait'

# Create swap file
sudo cd /var
sudo touch swap.img
sudo chmod 600 swap.img

# Set swap size
sudo dd if=/dev/zero of=/var/swap.img bs=1024 count="${swapSizeValue}k"

# Prepare the disk image
sudo mkswap /var/swap.img

# Enable swap file
sudo swapon /var/swap.img

# Mount swap on reboot
echo "/var/swap.img    none    swap    sw    0    0" >> /etc/fstab

# Change swappiness value
sudo sysctl -w vm.swappiness=30

#Final output
clear
echo -e "Swap file with size \e[1m$swapSizeValue Mb\e[0m  has been created successfully"
sudo free | grep Swap

echo 'Swapines value'
sudo sysctl -a | grep vm.swappiness
clear
		
		printf "${lightgreen}"	
		echo -e "-------------------------------------------------- "
		echo -e " `date +%m.%d.%Y_%H:%M:%S` : SWAP CREATED SUCCESSFULLY "
		echo -e "--> Thanks @Cryptotron for supplying swap code <-- "
		echo -e "-------------------------------------------------- \n"
		sleep 2
		printf "${nocolor}"
	fi
}



##############
##EnableCron##
##############
#Autoupdate CentOS 7 with CRON
#Description: This script will install CRON on your server


clear

echo 'Installing CRON..'
# Install CRON
sudo yum -y install yum-cron
sudo chkconfig yum-cron on

sudo service yum-cron start

#Final output
clear
echo 'CRON has been successfully installed and started'
echo 'You can edit CRON config in /etc/yum/yum-cron.conf'
echo 'Do not forget to restart CRON service after editing config' 
echo -e "\e[1mCRON has been successfully installed and started\e[0m"
sleep 2
clear

######################
## UPDATE & UPGRADE ##
######################

function update_upgrade() {

# NOTE I learned the hard way that you must put a "\" BEFORE characters "\" and "`"
echo -e "${lightcyan}"
printf "  ___  ____    _   _           _       _ \n"
printf " / _ \/ ___|  | | | |_ __   __| | __ _| |_ ___ \n"
printf "| | | \\___ \\  | | | | '_ \\ / _\` |/ _\` | __/ _ \\ \n"
printf "| |_| |___) | | |_| | |_) | (_| | (_| | ||  __/ \n"
printf " \___/|____/   \___/| .__/ \__,_|\__,_|\__\___| \n"
printf "                    |_| \n"
printf "${yellow}"
echo -e "---------------------------------------------------- "
echo -e " `date +%m.%d.%Y_%H:%M:%S` : INITIATING SYSTEM UPDATE "
echo -e "---------------------------------------------------- "
printf "${white}"
sleep 1


clear

echo 'This script will help you to configure your server'
echo '---------------------------------------------'
echo 'Steps:'
echo -e "\e[1mSTEP 1:\e[0m Update the system"
echo -e "\e[1mSTEP 2:\e[0m Create New User"
echo -e "\e[1mSTEP 3:\e[0m Add Public Key Authentication"
echo -e "\e[1mSTEP 4:\e[0m Configuring SSH"
echo -e "\e[1mSTEP 5:\e[0m Configuring a Basic Firewall"
echo -e "\e[1mSTEP 6:\e[0m Configuring Timezones and NTP"
echo '---------------------------------------------'
echo -e "\e[1mATTENTION!!!\e[0m"
echo 'This script will disable root login'
echo 'Also this script will disable authentication by password'
echo 'Only authentication by ssh key will be allowed'
echo '---------------------------------------------'
sleep 1
clear

#STEP 1 - Update the system
echo -e "\e[1mSTEP 1: Update the system \e[0m" 

sudo yum -y update

clear
echo -e "\e[1mSystem has been updated successfully\e[0m"
sleep 1

}
#STEP 2 - Create New User
		printf "${lightgreen}"	
		echo -e "-------------------------------------------------- "
		echo -e " `date +%m.%d.%Y_%H:%M:%S` :  CREATE A NEW ADMIN USER "
		echo -e "-------------------------------------------------- \n"
		sleep 2
		printf "${nocolor}"

echo -e "\e[1mSTEP 2: Create New User \e[0m" 

read -p "Enter new username (e.g. admin): " newUser
#Create User
sudo adduser "$newUser"
sudo passwd "$newUser"
#Grant new user the root privileges
sudo passwd -a "$newUser" wheel

clear
echo -e "\e[1mUser '${newUser}' with the root privileges has been created\e[0m"
sleep 1



		printf "${lightred}"
		echo -e "---------------------------------------------------- "
		echo -e " `date +%m.%d.%Y_%H:%M:%S` : SSH CHANGES "
		echo -e "---------------------------------------------------- \n" 
		sleep 2
		printf "${nocolor}"
		sleep 2

#STEP 4 - Configuring SSH
echo -e "\e[1mSTEP 4: Configuring SSH \e[0m" 

read -p "Enter new SSH port (47979-65536): " newSSHPort

#Backup SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config_BACKUP

#Change SSH port
sudo sed -i "/#Port 22/a Port ${newSSHPort}" /etc/ssh/sshd_config




echo 'FOR REAL THOUGH, ANYTHING AFTER THIS DISABLES ROOT.'
echo ' --=Make sure you have Oxidized already setup=-- '
		sleep 2
echo 'abort with ctrl+c'
echo 'PRESS ANY KEY TO CONTINUE'
read -n 1 -s
clear



#The root user should never be allowed to login to a system directly over a network. 
#To disable root login via SSH, add or correct the following line in /etc/ssh/sshd_config:
#PermitRootLogin no

SSHD_CONFIG='/etc/ssh/sshd_config'

# Obtain line number of first uncommented case-insensitive occurrence of Match
# block directive (possibly prefixed with whitespace) present in $SSHD_CONFIG
FIRST_MATCH_BLOCK=$(sed -n '/^[[:space:]]*Match[^\n]*/I{=;q}' $SSHD_CONFIG)

# Obtain line number of first uncommented case-insensitive occurence of
# PermitRootLogin directive (possibly prefixed with whitespace) present in
# $SSHD_CONFIG
FIRST_PERMIT_ROOT_LOGIN=$(sed -n '/^[[:space:]]*PermitRootLogin[^\n]*/I{=;q}' $SSHD_CONFIG)

# Case: Match block directive not present in $SSHD_CONFIG
if [ -z "$FIRST_MATCH_BLOCK" ]
then

    # Case: PermitRootLogin directive not present in $SSHD_CONFIG yet
    if [ -z "$FIRST_PERMIT_ROOT_LOGIN" ]
    then
        # Append 'PermitRootLogin no' at the end of $SSHD_CONFIG
        echo -e "\nPermitRootLogin no" >> $SSHD_CONFIG

    # Case: PermitRootLogin directive present in $SSHD_CONFIG already
    else
        # Replace first uncommented case-insensitive occurrence
        # of PermitRootLogin directive
        sed -i "$FIRST_PERMIT_ROOT_LOGIN s/^[[:space:]]*PermitRootLogin.*$/PermitRootLogin no/I" $SSHD_CONFIG
    fi

# Case: Match block directive present in $SSHD_CONFIG
else

    # Case: PermitRootLogin directive not present in $SSHD_CONFIG yet
    if [ -z "$FIRST_PERMIT_ROOT_LOGIN" ]
    then
        # Prepend 'PermitRootLogin no' before first uncommented
        # case-insensitive occurrence of Match block directive
        sed -i "$FIRST_MATCH_BLOCK s/^\([[:space:]]*Match[^\n]*\)/PermitRootLogin no\n\1/I" $SSHD_CONFIG

    # Case: PermitRootLogin directive present in $SSHD_CONFIG and placed
    #       before first Match block directive
    elif [ "$FIRST_PERMIT_ROOT_LOGIN" -lt "$FIRST_MATCH_BLOCK" ]
    then
        # Replace first uncommented case-insensitive occurrence
        # of PermitRootLogin directive
        sed -i "$FIRST_PERMIT_ROOT_LOGIN s/^[[:space:]]*PermitRootLogin.*$/PermitRootLogin no/I" $SSHD_CONFIG

    # Case: PermitRootLogin directive present in $SSHD_CONFIG and placed
    # after first Match block directive
    else
         # Prepend 'PermitRootLogin no' before first uncommented
         # case-insensitive occurrence of Match block directive
         sed -i "$FIRST_MATCH_BLOCK s/^\([[:space:]]*Match[^\n]*\)/PermitRootLogin no\n\1/I" $SSHD_CONFIG
    fi
fi





#To explicitly disallow remote login from accounts with empty passwords, add or correct the following line in /etc/ssh/sshd_config:

#PermitEmptyPasswords no

#Any accounts with empty passwords should be disabled immediately.
#Also, PAM configuration should prevent users from being able to assign themselves empty passwords. 

grep -qi ^PermitEmptyPasswords /etc/ssh/sshd_config && \
  sed -i "s/PermitEmptyPasswords.*/PermitEmptyPasswords no/gI" /etc/ssh/sshd_config
if ! [ $? -eq 0 ]; then
    echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
fi






#To ensure users are not able to present environment options to the SSH daemon, add or correct the following line in /etc/ssh/sshd_config:

#PermitUserEnvironment no

grep -qi ^PermitUserEnvironment /etc/ssh/sshd_config && \
  sed -i "s/PermitUserEnvironment.*/PermitUserEnvironment no/gI" /etc/ssh/sshd_config
if ! [ $? -eq 0 ]; then
    echo "PermitUserEnvironment no" >> /etc/ssh/sshd_config
fi






#Limit the ciphers to those algorithms which are FIPS-approved. Counter (CTR) mode is also preferred over cipher-block chaining (CBC) mode. 
#The following line in /etc/ssh/sshd_config demonstrates use of FIPS-approved ciphers:

#Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc

#The man page sshd_config(5) contains a list of supported ciphers. 

grep -qi ^Ciphers /etc/ssh/sshd_config && \
  sed -i "s/Ciphers.*/Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc/gI" /etc/ssh/sshd_config
if ! [ $? -eq 0 ]; then
    echo "Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc" >> /etc/ssh/sshd_config
fi








#Restrict Root Login
sudo sed -i "/#PermitRootLogin yes/a PermitRootLogin no" /etc/ssh/sshd_config

#Disable authentication by password and enable authentication by ssh key
sudo sed -i "/#RSAAuthentication yes/a RSAAuthentication yes" /etc/ssh/sshd_config
sudo sed -i "/#PubkeyAuthentication yes/a PubkeyAuthentication yes" /etc/ssh/sshd_config
sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config

sudo systemctl reload sshd.service

clear
echo -e "\e[1mSSH config has been HARDENED successfully\e[0m"
sleep 3




		printf "${lightgreen}"	
		echo -e "-------------------------------------------------- "
		echo -e " `date +%m.%d.%Y_%H:%M:%S` :  I didnt start the  "
		echo -e "-------------------------------------------------- \n"
		sleep 2
		printf "${nocolor}"

#STEP 5 - Configuring a Basic Firewall
echo -e "\e[1mSTEP 5: Configuring a Basic Firewall \e[0m" 

sudo systemctl start firewalld

#If port SSH has NOT changed
#sudo firewall-cmd --permanent --add-service=ssh

#If port SSH has BEEN changed
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --permanent --add-port="${newSSHPort}/tcp"
#HTTP
sudo firewall-cmd --permanent --add-service=http
#HTTPS
sudo firewall-cmd --permanent --add-service=https
#ADD MORE BELOW !!!!!!!!!!!!!!!!



#Reload firewall
sudo firewall-cmd --reload

sudo systemctl enable firewalld

#firewall-cmd --list-ports

clear
echo -e "\e[1mFirewall has been updated successfully\e[0m"


#STEP 6 - Configuring Timezones and NTP
echo -e "\e[1mSTEP 6: Configuring Timezones and NTP \e[0m" 

#Timezone
read -p "Enter server timezone (e.g. America/Chicago): " serverTimezone
#sudo timedatectl list-timezones
sudo timedatectl set-timezone "$serverTimezone"

#timedatectl -> check current settings

#NTP (Network Time Protocol Synchronization)
echo -e "\e[1mEnable NTP\e[0m"

sudo yum -y install ntp
sudo systemctl start ntpd
sudo systemctl enable ntpd

clear
echo -e "\e[1mNetwork Time Protocol Synchronization (NTP) has been successfully installed and enabled\e[0m"

#Final output
echo '-------------------------------------------------------'
echo 'Initial server setup has been completed successfully'
echo '-------------------------------------------------------'
echo 'Details:'
echo '1. System has been updated'
echo '2. CRON has been installed and started'
echo -e "3. User \e[1m${newUser}\e[0m with the root privileges has been created"
echo '4. Public SSH key for new user has been added successfully'
echo '5. SSH config has been updated:'
echo -e "  - New SSH port is \e[1m${newSSHPort}\e[0m"
echo '  - Root login has been disabled'
echo '  - Authentication by password has been disabled'
echo '  - SSH config backup: /etc/ssh/sshd_config_BACKUP'
echo '6. Firewall has been enabled'
echo '6. Firewall rules has been updated'
echo '7. Server timezone has been updated'
echo '8. Network Time Protocol Synchronization (NTP) has been enabled'
echo '---------------------------------------------'
