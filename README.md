# Rendaur

Rendaur is a MacOSX application that can open up an audio unit midi instrument, load a preset for the instrument
and a midi file and then render the midi file off-line into a 48k 32bit float wav file.

It can run both as a normal mac application and also as from the command line script via the script rendaur.sh in the
Scripts folder.

## GUI
The user interface lets the user to change the settings of the instrument and save the modified settings in a preset file.
It also allows the user to play the midi file using the instrument.

## Scripts

### rendaur.sh
A script that runs the Rendaur app from the command line and can render a single midifile using
a single audio unit with a preset into a 32-bit float wav file. Can also list the audio units that exist on the
system. The script needs the application to work, but uses osascript to locate the application, so they
need not be in the same location.

### als2preset.py
A script that analyses an Ableton project file (.als) and finds presets stored in that file. Can list the
presets contained in a project file, extract a given preset into a file that can be read by rendaur.sh and dump all
the presets found in an .als file into a folder.

### readwav.py
A script that can read a wav file, inspect the header and extract a region (as an array of values) 
 
