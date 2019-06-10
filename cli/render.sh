#!/bin/bash

#  render.sh
#  PluginViewer
#
#  Created by Gísli Másson on 10/06/2019.
#  Copyright © 2019 Gísli Másson. All rights reserved.

#May want to find a way to locate this one automatically
PLUGINVIEWER=/Users/gislim/Library/Developer/Xcode/DerivedData/PluginViewer-ggnamhngbicvthebwgykmsfpopes/Build/Products/Debug/PluginViewer.app

MIDIFILE=$1
PLUGIN=$2
OUTFILE=$3

${PLUGINVIEWER}/Contents/MacOS/PluginViewer render ${MIDIFILE} ${PLUGIN} ${OUTFILE}

#It may also be an option to use osascript to interact with the program, e.g.
#osascript -e 'tell application "PluginViewer" to run'
#osascript -e 'tell application "PluginViewer" to quit'
