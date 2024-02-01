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

# ONLY FIRST run of the server setup :
# cd ~/minecraft
# java -Xmx1024M -Xms1024M -jar server.jar nogui
# This will setup the environment, and FAIL. You will need to edit the eula.txt
#       nano eula.txt
#       change false to true
# Re-run : java -Xmx1024M -Xms1024M -jar server.jar nogui
# When you see the word "Done", the server is running.
#
# to kill the server: /stop


# Folder Structure
# ================
#
# minecraft/
# ├── banned-ips.json
# ├── banned-players.json
# ├── bu
# │   ├── daily
# │   └── hourly
# ├── error.log
# ├── eula.txt
# ├── libraries
# ├── logs
# ├── ops.json
# ├── scripts
# │   ├── mcbu.sh
# │   └── run.sh
# ├── server.jar
# ├── server.properties
# ├── usercache.json
# ├── versions
# ├── whitelist.json
# └── world

# Don't forget to add a new crontab to make this script run hourly
#
# Type: crontab -l to get a list of all cronjobs
#
# Type: crontab -e
#
# This will open up the crontab editor.
# Add the following line to run mcbu.sh every hour on the hour:
# Be sure to REMOVE the # so it isn't commented out !!!
# 0 * * * * /home/<USERNAME>/minecraft/scripts/mcbu.sh -c > /dev/null

# Make my player an admin : screen -R Server1 -X stuff "op <Account_Name>$(printf '\r')"
# Godmode                 : /effect give <Account_Name> minecraft:resistance 9999 255       # seconds / amplifier

SERVER_JAR_NAME=server.jar

SCREEN_NAME=Server1                   # Name of SCREEN session from run.sh
BU_HOURLY_PATH=~/minecraft/bu/hourly  # Where the HOURLY backups will be stored
BU_DAILY_PATH=~/minecraft/bu/daily    # Where the DAILY backups will be stored
WORLD_NAME=world                      # Name of the world folder

# Check if the minecraft server is running
RESULT=`ps aux | grep "${SERVER_JAR_NAME}"`
if [ "${RESULT:-null}" = null ]; then #if the RESULT from the previous command is null
echo "Minecraft Server is not running, not backing up."
exit 1
else
# Let users know of the backup and turn off world saving temporarily
screen -R ${SCREEN_NAME} -X stuff "/say Backup starting. World no longer saving... $(printf '\r')"
screen -R ${SCREEN_NAME} -X stuff "/save-off $(printf '\r')"
screen -R ${SCREEN_NAME} -X stuff "/save-all $(printf '\r')"
sleep 3

# change working directory to the hourly backup folder
cd ${BU_HOURLY_PATH}


# Rotate hourly backups
# Start from 23...if 23 exists...make it 24. Now if 22 exists...make it 23.
# Continue until reach 00...make it 01. The NEW save will be named 00.
for i in {23..00};
do
if [ -e ${WORLD_NAME}-Hour-$i.tar.gz ]; then # but only execute the following commands if the file exists
hP=$( echo "$i+1" |bc );

# Add leading zero if $hP is less that 10
if [[ $hP -lt 10 ]]; then
XX=0$hP # add leading zero
else
XX=$hP  # no leading zero
fi

mv ${WORLD_NAME}-Hour-$i.tar.gz ${WORLD_NAME}-Hour-$XX.tar.gz
fi
done


# After all the old saves have been re-ordered from 01-24
# This new save will have the number 00.
# do HOURLY level backup
cd ~/minecraft  # the WORLD folder resides in root of minecraft folder
tar -cpvzf ${WORLD_NAME}-Hour-00.tar.gz ${WORLD_NAME} >> /dev/null 2>> error.log
mv ${WORLD_NAME}-Hour-00.tar.gz ${BU_HOURLY_PATH}

# Copy newest backup to DAILY if it's 12 am with datestamp
H=$(date +%H) # get hour
if [ "$H" == "00" ]; then
cp -f ${BU_HOURLY_PATH}/${WORLD_NAME}-Hour-00.tar.gz ${BU_DAILY_PATH}/${WORLD_NAME}-Daily-$(date -d "today" +"%Y%m%d").tar.gz
fi

# Remove DAILY saves if they are older than 30 days
# -mtime +30 means any file older than 30 days
find ${BU_DAILY_PATH} -type f -mtime +30 -exec rm -f {} \;

# Let the users in-game know the backup is done and re-enable world saving.
screen -R ${SCREEN_NAME} -X stuff "/save-on $(printf '\r')"
screen -R ${SCREEN_NAME} -X stuff "/say Backup complete. World now saving. $(printf '\r')"
printf "\nBackup Complete.\n"

fi

exit 0
