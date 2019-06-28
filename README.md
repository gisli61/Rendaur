# Rendaur

Rendaur is a MacOSX application that can open up an audio unit midi instrument, load a preset for the instrument
and a midi file and then render the midi file off-line into a 48k 32bit float wav file. 

# GUI
The user interface lets the user to change the settings of the instrument and save the modified settings in a preset file.
It also allows the user to play the midi file using the instrument.

# CLI

The application comes with a helper script, rendaur.sh, that allows the user to render midi files into wav directly
from the command line. The script needs the application to work, but uses osascript to locate the application, so they
need not be in the same location.
