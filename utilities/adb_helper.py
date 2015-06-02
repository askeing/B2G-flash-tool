# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import re
import logging
import subprocess
from distutils import spawn


class AdbHelper(object):
    logger = logging.getLogger(__name__)

    @staticmethod
    def has_adb():
        if spawn.find_executable('adb') == None:
            return False
        return True

    @staticmethod
    def adb_devices():
        cmd = 'adb devices'
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        output = p.communicate()[0]
        AdbHelper.logger.debug('cmd: {0}'.format(cmd))
        AdbHelper.logger.debug('output: {0}'.format(output))
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
        AdbHelper.logger.debug('cmd: {0}'.format(cmd))
        AdbHelper.logger.debug('output: {0}'.format(output))
        if p.returncode is not 0:
            return False
        else:
            return True

    @staticmethod
    def adb_push(source, dest, serial=None):
        if serial is None:
            cmd = 'adb push'
        else:
            cmd = 'adb -s %s push' % (serial,)
        cmd = '%s %s %s' % (cmd, source, dest)
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        output = p.communicate()[0]
        AdbHelper.logger.debug('cmd: {0}'.format(cmd))
        AdbHelper.logger.debug('output: {0}'.format(output))
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
        cmd = "%s '%s'" % (cmd, command)
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        output = p.communicate()[0]
        AdbHelper.logger.debug('cmd: {0}'.format(cmd))
        AdbHelper.logger.debug('output: {0}'.format(output))
        return output
