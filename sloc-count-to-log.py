#!/usr/bin/python
with open('/home/prvak/misc/master-sloc.tsv', 'w') as f:
    for line in open('/home/prvak/misc/master-sloc-log.log'):
        line = line.strip()
        if line.startswith('SUM'):
            f.write("%s %s\n" % (date, line.split(' ')[-1]))
        if line.startswith('2016'):
            date = line
