#!/bin/bash
set -u

CONFIG=${CONFIG_PATH}/megacoin.conf
CONFIG_REUSE=${CONFIG_PATH}/.megacoin.conf

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
mkdir -p mkdir -p ${CONFIG_PATH}	
chown -R megacoin:megacoin ${CONFIG_PATH}

if [ -f ${CONFIG_REUSE} ] ; then
        sudo -u megacoin mv ${CONFIG_REUSE} ${CONFIG}
else
        sudo -u megacoin cp /tmp/megacoin.conf ${CONFIG}
        sed -i "s#^\(rpcuser=\).*#rpcuser=mecrpcnode$(openssl rand -base64 32 | tr -d '[:punct:]')#g" ${CONFIG}
        sed -i "s#^\(rpcpassword=\).*#rpcpassword=$(openssl rand -base64 32 | tr -d '[:punct:]')#g" ${CONFIG}
	RPC_ALLOWIP=$(ip addr | grep 'global eth0' | xargs | cut -f2 -d ' ')
	sed -i "s#^\(rpcallowip=\).*#rpcallowip=${RPC_ALLOWIP}#g" ${CONFIG}
fi

#
# Downloading bootstrap file
#
printf "** Downloading bootstrap file ***\n"
cd ${CONFIG_PATH}
if [ ! -d ${CONFIG_PATH}/blocks ] && [ "$(curl -Is https://${WEB}/${BOOTSTRAP} | head -n 1 | tr -d '\r\n')" = "HTTP/1.1 200 OK" ] ; then \
        sudo -u megacoin wget https://${WEB}/${BOOTSTRAP}; \
        sudo -u megacoin tar -xvzf ${BOOTSTRAP}; \
        sudo -u megacoin rm ${BOOTSTRAP}; \
fi

#
# Starting MegaCoin Service
#
# Hint: docker not supported systemd, use of supervisord
printf "*** Starting MegaCoin Service ***\n"
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
