#!/usr/bin/python

from Tkinter import Frame, Label, Button,\
    Radiobutton, StringVar, IntVar,\
    Entry, Listbox, ACTIVE, END
import sys

TITLE_FONT = ("Helvetica", 18, "bold")


class BasePage(Frame):
    def __init__(self, parent, controller):
        Frame.__init__(self, parent)
        self.grid()
        self.controller = controller

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

    def printErr(self, message):
        self.errLog.config(text=message)

    def setData(self, data):
        self.data = data

    def setupView(self, title="AllinOne", data=None):
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
        self.deviceLabel = Label(self, text="Select Device", font=TITLE_FONT)
        self.deviceLabel.grid(row=1, column=0)
        self.deviceList = Listbox(self, exportselection=0)
        self.deviceList.grid(row=2, column=0)
        self.deviceList.bind('<<ListboxSelect>>', self.deviceOnSelect)
        self.versionLabel = Label(self, text="Select Version", font=TITLE_FONT)
        self.versionLabel.grid(row=1, column=1)
        self.versionList = Listbox(self, exportselection=0)
        self.versionList.grid(row=2, column=1)
        self.versionList.config(state="disabled")
        self.versionList.bind('<<ListboxSelect>>', self.versionOnSelect)
        self.engLabel = Label(self, text="Build Type", font=TITLE_FONT)
        self.engLabel.grid(row=1, column=2)
        self.engList = Listbox(self, exportselection=0)
        self.engList.grid(row=2, column=2)
        self.engList.config(state="disabled")
        self.engList.bind('<<ListboxSelect>>', self.engOnSelect)
        self.packageLabel = Label(
            self,
            text="Gecko/Gaia/Full",
            font=TITLE_FONT)
        self.packageLabel.grid(row=1, column=3)
        self.packageList = Listbox(self, exportselection=0)
        self.packageList.grid(row=2, column=3)
        self.packageList.config(state="disabled")
        self.packageList.bind('<<ListboxSelect>>', self.packageOnSelect)

    def deviceOnSelect(self, evt):
        self.setVersionList()

    def versionOnSelect(self, evt):
        self.setEngList()

    def engOnSelect(self, evt):
        self.refreshPackageList()  # hard coded right now

    def packageOnSelect(self, evt):
        self.ok.config(state="normal")

    def confirm(self):
        # TODO:  verify if all options are selected
        params = []
        package = self.packageList.get(
            self.packageList.curselection()[0])
        if('images' in package):
            params.append('images')
        if('gaia' in package):
            params.append('gaia')
        if('gecko' in package):
            params.append('gecko')
        self.controller.doFlash(params)

    def setDeviceList(self, device=[]):
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
            device = self.deviceList.get(ACTIVE)
            version = self.versionList.get(ACTIVE)
            eng = self.data[device][version]
        self.engList.config(state="normal")
        self.packageList.config(state="disabled")
        self.ok.config(state="disabled")
        self.engList.delete(0, END)
        for li in eng:
            self.engList.insert(END, li)

    def refreshPackageList(self):
        self.packageList.config(state="normal")
        self.ok.config(state="normal")
        self.packageList.delete(0, END)
        device = self.deviceList.get(ACTIVE)
        version = self.versionList.get(ACTIVE)
        eng = self.engList.get(ACTIVE)
        package = self.controller.getPackages(
            self.data[device][version][eng]['src']
            )
        if len(package) == 0:
            package = ['gaia/gecko', 'gaia', 'gecko', 'full']
        for li in package:
            self.packageList.insert(END, li)


class AuthPage(BasePage):
    def __init__(self, parent, controller):
        BasePage.__init__(self, parent, controller)

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
        if(mode == 1):
            # mode:1 flash from pvt
            self.controller.setAuth(self,
                                    user,
                                    pwd)
        else:
            # mode:2, flash from local
            pass

    def setupView(self, title="Test Auth Page", user='', pwd_ori=''):
        Label(self, width=25).grid(row=1, column=0, columnspan=2)
        self.errLog = Label(self, text="")
        self.errLog.grid(row=4, column=1, columnspan=3, rowspan=3, sticky="NWSE")
        userVar = StringVar()
        pwdVar = StringVar()
        Label(self, text="Account").grid(row=2, column=1, sticky='E')
        userInput = Entry(
            self,
            textvariable=userVar,
            width="30")
        userInput.grid(
            row=2,
            column=2,
            columnspan=2,
            sticky="W")
        Label(self, text="Password").grid(row=3, column=1, sticky='E')
        pwdInput = Entry(
            self,
            textvariable=pwdVar,
            show="*",
            width="30")
        pwdInput.grid(
            row=3,
            column=2,
            columnspan=2,
            sticky="W")
        userVar.set(user)
        pwdVar.set(pwd_ori)
        Label(
            self,
            text='    Welcome to fxos flash tool',
            font=TITLE_FONT
            ).grid(
            row=0,
            column=1,
            columnspan=3,
            sticky="WE")
        mode = IntVar()
        mode.set(1)
        Radiobutton(self,
                    state='disabled',
                    text='Download build from pvt',
                    variable=mode,
                    value=1,
                    command=lambda: self.entryToggle(
                        True,
                        [userInput, pwdInput])
                    ).grid(row=1, column=2, columnspan=2, sticky="E")
        Radiobutton(self,
                    state='disabled',
                    text='Flash build from local',
                    variable=mode,
                    value=2,
                    command=lambda: self.entryToggle(
                        False,
                        [userInput, pwdInput])
                    ).grid(row=1, column=4, sticky="W")

        self.ok = Button(self,
                         text='Next',
                         command=lambda: self.
                         confirm(mode.get(), userVar.get(), pwdVar.get()))
        self.ok.grid(row=4, column=4, sticky="W")


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
