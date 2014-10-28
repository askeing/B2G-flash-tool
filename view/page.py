#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from Tkinter import Frame, Label, Button, Radiobutton, StringVar, IntVar, Entry, Listbox, END, Checkbutton, IntVar
import ttk
import sys
import threading
from threading import Lock
from utilities.path_parser import PathParser
from utilities.logger import Logger

TITLE_FONT = ("Helvetica", 18, "bold")


class BasePage(Frame):
    def __init__(self, parent, controller):
        Frame.__init__(self, parent)
        self.logger = Logger()
        self.grid()
        self.controller = controller

    def prepare(self):
        pass

    def setName(self, value):
        self.name = value

    def setIndex(self, value):
        self.index = value

    def setupView(self):
        raise NotImplementedError

    def printErr(self, message):
        raise NotImplementedError


class ListPage(BasePage):
    def __init__(self, parent, controller):
        BasePage.__init__(self, parent, controller)
        self.target_keep_profile_var = IntVar()
        self.mutex = Lock()

    def prepare(self):
        self.enable_device_list()
        self.enable_bid_input()
        self.setData(self.controller.data)
        self.setDeviceList(self.data.keys())
        self.controller.setDefault(self, self.controller.loadOptions())
        self.deviceList.focus_force()

    def printErr(self, message):
        self.errLog.config(text=message)

    def setData(self, data):
        self.data = data

    def setupView(self, title="Select your flash", data=None):
        if(data):
            self.setData(data)
        Label(self, text="Status:").grid(row=4, column=0, columnspan=1, sticky="SW")
        self.errLog = Label(self, text="", width="90")
        self.errLog.grid(row=5, column=0, columnspan=4, sticky="NW")
        self.desc = Label(self, text=title, font=TITLE_FONT)
        self.desc.grid(row=0, column=0, columnspan=2)
        self.ok = Button(self, text='Flash', command=lambda: self.confirm())
        self.ok.grid(row=4, column=3, sticky="E")
        # bind self.target_keep_profile_var (IntVar) to keepProfileCheckbutton, 1 is True, 0 is Flase
        self.keepProfileCheckbutton = Checkbutton(self, text="Keep User Profile (BETA)", variable=self.target_keep_profile_var)
        self.keepProfileCheckbutton.grid(row=7, column=0, columnspan=4, sticky="W")
        self.deviceLabel = Label(self, text="Device", font=TITLE_FONT)
        self.deviceLabel.grid(row=1, column=0)
        self.deviceList = Listbox(self, exportselection=0)
        self.deviceList.grid(row=2, column=0)
        self.versionLabel = Label(self, text="Branch", font=TITLE_FONT)
        self.versionLabel.grid(row=1, column=1)
        self.versionList = Listbox(self, exportselection=0)
        self.versionList.grid(row=2, column=1)
        self.engLabel = Label(self, text="Build Type", font=TITLE_FONT)
        self.engLabel.grid(row=1, column=2)
        self.engList = Listbox(self, exportselection=0)
        self.engList.grid(row=2, column=2)
        self.packageLabel = Label(self, text="Gecko/Gaia/Full", font=TITLE_FONT)
        self.packageLabel.grid(row=1, column=3)
        self.packageList = Listbox(self, exportselection=0)
        self.packageList.grid(row=2, column=3)
        self.bidVar = StringVar()
        Label(self, text="Build ID").grid(row=3, column=0, sticky='E')
        self.bidInput = Entry(self, textvariable=self.bidVar, width="30")
        self.bidInput.grid(row=3, column=1, columnspan=2, sticky="W")
        self.bidVar.set('latest')
        self.progress = ttk.Progressbar(self, orient='horizontal', length=120, mode='indeterminate')
        self.progress.grid(row=3, column=3)
        self.disable_device_list()
        self.disable_version_list()
        self.disable_eng_list()
        self.disable_package_list()
        self.disable_bid_input()
        self.disable_ok_button()

    def enable_device_list(self):
        target = self.deviceList
        target.bind('<<ListboxSelect>>', self.deviceOnSelect)
        target.bind('<Return>', self.pressReturnKey)
        target.config(state="normal")

    def disable_device_list(self):
        target = self.deviceList
        target.unbind('<<ListboxSelect>>')
        target.unbind('<Return>')
        target.config(state="disabled")

    def enable_version_list(self):
        target = self.versionList
        target.bind('<<ListboxSelect>>', self.versionOnSelect)
        target.bind('<Return>', self.pressReturnKey)
        target.config(state="normal")

    def disable_version_list(self):
        target = self.versionList
        target.unbind('<<ListboxSelect>>')
        target.unbind('<Return>')
        target.config(state="disabled")

    def enable_eng_list(self):
        target = self.engList
        target.bind('<<ListboxSelect>>', self.engOnSelect)
        target.bind('<Return>', self.pressReturnKey)
        target.config(state="normal")

    def disable_eng_list(self):
        target = self.engList
        target.unbind('<<ListboxSelect>>')
        target.unbind('<Return>')
        target.config(state="disabled")

    def enable_package_list(self):
        target = self.packageList
        target.bind('<<ListboxSelect>>', self.packageOnSelect)
        target.bind('<Return>', self.pressReturnKey)
        target.config(state="normal")

    def disable_package_list(self):
        target = self.packageList
        target.unbind('<<ListboxSelect>>')
        target.unbind('<Return>')
        target.config(state="disabled")

    def enable_ok_button(self):
        target = self.ok
        target.bind('<Return>', self.pressReturnKey)
        target.config(state="normal")

    def disable_ok_button(self):
        target = self.ok
        target.unbind('<Return>')
        target.config(state="disabled")

    def enable_bid_input(self):
        target = self.bidInput
        # binding unfocus for build id field
        target.bind('<FocusOut>', self.updateBuildId)
        target.bind('<Return>', self.pressReturnKey)
        target.config(state="normal")

    def disable_bid_input(self):
        target = self.bidInput
        target.unbind('<FocusOut>')
        target.unbind('<Return>')
        target.config(state="disabled")

    def selection_all_checked(self):
        result = False
        if len(self.deviceList.curselection()) == 0:
            self.logger.log('Please select device.', status_callback=self.printErr)
            self.disable_ok_button()
            self.deviceList.focus_set()
        elif len(self.versionList.curselection()) == 0:
            self.logger.log('Please select branch.', status_callback=self.printErr)
            self.disable_ok_button()
            self.versionList.focus_set()
        elif len(self.engList.curselection()) == 0:
            self.logger.log('Please select user or engineer build.', status_callback=self.printErr)
            self.disable_ok_button()
            self.engList.focus_set()
        elif len(self.packageList.curselection()) == 0:
            self.logger.log('Please select package to flash.', status_callback=self.printErr)
            self.disable_ok_button()
            self.packageList.focus_set()
        elif len(self.bidVar.get()) != 14 and self.bidVar.get() != 'latest':
            self.logger.log('Please enter build ID to flash or use "latest" to get the newest', status_callback=self.printErr)
            self.logger.log(self.bidVar.get() + ' is invalid: ' + str(len(self.bidVar.get())))
            self.bidVar.set('latest')
        else:
            result = True
        return result

    def updateBuildId(self, event=None):
        # if the value is '' or 'latest', the set the build_id option as ''.
        buildId = self.bidVar.get()
        if buildId == 'latest':
            buildId = ''
        elif len(buildId) != 14:
            self.printErr("Invalid build ID: " + buildId + ", reset to latest")
            buildId = ''
            self.bidVar.set('latest')
        else:
            if len(self.engList.curselection()) != 0:
                refresh_package_list_thread = threading.Thread(target=self.refreshPackageList)
                refresh_package_list_thread.start()

    def pressReturnKey(self, event=None):
        if self.selection_all_checked():
            self.disable_ok_button()
            self.confirm()

    def deviceOnSelect(self, evt):
        self.setVersionList()

    def versionOnSelect(self, evt):
        self.setEngList()

    def engOnSelect(self, evt):
        refresh_package_list_thread = threading.Thread(target=self.refreshPackageList)
        refresh_package_list_thread.start()

    def packageOnSelect(self, evt):
        self.enable_ok_button()

    def confirm(self):
        self.mutex.acquire()
        try:
            if self.selection_all_checked():
                self.disable_ok_button()
                params = []
                package = self.packageList.get(self.packageList.curselection()[0])
                self.logger.log('Start to flash [' + package + '].', status_callback=self.printErr)
                if(PathParser._IMAGES in package):
                    params.append(PathParser._IMAGES)
                else:
                    if(PathParser._GAIA in package):
                        params.append(PathParser._GAIA)
                    if(PathParser._GECKO in package):
                        params.append(PathParser._GECKO)
                keep_profile = (self.target_keep_profile_var.get() == 1)
                run_flash_thread = threading.Thread(target=self.run_flash, args=(params, keep_profile))
                run_flash_thread.start()
                self.controller.transition(self)
        finally:
            self.mutex.release()

    def run_flash(self, params, keep_profile):
        self.progress.start(10)
        self.disable_device_list()
        self.disable_version_list()
        self.disable_eng_list()
        self.disable_package_list()
        self.disable_bid_input()
        self.disable_ok_button()
        archives = self.controller.do_download(params)
        self.controller.do_flash(params, archives, keep_profile=keep_profile)
        self.enable_device_list()
        self.enable_version_list()
        self.enable_eng_list()
        self.enable_package_list()
        self.enable_bid_input()
        self.enable_ok_button()
        self.progress.stop()

    def setDeviceList(self, device=[]):
        self.deviceList.delete(0, END)
        for li in device:
            self.deviceList.insert(END, li)

    def setVersionList(self, version=[]):
        if len(version) == 0:
            version = self.data[self.deviceList.get(self.deviceList.curselection())]
        self.enable_version_list()
        self.disable_eng_list()
        self.disable_package_list()
        self.disable_ok_button()
        self.versionList.delete(0, END)
        for li in version:
            self.versionList.insert(END, li)

    def setEngList(self, eng=[]):
        if len(eng) == 0:
            device = self.deviceList.get(self.deviceList.curselection())
            version = self.versionList.get(self.versionList.curselection())
            eng = self.data[device][version]
        self.enable_eng_list()
        self.disable_package_list()
        self.disable_ok_button()
        self.engList.delete(0, END)
        for li in eng:
            self.engList.insert(END, li)

    def refreshPackageList(self):
        self.mutex.acquire()
        self.progress.start(10)
        try:
            self.disable_device_list()
            self.disable_version_list()
            self.disable_eng_list()
            self.disable_bid_input()
            self.enable_package_list()
            #self.packageList.config(state="normal")
            self.packageList.delete(0, END)
            device = self.deviceList.get(self.deviceList.curselection())
            version = self.versionList.get(self.versionList.curselection())
            eng = self.engList.get(self.engList.curselection())
            buildId = '' if (len(self.bidVar.get()) == 0 or self.bidVar.get() == 'latest') else self.bidVar.get()
            package = self.controller.getPackages(self.data[device][version][eng]['src'], build_id=buildId)
            if len(package) == 0:
                self.logger.log('Invalid build ID: ' + buildId + ', reset to latest', status_callback=self.printErr)
                buildId = ''
                self.bidVar.set('latest')
                package = self.controller.getPackages(self.data[device][version][eng]['src'], build_id=buildId)
            for li in package:
                self.packageList.insert(END, li)
        finally:
            self.enable_device_list()
            self.enable_version_list()
            self.enable_eng_list()
            self.enable_bid_input()
            #self.ok.config(state="normal")
            self.progress.stop()
            self.mutex.release()


