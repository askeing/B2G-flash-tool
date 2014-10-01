#!/usr/bin/python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import os
import sys
import stat
import re
import shutil
import tempfile
from sys import platform as _platform
from utilities.logger import Logger
from utilities.path_parser import PathParser
from utilities.authenticator import Authenticator
from utilities.arg_parse import Parser
from utilities.downloader import Downloader
from utilities.decompressor import Decompressor


class BaseController(object):
    def __init__(self, settings_file=None, *args, **kwargs):
        '''
        Generate base frame and each page, bind them in a list
        '''
        self.logger = Logger()
        self.baseUrl = ''  # NOTE: Need to be overwritten
        self.destRootFolder = ''  # NOTE: Need to be overwritten
        self.destFolder = ''
        self.auth = Authenticator()
        self.pathParser = PathParser()
        # load config from .flash_pvt file
        self.load_config_file(settings_file)

    def setData(self, data=None):
        if data is None:
            data = self.pathParser.get_builds_list_from_url(self.baseUrl)
        self.data = data

    def setAuth(self, user, pwd):
        ## pass auth parameters
        self.auth.authenticate(self.baseUrl, user, pwd)
        if not self.auth.is_authenticated:
            return False
        self.setData()
        return True

    def quit(self):
        '''
        Halt the program
        '''
        print('### quit function invoked')
        sys.exit(0)

    def do_download(self, targets):
        if len(self.destFolder) == 0:
            self.destFolder = self.destRootFolder
        downloader = Downloader()
        archives = {}
        for target in targets:
            archives[target] = downloader.download(self.paths[target], self.destFolder, status_callback=self.printErr)
        return archives

    def do_flash(self, targets, archives, keep_profile=False):
        cmd = './shallow_flash.sh -y'
        sp = ''
        if _platform == 'darwin':
            sp = ' '
        if PathParser._IMAGES in targets:
            try:
                self.temp_dir = tempfile.mkdtemp()
                self.logger.log('Create temporary folder:' + self.temp_dir, status_callback=self.printErr)
                Decompressor().unzip(archives[PathParser._IMAGES], self.temp_dir, status_callback=self.printErr)
                # set the permissions to rwxrwxr-x (509 in python's os.chmod)
                os.chmod(self.temp_dir + '/b2g-distro/flash.sh', stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR | stat.S_IRGRP | stat.S_IWGRP | stat.S_IXGRP | stat.S_IROTH | stat.S_IXOTH)
                os.chmod(self.temp_dir + '/b2g-distro/load-config.sh', stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR | stat.S_IRGRP | stat.S_IWGRP | stat.S_IXGRP | stat.S_IROTH | stat.S_IXOTH)
                os.system('cd ' + self.temp_dir + '/b2g-distro; ./flash.sh -f')
                # support NO_FTU environment for skipping FTU (e.g. monkey test)
                if 'NO_FTU' in os.environ and os.environ['NO_FTU'] == 'true':
                    self.logger.log('The [NO_FTU] is [true].')
                    os.system('adb wait-for-device && adb shell stop b2g; (RET=$(adb root); if ! case ${RET} in *"cannot"*) true;; *) false;; esac; then adb remount && sleep 5; else exit 1; fi; ./disable_ftu.py) || (echo "No root permission, cannot setup NO_FTU."); adb reboot;')
            finally:
                try:
                    shutil.rmtree(self.temp_dir)  # delete directory
                except OSError:
                    self.logger.log('Can not remove temporary folder:' + self.temp_dir, status_callback=self.printErr, level=Logger._LEVEL_WARNING)
            flash_img_cmd = 'CUR_DIR=`pwd`; TEMP_DIR=`mktemp -d`; unzip -d $TEMP_DIR ' + archives[PathParser._IMAGES] + '; \\\n' + \
                            'cd $TEMP_DIR/b2g-distro/; ./flash.sh -f; \\\ncd $CUR_DIR; rm -rf $TEMP_DIR; '
            # support NO_FTU environment for skipping FTU (e.g. monkey test)
            if 'NO_FTU' in os.environ and os.environ['NO_FTU'] == 'true':
                flash_img_cmd = flash_img_cmd + '\\\nadb wait-for-device && adb shell stop b2g; \\\n' + \
                                                '(RET=$(adb root); if ! case ${RET} in *"cannot"*) true;; *) false;; esac; then adb remount && sleep 5; else exit 1; fi; ./disable_ftu.py) || \\\n' + \
                                                '(echo "No root permission, cannot setup NO_FTU."); adb reboot; '
            self.logger.log('!!NOTE!! Following commands can help you to flash packages into other device WITHOUT download again.\n%s\n' % (flash_img_cmd,))
        else:
            if PathParser._GAIA in targets:
                cmd = cmd + ' -g' + sp + archives[PathParser._GAIA]
            if PathParser._GECKO in targets:
                cmd = cmd + ' -G' + sp + archives[PathParser._GECKO]
            if keep_profile:
                self.logger.log('Keep User Profile.')
                cmd = cmd + ' --keep_profile'
            print('run command: ' + cmd)
            os.system(cmd)
            self.logger.log('!!NOTE!! Following commands can help you to flash packages into other device WITHOUT download again.\n%s\n' % (cmd,))
        self.logger.log('Flash Done.', status_callback=self.printErr)
        self.after_flash_action()
        self.quit()

    def after_flash_action(self):
        pass

    def printErr(self, message):
        raise NotImplementedError

    def getPackages(self, src, build_id=''):
        '''
        input src and build-id, then setup the dest-folder and return the available packages.
        '''
        #TODO: Async request?
        query = self.pathParser.get_available_packages_from_url(base_url=self.baseUrl, build_src=src, build_id=build_id, build_id_format=self.build_id_format)
        self.paths = {}
        package = []
        if PathParser._GAIA in query and PathParser._GECKO in query:
            package.append(PathParser._GAIA_GECKO)
        if PathParser._GAIA in query:
            package.append(PathParser._GAIA)
            self.paths[PathParser._GAIA] = query[PathParser._GAIA]
        if PathParser._GECKO in query:
            package.append(PathParser._GECKO)
            self.paths[PathParser._GECKO] = query[PathParser._GECKO]
        if PathParser._IMAGES in query:
            package.append(PathParser._IMAGES)
            self.paths[PathParser._IMAGES] = query[PathParser._IMAGES]
        # set up the download dest folder
        self.destFolder = self._get_dest_folder_from_build_id(self.destRootFolder, src, build_id)
        return package

    def getLatestBuildId(self, src):
        # TODO: Get from remote and Use in local flash;
        #       should be an async request?
        pass

    def load_config_file(self, settings_file=None):
        '''
        Load ".flash_pvt" as config file.
        If there is no file, then copy from ".flash_pvt.template".
        '''
        if settings_file is None:
            settings_file = '.flash_pvt'
        if not os.path.exists(settings_file):
            self.logger.log('Creating %s from %s' % (settings_file, settings_file + '.template'))
            shutil.copy2(settings_file + '.template', settings_file)
        self.logger.log('Loading settings from %s' % (settings_file,))
        account = {}
        with open(settings_file) as f:
            config = eval(f.read())
        if 'account' in config:
            self.account = config['account']
        else:
            self.account = ''
        if 'password' in config:
            self.password = config['password']
        else:
            self.password = ''
        if 'download_home' in config:
            self.destRootFolder = config['download_home']
        else:
            self.destRootFolder = 'pvt'
        if 'base_url' in config:
            self.baseUrl = config['base_url']
        else:
            self.baseUrl = 'pvhttps://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/'
        if 'build_id_format' in config:
            self.build_id_format = config['build_id_format']
        else:
            self.build_id_format = '/{year}/{month}/{year}-{month}-{day}-{hour}-{min}-{sec}/'

    def _get_dest_folder_from_build_id(self, root_folder, build_src, build_id):
        target_folder = ''
        if not build_id == '' or build_id == 'latest':
            if self.pathParser.verify_build_id(build_id):
                sub_folder = re.sub(r'^/', '', self.pathParser.get_path_of_build_id(build_id=build_id, build_id_format=self.build_id_format))
                target_folder = os.path.join(root_folder, build_src, sub_folder)
            else:
                self.logger.log('The build id [' + build_id + '] is not not valid.', status_callback=self.printErr, level=Logger._LEVEL_WARNING)
                self.quit()
        else:
            target_folder = os.path.join(root_folder, build_src, 'latest')
        self.logger.log('Set up dest folder to [' + target_folder + '].', status_callback=self.printErr)
        return target_folder

if __name__ == '__main__':
    data = {}
    with open('../test/flash_info.data') as f:
        data = eval(f.read())
    prog = BaseController()
    prog.setData(data)
