#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import re
import os
import shutil
import logging
import tempfile
import argparse
import ConfigParser
from datetime import datetime
from argparse import ArgumentDefaultsHelpFormatter
from utilities.adb_helper import AdbHelper


class BackupRestoreHelper(object):
    def __init__(self, **kwargs):
        self._FILE_PROFILE_INI = 'profiles.ini'
        self._FILE_COMPATIBILITY_INI = 'compatibility.ini'
        self._LOCAL_DIR_SDCARD = 'sdcard'
        self._LOCAL_DIR_WIFI = 'wifi'
        self._LOCAL_FILE_WIFI = 'wifi/wpa_supplicant.conf'
        self._LOCAL_DIR_B2G = 'b2g-mozilla'
        self._LOCAL_DIR_DATA = 'data-local'
        self._LOCAL_DIR_DATA_APPS = 'webapps'
        self._REMOTE_DIR_SDCARD = '/sdcard/'
        self._REMOTE_FILE_WIFI = '/data/misc/wifi/wpa_supplicant.conf'
        self._REMOTE_FILE_WIFI_OWNER = 'system:wifi'
        self._REMOTE_DIR_B2G = '/data/b2g/mozilla'
        self._REMOTE_DIR_DATA = '/data/local'

        self.logger = logging.getLogger(__name__)
        self.arg_parser = argparse.ArgumentParser(description='Backup and restore Firefox OS profiles. (BETA)',
                                                  formatter_class=ArgumentDefaultsHelpFormatter)
        self.arg_parser.add_argument('-s', '--serial', action='store', dest='serial', default=None, help='Directs command to the device or emulator with the given serial number. Overrides ANDROID_SERIAL environment variable.')
        self.arg_parser.add_argument('-b', '--backup', action='store_true', dest='backup', default=False, help='Backup user profile.')
        self.arg_parser.add_argument('-r', '--restore', action='store_true', dest='restore', default=False, help='Restore user profile.')
        self.arg_parser.add_argument('--sdcard', action='store_true', dest='sdcard', default=False, help='Also backup/restore SD card.')
        self.arg_parser.add_argument('--no-reboot', action='store_true', dest='no_reboot', default=False, help='Do not reboot B2G after backup/restore.')
        self.arg_parser.add_argument('-p', '--profile-dir', action='store', dest='profile_dir', default='mozilla-profile', help='Specify the profile folder.')
        self.arg_parser.add_argument('--debug', action='store_true', dest='debug', default=False, help='Debug mode.')
        self.args = self.arg_parser.parse_args()

    def stop_b2g(self, serial=None):
        self.logger.info('Stop B2G.')
        output = AdbHelper.adb_shell('stop b2g', serial=serial)

    def start_b2g(self, serial=None):
        self.logger.info('Start B2G.')
        output = AdbHelper.adb_shell('start b2g', serial=serial)

    def backup_sdcard(self, local_dir, serial=None):
        self.logger.info('Backing up SD card...')
        # try to get the /sdcard folder on device
        output = AdbHelper.adb_shell('ls -d {0}; echo $?'.format(self._REMOTE_DIR_SDCARD), serial=serial)
        output_list = [item for item in re.split(r'\n+', re.sub(r'\r+', '', output)) if item]
        ret_code = output_list[-1]
        output_list.remove(output_list[-1])
        ret_msg = '\n'.join(output_list)
        if ret_code == '0':
            target_dir = local_dir + os.sep + self._LOCAL_DIR_SDCARD + os.sep
            os.makedirs(target_dir)
            self.logger.info('Backup: {0} to {1}'.format(self._REMOTE_DIR_SDCARD, target_dir))
            if not AdbHelper.adb_pull(self._REMOTE_DIR_SDCARD, target_dir, serial=serial):
                self.logger.warning('Can not pull files from {0} to {1}'.format(self._REMOTE_DIR_SDCARD, target_dir))
        else:
            self.logger.info(ret_msg)
        self.logger.info('Backup SD card done.')

    def restore_sdcard(self, local_dir, serial=None):
        self.logger.info('Restoring SD card...')
        target_dir = local_dir + os.sep + self._LOCAL_DIR_SDCARD
        if os.path.isdir(target_dir):
            self.logger.info('Restore: {0} to {1}'.format(target_dir, self._REMOTE_DIR_SDCARD))
            if not AdbHelper.adb_push(target_dir, self._REMOTE_DIR_SDCARD, serial=serial):
                self.logger.warning('Can not push files from {0} to {1}'.format(target_dir, self._REMOTE_DIR_SDCARD))
        else:
            self.logger.info('{0}: No such file or directory'.format(target_dir))
            return
        self.logger.info('Restore SD card done.')

    def backup_profile(self, local_dir, serial=None):
        self.logger.info('Backing up profile...')
        # Backup Wifi
        wifi_dir = local_dir + os.sep + self._LOCAL_DIR_WIFI + os.sep
        wifi_file = local_dir + os.sep + self._LOCAL_FILE_WIFI
        os.makedirs(wifi_dir)
        self.logger.info('Backing up Wifi information...')
        if not AdbHelper.adb_pull(self._REMOTE_FILE_WIFI, wifi_file, serial=serial):
            self.logger.warning('If you don\'t have root permission, you cannot backup Wifi information.')
        # Backup profile
        b2g_mozilla_dir = local_dir + os.sep + self._LOCAL_DIR_B2G + os.sep
        os.makedirs(b2g_mozilla_dir)
        self.logger.info('Backing up {0} to {1} ...'.format(self._REMOTE_DIR_B2G, b2g_mozilla_dir))
        if not AdbHelper.adb_pull(self._REMOTE_DIR_B2G, b2g_mozilla_dir, serial=serial):
            self.logger.warning('Can not pull files from {0} to {1}'.format(self._REMOTE_DIR_B2G, b2g_mozilla_dir))
        # Backup data/local
        datalocal_dir = local_dir + os.sep + self._LOCAL_DIR_DATA + os.sep
        os.makedirs(datalocal_dir)
        self.logger.info('Backing up {0} to {1} ...'.format(self._REMOTE_DIR_DATA, datalocal_dir))
        if not AdbHelper.adb_pull(self._REMOTE_DIR_DATA, datalocal_dir, serial=serial):
            self.logger.warning('Can not pull files from {0} to {1}'.format(self._REMOTE_DIR_DATA, datalocal_dir))
        # Remove "marketplace" app and "gaiamobile.org" apps from webapps
        webapps_dir = datalocal_dir + self._LOCAL_DIR_DATA_APPS
        for root, dirs, files in os.walk(webapps_dir):
            if (os.path.basename(root).startswith('marketplace') or
                os.path.basename(root).endswith('gaiamobile.org') or
                os.path.basename(root).endswith('allizom.org')):
                self.logger.info('Removing Mozilla webapps: [{0}]'.format(root))
                shutil.rmtree(root)
        self.logger.info('Backup profile done.')

    def check_profile_version(self, local_dir, serial=None):
        self.logger.info('Checking profile...')
        # get local version
        if os.path.isdir(local_dir):
            local_config = ConfigParser.ConfigParser()
            local_config.read(local_dir + os.sep + self._LOCAL_DIR_B2G + os.sep + self._FILE_PROFILE_INI)
            local_profile_path = local_config.get('Profile0', 'Path')
            local_config.read(local_dir + os.sep + self._LOCAL_DIR_B2G + os.sep + local_profile_path + os.sep + self._FILE_COMPATIBILITY_INI)
            version_of_backup = local_config.get('Compatibility', 'LastVersion')
            self.logger.info('The Version of Backup Profile: {}'.format(version_of_backup))
        else:
            return False
        # get remote version
        tmp_dir = tempfile.mkdtemp(prefix='backup_restore_')
        if not AdbHelper.adb_pull(self._REMOTE_DIR_B2G + os.sep + self._FILE_PROFILE_INI, tmp_dir, serial=serial):
            self.logger.warning('Can not pull {2} from {0} to {1}'.format(self._REMOTE_DIR_B2G, tmp_dir, self._FILE_PROFILE_INI))
            return False
        remote_config = ConfigParser.ConfigParser()
        remote_config.read(tmp_dir + os.sep + self._FILE_PROFILE_INI)
        remote_profile_path = remote_config.get('Profile0', 'Path')
        if not AdbHelper.adb_pull(self._REMOTE_DIR_B2G + os.sep + remote_profile_path + os.sep + self._FILE_COMPATIBILITY_INI, tmp_dir, serial=serial):
            self.logger.warning('Can not pull {2} from {0} to {1}'.format(self._REMOTE_DIR_B2G, tmp_dir, self._FILE_COMPATIBILITY_INI))
            return False
        remote_config.read(tmp_dir + os.sep + self._FILE_COMPATIBILITY_INI)
        version_of_device = remote_config.get('Compatibility', 'LastVersion')
        self.logger.info('The Version of Device Profile: {}'.format(version_of_device))
        # compare
        version_of_backup_float = float(version_of_backup.split('_')[0])
        version_of_device_float = float(version_of_device.split('_')[0])
        if version_of_device_float >= version_of_backup_float:
            return True
        else:
            return False

    def restore_profile(self, local_dir, serial=None):
        self.logger.info('Restoring profile...')
        if os.path.isdir(local_dir):
            # Restore Wifi
            wifi_file = local_dir + os.sep + self._LOCAL_FILE_WIFI
            if os.path.isfile(wifi_file):
                self.logger.info('Restoring Wifi information...')
                if not AdbHelper.adb_push(wifi_file, self._REMOTE_FILE_WIFI, serial=serial):
                    self.logger.warning('If you don\'t have root permission, you cannot restore Wifi information.')
                AdbHelper.adb_shell('chown {0} {1}'.format(self._REMOTE_FILE_WIFI_OWNER, self._REMOTE_FILE_WIFI))
            # Restore profile
            b2g_mozilla_dir = local_dir + os.sep + self._LOCAL_DIR_B2G
            if os.path.isdir(b2g_mozilla_dir):
                self.logger.info('Restore from {0} to {1} ...'.format(b2g_mozilla_dir, self._REMOTE_DIR_B2G))
                AdbHelper.adb_shell('rm -r {0}'.format(self._REMOTE_DIR_B2G))
                if not AdbHelper.adb_push(b2g_mozilla_dir, self._REMOTE_DIR_B2G, serial=serial):
                    self.logger.warning('Can not push files from {0} to {1}'.format(b2g_mozilla_dir, self._REMOTE_DIR_B2G))
            # Restore data/local
            datalocal_dir = local_dir + os.sep + self._LOCAL_DIR_DATA
            if os.path.isdir(datalocal_dir):
                self.logger.info('Restore from {0} to {1} ...'.format(datalocal_dir, self._REMOTE_DIR_DATA))
                AdbHelper.adb_shell('rm -r {0}'.format(self._REMOTE_DIR_DATA))
                if not AdbHelper.adb_push(datalocal_dir, self._REMOTE_DIR_DATA, serial=serial):
                    self.logger.warning('Can not push files from {0} to {1}'.format(datalocal_dir, self._REMOTE_DIR_DATA))
            self.logger.info('Restore profile done.')
        else:
            self.logger.info('{0}: No such file or directory'.format(local_dir))
            return

    def run(self):
        # get the device's serial number
        devices = AdbHelper.adb_devices()
        if len(devices) == 0:
            self.logger.warning('No device.')
            exit(1)
        else:
            if self.args.serial is not None and self.args.serial in devices:
                self.logger.debug('Setup serial to [{0}] by --serial'.format(self.args.serial))
                device_serial = self.args.serial
            elif 'ANDROID_SERIAL' in os.environ and os.environ['ANDROID_SERIAL'] in devices:
                self.logger.debug('Setup serial to [{0}] by ANDROID_SERIAL'.format(os.environ['ANDROID_SERIAL']))
                device_serial = os.environ['ANDROID_SERIAL']
            elif self.args.serial is None and not 'ANDROID_SERIAL' in os.environ:
                if len(devices) == 1:
                    self.logger.debug('No serial, and only one device')
                    device_serial = None
                else:
                    self.logger.debug('No serial, but there are more than one device')
                    self.logger.warning('Please specify the device by --serial option.')
                    exit(1)
            else:
                device_serial = None

        # checking the adb root for backup/restore
        if not AdbHelper.adb_root(serial=device_serial):
            exit(2)

        # Backup
        if self.args.backup:
            try:
                self.logger.info('Target device [{0}]'.format(device_serial))
                # Create temp folder
                tmp_dir = tempfile.mkdtemp(prefix='backup_restore_')
                # Stop B2G
                self.stop_b2g(serial=device_serial)
                # Backup User Profile
                self.backup_profile(local_dir=tmp_dir, serial=device_serial)
                # Backup SDCard
                if self.args.sdcard:
                    self.backup_sdcard(local_dir=tmp_dir, serial=device_serial)
                # Copy backup files from temp folder to target folder
                if os.path.isdir(self.args.profile_dir):
                    self.logger.warning('Removing [{0}] folder...'.format(self.args.profile_dir))
                    shutil.rmtree(self.args.profile_dir)
                self.logger.info('Copy profile from [{0}] to [{1}].'.format(tmp_dir, self.args.profile_dir))
                shutil.copytree(tmp_dir, self.args.profile_dir)
                # Start B2G
                if not self.args.no_reboot:
                    self.start_b2g(serial=device_serial)
            finally:
                self.logger.debug('Removing [{0}] folder...'.format(tmp_dir))
                shutil.rmtree(tmp_dir)
        # Restore
        elif self.args.restore:
            self.logger.info('Target device [{0}]'.format(device_serial))
            # Checking the Version of Profile
            if self.check_profile_version(local_dir=self.args.profile_dir, serial=device_serial):
                # Stop B2G
                self.stop_b2g(serial=device_serial)
                # Restore User Profile
                self.restore_profile(local_dir=self.args.profile_dir, serial=device_serial)
                # Restore SDCard
                if self.args.sdcard:
                    self.restore_sdcard(local_dir=self.args.profile_dir, serial=device_serial)
                # Start B2G
                if not self.args.no_reboot:
                    self.start_b2g(serial=device_serial)
            else:
                self.logger.warn('The version on device is smaller than backup\'s version.')


if __name__ == "__main__":
    my_app = BackupRestoreHelper()
    # setup logger
    formatter = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    if my_app.args.debug is True:
        logging.basicConfig(level=logging.DEBUG, format=formatter)
    else:
        logging.basicConfig(level=logging.INFO, format=formatter)
    # check adb
    if not AdbHelper.has_adb():
        print 'There is no "adb" in your environment PATH.'
        exit(1)
    # run
    my_app.run()
