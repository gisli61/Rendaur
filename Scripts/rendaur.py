#!/usr/bin/env python

import sys
import os
import getopt
import subprocess

__doc__ = """Synopsis:
    A command line interface to the mac application Rendaur.

Usage:
    rendaur.py -l
    rendaur.py -I -i <instrument> [-p <preset>]
    rendaur.py -m <midifile> -i <instrument> -p <preset> -o <wavfile> [-O <latency>]
    rendaur.py [-h]

Options:
    -h print this help and exit
    -l list the instruments available on the system
    -m <arg> The midi file to be rendered
    -i <arg> The instrument to be used
    -p <arg> The preset to be used.
    -o <arg> The output wavfile
    -O <arg> Offset in frames from start to start render.
             Use to get rid of latency in some plugin/preset combinations
"""

#TODO: Modify all calls when we have applescript support in Rendaur

#TODO: Consider the right strategy if Rendaur is already running. May
# want to allow user to preload instrument and preset and then just render
# various midi files. E.g. if user is modifying the settings from user interface

#TODO: Look at https://stackoverflow.com/questions/16065162/calling-applescript-from-python-without-using-osascript-or-appscript
# to avoid system calls when using applescript.

def fail(message):
    print "Error: %s" % message
    raise SystemExit(1)

def assert_file_exists(filename):
    if not os.path.exists(filename):
        fail("File not found: %s"%filename)

def assert_no_file(filename):
    if os.path.exists(filename):
        fail("File exists: Will not overwrite: %s"%filename)

def assert_not_running():
    arguments = [
        'osascript',
        '-e',
        '''if application "Rendaur" is running then
            set a to "running"
            else
            set a to ""
            end if
            a
        '''
    ]
    try:
        res = subprocess.check_output(arguments)
    except:
        fail("Unknown error occured")
    res = res.strip()
    if res != "":
        fail("Rendaur is running. Quit before running the script")

def assert_app_exists():
    try:
        res = subprocess.check_output([
            'osascript',
            '-e',
            """tell application "Finder" to POSIX path of (application file id "com.gislimasson.Rendaur" as alias)"""
        ])
    except subprocess.CalledProcessError:
        fail("Could not find application Rendaur. Is is installed on the system?")
    except:
        fail("Uknown error")

    return res.strip()+"Contents/MacOS/Rendaur"

def list_instruments():
    try:
        res = subprocess.check_output([
            'osascript',
            '-e',
            """tell application "Rendaur"
                   set a to list plugins
                   quit
               end tell
               a
            """
        ])
    except:
        fail("Rendaur failed")

    for r in res.strip().split(","):
        print r

def info(instrument,presetfile):
    if presetfile is None:
        script = """
            tell application "Rendaur"
            load plugin "%s"
            set a to get info
            quit
            end tell
            a
        """ % instrument
    else:
        if not os.path.exists(presetfile):
            fail("File not found: %s" % presetfile)
        presetfile = os.path.abspath(presetfile)
        script = """
            tell application "Rendaur"
            load plugin "%s"
            load preset "%s"
            set a to get info
            quit
            end tell
            a
            """ % (instrument,presetfile)
    arguments = [
        'osascript',
        '-e',
        script
    ]
    try:
        res = subprocess.check_output(arguments)
        print res.strip()
    except:
        fail("Rendaur failed")

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

if __name__ == '__main__':
    if len(sys.argv) == 1 :
        print __doc__
        raise SystemExit

    opt,args = getopt.getopt(sys.argv[1:],'hlIm:i:p:o:O:')
    opt = dict(opt)

    if '-h' in opt:
        print __doc__
        raise SystemExit

    if len(args) != 0:
        fail("Invalid arguments")

    if '-l' in opt:
        assert_app_exists()
        assert_not_running()
        list_instruments()
    elif '-I' in opt and '-i' in opt:
        assert_app_exists()
        assert_not_running()
        instrument = opt['-i']
        info(instrument,opt.get('-p'))
    elif '-m' in opt and '-i' in opt and '-p' in opt and '-o' in opt:
        assert_app_exists()
        assert_not_running()
        midifile   = opt['-m']
        instrument = opt['-i']
        presetfile = opt['-p']
        wavfile    = opt['-o']
        render(midifile,instrument,presetfile,wavfile,offset=opt.get('-O'))
    else:
        fail("Wrong arguments. Run with -h to see documentation")
