#!/bin/bash

# Minecraft Server backup script
# This script will make hourly backups, as well as daily backps that will go back 30 days.
# Make sure to find/replace <USERNAME> with your actual username.
# Make this file executable :   chmod +x mcbu.sh

# make sure to add the following directories:
# mkdir ~/minecraft
# mkdir -p ~/minecraft/bu/daily
# mkdir -p ~/minecraft/bu/hourly
# mkdir -p ~/minecraft/scripts

# First run of the server setup (drag jar file into mincraft directory):
# java -Xmx1024M -Xms1024M -jar /home/<USERNAME>/minecraft/server.jar nogui
# This will setup the environment, and fail. You will need to edit the eula.txt

# Make a file called run.sh:
#      nano ~/minecraft/scripts/run.sh
# add the following text:
#      #!/bin/bash
#      java -Xmx1024M -Xms1024M -jar /home/<USERNAME>/minecraft/versions/1.20.2/server-1.20.2.jar nogui

# Now make run.sh executable : chmod +x run.sh

# Place run.sh and mcbu.sh(this file) into the scripts folder.

# Folder Structure
# ================
#
# minecraft/
# ├── banned-ips.json
# ├── banned-players.json
# ├── bu
# │   ├── daily
# │   └── hourly
# ├── error.log
# ├── eula.txt
# ├── libraries
# ├── logs
# ├── ops.json
# ├── scripts
# │   ├── mcbu.sh
# │   └── run.sh
# ├── server.properties
# ├── usercache.json
# ├── versions
# │   └── 1.20.2
# │       └── server_1.20.2.jar
# ├── whitelist.json
# └── world


# To start the SERVER
# Make sure to launch screen with a name
# ie:
#     > screen -R Server1
#           wait until new screen opens
#     > cd minecraft/scripts
#     > ./run.sh
#
# Use <ctrl>-a d to exit the screen
#
#  to reconnect to this screen, type :   > screen -r
#
#  to stop the server while in screen    > /stop


# Don't forget to add a new crontab to make this script run hourly
#
# Type: crontab -e
#
# This will open up the crontab editor.
# Add the following line to run mcbu.sh every hour on the hour:
#
# 0 * * * * /home/<USERNAME>/minecraft/scripts/mcbu.sh -c > /dev/null


SERVER_VERSION=1.20.2
SERVER_JAR_NAME=server-${SERVER_VERSION}.jar

SERVER_PATH=~/minecraft/versions/${SERVER_VERSION}/

SCREEN_NAME=Server1                   # Name of SCREEN session
BU_HOURLY_PATH=~/minecraft/bu/hourly  # Where the HOURLY backups will be stored
BU_DAILY_PATH=~/minecraft/bu/daily    # Where the DAILY backups will be stored
WORLD_NAME=world                      # Name of the world folder
MAX_COUNT=23                          # Maximum number of files ie: 23 = 0-23 = 24 saves

# Check if the minecraft server is running
RESULT=`ps aux | grep "${SERVER_JAR_NAME}"`
if [ "${RESULT:-null}" = null ]; then #if the RESULT from the previous command is null
echo "Minecraft Server is not running, not backing up."
exit 1
else
# Let users know of the backup and turn off world saving temporarily
screen -R ${SCREEN_NAME} -X stuff "say Backup starting. World no longer saving... $(printf '\r')"
screen -R ${SCREEN_NAME} -X stuff "save-off $(printf '\r')"
screen -R ${SCREEN_NAME} -X stuff "save-all $(printf '\r')"
sleep 3

# change working directory to the hourly backup folder
cd ${BU_HOURLY_PATH}

# Rotate hourly backups
for (( X=$MAX_COUNT; X>=0; X-- )); do        # Go though the iterations,
if [ -e ${WORLD_NAME}-Hour-$X.tar.gz ]; then # but only execute the following command if the file exists
mv ${WORLD_NAME}-Hour-$X.tar.gz ${WORLD_NAME}-Hour-$(($X+1)).tar.gz
fi
done

# do HOURLY level backup
cd ~/minecraft  # the WORLD folder resides in root of minecraft folder
tar -cpvzf ${WORLD_NAME}-Hour-0.tar.gz ${WORLD_NAME} >> /dev/null 2>> error.log
mv ${WORLD_NAME}-Hour-0.tar.gz ${BU_HOURLY_PATH}

# Copy newest backup to DAILY if it's 12 am with datestamp
H=$(date +%H) # get hour
if [ "$H" == "00" ]; then
cp -f ${BU_HOURLY_PATH}/${WORLD_NAME}-Hour-0.tar.gz ${BU_DAILY_PATH}/${WORLD_NAME}-Daily-$(date -d "today" +"%Y%m%d").tar.gz
fi

# Remove DAILY saves if they are older than 30 days
# -mtime +30 means any file older than 30 days
find ${BU_DAILY_PATH} -type f -mtime +30 -exec rm -f {} \;

# Let users know the backup is done and re-enable world saving. Also relay the time, because why not.
screen -R ${SCREEN_NAME} -X stuff "save-on $(printf '\r')"
screen -R ${SCREEN_NAME} -X stuff "say Backup complete. World now saving. $(printf '\r')"
printf "\nBackup Complete.\n"

fi

exit 0
