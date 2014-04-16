#!/usr/bin/python
import os
from sys import platform as _platform
from utilities.console_dialog import ConsoleDialog
from base_controller import BaseController


class ConsoleApp(BaseController):

    def __init__(self, *args, **kwargs):
        '''
        init
        '''
        BaseController.__init__(self, *args, **kwargs)
        self.dialog = ConsoleDialog()
        self.baseUrl = 'https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/'
        self.destFolder = 'pvt'

    def run(self):
        # The init of BaseController will load .ldap file. If there are no acct info then ask user.
        if self.account == '':
            self.account = self.dialog.input_box('User Name', 'Enter HTTP Username (LDAP)')
        if self.password == '':
            self.password = self.dialog.input_box('User Password', 'Enter HTTP Password (LDAP)', password=True)

        # Get the Build Data into self.data obj.
        self.setAuth(self.account, self.password)
        if not self.auth.is_authenticated:
            self.quit()

        # get target device
        devices = self.data.keys()
        if len(devices) > 1:
            ret_obj = self.dialog.menu('Device List', 'Select Device from PVT Server', devices)
            if ret_obj['SELECT'] == 'q':
                self.quit()
            self.target_device = ret_obj['ITEMS'][ret_obj['SELECT']]['NAME']
        else:
            self.target_branch = devices[0]

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

        self.flash_params = []
        if('images' in self.target_package):
            self.flash_params.append('images')
        if('gaia' in self.target_package):
            self.flash_params.append('gaia')
        if('gecko' in self.target_package):
            self.flash_params.append('gecko')
        self.doFlash(self.flash_params)

    def after_flash_action(self):
        self.dialog.msg_box('Flash Information', 'Flash ' + str(self.flash_params) + ' of [' + self.target_device + '] [' + self.target_branch + '] [' + self.target_build + '] Done.')

    def printErr(self, message):
        pass
