#  PluginViewer

Can be run as a normal mac application or from command line using cli/raunder.sh

## Helper scripts

### rendaur.sh
A script that runs the PluginViewer app from the command line and can render a single midifile using
a single audio unit with a preset into a 32-bit float wav file. Can also list the audio units that exist on the
system

### als2preset.py
A script that analyses an Ableton project file (.als) and finds presets stored in that file. Can both list the
presets contained in a project file and extract a given preset into a file that can be read by rendaur.sh

### readwav.py
A script that can read a wav file, inspect the header and extract a region (as an array of numbers) 

## Outstanding issues

1. Check for match (manufacturer, type, subtype) with current plugin when loading presets
2. Fix layout issues in window.
3. play/render doesn't work after render has been run once
4. Allow user to specify pad at end of song (to allow for reverb etc). Default to 0.
5. Support true float 32bit (**DONE**)
6. Full AppleScript support
7. Combine play/stop button and make machine stop after song ends
8. Enable/Disable buttons appropriately in UI
9. Let functions in CLI report errors and stop processing on errors (if load plugin fails, there is no point to continue)
10. Create a program to extract AU presets out of ALS files (**DONE**: als2preset.py)
11. Set menus up correctly
12. Allow user to save current AU settings as presets
13. Display parameters (fullparametertree) for audio units.
14. Add Generic view for AU without a custom view.
15. First buffer returned by render contains only 0. Contemplate to skip
16. Currently the length in frames is a multiple of 512. Remove that constriction (**DONE**)
17. Figure out why fade in occurs at start of file for some AU and fix/find workaround.
18. Current maximum length is 60 sec (23MB). Allow user to override that restriction.

## Boundary issues
In relation to issue 17, it seems like the audio units have their own policies regarding the render start. There are
at least some that do some sort of short fade-in at the start and it is possible that some audio units introduce a
slight delay before starting the actual rendering. These issues must be addressed, but it is nearly impossible
to do that in code, unless a special provision is made for each audio unit. A better way is perhaps to allow the user
to specify a pre-rendering pad at the start that will not be included in the output and perhaps also a shift so that
the first frames in the output are ignored (and an equal amout is padded at the end to make the final product have
correct number of frames)

