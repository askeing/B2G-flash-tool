#!/usr/bin/python

import os
import sys
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
    def __init__(self, *args, **kwargs):
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
        self.load_config_file()

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

    def doFlash(self, targets):
        if len(self.destFolder) == 0:
            self.destFolder = self.destRootFolder
        download = Downloader()
        archives = {}
        cmd = './shallow_flash.sh -y'
        sp = ''
        if _platform == 'darwin':
            sp = ' '
        for target in targets:
            archives[target] = download.download(self.paths[target], self.destFolder, status_callback=self.printErr)
        if 'images' in targets:
            try:
                temp_dir = tempfile.mkdtemp()
                self.logger.log('Create temporary folder:' + temp_dir, status_callback=self.printErr)
                Decompressor().unzip(archives['images'], self.temp_dir, status_callback=self.printErr)
                os.system(self.temp_dir + '/flash.sh -f')
                return
            finally:
                try:
                    shutil.rmtree(tmp_dir)  # delete directory
                except OSError:
                    self.logger.log('Can not remove temporary folder:' + temp_dir, status_callback=self.printErr, level=Logger._LEVEL_WARNING)
        if 'gaia' in targets:
            cmd = cmd + ' -g' + sp + archives['gaia']
        if 'gecko' in targets:
            cmd = cmd + ' -G' + sp + archives['gecko']
        print('run command: ' + cmd)
        os.system(cmd)
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
        query = self.pathParser.get_available_packages_from_url(self.baseUrl, src, build_id=build_id)
        self.paths = {}
        package = []
        if 'gaia' in query and 'gecko' in query:
            package.append('gaia + gecko')
        if 'gaia' in query:
            package.append('gaia')
            self.paths['gaia'] = query['gaia']
        if 'gecko' in query:
            package.append('gecko')
            self.paths['gecko'] = query['gecko']
        if 'images' in query:
            package.append('full image')
            self.paths['images'] = query['images']
        # set up the download dest folder
        self.destFolder = self._get_dest_folder_from_build_id(self.destRootFolder, src, build_id)
        return package

    def getLatestBuildId(self, src):
        # TODO: Get from remote and Use in local flash;
        #       should be an async request?
        pass

    def load_config_file(self):
        '''
        Load ".flash_pvt" as config file.
        If there is no file, then copy from ".flash_pvt.template".
        '''
        if not os.path.exists('.flash_pvt'):
            shutil.copy2('.flash_pvt.template', '.flash_pvt')
        account = {}
        with open('.flash_pvt') as f:
            config = eval(f.read())
        if 'account' in config:
            self.account = config['account']
        if 'password' in config:
            self.password = config['password']
        if 'download_home' in config:
            self.destRootFolder = config['download_home']
        if 'base_url' in config:
            self.baseUrl = config['base_url']

    def _get_dest_folder_from_build_id(self, root_folder, build_src, build_id):
        target_folder = ''
        if not build_id == '':
            if self.pathParser.verify_build_id(build_id):
                sub_folder = re.sub(r'^/', '', self.pathParser.get_path_of_build_id(build_id))
                target_folder = os.path.join(root_folder, build_src, sub_folder)
            else:
                self.logger.log('The build id [' + self.target_build_id + '] is not not valid.', status_callback=self.printErr, level=Logger._LEVEL_WARNING)
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
