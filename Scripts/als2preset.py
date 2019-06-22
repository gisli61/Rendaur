#!/usr/bin/env python

import sys
import os
import getopt
import gzip
import xml.etree.ElementTree as ET

__doc__ = """Synopsis:
    List and extract Audio Unit presets from Ableton project files (.als files)
Usage:
    als2preset.py -l <alsfile>
    als2preset.py -n <track> [-o <outfile>] <alsfile>
    als2preset.py -h
Options:
    -h Print this help and exit.
    -l List tracks containing presets.
    -n Extract the preset from the track.
    -o Write preset data into file. If omitted, the preset data is
       written to the standard output."""
def getPreset(xmlfile,trackIndex,outputfile):
    root = ET.parse(xmlfile).getroot()
    track = root.getchildren()[0].find('Tracks').getchildren()[trackIndex-1]
    path = 'DeviceChain/DeviceChain/Devices/AuPluginDevice/PluginDesc/AuPluginInfo/Preset/AuPreset/Buffer'

    bufferElement = track.find(path)
    if bufferElement == None:
        raise Exception("No preset found for track!")

    bufferdata = "".join(bufferElement.text.strip().split())
    bufferxml = "".join(chr(int(bufferdata[i:i+2],16)) for i in range(0,len(bufferdata),2))
    if outputfile == None:
        print bufferxml.strip()
    else:
        f = open(outputfile,"w")
        f.write(bufferxml)
        f.close()


def listPresets(xmlfile):
    root = ET.parse(xmlfile).getroot()
    tracks = root.getchildren()[0].find('Tracks').getchildren()
    path = 'DeviceChain/DeviceChain/Devices/AuPluginDevice/PluginDesc/AuPluginInfo'
    
    print "TrackNum,TrackName,Manufacturer,Plugin,PresetName"
    
    trackNumber = 0
    
    for t in tracks:
        trackNumber += 1
        trackId = t.get('Id')
        if trackId == None:
            continue
    
        #print t.find('Name').getchildren()
        trackName = t.find('Name/EffectiveName').get('Value')
        #print t.find('Name/UserName').get('Value')
        #print t.find('Name/Annotation').get('Value')
        #print t.find('Name/MemorizedFirstClipName').get('Value')
        
        auplugininfo = t.find(path)
        if auplugininfo == None:
            continue
        
        nameElement = auplugininfo.find('Name')
        if nameElement == None:
            continue
        pluginName = nameElement.get('Value')

        manufacturerElement = auplugininfo.find('Manufacturer')
        if manufacturerElement == None:
            continue
        pluginManufacturer = manufacturerElement.get('Value')

        auPresetElement = auplugininfo.find('Preset/AuPreset')
        if auPresetElement == None:
            continue
        
        presetNameElement = auPresetElement.find('Name')
        if presetNameElement == None:
            continue
        presetName = presetNameElement.get('Value')

        print ",".join([str(trackNumber),trackName,pluginManufacturer,pluginName,presetName])
    #print(len(miditracks))

def main(alsfile,index=None,list=False,outputfile=None):
    f = gzip.open(alsfile)
    if list:
        listPresets(f)
    else:
        getPreset(f,index,outputfile)
    f.close()

if __name__ == '__main__':
    opt,args = getopt.getopt(sys.argv[1:],"hln:o:")
    opt = dict(opt)
    
    if len(sys.argv) == 1 or '-h' in opt:
        print __doc__
        raise SystemExit(0)
    
    if len(args) != 1 or ('-l' not in opt and '-n' not in opt):
        print __doc__
        raise SystemExit(1)

    alsfile = args[0]
    
    index = None
    if '-n' in opt:
        index = int(opt['-n'])

    outputfile = None
    if '-o' in opt:
        outputfile = opt['-o']
        if os.path.exists(outputfile):
            print "###Error:File exists:Will not overwrite:%s"%outputfile
            raise SystemExit(1)
    
    main(alsfile,index,list=('-l' in opt),outputfile = outputfile)