class AuthPage(BasePage):
    def __init__(self, parent, controller):
        self.is_auth = False
        self.mutex = Lock()
        BasePage.__init__(self, parent, controller)

    def prepare(self):
        mode = self.mode.get()
        user = self.userVar.get()
        pwd = self.pwdVar.get()
        if mode is 1 and user and pwd:
            self.confirm(mode, user, pwd)
        self.userInput.focus_force()

    def printErr(self, message):
        self.errLog.config(text=message)

    def entryToggle(self, toggle, target):
        if(toggle):
            for t in target:
                t.configure(state='normal')
        else:
            for t in target:
                t.configure(state='disabled')

    def confirm(self, mode, user, pwd):
        self.mutex.acquire()
        try:
            if mode == 1 and not self.is_auth:
                # mode:1 flash from pvt
                # TODO: the GUI do not updated due to the correct way to update the UI in tk is to use the after method.
                self.logger.log('Logging into server...', status_callback=self.printErr)
                if self.controller.setAuth(user, pwd):
                    self.is_auth = True
                    self.ok.config(state="disabled")
                    self.userInput.config(state="disabled")
                    self.pwdInput.config(state="disabled")
                    self.controller.transition(self)
                else:
                    self.printErr("Auththentication failed")
            else:
                # mode:2, flash from local
                pass
        finally:
            self.mutex.release()

    def pressReturnKey(self, event=None):
        if len(self.userVar.get()) > 0 and len(self.pwdVar.get()) > 0:
            self.confirm(self.mode.get(), self.userVar.get(), self.pwdVar.get())
        elif len(self.userVar.get()) == 0:
            self.logger.log('Please enter username.', status_callback=self.printErr)
            self.userInput.focus_set()
        else:
            self.logger.log('Please enter password.', status_callback=self.printErr)
            self.pwdInput.focus_set()

    def setupView(self, title="Test Auth Page", user='', pwd_ori=''):
        self.mode = IntVar()
        self.mode.set(1)
        Label(self, width=25).grid(row=1, column=0, columnspan=2)
        self.errLog = Label(self, text="")
        self.errLog.grid(row=4,
                         column=1,
                         columnspan=3,
                         rowspan=3,
                         sticky="NWSE")
        self.userVar = StringVar()
        self.pwdVar = StringVar()
        Label(self, text="Account").grid(row=2, column=1, sticky='E')
        self.userInput = Entry(self,
                               textvariable=self.userVar,
                               width="30")
        self.userInput.grid(row=2,
                            column=2,
                            columnspan=2,
                            sticky="W")
        Label(self, text="Password").grid(row=3, column=1, sticky='E')
        self.pwdInput = Entry(self,
                              textvariable=self.pwdVar,
                              show="*",
                              width="30")
        self.pwdInput.grid(row=3,
                           column=2,
                           columnspan=2,
                           sticky="W")
        self.userVar.set(user)
        self.pwdVar.set(pwd_ori)
        Label(self,
              text='    Welcome to fxos flash tool',
              font=TITLE_FONT
              ).grid(row=0,
                     column=1,
                     columnspan=3,
                     sticky="WE")
        Radiobutton(self,
                    state='disabled',
                    text='Download build from pvt',
                    variable=self.mode,
                    value=1,
                    command=lambda: self.entryToggle(
                        True,
                        [self.userInput, self.pwdInput])
                    ).grid(row=1, column=2, columnspan=2, sticky="E")
        Radiobutton(self,
                    state='disabled',
                    text='Flash build from local',
                    variable=self.mode,
                    value=2,
                    command=lambda: self.entryToggle(
                        False,
                        [self.userInput, self.pwdInput])
                    ).grid(row=1, column=4, sticky="W")

        self.ok = Button(self,
                         text='Next',
                         command=lambda: self.
                         confirm(self.mode.get(), self.userVar.get(), self.pwdVar.get()))
        self.ok.grid(row=4, column=4, sticky="W")
        self.userInput.bind('<Return>', self.pressReturnKey)
        self.pwdInput.bind('<Return>', self.pressReturnKey)
        self.ok.bind('<Return>', self.pressReturnKey)


class buildIdPage(BasePage):
    def __init__(self, parent, controller):
        BasePage.__init__(self, parent, controller)

    def setupView(self, title="Test BuildId Page", buildId=''):
        buildIdInput = Entry(self,
                             width="40").grid(row=1,
                                              columnspan=2,
                                              sticky="WE")
        self.ok = Button(self,
                         text='Next',
                         command=lambda: self.
                         controller.setValue(self,
                                             "BUILD_ID",
                                             buildIdInput.get()
                                             )
                         )
        self.ok.grid(row=2, column=1, sticky="W")


if __name__ == '__main__':
    print("Not executable")
    sys.exit(1)
