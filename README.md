# Rendaur

Rendaur is a MacOSX application that can open up an audio unit midi instrument, load a preset for the instrument
and a midi file and then render the midi file off-line into a 48k 32bit float wav file.

It can run both as a normal mac application and also as from the command line script via the script rendaur.py in the
Scripts folder.

## Application
The user interface lets the user to change the settings of the instrument and save the modified settings in a preset file.
It also allows the user to play the midi file using the instrument.

### Requirements
This is an XCode 10.2 project written in swift 5. It is developed on Mojave (10.14) but set to build on 10.13 or later. It depends only on Apple standard libraries so it should build out of the box if the already mentioned requirements are fulfilled.

### Issues and workarounds
After trying on several audio units, it seems like the audio units have their own policies regarding the render 
start. There are
at least some that do some sort of short fade-in at the start and it is possible that some audio units introduce a
slight delay before starting the actual rendering. These issues must be addressed, but it is nearly impossible
to do that in code, unless a special provision is made for each audio unit. A better way is perhaps to allow the user
to specify a pre-rendering pad at the start that will not be included in the output and perhaps also a shift so that
the first frames in the output are ignored (and an equal amout is padded at the end to make the final product have
correct number of frames).

The current workarounds are to render the audio twice, first without writing any data and only use the second-round
rendering. In addition, the user can correct for latency.

## Scripts

### rendaur.py
A script that runs the Rendaur app from the command line and can render a single source file (midi or wav) using
a single audio unit with a preset into a 32-bit float wav file. Can also list the audio units that exist on the
system. The script needs the application to work, but uses osascript to communicate with the application, so they
need not be in the same location.

### als2preset.py
A script that analyses an Ableton project file (.als) and finds presets stored in that file. Can list the
presets contained in a project file, extract a given preset into a file that can be read by rendaur.py and dump all
the presets found in an .als file into a folder.

### readwav.py
A script that can read a wav file, inspect the header and extract a region as an array of values.

### plot_array.py
Reads an array of values on the standard input and plots each column in a window as a curve. Useful to
view the output from readwav.py. Requires matplotlib.

### writewav.py
creates a 32-bit 48k wav file from an array of floats read from the standard input. The inverse of readwav.py

### rendermidi.py
Batch renders a set of midi files into wav files.
 
