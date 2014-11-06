# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import re
import subprocess
from distutils import spawn


class AdbHelper(object):

    @staticmethod
    def has_adb():
        if spawn.find_executable('adb') == None:
            return False
        return True

    @staticmethod
    def adb_devices():
        p = subprocess.Popen('adb devices', shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        output = p.communicate()[0]
        output = re.sub(r'\r+', '', output)
        output_list = re.split(r'\n+', output)
        output_list = [item for item in output_list if item]
        filter = re.compile(r'(^List of devices attached\s*|^\s+$)')
        output_list = [i for i in output_list if not filter.search(i)]
        output_list = [(re.split(r'\t', item)) for item in output_list if True]
        devices = {}
        for device in output_list:
            devices[device[0]] = device[1]
        return devices

    @staticmethod
    def adb_pull(source, dest, serial=None):
        if serial is None:
            cmd = 'adb pull'
        else:
            cmd = 'adb -s %s pull' % (serial,)
        cmd = '%s %s %s' % (cmd, source, dest)
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        output = p.communicate()[0]
        if p.returncode is not 0:
            return False
        else:
            return True

    @staticmethod
    def adb_shell(command, serial=None):
        if serial is None:
            cmd = 'adb shell'
        else:
            cmd = 'adb -s %s shell' % (serial,)
        cmd = '%s %s' % (cmd, command)
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        output = p.communicate()[0]
        return output
