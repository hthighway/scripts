#
#
# post-processing script for radarr that will set audio language of the MKV to English
# Update just the movie folder in Plex, not the entire library
# Empty Trash - incase this is a replacement for a previous version
#
#

#!/bin/bash 

Event=$radarr_eventtype
PLEXLIBRARY=1   #Get this by hovering over library in the web interface
TIMEOUT=600     # In seconds
SCANFILE=$radarr_moviefile_path
SCANFOLDER=$radarr_movie_path
MODDATE=$(stat -c %Y "$SCANFILE")

if [[ $Event == Download ||  $Event == Upgrade  ||  $Event == Rename ]]; then  
      /usr/bin/mkvpropedit -s title="" "$SCANFILE"   
      /usr/bin/mkvpropedit --edit track:a1 --set language=eng --edit track:v1 --set language=eng "$SCANFILE"   
      touch -d @$MODDATE "$SCANFILE"
  i=0
  while pidof -o %PPID -x "$(basename $0)"
  do
      echo "Already scanning..."
      sleep 1
      i=$((i+1))
      if [ $i -gt $TIMEOUT ]
      then
          echo "Timed out waiting for other scanners to finish."
          exit 1
      fi
  done

  export LD_LIBRARY_PATH=/usr/lib/plexmediaserver 
  export PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=/var/lib/plexmediaserver/Library/Application\ Support
  /usr/lib/plexmediaserver/Plex\ Media\ Scanner -s -r -c $PLEXLIBRARY -d "$SCANFOLDER" > /dev/null 2>&1
  sleep 8
 

 
  i=0
  while pidof -o %PPID -x "$(basename $0)"
  do
    echo "Already scanning..."
    sleep 1
    i=$((i+1))
    if [ $i -gt $TIMEOUT ]
    then
      echo "Timed out waiting for other scanners to finish."
      exit 1
    fi
  done
  curl -X PUT http://127.0.0.1:32400/library/sections/$PLEXLIBRARY/emptyTrash?X-Plex-Token=xxxxxxxxxxxxxx > /dev/null 2>&1
  echo "Plex Library Updated"

fi
exit 

11
