#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import os
import sys
import re
from sys import platform as _platform
from utilities.logger import Logger
from utilities.arg_parse import Parser
from utilities.path_parser import PathParser
from utilities.console_dialog import ConsoleDialog
from base_controller import BaseController


class ConsoleApp(BaseController):

    def __init__(self, settings_file=None, *args, **kwargs):
        '''
        init
        '''
        BaseController.__init__(self, settings_file=settings_file, *args, **kwargs)
        # Setup Default value
        self.flash_params = []
        self.dialog = ConsoleDialog()
        if len(self.baseUrl) == 0:
            self.baseUrl = 'https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/'
        if len(self.destRootFolder) == 0:
            self.destRootFolder = 'pvt'
        self.destFolder = ''
        self.target_device = ''
        self.target_branch = ''
        self.target_build = ''
        self.target_build_id = ''
        self.target_keep_profile = False
        # Load options from input argvs
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
        # check device from load options
        if not self.target_device == '' and self.target_device not in devices:
            self.logger.log('The device [' + self.target_device + '] do not exist.', level=Logger._LEVEL_WARNING)
            self.target_device = ''
        elif not self.target_device == '' and self.target_device in devices:
            self.logger.log('The device [' + self.target_device + '] exist.')
        # user input
        if self.target_device == '':
            if len(devices) > 1:
                ret_obj = self.dialog.menu('Device List', 'Select Device from PVT Server', devices)
                if ret_obj['SELECT'] == ConsoleDialog._QUIT_CMD_INDEX:
                    self.quit()
                self.target_device = ret_obj['ITEMS'][ret_obj['SELECT']]['NAME']
            elif len(devices) == 1:
                self.target_device = devices[0]
                self.logger.log('Only one device [' + self.target_device + '] exist.')
            else:
                self.logger.log('There is no device in packages list.', level=Logger._LEVEL_WARNING)
                self.quit()

        # get target branch
        branchs = self.data[self.target_device].keys()
        # check branch from load options
        if not self.target_branch == '' and self.target_branch not in branchs:
            self.logger.log('The branch [' + self.target_branch + '] of [' + self.target_device + '] do not exist.', level=Logger._LEVEL_WARNING)
            self.target_branch = ''
        elif not self.target_branch == '' and self.target_branch in branchs:
            self.logger.log('The branch [' + self.target_branch + '] of [' + self.target_device + '] exist.')
        # user input
        if self.target_branch == '':
            if len(branchs) > 1:
                ret_obj = self.dialog.menu('Branch List', 'Select Branch of [' + self.target_device + '] device', branchs)
                if ret_obj['SELECT'] == ConsoleDialog._QUIT_CMD_INDEX:
                    self.quit()
                self.target_branch = ret_obj['ITEMS'][ret_obj['SELECT']]['NAME']
            elif len(branchs) == 1:
                self.target_branch = branchs[0]
                self.logger.log('Only one branch [' + self.target_branch + '] of [' + self.target_device + '] exist.')
            else:
                self.logger.log('There is no branch of [' + self.target_device + '].', level=Logger._LEVEL_WARNING)
                self.quit()

        # get target build
        builds = self.data[self.target_device][self.target_branch].keys()
        # check engineer/user build from load options
        if not self.target_build == '' and self.target_build not in builds:
            self.logger.log('The [' + self.target_build + '] build of [' + self.target_device + '] [' + self.target_branch + '] do not exist.', level=Logger._LEVEL_WARNING)
            self.target_build = ''
        elif not self.target_build == '' and self.target_build in builds:
            self.logger.log('The [' + self.target_build + '] build of [' + self.target_device + '] [' + self.target_branch + '] exist.')
        # user input
        if self.target_build == '':
            if len(builds) > 1:
                ret_obj = self.dialog.menu('Build List', 'Select Build of [' + self.target_device + '] [' + self.target_branch + '] Branch', builds)
                if ret_obj['SELECT'] == ConsoleDialog._QUIT_CMD_INDEX:
                    self.quit()
                self.target_build = ret_obj['ITEMS'][ret_obj['SELECT']]['NAME']
            elif len(builds) == 1:
                self.target_build = builds[0]
                self.logger.log('Only one [' + self.target_build + '] build of [' + self.target_device + '] [' + self.target_branch + '] exist.')
            else:
                self.logger.log('There is no build of [' + self.target_device + '] [' + self.target_branch + '].', level=Logger._LEVEL_WARNING)
                self.quit()

        # Get the target build's information
        self.target_build_info = self.data[self.target_device][self.target_branch][self.target_build]

        # TODO: build id part, not sure do we have to ask user? or only input build id from options?
        #ret_obj = self.dialog.yes_no('Latest or Build ID', 'Do you want to flash the latest build', ConsoleDialog._YES_CMD_INDEX)
        self.latest_or_buildid = 'Latest'
        if not self.target_build_id == '':
            if self.pathParser.verify_build_id(self.target_build_id):
                self.latest_or_buildid = self.target_build_id
                self.logger.log('Set up the build ID [' + self.target_build_id + '] of [' + self.target_device + '] [' + self.target_branch + '].')
            else:
                self.logger.log('The build id [' + self.target_build_id + '] is not not valid.', level=Logger._LEVEL_WARNING)
                self.quit()
        else:
            self.logger.log('Set up the latest build of [' + self.target_device + '] [' + self.target_branch + '].')

        # get available packages
        packages = self.getPackages(self.target_build_info['src'], build_id=self.target_build_id)
        if len(packages) <= 0:
            self.logger.log('There is no flash package of [' + self.target_device + '] [' + self.target_branch + '] [' + self.target_build + '] [' + self.latest_or_buildid + ']  Build.', level=Logger._LEVEL_WARNING)
            self.quit()

        # check flash build from load options
        select_flash = True
        # if there are flash params from options
        if len(self.flash_params) > 0:
            # do not ask user
            select_flash = False
            # but if there is any param do not exist, then ask user.
            for flash_param in self.flash_params:
                if flash_param not in packages:
                    self.logger.log('The [' + flash_param + '] of flash options ' + str(self.flash_params) + ' do not exist.', level=Logger._LEVEL_WARNING)
                    self.flash_params = []
                    select_flash = True
                    break
        # user input
        if select_flash:
            if len(packages) > 1:
                ret_obj = self.dialog.menu('Flash List', 'Select Flash Type of [' + self.target_device + '] [' + self.target_branch + '] [' + self.target_build + '] [' + self.latest_or_buildid + '] Build', packages)
                if ret_obj['SELECT'] == ConsoleDialog._QUIT_CMD_INDEX:
                    self.quit()
                self.target_package = ret_obj['ITEMS'][ret_obj['SELECT']]['NAME']
            else:
                self.target_package = packages[0]
            # setup the flash params from user selection
            if PathParser._IMAGES in self.target_package:
                self.flash_params.append(PathParser._IMAGES)
            else:
                if PathParser._GAIA in self.target_package:
                    self.flash_params.append(PathParser._GAIA)
                if PathParser._GECKO in self.target_package:
                    self.flash_params.append(PathParser._GECKO)

        # flash
        self.logger.log('Flash' + str(self.flash_params) + ' of [' + self.target_device + '] [' + self.target_branch + '] [' + self.target_build + '] [' + self.latest_or_buildid + '] Build ...')
        archives = self.do_download(self.flash_params)
        self.do_flash(self.flash_params, archives, keep_profile=self.target_keep_profile)

    def _load_options(self):
        # Settings
        target = self.options.dl_home
        if target is not None and len(target) > 0:
            self.destRootFolder = target

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
        # debug build
        if self.options.debug:
            self.target_build = ' '.join([self.target_build,
                                          PathParser._DEBUG_BUILD_NAME])
        # build id
        target = self.options.build_id
        if target is not None and len(target) > 0:
            self.target_build_id = target
        # gaia/gecko/images
        if self.options.full_flash:
            self.flash_params.append(PathParser._IMAGES)
        else:
            if self.options.gaia:
                self.flash_params.append(PathParser._GAIA)
            if self.options.gecko:
                self.flash_params.append(PathParser._GECKO)
        # keep profile
        self.target_keep_profile = self.options.keep_profile

    def after_flash_action(self):
        self.dialog.msg_box('Flash Information', 'Flash ' + str(self.flash_params) + ' of [' + self.target_device + '] [' + self.target_branch + '] [' + self.target_build + '] [' + self.latest_or_buildid + '] Done.')

    def printErr(self, message):
        pass
