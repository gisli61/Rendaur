#!/usr/bin/env python

import sys
import os
import getopt
import subprocess

__doc__ = """Synopsis:
    A command line interface to the mac application Rendaur.

Usage:
    rendaur.py -l
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

def fail(message):
    print "Error: %s" % message
    raise SystemExit(1)

def assert_file_exists(filename):
    if not os.path.exists(filename):
        fail("File not found: %s"%filename)

def assert_no_file(filename):
    if os.path.exists(filename):
        fail("File exists: Will not overwrite: %s"%filename)

def find_rendaur():
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
    rendaur_path = find_rendaur()
    try:
        res = subprocess.check_output([rendaur_path,'list'])
    except:
        fail("Rendaur failed")

    for r in res.strip().split():
        print r

def render(midifile,instrument,presetfile,wavfile,offset=None):
    rendaur_path = find_rendaur()
    assert_file_exists(midifile)
    assert_file_exists(presetfile)
    assert_no_file(wavfile)

    arguments = [rendaur_path,"render",midifile,instrument,presetfile,wavfile]
    if offset != None:
        arguments += offset

    res = subprocess.check_output(arguments)
    if "###Error" in res:
        fail("Rendering failed: %s"%res.strip())

if __name__ == '__main__':
    if len(sys.argv) == 1 :
        print __doc__
        raise SystemExit

    opt,args = getopt.getopt(sys.argv[1:],'hlm:i:p:o:O:')
    opt = dict(opt)

    if '-h' in opt:
        print __doc__
        raise SystemExit

    if len(args) != 0:
        fail("Invalid arguments")

    if '-l' in opt:
        list_instruments()
    elif '-m' in opt and '-i' in opt and '-p' in opt and '-o' in opt:
        midifile   = opt['-m']
        instrument = opt['-i']
        presetfile = opt['-p']
        wavfile    = opt['-o']
        render(midifile,instrument,presetfile,wavfile,offset=opt.get('-O'))
    else:
        fail("Wrong arguments. Run with -h to see documentation")
