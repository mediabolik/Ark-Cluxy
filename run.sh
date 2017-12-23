#!/usr/bin/env bash
echo "###########################################################################"
echo "# Ark Server - " `date`
echo "# UID $UID - GID $GID"
echo "###########################################################################"
[ -p /tmp/FIFO ] && rm /tmp/FIFO
mkfifo /tmp/FIFO

export TERM=linux

function stop {
	if [ ${BACKUPONSTOP} -eq 1 ] && [ "$(ls -A server/ShooterGame/Saved/SavedArks)" ]; then
		echo "[Backup on stop]"
		arkmanager backup
	fi
	if [ ${WARNONSTOP} -eq 1 ];then 
	    arkmanager stop --warn
	else
	    arkmanager stop
	fi
	exit
}



# Change working directory to /volume1/ArkServer to allow relative path
cd /volume1/ArkServer

# Add a template directory to store the last version of config file
[ ! -d /volume1/ArkServer/template ] && mkdir /volume1/ArkServer/template
# We overwrite the template file each time
cp /home/steam/arkmanager.cfg /volume1/ArkServer/template/arkmanager.cfg
cp /home/steam/crontab /volume1/ArkServer/template/crontab
# Creating directory tree && symbolic link
[ ! -f /volume1/ArkServer/arkmanager.cfg ] && cp /home/steam/arkmanager.cfg /volume1/ArkServer/arkmanager.cfg
[ ! -d /volume1/ArkServer/log ] && mkdir /volume1/ArkServer/log
[ ! -d /volume1/ArkServer/backup ] && mkdir /volume1/ArkServer/backup
[ ! -d /volume1/ArkServer/staging ] && mkdir /volume1/ArkServer/staging
[ ! -L /volume1/ArkServer/Game.ini ] && ln -s server/ShooterGame/Saved/Config/LinuxServer/Game.ini Game.ini
[ ! -L /volume1/ArkServer/GameUserSettings.ini ] && ln -s server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini GameUserSettings.ini
[ ! -f /volume1/ArkServer/crontab ] && cp /volume1/ArkServer/template/crontab /volume1/ArkServer/crontab



if [ ! -d /volume1/ArkServer/server  ] || [ ! -f /volume1/ArkServer/server/arkversion ];then 
	echo "No game files found. Installing..."
	mkdir -p /volume1/ArkServer/server/ShooterGame/Saved/SavedArks
	mkdir -p /volume1/ArkServer/server/ShooterGame/Content/Mods
	mkdir -p /volume1/ArkServer/server/ShooterGame/Binaries/Linux/
	touch /volume1/ArkServer/server/ShooterGame/Binaries/Linux/ShooterGameServer
	arkmanager install
	# Create mod dir
else

	if [ ${BACKUPONSTART} -eq 1 ] && [ "$(ls -A server/ShooterGame/Saved/SavedArks/)" ]; then 
		echo "[Backup]"
		arkmanager backup
	fi
fi


# If there is uncommented line in the file
CRONNUMBER=`grep -v "^#" /volume1/ArkServer/crontab | wc -l`
if [ $CRONNUMBER -gt 0 ]; then
	echo "Loading crontab..."
	# We load the crontab file if it exist.
	crontab /volume1/ArkServer/crontab
	# Cron is attached to this process
	sudo cron -f &
else
	echo "No crontab set."
fi

# Launching ark server
if [ $UPDATEONSTART -eq 0 ]; then
	arkmanager start -noautoupdate
else
	arkmanager start
fi


# Stop server in case of signal INT or TERM
echo "Waiting..."
trap stop INT
trap stop TERM

read < /tmp/FIFO &
wait
