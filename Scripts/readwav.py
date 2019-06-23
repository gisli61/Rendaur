#!/usr/bin/env python

import sys
import struct
import getopt

__doc__ = """Synopsis:
    List and extract Audio Unit presets from Ableton project files (.als files)
Usage:
    read_32bitfloat.py [-D] [-H|-A] [-r <range>] <wavfile>
    read_32bitfloat.py -h
Options:
    -h Print this help and exit.
    -r Return a range from the frames. Range format as in python <start>:<stop> where <start>
       and <stop> are offsets into the file. The range returned will start at frame with offset
       <start> and then return <stop>-<start> frames. Use negative numbers to express positions
       relative to the end and use blanks to express the two ends. Examples:
       :512   : the first 512 frames
       -512:  : the last 512 frames
       2:102  : 100 frames starting at frame 3 (offset 0 refers to the first frame)
    -H Print only the header information (sample depth, sample rate etc)
    -A Print both the header and the data frames
    -D Debug. Print the actual header information read

"""
def main(infile,debug=False,header=False,content=True,framerange=None):

    # It would be nice to read data directly from file stream rather than loading the 
    # entire file into memory. Perhaps an approach like in 
    # http://code.activestate.com/recipes/577610-decoding-binary-files/
    # would do.
    f = open(infile)
    data = f.read()
    f.close()
    if debug: print len(data)

    offset = 0
    v = struct.unpack_from('<cccc',data,offset=offset)
    offset+=4
    if not "".join(v) == "RIFF":
        raise Exception("Unknown file format")
    if debug: print v #ckID

    v = struct.unpack_from('<I',data,offset=offset)
    offset+=4
    if debug: print v #cksize

    v = struct.unpack_from('<cccc',data,offset=offset)
    offset+=4
    if not "".join(v) == "WAVE":
        raise Exception("Unknown file format")
    if debug: print v #WAVEID

    v = struct.unpack_from('<cccc',data,offset=offset)
    offset+=4
    if not "".join(v) == "fmt ":
        raise Exception("Unknown file format")
    if debug: print v #ckID

    v = struct.unpack_from('<I',data,offset=offset)
    offset+=4
    if v[0] == 18:
        has_cbSize = True
    elif v[0] == 16:
        has_cbSize = False
    else:
        raise Exception("Unknown file format: chunkSize=%d"%v[0])
    if debug: print v #cksize

    v = struct.unpack_from('<HHIIHH',data,offset=offset)
    offset += 16
    if debug: print v #wFormatTag,nChannels,nSamplesPerSec,nAvgBytesPerSec,nBlockAlign,wBitsPerSample
    format,nChannels,sampleRate = v[0:3]
    sampleDepth = v[-1]

    if has_cbSize:
        v = struct.unpack_from('<H',data,offset=offset)
        offset += 2
        if debug: print v #cbSize

    v = struct.unpack_from('<cccc',data,offset=offset)
    offset += 4
    if debug: print v # ckID

    while "".join(v) != 'data':
        if "".join(v) == 'fact':
            v = struct.unpack_from('<II',data,offset=offset)
            offset += 8
            if debug: print v
        else:
            v = struct.unpack_from('<I',data,offset=offset)
            offset += 4
            if debug: print v
            if debug: print "Unknown content of size %d"%v[0]
            offset += v[0]

        v = struct.unpack_from('<cccc',data,offset=offset)
        offset += 4
        if debug: print v

    if "".join(v) != 'data':
        raise Exception("Unknown format: Didn't get token 'data'")

    v = struct.unpack_from('<I',data,offset=offset)
    offset += 4
    if debug: print v # cksize
    datasize = v[0]

    bytesPerSample = sampleDepth/8
    nFrames = datasize/(bytesPerSample*nChannels)
    if header: print "nFrames        =",nFrames
    if header: print "format         =",format
    if header: print "nChannels      =",nChannels
    if header: print "sampleRate     =",sampleRate
    if header: print "sampleDepth    =",sampleDepth
    if header: print "bytesPerSample =",bytesPerSample

    framesize = bytesPerSample*nChannels

    if format == 3 and bytesPerSample==4:
        readformat = '<'+'f'*nChannels
    elif format == 1 and bytesPerSample==4:
        readformat = '<'+'i'*nChannels
    elif format == 1 and bytesPerSample==2:
        readformat = '<'+'h'*nChannels
    elif format == 1 and bytesPerSample==1:
        readformat = '<'+'b'*nChannels
    elif format == 1 and bytesPerSample==3:
        readformat = '<'+'Bh'*nChannels
    else:
        raise Exception("Unknown format")

    if not content:
        return

    if framerange is not None:
        start,stop = framerange.split(":")
        if start == "":
            start = 0
        if stop == "":
            stop = nFrames
        start = int(start)
        stop = int(stop)
        #print start,stop
        if start<0: start = nFrames+start
        if stop<0: stop = nFrames+stop
        #print start,stop
    else:
        start = 0
        stop = nFrames

    if start < 0: start = 0
    if stop < 0: stop = 0
    if start > nFrames: start = nFrames
    if stop > nFrames: stop = nFrames

    if stop < start:
        raise Exception("Bad range")

    num_frames = stop - start
    offset += start*bytesPerSample*nChannels

    for i in xrange(num_frames):
        v = struct.unpack_from(readformat,data,offset=offset)
        offset += framesize
        if bytesPerSample == 3:
            print "\t".join(str(x) for x in [v[i]+v[i+1]<<8 for i in xrange(0,len(v),2)])
        else:
            print "\t".join(str(x) for x in v)

if __name__ == '__main__':
    opt,args = getopt.getopt(sys.argv[1:],'HDAr:')
    opt = dict(opt)

    main(args[0],
        debug=('-D' in opt),
        header= '-D' not in opt and ('-H' in opt or '-A' in opt),
        content= '-D' not in opt and ('-H' not in opt or '-A' in opt),
        framerange=opt.get('-r')
    )
