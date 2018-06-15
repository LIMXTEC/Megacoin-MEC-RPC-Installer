#!/bin/bash
set -u

BOOTSTRAP='bootstrap.tar.gz'

#
# Set passwd of megacoin user
#
echo megacoin:${MECPWD} | chpasswd

#
# Downloading megacoin.conf
#
cd /tmp/
wget https://raw.githubusercontent.com/LIMXTEC/Megacoin-MEC-RPC-Installer/master/megacoin.conf -O /tmp/megacoin.conf
chown megacoin:megacoin /tmp/megacoin.conf

#
# Configure megacoin.conf
#
printf "** Configure megacoin.conf ***\n"
mkdir -p /home/megacoin/.megacoin	
chown -R megacoin:megacoin /home/megacoin/
sudo -u megacoin cp /tmp/megacoin.conf /home/megacoin/.megacoin/megacoin.conf
sed -i "s/^\(rpcuser=\).*/rpcuser=mecrpcnode${MECPWD}/" /home/megacoin/.megacoin/megacoin.conf
sed -i "s/^\(rpcpassword=\).*/rpcpassword=${MECPWD}/" /home/megacoin/.megacoin/megacoin.conf

#
# Downloading bootstrap file
#
printf "** Downloading bootstrap file ***\n"
cd /home/megacoin/.megacoin/
if [ ! -d /home/megacoin/.megacoin/blocks ] && [ "$(curl -Is https://megacoin.eu/downloads/${BOOTSTRAP} | head -n 1 | tr -d '\r\n')" = "HTTP/1.1 200 OK" ] ; then \
        sudo -u megacoin wget https://megacoin.eu/downloads/${BOOTSTRAP}; \
        sudo -u megacoin tar -xvzf ${BOOTSTRAP}; \
        sudo -u megacoin rm ${BOOTSTRAP}; \
fi

#
# Starting MegaCoin Service
#
# Hint: docker not supported systemd, use of supervisord
printf "*** Starting MegaCoin Service ***\n"
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
