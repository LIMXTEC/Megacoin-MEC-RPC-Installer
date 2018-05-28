#!/bin/bash
set -u

DOCKER_REPO="dalijolijo"
CONFIG="/home/megacoin/.megacoin/megacoin.conf"

#
# Check if megacoin.conf already exist. Set megacoin user pwd.
#
REUSE="No"
if [ -f "$CONFIG" ]
then
        echo -n "Found $CONFIG on your system. Do you want to re-use this existing config file? Enter Yes or No and Hit [ENTER]: "
        read REUSE
fi

if [[ $REUSE =~ "N" ]] || [[ $REUSE =~ "n" ]]; then
        echo -n "Enter new password for [megacoin] user and Hit [ENTER]: "
        read MECPWD
else
        source $CONFIG
        MECPWD=$(echo $rpcpassword)
fi

#
# Check distro version for further configurations (TODO)
#
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

# Configurations for Ubuntu
if [[ $OS =~ "Ubuntu" ]] || [[ $OS =~ "ubuntu" ]]; then
    echo "Configuration for $OS ($VER)..."
 
    # Firewall settings (for Ubuntu)
    echo "Setup firewall..."
    ufw logging on
    ufw allow 22/tcp
    ufw limit 22/tcp
    ufw allow 7951/tcp
    ufw allow 8556/tcp
    ufw allow 9051/tcp
    # if other services run on other ports, they will be blocked!
    #ufw default deny incoming 
    ufw default allow outgoing 
    yes | ufw enable

    # Installation further package (Ubuntu 16.04)
    echo "Install further packages..."
    apt-get update
    sudo apt-get install -y apt-transport-https \
                            ca-certificates \
                            curl \
                            software-properties-common
else
    echo "Automated firewall setup for $OS ($VER) not supported!"
    echo "Please open firewall ports 22, 7951, 8556 and 9051 manually."
    exit
fi

#
# Pull docker images and run the docker container
#
docker rm mec-rpc-server
docker pull ${DOCKER_REPO}/mec-rpc-server
docker run -p 7951:7951 -p 8556:8556 -p 9051:9051 --name mec-rpc-server -e MECPWD="${MECPWD}" -v /home/megacoin:/home/megacoin:rw -d ${DOCKER_REPO}/mec-rpc-server
