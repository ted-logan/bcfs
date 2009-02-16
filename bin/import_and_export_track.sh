#!/bin/sh

~/src/bcfs/bin/import_track.pl $1 || exit
rm $1
cd /tmp || exit
~/src/bcfs/bin/make_kml.pl > doc.kml || exit
zip jaeger.kmz doc.kml || exit
mv jaeger.kmz ~/web/jaeger.festing.org/
rm doc.kml
