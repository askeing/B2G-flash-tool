#!/usr/bin/python

from Tkinter import Frame, Label, Button, Radiobutton, StringVar, IntVar, Entry, Listbox, END
import sys
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
        self.mutex = Lock()

    def prepare(self):
        self.deviceList.config(state='normal')
        self.versionList.config(state='disabled')
        self.engList.config(state='disabled')
        self.packageList.config(state='disabled')
        self.ok.config(state='disabled')
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
        self.errLog = Label(self, text="")
        self.errLog.grid(row=4, column=1, columnspan=3, sticky="NWSE")
        self.desc = Label(self, text=title, font=TITLE_FONT)
        self.desc.grid(row=0, column=0, columnspan=2)
        self.ok = Button(self,
                         text='Next',
                         command=lambda: self.
                         confirm())
        self.ok.grid(row=4, column=3, sticky="E")
        self.ok.config(state="disabled")
        self.deviceLabel = Label(self, text="Device", font=TITLE_FONT)
        self.deviceLabel.grid(row=1, column=0)
        self.deviceList = Listbox(self, exportselection=0)
        self.deviceList.grid(row=2, column=0)
        self.deviceList.bind('<<ListboxSelect>>', self.deviceOnSelect)
        self.deviceList.config(state="disabled")
        self.versionLabel = Label(self, text="Branch", font=TITLE_FONT)
        self.versionLabel.grid(row=1, column=1)
        self.versionList = Listbox(self, exportselection=0)
        self.versionList.grid(row=2, column=1)
        self.versionList.bind('<<ListboxSelect>>', self.versionOnSelect)
        self.versionList.config(state="disabled")
        self.engLabel = Label(self, text="Build Type", font=TITLE_FONT)
        self.engLabel.grid(row=1, column=2)
        self.engList = Listbox(self, exportselection=0)
        self.engList.grid(row=2, column=2)
        self.engList.bind('<<ListboxSelect>>', self.engOnSelect)
        self.engList.config(state="disabled")
        self.packageLabel = Label(
            self,
            text="Gecko/Gaia/Full",
            font=TITLE_FONT)
        self.packageLabel.grid(row=1, column=3)
        self.packageList = Listbox(self, exportselection=0)
        self.packageList.grid(row=2, column=3)
        self.packageList.bind('<<ListboxSelect>>', self.packageOnSelect)
        self.packageList.config(state="disabled")
        self.bidVar = StringVar()
        Label(self, text="Build ID").grid(row=3, column=0, sticky='E')
        self.bidInput = Entry(
            self,
            textvariable=self.bidVar,
            width="30")
        self.bidInput.grid(
            row=3,
            column=1,
            columnspan=2,
            sticky="W")
        self.bidVar.set('latest')
        # binding unfocus for build id field
        self.bidInput.bind('<FocusOut>', self.updateBuildId)
        # binding the Return Key to each componments
        self.deviceList.bind('<Return>', self.pressReturnKey)
        self.versionList.bind('<Return>', self.pressReturnKey)
        self.engList.bind('<Return>', self.pressReturnKey)
        self.packageList.bind('<Return>', self.pressReturnKey)
        self.bidInput.bind('<Return>', self.pressReturnKey)
        self.ok.bind('<Return>', self.pressReturnKey)

    def selection_all_checked(self):
        result = False
        if len(self.deviceList.curselection()) == 0:
            self.logger.log('Please select device.', status_callback=self.printErr)
            self.ok.config(state="disabled")
            self.deviceList.focus_set()
        elif len(self.versionList.curselection()) == 0:
            self.logger.log('Please select branch.', status_callback=self.printErr)
            self.ok.config(state="disabled")
            self.versionList.focus_set()
        elif len(self.engList.curselection()) == 0:
            self.logger.log('Please select user or engineer build.', status_callback=self.printErr)
            self.ok.config(state="disabled")
            self.engList.focus_set()
        elif len(self.packageList.curselection()) == 0:
            self.logger.log('Please select package to flash.', status_callback=self.printErr)
            self.ok.config(state="disabled")
            self.packageList.focus_set()
        elif len(self.bidVar.get()) == 0:
            self.logger.log('Please enter build ID to flash or use "latest" to get the newest', status_callback=self.printErr)
            self.bidVar.set('latest')
        else:
            result = True
        return result

    def updateBuildId(self, event=None):
        if len(self.engList.curselection()) != 0:
            self.refreshPackageList()

    def pressReturnKey(self, event=None):
        if self.selection_all_checked():
            self.ok.config(state="disabled")
            self.confirm()

    def deviceOnSelect(self, evt):
        self.setVersionList()

    def versionOnSelect(self, evt):
        self.setEngList()

    def engOnSelect(self, evt):
        self.refreshPackageList()  # hard coded right now

    def packageOnSelect(self, evt):
        self.ok.config(state="normal")

    def confirm(self):
        self.mutex.acquire()
        try:
            if self.selection_all_checked():
                self.ok.config(state="disabled")
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
                self.controller.doFlash(params)
                self.packageList.select_clear(0, END)
                self.controller.transition(self)
        finally:
            self.mutex.release()

    def setDeviceList(self, device=[]):
        self.deviceList.delete(0, END)
        for li in device:
            self.deviceList.insert(END, li)

    def setVersionList(self, version=[]):
        if len(version) == 0:
            version = self.data[
                self.deviceList.get(self.deviceList.curselection())
                ]
        self.versionList.config(state="normal")
        self.engList.config(state="disabled")
        self.packageList.config(state="disabled")
        self.ok.config(state="disabled")
        self.versionList.delete(0, END)
        for li in version:
            self.versionList.insert(END, li)

    def setEngList(self, eng=[]):
        if len(eng) == 0:
            device = self.deviceList.get(self.deviceList.curselection())
            version = self.versionList.get(self.versionList.curselection())
            eng = self.data[device][version]
        self.engList.config(state="normal")
        self.packageList.config(state="disabled")
        self.ok.config(state="disabled")
        self.engList.delete(0, END)
        for li in eng:
            self.engList.insert(END, li)

    def refreshPackageList(self):
        self.mutex.acquire()
        try:
            self.packageList.config(state="normal")
            self.ok.config(state="normal")
            self.packageList.delete(0, END)
            device = self.deviceList.get(self.deviceList.curselection())
            version = self.versionList.get(self.versionList.curselection())
            eng = self.engList.get(self.engList.curselection())
            # if the value is '' or 'latest', the set the build_id option as ''.
            buildId = '' if (len(self.bidVar.get()) == 0 or self.bidVar.get() == 'latest') else self.bidVar.get()
            package = self.controller.getPackages(self.data[device][version][eng]['src'], build_id=buildId)
            if len(package) == 0:
                package = [PathParser._GAIA_GECKO, PathParser._GAIA, PathParser._GECKO, PathParser._IMAGES]
            for li in package:
                self.packageList.insert(END, li)
        finally:
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
        self.errLog.grid(
            row=4,
            column=1,
            columnspan=3,
            rowspan=3,
            sticky="NWSE"
            )
        self.userVar = StringVar()
        self.pwdVar = StringVar()
        Label(self, text="Account").grid(row=2, column=1, sticky='E')
        self.userInput = Entry(
            self,
            textvariable=self.userVar,
            width="30")
        self.userInput.grid(
            row=2,
            column=2,
            columnspan=2,
            sticky="W")
        Label(self, text="Password").grid(row=3, column=1, sticky='E')
        self.pwdInput = Entry(
            self,
            textvariable=self.pwdVar,
            show="*",
            width="30")
        self.pwdInput.grid(
            row=3,
            column=2,
            columnspan=2,
            sticky="W")
        self.userVar.set(user)
        self.pwdVar.set(pwd_ori)
        Label(
            self,
            text='    Welcome to fxos flash tool',
            font=TITLE_FONT
            ).grid(
            row=0,
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
