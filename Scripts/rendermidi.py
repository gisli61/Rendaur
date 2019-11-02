#!/usr/bin/env python

import sys
import os
import getopt
import json
import subprocess
import time

__doc__ = """Synopsis:
    Render a directory of midi files into wav files using preset database

Usage:
    rendermidi.py [-d] -p <presetsdir> <mididir>
    rendermidi.py [-h]

Options:
    -h Print this help and exit.
    -p <arg> A path to preset directory. Required

Description:
    Create a directory of midi files with names matching some of the plist
    files in the preset directory. The command will then render each midi file
    into a wav file in the midi file directory using the corresponding preset
    in the preset directory. Each preset must have an accompanying .json file
    containing the name of the plugin and the offset to be used for the preset.
"""

def fail(message):
    print "Error: %s" % message
    raise SystemExit(1)

def assert_file_exists(filename):
    if not os.path.exists(filename):
        fail("File not found: %s"%filename)

def assert_no_file(filename):
    if os.path.exists(filename):
        fail("File exists: Will not overwrite: %s"%filename)

def render(midifile,instrument,presetfile,wavfile,offset=None):
    assert_file_exists(midifile)
    assert_file_exists(presetfile)
    assert_no_file(wavfile)

    midifile = os.path.abspath(midifile)
    presetfile = os.path.abspath(presetfile)
    wavfile = os.path.abspath(wavfile)

    offsetopt = ""
    if offset is not None:
        offsetopt = "with offset %s" % offset

    script = """
        tell application "Rendaur"
        load plugin "%s"
        load preset "%s"
        load midi "%s"
        render into "%s" %s
        quit
        end tell
    """ % (instrument,presetfile,midifile,wavfile,offsetopt)

    arguments = ['osascript','-e',script]

    try:
        res = subprocess.check_output(arguments)
    except:
        fail("Rendaur failed")

def main(presetdir,mididir):
    if not os.path.exists(mididir):
        fail("Directory does not exist: %s"%mididir)
    if not os.path.isdir(mididir):
        fail("Not a directory: %s"%mididir)

    if not os.path.exists(presetdir):
        fail("Directory does not exist: %s"%presetdir)
    if not os.path.isdir(presetdir):
        fail("Not a directory: %s"%mididir)

    plists  = set([x[:-6] for x in os.listdir(presetdir) if x.endswith(".plist")])
    jsons   = set([x[:-5] for x in os.listdir(presetdir) if x.endswith(".json")])
    presets = plists.intersection(jsons)

    midi = [x[:-4] for x in os.listdir(mididir) if x.endswith(".mid")]

    preset_missing = [x for x in midi if x not in presets]
    if len(preset_missing)>0:
        fail("Missing preset for %s"%",".join(preset_missing))

    for m in midi:
        midifile   = mididir+os.sep+m+".mid"
        presetfile = presetdir+os.sep+m+".plist"
        jsonfile   = presetdir+os.sep+m+".json"
        wavfile    = mididir+os.sep+m+".wav"
        f = open(jsonfile)
        plugininfo = json.loads(f.read())
        f.close()
        plugin = plugininfo["plugin"]
        if "offset" in plugininfo:
            offset = int(plugininfo["offset"])
        else:
            offset = 0
        if offset == 0: 
            offset = None
        else:
            offset = str(offset)
        print "Rendering %(mid)s.mid into %(mid)s.wav..." % {"mid":m},
        render(midifile,plugin,presetfile,wavfile,offset=offset)
        print "done."
        #Seem to have to sleep for a little bit in order to give Rendaur
        #change to quit properly. 2 secs work on my machine but it's hard
        #to tell if that's always enough. Better if we can skip quitting altogether.
        time.sleep(2)

if __name__ == '__main__':
    opt,args = getopt.getopt(sys.argv[1:],'hp:')
    opt = dict(opt)

    if len(sys.argv) == 1 or '-h' in opt:
        print __doc__
        raise SystemExit(0)

    if '-p' not in opt:
        fail("preset directory must be specified using -p")

    if len(args) == 0:
        fail("A midi directory must be specified")

    mididir = args[0]
    presetdir = opt['-p']
    main(presetdir,mididir)
