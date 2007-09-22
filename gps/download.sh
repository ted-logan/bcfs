#!/bin/sh

DATE=`date +%F`

echo "Downloading waypoints"
gpsbabel -i garmin -f /dev/ttyS0 -o gpx -F waypoints-$DATE.gpx || exit

echo "Downloading track"
gpsbabel -t -i garmin -f /dev/ttyS0 -o gpx -F track-$DATE.gpx || exit

echo "Downloading routes"
gpsbabel -r -i garmin -f /dev/ttyS0 -o gpx -F route-$DATE.gpx || exit

rsync -av --progress *-$DATE.gpx ziyal:gps/
rsync -avz --progress track-$DATE.gpx honor.festing.org:/tmp
ssh honor.festing.org src/bcfs/bin/import_and_export_track.sh \
	/tmp/track-$DATE.gpx
rsync -av --progress honor.festing.org:web/jaeger.festing.org/jaeger.kmz \
	../jaeger.kmz
