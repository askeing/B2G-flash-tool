#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import re
import os
import json
import shutil
import zipfile
import tempfile
import argparse
import subprocess
from datetime import datetime
from argparse import ArgumentDefaultsHelpFormatter
from utilities import console_utilities
from utilities.adb_helper import AdbHelper


class VersionChecker(object):
    def __init__(self, **kwargs):
        self.arg_parser = argparse.ArgumentParser(description='Check the version information of Firefox OS.',
                                                  formatter_class=ArgumentDefaultsHelpFormatter)
        self.arg_parser.add_argument('--no-color', action='store_true', dest='no_color', default=False, help='Do not print output with color.')
        self.arg_parser.add_argument('-s', '--serial', action='store', dest='serial', default=None, help='Overrides ANDROID_SERIAL environment variable.')
        self.arg_parser.add_argument('--log-text', action='store', dest='log_text', default=None, help='Text ouput.')
        self.arg_parser.add_argument('--log-json', action='store', dest='log_json', default=None, help='JSON output.')
        self.args = self.arg_parser.parse_args()

    def get_device_info(self, serial=None):
        try:
            tmp_dir = tempfile.mkdtemp(prefix='checkversions_')
            # pull data from device
            if not AdbHelper.adb_pull('/system/b2g/omni.ja', tmp_dir, serial=serial):
                print 'Error pulling Gecko file.'
            if not AdbHelper.adb_pull('/data/local/webapps/settings.gaiamobile.org/application.zip', tmp_dir, serial=serial):
                if not AdbHelper.adb_pull('/system/b2g/webapps/settings.gaiamobile.org/application.zip', tmp_dir, serial=serial):
                    print 'Error pulling Gaia file.'
            if not AdbHelper.adb_pull('/system/b2g/application.ini', tmp_dir, serial=serial):
                print 'Error pulling application.ini file.'
            # get Gaia info
            gaia_rev = 'n/a'
            gaia_date = 'n/a'
            application_zip_file = tmp_dir + os.sep + 'application.zip'
            if os.path.isfile(application_zip_file):
                f = open(application_zip_file, 'rb')
                z = zipfile.ZipFile(f)
                z.extract('resources/gaia_commit.txt', tmp_dir)
                f.close()
            else:
                print 'Can not find application.zip file.'
            gaiacommit_file = tmp_dir + os.sep + 'resources/gaia_commit.txt'
            if os.path.isfile(gaiacommit_file):
                f = open(gaiacommit_file, "r")
                gaia_rev = re.sub(r'\n+', '', f.readline())
                gaia_date_sec_from_epoch = re.sub(r'\n+', '', f.readline())
                f.close()
                gaia_date = datetime.utcfromtimestamp(int(gaia_date_sec_from_epoch)).strftime('%Y-%m-%d %H:%M:%S')
            else:
                print 'Can not get gaia_commit.txt file from application.zip file.'
            # deoptimize omni.ja for Gecko info
            gecko_rev = 'n/a'
            if os.path.isfile(tmp_dir + os.sep + 'omni.ja'):
                deopt_dir = tmp_dir + os.sep + 'deopt'
                deopt_file = deopt_dir + os.sep + 'omni.ja'
                deopt_exec = tmp_dir + os.sep + 'optimizejars.py'
                os.makedirs(deopt_dir)
                shutil.copyfile('./optimizejars.py', deopt_exec)
                cmd = 'python %s --deoptimize %s %s %s' % (deopt_exec, tmp_dir, tmp_dir, deopt_dir)
                p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                output = p.communicate()[0]
                # unzip omni.ja to get Gecko info
                if os.path.isfile(deopt_file):
                    f = open(deopt_file, 'rb')
                    z = zipfile.ZipFile(f)
                    z.extract('chrome/toolkit/content/global/buildconfig.html', tmp_dir)
                    f.close()
                else:
                    print 'Can not deoptimize omni.ja file.'
                    gecko_rev = 'n/a'
                # get Gecko info from buildconfig.html file
                buildconfig_file = tmp_dir + os.sep + 'chrome/toolkit/content/global/buildconfig.html'
                if os.path.isfile(buildconfig_file):
                    for line in open(buildconfig_file, "r"):
                        if re.search(r'Built from', line):
                            ret = re.findall(r'>(.*?)<', line)
                            gecko_rev = ret[1]
                            break
                else:
                    print 'Can not get buildconfig.html file from omni.ja file.'
            else:
                print 'Can not find omni.ja file.'
            # get Gecko version, and B2G BuildID from application.ini file
            if os.path.isfile(tmp_dir + os.sep + 'application.ini'):
                for line in open(tmp_dir + os.sep + 'application.ini', "r"):
                    if re.search(r'^\s*BuildID', line):
                        ret = re.findall(r'.*?=(.*)', line)
                        build_id = ret[0]
                    if re.search(r'^\s*Version', line):
                        ret = re.findall(r'.*?=(.*)', line)
                        version = ret[0]
            else:
                build_id = 'n/a'
                version = 'n/a'
            # get device information by getprop command
            device_name = re.sub(r'\r+|\n+', '', AdbHelper.adb_shell('getprop ro.product.device', serial=serial))
            firmware_release = re.sub(r'\r+|\n+', '', AdbHelper.adb_shell('getprop ro.build.version.release', serial=serial))
            firmware_incremental = re.sub(r'\r+|\n+', '', AdbHelper.adb_shell('getprop ro.build.version.incremental', serial=serial))
            firmware_date = re.sub(r'\r+|\n+', '', AdbHelper.adb_shell('getprop ro.build.date', serial=serial))
            firmware_bootloader = re.sub(r'\r+|\n+', '', AdbHelper.adb_shell('getprop ro.boot.bootloader', serial=serial))
            # prepare the return information
            device_info = {}
            device_info['Serial'] = serial
            device_info['Build ID'] = build_id
            device_info['Gaia Revision'] = gaia_rev
            device_info['Gaia Date'] = gaia_date
            device_info['Gecko Revision'] = gecko_rev
            device_info['Gecko Version'] = version
            device_info['Device Name'] = device_name
            device_info['Firmware(Release)'] = firmware_release
            device_info['Firmware(Incremental)'] = firmware_incremental
            device_info['Firmware Date'] = firmware_date
            device_info['Bootloader'] = firmware_bootloader
        finally:
            shutil.rmtree(tmp_dir)
        return device_info

    def _print_device_info_item(self, title, value, title_color=None, value_color=None):
        console_utilities.print_color('{0:22s}'.format(title), fg_color=title_color, newline=False)
        console_utilities.print_color(value, fg_color=value_color)

    def print_device_info(self, device_info, no_color=False):
        # setup the format by platform
        if no_color:
            title_color = None
            sw_color = None
            hw_color = None
        else:
            title_color = console_utilities.COLOR_LIGHT_BLUE
            sw_color = console_utilities.COLOR_LIGHT_GREEN
            hw_color = console_utilities.COLOR_LIGHT_YELLOW
        # print the device information
        self._print_device_info_item('Build ID', device_info['Build ID'], title_color=title_color, value_color=sw_color)
        self._print_device_info_item('Gaia Revision', device_info['Gaia Revision'], title_color=title_color, value_color=sw_color)
        self._print_device_info_item('Gaia Date', device_info['Gaia Date'], title_color=title_color, value_color=sw_color)
        self._print_device_info_item('Gecko Revision', device_info['Gecko Revision'], title_color=title_color, value_color=sw_color)
        self._print_device_info_item('Gecko Version', device_info['Gecko Version'], title_color=title_color, value_color=sw_color)
        self._print_device_info_item('Device Name', device_info['Device Name'], title_color=title_color, value_color=hw_color)
        self._print_device_info_item('Firmware(Release)', device_info['Firmware(Release)'], title_color=title_color, value_color=hw_color)
        self._print_device_info_item('Firmware(Incremental)', device_info['Firmware(Incremental)'], title_color=title_color, value_color=hw_color)
        self._print_device_info_item('Firmware Date', device_info['Firmware Date'], title_color=title_color, value_color=hw_color)
        if device_info['Bootloader'] is not '':
            self._print_device_info_item('Bootloader', device_info['Bootloader'], title_color=title_color, value_color=hw_color)
        print ''

    def output_log(self, device_info_list):
        if self.args.log_json is None and self.args.log_text is None:
            return
        # prepare the result dict for parsing
        result = {}
        unknown_serial_index = 1
        for device_info in device_info_list:
            if device_info['Serial'] == None:
                device_serial = 'unknown_serial_' + str(unknown_serial_index)
                unknown_serial_index = unknown_serial_index + 1
            else:
                device_serial = device_info['Serial']
            result[device_serial] = device_info
        # output
        if self.args.log_text is not None:
            with open(self.args.log_text, 'w') as outfile:
                for device_serial, device_info in result.items():
                    outfile.write('# %s\n' % device_serial)
                    if 'Skip' in device_info and device_info['Skip'] is True:
                        outfile.write('%s=%s\n' % ('Skip', device_info['Skip']))
                    else:
                        for key, value in device_info.items():
                            outfile.write('%s=%s\n' % (re.sub(r'\s+|\(|\)', '', key), re.sub(r'\s+', '_', value)))
                        outfile.write('\n')
        if self.args.log_json is not None:
            with open(self.args.log_json, 'w') as outfile:
                json.dump(result, outfile, indent=4)

