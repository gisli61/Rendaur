#!/bin/bash

set -eo pipefail

#  rendaur.sh
#  PluginViewer
#
#  Created by Gísli Másson on 10/06/2019.
#  Copyright © 2019 Gísli Másson. All rights reserved.

#May want to find a way to locate this one automatically

#POSIX path of (application file id (id of application "PluginViewer") as alias)
PLUGINVIEWER=$(osascript -e 'tell application "Finder" to POSIX path of (application file id "com.gislimasson.PluginViewer" as alias)')

##echo ${PLUGINVIEWER}

##PLUGINVIEWER=/Users/gislim/Library/Developer/Xcode/DerivedData/PluginViewer-ggnamhngbicvthebwgykmsfpopes/Build/Products/Debug/PluginViewer.app

if [ "$1" == "" ] || [ "$1" == "-h" ]
then
echo "Synopsis:"
echo "    Render a midi file into a wav file using an Audio Unit and a preset"
echo "Usage:"
echo "    $0 <midifile> <instument> <preset> <wavfile>"
echo "    $0 -l"
echo "    $0 [-h]"
echo "Options:"
echo "    -h Display this help and exit"
echo "    -l List all instruments and exit"
exit 0
fi

if [ "$1" == "-l" ]
then
${PLUGINVIEWER}/Contents/MacOS/PluginViewer list
exit 0
fi

MIDIFILE=$1
PLUGIN=$2
PRESET=$3
OUTFILE=$4

if [ "$4" == "" ]
then
echo "###Error: Arguments missing"
exit 1
fi

${PLUGINVIEWER}/Contents/MacOS/PluginViewer render ${MIDIFILE} ${PLUGIN} ${PRESET} ${OUTFILE}

#It may also be an option to use osascript to interact with the program, e.g.
#osascript -e 'tell application "PluginViewer" to run'
#osascript -e 'tell application "PluginViewer" to quit'
