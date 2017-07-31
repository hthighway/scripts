#!/bin/bash
## PLEX SCAN ONLY NEW/MODIFED FOLDERS SINCE LAST RUN
## This file is a modified version of the one found here:
## https://github.com/ajkis/scripts/blob/master/plex/plex-scan-new.sh
## OS: Linux Ubuntu 16.04
## Make script executable by chmod a+x plex-scan-new.sh
## Add script to crontab -e ( paste the line bellow without ## )
## */15 * * * *   /path to script/plex-update-libraries.sh >/dev/null 2>&1
## Make sure you disable all Plex automatic & scheduled library scans.
if pidof -o %PPID -x "$0"; then
   echo "$(date "+%d.%m.%Y %T") Exit, already running."
   exit 1
fi

#SETTINGS
MOVIELIBRARY="/plexmedia/media/Movies/"
MOVIESECTION=1
TVLIBRARY="/plexmedia/media/TV Shows/"
TVSECTION=2
USERN=user
LOGFILE="/home/$USERN/scripts/logs/plex-update-libraries.log"
FOLDERLISTFILE="/home/$USERN/.cache/folderlistfile"
LASTRUNFILE="/home/$USERN/.cache/lastrunfile"
PTOKEN="XXXXXXXXXXXXXXXXXX"

systemctl is-active plexunion >/dev/null 2>&1 && PU=1 || PU=0
systemctl is-active plexdrive >/dev/null 2>&1 && PD=1 || PD=0 
systemctl is-active plexmediaserver >/dev/null 2>&1 && PMS=1 || PMS=0
if [ $PD -eq 1 ] && [ $PU -eq 1 ] && [ $PMS -eq 1 ]
then

	export LD_LIBRARY_PATH=/usr/lib/plexmediaserver
	export PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=/var/lib/plexmediaserver/Library/Application\ Support

	echo "$(date "+%d.%m.%Y %T") PLEX SCAN FOR NEW/MODIFIED FILES AFTER: $(date -r $LASTRUNFILE)"

	if [[ -f "$FOLDERLISTFILE" ]]; then
    		echo "Removing previous folder list"
    		rm $FOLDERLISTFILE
	fi

	start=$(date +'%s')
	startmovies=$(date +'%s')
	echo "Scaning for new files: $MOVIELIBRARY"
	find "$MOVIELIBRARY" -mindepth 1 -type f -cnewer $LASTRUNFILE |
	while read mfile; do
        	echo "$(date "+%d.%m.%Y %T") New file detected: $mfile" | tee -a "$LOGFILE"
        	MFOLDER=$(dirname "${mfile}")
        	echo "$MFOLDER" | tee -a "$FOLDERLISTFILE"
	done	
	echo "$(date "+%d.%m.%Y %T") Movie files scanned in $(($(date +'%s') - $startmovies)) seconds" | tee -a "$LOGFILE"

	startseries=$(date +'%s')
	echo "Scaning for new files: $TVLIBRARY"
	find "$TVLIBRARY" -mindepth 2 -type f -cnewer $LASTRUNFILE |
	while read tvfile; do
        	echo "$(date "+%d.%m.%Y %T") New file detected: $tvfile" | tee -a "$LOGFILE"
        	TVFOLDER=$(dirname "${tvfile}")
        	echo "$TVFOLDER" | tee -a "$FOLDERLISTFILE"
	done
	echo "$(date "+%d.%m.%Y %T") TV folders scanned in $(($(date +'%s') - $startseries)) seconds" | tee -a "$LOGFILE"

	echo "$(date "+%d.%m.%Y %T") Move & TV folders scanned in $(($(date +'%s') - $start)) seconds" | tee -a "$LOGFILE"
	echo "$(date "+%d.%m.%Y %T") Setting lastrun for next folder scans" | tee -a "$LOGFILE"
	#touch $LASTRUNFILE
	echo "$(date "+%d.%m.%Y %T") Remove duplicates" | tee -a "$LOGFILE"
	sort "$FOLDERLISTFILE" | uniq | tee "$FOLDERLISTFILE"

	startplexscan=$(date +'%s')
	echo "$(date "+%d.%m.%Y %T") Plex scan started" | tee -a "$LOGFILE"
	readarray -t FOLDERS < "$FOLDERLISTFILE"
	for FOLDER in "${FOLDERS[@]}"
	do
    	if [[  $FOLDER == "$MOVIELIBRARY"* ]]; then
        	echo "$(date "+%d.%m.%Y %T") Plex scan movie folder:: $FOLDER" | tee -a "$LOGFILE"
        	$LD_LIBRARY_PATH/Plex\ Media\ Scanner --scan --refresh --section "$MOVIESECTION" --directory "$FOLDER" | tee -a "$LOGFILE"
        	        touch -d "1 hours ago" $LASTRUNFILE      
    	elif [[  $FOLDER == "$TVLIBRARY"* ]]; then
        	echo "$(date "+%d.%m.%Y %T") Plex scan TV folder: $FOLDER" | tee -a "$LOGFILE"
        	$LD_LIBRARY_PATH/Plex\ Media\ Scanner --scan --refresh --section "$TVSECTION" --directory "$FOLDER" | tee -a "$LOGFILE"
                        touch -d "1 hours ago" $LASTRUNFILE      
	fi
	done
	echo "$(date "+%d.%m.%Y %T") Plex scan finished in $(($(date +'%s') - $startplexscan)) seconds" | tee -a "$LOGFILE"

	echo "$(date "+%d.%m.%Y %T") Scan completed in $(($(date +'%s') - $start)) seconds" | tee -a "$LOGFILE"

	PLEXDB="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"

	delmetada=$(sqlite3 "$PLEXDB" "SELECT count(*) FROM metadata_items WHERE deleted_at is not null")
	delparts=$(sqlite3 "$PLEXDB" "SELECT count(*) FROM media_parts WHERE deleted_at is not null")
	delitems=$(($delmetada+$delparts))
	echo "Deleted metadata_items: $delitems"
	if [[ $delitems -gt 1 ]] && [[ $delitems -lt 150 ]]; then
  		echo "$(date "+%d.%m.%Y %T") Empty trash, deleted metadata = $delmetada , parts = $delparts " | tee -a "$LOGFILE"
  		curl -X PUT -H "X-Plex-Token: $PTOKEN" http://127.0.0.1:32400/library/sections/1/emptyTrash
  		/bin/sleep 10
        	curl -X PUT -H "X-Plex-Token: $PTOKEN" http://127.0.0.1:32400/library/sections/2/emptyTrash
	fi


	# Remove unionFS hidden files created by Radarr/Sonarr removing older content
  	find /plexmedia/media/.unionfs-fuse -type f -name '*_HIDDEN~' | while read line; do
  		oldPath=${line#/plexmedia/media/.unionfs-fuse}
  		newPath=GD:/plexmedia_clear${oldPath%_HIDDEN~}
  		echo "$newPath"
  		echo "$line"
  		/usr/bin/rclone delete "$newPath" --config=/home/hawk/.config/rclone/rclone.conf
  		rm "$line"
  	done
  	find "/plexmedia/media/.unionfs-fuse" -mindepth 1 -type d -empty -delete     
	#
fi
exit
