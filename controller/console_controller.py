#!/usr/bin/python
import os
import sys
from sys import platform as _platform
from utilities.path_parser import PathParser
from utilities.arg_parse import Parser
from utilities.console_dialog import ConsoleDialog
from base_controller import BaseController


class ConsoleApp(BaseController):

    def __init__(self, *args, **kwargs):
        '''
        init
        '''
        BaseController.__init__(self, *args, **kwargs)
        self.flash_params = []
        self.dialog = ConsoleDialog()
        self.baseUrl = 'https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/'
        self.destFolder = 'pvt'
        self.options = Parser.pvtArgParse(sys.argv[1:])
        self._load_options()

    def run(self):
        while not self.auth.is_authenticated:
            # The init of BaseController will load .ldap file. If there are no acct info then ask user.
            if self.account == '':
                self.account = self.dialog.input_box('User Name', 'Enter HTTP Username (LDAP)')
            if self.password == '':
                self.password = self.dialog.input_box('User Password', 'Enter HTTP Password of [' + self.account + '] (LDAP)', password=True)
            # Get the Build Data into self.data obj.
            self.setAuth(self.account, self.password)
            if not self.auth.is_authenticated:
                self.account = ''
                self.password = ''

        # get target device
        devices = self.data.keys()
        if len(devices) > 1:
            ret_obj = self.dialog.menu('Device List', 'Select Device from PVT Server', devices)
            if ret_obj['SELECT'] == 'q':
                self.quit()
            self.target_device = ret_obj['ITEMS'][ret_obj['SELECT']]['NAME']
        else:
            self.target_device = devices[0]

        # get target branch
        branchs = self.data[self.target_device].keys()
        if len(branchs) > 1:
            ret_obj = self.dialog.menu('Branch List', 'Select Branch of [' + self.target_device + '] device', branchs)
            if ret_obj['SELECT'] == 'q':
                self.quit()
            self.target_branch = ret_obj['ITEMS'][ret_obj['SELECT']]['NAME']
        else:
            self.target_branch = branchs[0]

        # get target build
        builds = self.data[self.target_device][self.target_branch].keys()
        if len(builds) > 1:
            ret_obj = self.dialog.menu('Build List', 'Select Build of [' + self.target_device + '] [' + self.target_branch + '] Branch', builds)
            if ret_obj['SELECT'] == 'q':
                self.quit()
            self.target_build = ret_obj['ITEMS'][ret_obj['SELECT']]['NAME']
        else:
            self.target_build = builds[0]
        self.target_build_info = self.data[self.target_device][self.target_branch][self.target_build]

        # get available packages
        packages = self.getPackages(self.target_build_info['src'])
        if len(packages) > 1:
            ret_obj = self.dialog.menu('Flash List', 'Select Flash Type of [' + self.target_device + '] [' + self.target_branch + '] [' + self.target_build + '] Build', packages)
            if ret_obj['SELECT'] == 'q':
                self.quit()
            self.target_package = ret_obj['ITEMS'][ret_obj['SELECT']]['NAME']
        else:
            self.target_package = packages[0]

        if 'images' in self.target_package:
            self.flash_params.append('images')
        else:
            if 'gaia' in self.target_package:
                self.flash_params.append('gaia')
            if 'gecko' in self.target_package:
                self.flash_params.append('gecko')
        self.doFlash(self.flash_params)

    def _load_options(self):
        # Settings
        target = self.options.dl_home
        if target is not None and len(target) > 0:
            self.destFolder = target

        # Account Info
        target = self.options.username
        if target is not None and len(target) > 0:
            self.account = target
        target = self.options.password
        if target is not None and len(target) > 0:
            self.password = target

        # Build Info
        # device
        target = self.options.device
        if target is not None and len(target) > 0:
            self.target_device = target
        # branch
        target = self.options.version
        if target is not None and len(target) > 0:
            self.target_branch = target
        # eng/user build
        if self.options.eng:
            self.target_build = PathParser._ENGINEER_BUILD_NAME
        elif self.options.usr:
            self.target_build = PathParser._USER_BUILD_NAME
        # build id
        target = self.options.build_id
        if target is not None and len(target) > 0:
            self.target_build_id = target
        # gaia/gecko/images
        if self.options.full_flash:
            self.flash_params.append('images')
        else:
            if self.options.gaia:
                self.flash_params.append('gaia')
            if self.options.gecko:
                self.flash_params.append('gecko')

    def after_flash_action(self):
        self.dialog.msg_box('Flash Information', 'Flash ' + str(self.flash_params) + ' of [' + self.target_device + '] [' + self.target_branch + '] [' + self.target_build + '] Done.')

    def printErr(self, message):
        pass
