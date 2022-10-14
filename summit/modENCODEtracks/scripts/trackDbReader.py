#!/usr/bin/env python3
# I got the trackDb file by following the hub.txt that loads in the genome browser as a trackHub. 
# https://waterston.gs.washington.edu/modERN/worm_hub.txt
# from there, the parent directory is navigable, and leads you to https://waterston.gs.washington.edu/modERN/ce11/worm_trackDb.txt
# That is the file that may be parsed to find and download the BigBed format files.
# It would probably be better to download them from this script, since they are relatively small files, but I wasn't expecting that.
import sys, os
import urllib.request # if downloading here

write_dir = sys.argv[2]
if not os.path.exists(write_dir):
    os.mkdir(write_dir)

FILE_VERSIONS = {}

def version_dups(filename):
    # some input files are duplicated in both factor name and stage, and differentiated only by accession number
    # keep track of names and increment versions

    if filename not in FILE_VERSIONS:
        FILE_VERSIONS[ filename ] = 0
        return filename

    version = FILE_VERSIONS[ filename ] + 1
    FILE_VERSIONS[ filename ] = version
    return filename.replace('.bb', "-%d.bb" % version)
    

def processRecord(record):
    # search the record for entries containing "Combined Optimal" in longLabel. Example:
    """
     track ENCFF850FUA_1
     parent Optimal_ENCSR977DAI
     subGroups replicate=Combined view=Optimal
     shortLabel aha-1_L1 larva
     longLabel Combined Optimal aha-1 L1 larva
     type bigBed 6 +
     color 0,0,0
     maxHeightPixels 128:40:15
     visibility dense
     autoScale on
     bigDataUrl https://www.encodeproject.org/files/ENCFF850FUA/@@download/ENCFF850FUA.bigBed?proxy=true
     html http://waterston.gs.washington.edu/modERN/html/file/ENCFF850FUA.html
    """
    if 'longLabel' in record and record[ 'longLabel' ].find('Combined Optimal') > -1:
        #print(record['shortLabel'])
        #print(record['track'], record['longLabel'])
        #print(record['bigDataUrl'])

        shortlabel = record['shortLabel']
        # downstream script will parse the following to write the downloaded file to "filename"
        filename = shortlabel.replace(' ', '_').replace('(embryonic)', 'embryonic') + '.' + record['track'] + '.bb'

        # deal with some problems with the name found in the short label
        filename = filename.replace('/', '+') # found in 'shortLabel dao-5_L4/young adult'
        filename = filename.replace('_larva', '') #  is always proceeded by L1,L4, etc., so "_larva" is redundant
        filename = filename.replace('young_adult', 'yAd') # as it appears in Figure3 Kudron 2018
        filename = filename.replace('mixed_stage_embryonic', 'EM')
        filename = filename.replace('late_embryonic', 'LE')
        filename = filename.replace('midembryonic', 'MdE')
        filename = filename.replace('early_embryonic', 'EE') # this is a guess, I don't see one in the figure
        filename = filename.replace('dauer', 'D4')

        factor = filename.split('_')[0]
        filename = version_dups(filename)
        if os.path.exists( filename ):
            print("skipping", factor, filename, record['track'], ": it already exists") # from jobs timing out
        else:
            print("downloading", factor, filename, record['track'], record['bigDataUrl'], file=sys.stderr)
            urllib.request.urlretrieve(record['bigDataUrl'], os.path.join(write_dir,filename)) 
    

# each line that starts with "track" is a new record, therefore ending the previous one 
record = None
lastRecord = None
for i, line in enumerate(open(sys.argv[1])):
    # skip blank
    if len(line.strip()) == 0: continue
    # skip comment
    if line.startswith('#'): continue

    # get indent level
    ws = len(line) - len(line.lstrip())
    indent = (1+ws) / 4

    fields = line.strip().split()

    if fields[0] == 'track':
        if record is not None: 
            lastRecord = record
            processRecord(lastRecord)

        # new record
        record = {}
        record[fields[0]] = fields[1]
        record['linenum'] = i
        
    else:
        # auto populate record
        try:
            record[ fields[0] ] = " ".join(fields[1:])
        except BaseException as err:
            print(f"Unexpected {err=}, {type(err)=}", file=sys.stderr)
            print("line", i, "'" + line + "'", file=sys.stderr,)
            print(record, file=sys.stderr,)
            raise
    
processRecord(record)


