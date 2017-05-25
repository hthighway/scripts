#
#
# This will upload all content in your local folder of the UnionFS mount
# that are older than X days
# additionally it will parse the .unionfs-fuse folder and based on the "hidden" tag it will delete the corisponding file on GDrive
#
#

#!/bin/bash

#get date
_now=$(date +"%m_%d_%Y")
DAYS=5d   #use xd for days, xm for mintures, or x for seconds

# Define PID file
PIDFILE=/home/user/griveupload.pid
# Check if PID file exists, if it does, check it's valid, and if not create new
if [ -f $PIDFILE ] 
then
  PID=$(cat $PIDFILE)
  ps -p $PID > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "Rclone GD upload already running"
    exit 1
  else
    ## If process not found assume not running
    echo $$ > $PIDFILE
    if [ $? -ne 0 ]
    then
      echo "Unable to create PID file"
      exit 1
    fi
  fi
else
  echo $$ > $PIDFILE
  if [ $? -ne 0 ]
  then
    echo "Unable to create PID file"
    exit 1
  fi
fi

##
# Remove unionFS hidden files created by Radarr removing older content
# credit this portion to @numberedthought :)
#
find /plexmedia/media/.unionfs-fuse -name '*_HIDDEN~' | while read line; do
oldPath=${line#/plexmedia/media/.unionfs-fuse}
newPath=GD:/plexmedia_clear${oldPath%_HIDDEN~}
echo "$newPath"
echo "$line"
/usr/bin/rclone delete "$newPath"
rm "$line"
done
find "/plexmedia/media/.unionfs-fuse" -mindepth 1 -type d -empty -delete     
#
##

# Run the sync job
_logfile="/home/user/scripts/logs/rclone_$_now.log" 
/usr/bin/rclone move /plexmedia/local GD:media_folder -v --exclude="/.unionfs-fuse/**" --transfers=10 --checkers=10 --min-age=$DAYS --no-traverse --log-file=$_logfile

# remove the PID file
rm $PIDFILE
