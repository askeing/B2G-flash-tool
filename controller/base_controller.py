#!/usr/bin/python

import os
import sys
from sys import platform as _platform
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
        self.baseUrl = ""  # NOTE: Need to be overwritten
        self.destFolder = ""  # NOTE: Need to be overwritten
        account, password = self.loadAccountInfo()
        self.account = account
        self.password = password
        self.auth = Authenticator()
        self.pathParser = PathParser()

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
        print("### quit function invoked")
        sys.exit(0)

    def doFlash(self, targets):
        download = Downloader()
        archives = {}
        cmd = './shallow_flash.sh -y'
        sp = ''
        if _platform == 'darwin':
            sp = ' '
        for target in targets:
            archives[target] = download.download(
                self.paths[target],
                self.destFolder,
                self.printErr
                )
        if 'images' in targets:
            Decompressor().unzip(
                archives['images'],
                self.destFolder,
                self.printErr
                )
            os.system(self.destFolder + "/flash.sh -f")
            return
        if 'gaia' in targets:
            cmd = cmd + ' -g' + sp + archives['gaia']
        if 'gecko' in targets:
            cmd = cmd + ' -G' + sp + archives['gecko']
        print("run command: " + cmd)
        os.system(cmd)
        self.after_flash_action()
        self.quit()

    def after_flash_action(self):
        print(targets)

    def printErr(self, message):
        raise NotImplementedError

    def getPackages(self, src):
        #TODO: Async request?
        query = self.pathParser.get_available_packages_from_url(
            self.baseUrl,
            src
            )
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
        return package

    def loadOptions(self):
        data = self.data
        if not data:
            return
        options = Parser.pvtArgParse(sys.argv[1:])
        default = {}
        deviceList = data.keys()
        if options.device in deviceList:
            default['device'] = deviceList.index(options.device)
            versionList = data[options.device].keys()
            if options.version in versionList:
                default['version'] = versionList.index(options.version)
                engList = data[options.device][options.version].keys()
                if options.eng and 'Engineer' in engList:
                    default['eng'] = engList.index('Engineer')
                elif options.usr and 'User' in engList:
                    default['eng'] = engList.index('User')
                else:
                    return default
                if default['eng']:
                    package = self.getPackages(
                        data[options.device][
                            options.version][
                            engList[default['eng']]][
                            'src']
                        )
                    if options.gaia and options.gecko:
                        package[0:0] = 'gecko + gaia'
                        if 'gaia' in package and 'gecko' in package:
                            default['package'] = 0
                    elif options.gaia and 'gaia' in package:
                        default['package'] = package.index('gaia')
                    elif options.gecko:
                        default['package'] = package.index('gecko')
                    elif options.full_flash:
                        default['package'] = package.index('full image')
        return default

    def loadAccountInfo(self):
        account = {}
        with open('.ldap') as f:
            account = eval(f.read())
        if 'account' not in account:
            account['account'] = ''
        if 'password' not in account:
            account['password'] = ''
        return account['account'], account['password']


if __name__ == '__main__':
    data = {}
    with open('../test/flash_info.data') as f:
        data = eval(f.read())
    prog = BaseController()
    prog.setData(data)
