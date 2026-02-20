#!/bin/bash

set -eu

USER=${USER:-crduser}

#autostart tint2 xterm when openbox started
OPENBOX_PATH="/home/${USER}/.config/openbox"
if [[ ! -e "${OPENBOX_PATH}" ]];then 
	mkdir -p $OPENBOX_PATH 

	for i in tint2 xterm;do 
		echo "$i &" >> ${OPENBOX_PATH}/autostart;
	done;
fi

#chrome remote desktop display
DISPLAY= /opt/google/chrome-remote-desktop/start-host --code=$CODE --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$HOSTNAME --pin=$PIN
#HOST_HASH=$(echo -n "$(hostname)" | md5sum | awk '{print $1}')  
#FILENAME=.config/chrome-remote-desktop/host#${HOST_HASH}.json 
#mv .config/chrome-remote-desktop/host#*.json $FILENAME  
#sudo service chrome-remote-desktop stop 
#sudo service chrome-remote-desktop start 


sleep infinity & wait