if __name__ == "__main__":
    if not AdbHelper.has_adb():
        print 'There is no "adb" in your environment PATH.'
        exit(1)

    my_app = VersionChecker()
    devices = AdbHelper.adb_devices()

    if len(devices) == 0:
        print 'No device.'
        exit(1)
    elif len(devices) >= 1:
        # has --serial, then skip ANDROID_SERIAL, then list one device by --serial
        if (my_app.args.serial is not None):
            if my_app.args.serial in devices:
                serial = my_app.args.serial
                print 'Serial: {0} (State: {1})'.format(serial, devices[serial])
                device_info = my_app.get_device_info(serial=serial)
                my_app.print_device_info(device_info, no_color=my_app.args.no_color)
                my_app.output_log([device_info])
            else:
                print 'Can not found {0}.\nDevices:'.format(my_app.args.serial)
                for device, state in devices.items():
                    print 'Serial: {0} (State: {1})'.format(device, state)
                exit(1)
        # no --serial, but has ANDROID_SERIAL, then list one device by ANDROID_SERIAL
        elif (my_app.args.serial is None) and ('ANDROID_SERIAL' in os.environ):
            if os.environ['ANDROID_SERIAL'] in devices:
                serial = os.environ['ANDROID_SERIAL']
                print 'Serial: {0} (State: {1})'.format(serial, devices[serial])
                device_info = my_app.get_device_info(serial=serial)
                my_app.print_device_info(device_info, no_color=my_app.args.no_color)
                my_app.output_log([device_info])
            else:
                print 'Can not found {0}.\nDevices:'.format(os.environ['ANDROID_SERIAL'])
                for device, state in devices.items():
                    print 'Serial: {0} (State: {1})'.format(device, state)
                exit(1)
        # no --serial, no ANDROID_SERIAL, then list all devices
        if (my_app.args.serial is None) and (not 'ANDROID_SERIAL' in os.environ):
            if len(devices) > 1:
                print 'More than one device.'
                print 'You can specify ANDROID_SERIAL by "--serial" option.\n'
            device_info_list = []
            for device, state in devices.items():
                print 'Serial: {0} (State: {1})'.format(device, state)
                if state == 'device':
                    device_info = my_app.get_device_info(serial=device)
                    my_app.print_device_info(device_info, no_color=my_app.args.no_color)
                    device_info_list.append(device_info)
                else:
                    print 'Skipped.\n'
                    device_info_list.append({'Serial': device, 'Skip': True})
            my_app.output_log(device_info_list)
