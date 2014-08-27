#!/usr/bin/python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import os
import sys
import json
import tempfile
import subprocess


def run_commands(command_list):
    current_process = subprocess.Popen(command_list, shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    ret_stdout, ret_stderr = current_process.communicate()
    ret_code = current_process.returncode
    if ret_stdout:
        print ret_stdout
    if ret_stderr:
        print ret_stderr
    if ret_code != 0:
        exit(ret_code)

def load_settings_json(file):
    if file is None:
        print 'No file', file
        exit(1)
    else:
        if not os.path.exists(file):
            print 'No file', file
        print 'Loading:', file
    return json.load(open(file))

def main():
    tmp_dir = tempfile.gettempdir()
    tmp_file = tmp_dir + os.sep + 'settings.json'

    # Stoping B2G.
    #print 'Stoping B2G...'
    #run_commands(['adb', 'shell', 'stop b2g'])

    # Pulling the settings file from phone.
    print 'Pulling the settings...'
    run_commands(['adb', 'pull', '/system/b2g/defaults/settings.json', tmp_file])

    # Loading the settings.
    print 'Processing...'
    settings = load_settings_json(tmp_file)
    settings['ftu.manifestURL'] = None
    settings_json = json.dumps(settings)
    f = open(tmp_file,'w')
    f.write(settings_json)
    f.close()


    # Pushing the settings file to phone.
    print 'Pushing the settings...'
    #run_commands(['adb', 'shell', 'mount -o rw,remount /system']) 
    run_commands(['adb', 'push', tmp_file, '/system/b2g/defaults/settings.json'])
    #run_commands(['adb', 'shell', 'mount -o ro,remount /system']) 

    # Starting B2G.
    #print 'Strating B2G...'
    #run_commands(['adb', 'shell', 'start b2g'])
    print 'Done.'


if __name__ == '__main__':
    main()
