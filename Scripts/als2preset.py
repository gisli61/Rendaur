#!/usr/bin/env python

import sys
import os
import getopt
import gzip
import xml.etree.ElementTree as ET
import json

__doc__ = """Synopsis:
    List and extract Audio Unit presets from Ableton project files (.als files)
Usage:
    als2preset.py list <alsfile>
    als2preset.py get -n <track> [-o <outfile>] <alsfile>
    als2preset.py dump -o <outdir> <alsfile>
    als2preset.py [-h]
Options:
    -h Print this help and exit
    -n Extract the preset from the track.
    -o Destination for written data. If omitted in get, the preset data is
       written to the standard output. Required argument in dump"""

def get_preset(xmlfile,trackIndex,outputfile):
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

def dump_presets(xmlfile,outputfolder):
    root = ET.parse(xmlfile).getroot()
    tracks = root.getchildren()[0].find('Tracks').getchildren()
    path = 'DeviceChain/DeviceChain/Devices/AuPluginDevice/PluginDesc/AuPluginInfo'
    bufferpath = 'Preset/AuPreset/Buffer'
    
    trackNumber = 0
    
    for t in tracks:
        trackNumber += 1
        trackId = t.get('Id')
        if trackId == None:
            continue
    
        #print t.find('Name').getchildren()
        preset_name = t.find('Name/EffectiveName').get('Value')
        print "Extracting %s" % preset_name
        if os.path.exists(outputfolder+os.sep+preset_name+".plist"):
            print("  %s.plist already exists. Skipping."%preset_name)
            continue
        elif os.path.exists(outputfolder+os.sep+preset_name+".json"):
            print("  %s.json already exists. Skipping."%preset_name)
            continue

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

        bufferelement = auplugininfo.find(bufferpath)
        if bufferelement == None:
            continue

        bufferdata = "".join(bufferelement.text.strip().split())
        bufferxml = "".join(chr(int(bufferdata[i:i+2],16)) for i in range(0,len(bufferdata),2))

        preset_info = {'plugin':pluginName,'offset':0}

        json_data = json.dumps(preset_info,indent=4,separators=(',', ': '))

        f = open(outputfolder+os.sep+"%s.plist"%preset_name,'w')
        f.write(bufferxml)
        f.close()

        f = open(outputfolder+os.sep+"%s.json"%preset_name,'w')
        f.write(json_data)
        f.close()

        print("  wrote %s.plink and %s.json"%(preset_name,preset_name))


        #print trackName,pluginName,len(bufferxml)

        #print ",".join([str(trackNumber),trackName,pluginManufacturer,pluginName,presetName])


def list_presets(xmlfile):
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

def cmd_dump(args):
    opt,args = getopt.getopt(args,'o:')
    opt = dict(opt)

    alsfile = args[0]

    if '-o' not in opt:
        raise Exception("Error: Required argument -o missing")

    outputfolder = opt['-o']

    if not os.path.exists(outputfolder) or not os.path.isdir(outputfolder):
        raise Exception("Error: %s is not a writable folder" % outputfolder)

    f = gzip.open(alsfile)

    dump_presets(f,outputfolder)

    f.close()

def cmd_get(args):
    opt,args = getopt.getopt(args,'n:o:')
    opt = dict(opt)

    if '-n' not in opt:
        raise Exception("Error: Required argument -n missing")

    trackIndex = int(opt['-n'])

    alsfile = args[0]

    f = gzip.open(alsfile)

    get_preset(f,trackIndex,opt.get('-o'))

    f.close()

def cmd_list(args):
    
    alsfile = args[0]

    f = gzip.open(alsfile)

    list_presets(f)

    f.close()

if __name__ == '__main__':

    if len(sys.argv) == 1:
        print __doc__
        raise SystemExit(0)

    command = sys.argv[1]

    if command not in ('list','dump','get'):
        opt,args = getopt.getopt(sys.argv[1:],'hv')
        opt = dict(opt)
        if '-h' in opt:
            print __doc__
            raise SystemExit(0)
        elif '-v' in opt:
            print __version__
            raise SystemExit(0)
        else:
            raise Exception("Error: Unknown command: %s" % command)

    if command == 'get':
        cmd_get(sys.argv[2:])
    elif command == 'list':
        cmd_list(sys.argv[2:])
    elif command == 'dump':
        cmd_dump(sys.argv[2:])
    else:
        raise Exception("Error: Unknown command: %s" % command)


