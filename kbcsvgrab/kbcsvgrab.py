#!/usr/bin/python3

# TODO: make this non-interactive

import shutil
import subprocess
import sys
import time

commandline = ['/home/prvak/bin/kbcsvgrab/kbcsvgrab-phantomjs',
               '/home/prvak/bin/kbcsvgrab/kbcsvgrab.js']
p = subprocess.Popen(commandline, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                     stderr=subprocess.PIPE, close_fds=True)
returncode = p.wait()
if returncode != 0:
    print("JS stuff failed")
    sys.exit(1)

stdout = p.stdout.read()
print(stdout)
print()
stderr = p.stderr.read()
print(stderr)

lines = stderr.decode("utf-8").splitlines()
if 'downloading to' not in lines[-1]:
    print("JS stuff did not download new csv")
    sys.exit(1)

downloaded_file = '/tmp/' + lines[-1].replace('downloading to ', '')
filename = time.strftime('%Y%m%d-%H%M') + '.csv'
target = '/home/prvak/dropbox/finance/vypisy/' + filename
shutil.move(downloaded_file, target)

subprocess.check_output(['enconv', '-L', 'cs', target])

print("Saved to " + target)

sys.exit(0)
