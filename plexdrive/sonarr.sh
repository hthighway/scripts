#!/bin/bash 

Event=$sonarr_eventtype
Episode=$sonarr_episodefile_path
Series=$sonarr_series_title
SCANDIR=$sonarr_series_path
PLEXLIBRARY=2 #Get this by hovering over library in the web interface
TIMEOUT=600 # In seconds
MODDATE=$(stat -c %Y "$Episode")


if [[ $Event == Download ||  $Event == Upgrade  ||  $Event == Rename ]]; then  
      # Make sure each MVK has the audio lang set to ENGLISH
	  /usr/bin/mkvpropedit -s title="" "$Episode"   
      /usr/bin/mkvpropedit --edit track:a1 --set language=eng --edit track:v1 --set language=eng "$Episode"   
      touch -d @$MODDATE "$Episode"
		#  sets file date back to origianl date

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
   /usr/lib/plexmediaserver/Plex\ Media\ Scanner -s -r -c $PLEXLIBRARY -d "$SCANDIR" > /dev/null 2>&1
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

    curl -X PUT http://127.0.0.1:32400/library/sections/$PLEXLIBRARY/emptyTrash?X-Plex-Token=xxxxxxxxxxxxx > /dev/null 2>&1
    echo "Plex Library Updated"  

fi

exit 

