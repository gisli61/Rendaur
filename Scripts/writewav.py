#!/usr/bin/env python

import sys
import os
import struct

DEFAULT_FRAMERATE=48000

def float32_wav_header(num_frames,num_channels, sample_rate=DEFAULT_FRAMERATE):
    #sample_array = normalize(sample_array)
    byte_count = num_frames * num_channels * 4  # 32-bit floats
    wav_header = ""
    # write the header
    wav_header += struct.pack('<ccccIccccccccIHHIIHH',
        'R', 'I', 'F', 'F',
        byte_count + 0x2c - 8,  # header size
        'W', 'A', 'V', 'E', 'f', 'm', 't', ' ',
        0x10,  # size of 'fmt ' header
        3,  # format 3 = floating-point PCM
        num_channels,  # channels
        sample_rate,  # samples / second
        sample_rate * 4,  # bytes / second
        4,  # block alignment
        32)  # bits / sample
    wav_header += struct.pack('<ccccI',
        'd', 'a', 't', 'a', byte_count)
    #for sample in sample_array:
    #    wav_file += struct.pack("<f", sample)
    return wav_header

def main(inputfile,outputfile):
    if os.path.exists(outputfile):
        raise Exception("Error: File exists: Will not overwrite: %s" % outputfile)

    
    if inputfile == '-':
        f = sys.stdin
    else:
        f = open(inputfile)

    o = open(outputfile,"w")

    header = float32_wav_header(0,0)

    o.write(header)

    num_channels = None
    num_frames = 0
    data_buffer = ""
    for l in f:
        num_frames += 1
        v = [float(x) for x in l.strip().split()]
        if num_channels == None: 
            num_channels = len(v)
            struct_format = '<'+'f'*num_channels
        if len(v) != num_channels:
            raise Exception("Error: Malformed input")
        data_buffer += struct.pack(struct_format,*v)
        if num_frames%512 == 0:
            o.write(data_buffer)
            data_buffer = ""
    o.write(data_buffer)

    if inputfile != '-':
        f.close()

    o.seek(0)
    header = float32_wav_header(num_frames,num_channels)
    o.write(header)
    o.close()



if __name__ == '__main__':
    main(sys.argv[1],sys.argv[2])