#!/usr/bin/env python

import sys
import gzip
import xml.etree.ElementTree as ET

def parseXML(xmlfile,index):
    
    root = ET.parse(xmlfile).getroot()
    miditracks = root.getchildren()[0].find('Tracks').getchildren()
    miditrack = miditracks[index]
    miditrackId =  miditrack.get('Id')
    #print "Miditrack :",miditrackId
    #miditrack.find('DeviceChain').find('DeviceChain').getchildren()[0].getchildren()[0].getchildren()
    #miditrack.find('DeviceChain').find('DeviceChain').getchildren()[0].getchildren()[0].find('PluginDesc').getchildren()[0].getchildren()
    auplugininfo = miditrack.find('DeviceChain').find('DeviceChain').getchildren()[0].getchildren()[0].find('PluginDesc').getchildren()[0]
    #print auplugininfo.getchildren()
    pluginName = auplugininfo.find('Name').get('Value')
    pluginManufacturer = auplugininfo.find('Manufacturer').get('Value')
    #print "Plugin name :", pluginName
    #print "Plugin manufacturer :",pluginManufacturer
    preset = auplugininfo.find('Preset')
    aupreset = preset.find('AuPreset')
    name = aupreset.find('Name')
    presetName = name.get('Value')
    bufferElement = preset.find('AuPreset').find('Buffer')
    bufferdata = "".join(bufferElement.text.strip().split())
    bufferxml = "".join(chr(int(bufferdata[i:i+2],16)) for i in range(0,len(bufferdata),2))
    
    #broot = ET.fromstring(bufferxml)
    #print broot.getchildren()[0].getchildren()
    #print bufferxml
    print pluginManufacturer,pluginName,presetName

def main(alsfile,index):
    f = gzip.open(alsfile)
    parseXML(f,index)
    f.close()

if __name__ == '__main__':
    main(sys.argv[1],int(sys.argv[2]))
