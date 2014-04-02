#!/usr/bin/python

from Tkinter import Frame, Label, Button,\
    Radiobutton, StringVar, IntVar,\
    Entry, Listbox, END

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


class ListPage(BasePage):
    def __init__(self, parent, controller):
        BasePage.__init__(self, parent, controller)

    def setupView(self, title="AllinOne"):
        self.desc = Label(self, text=title, font=TITLE_FONT)
        self.desc.grid(row=0, column=0, columnspan=2)
        self.ok = Button(self,
                         text='Next',
                         command=lambda: self.
                         confirm())
        self.ok.grid(row=4, column=1, sticky="W")
        self.cancel = Button(self,
                             text='Exit',
                             command=lambda: self.controller.quit())
        self.cancel.grid(row=4, column=0, sticky="E")

    def confirm(self):
        params = {}
        params['device'] = self.deviceList.get(
            self.deviceList.curselection()[0])
        params['version'] = self.versionList.get(
            self.versionList.curselection()[0])
        params['package'] = self.packageList.get(
            self.packageList.curselection()[0])
        params['eng'] = self.engList.get(
            self.engList.curselection()[0])
        self.controller.doFlash(params)

    def setDeviceList(self, list=[], default=0):
        self.deviceLabel = Label(self, text="Select Device", font=TITLE_FONT)
        self.deviceLabel.grid(row=1, column=0)
        self.deviceList = Listbox(self, exportselection=0)
        if len(list) > 0:
            self.deviceList.select_set(default)
        for l in list:
            self.deviceList.insert(END, l)
        self.deviceList.grid(row=2, column=0)

    def setVersionList(self, list=[], default=0):
        self.versionLabel = Label(self, text="Select Version", font=TITLE_FONT)
        self.versionLabel.grid(row=1, column=1)
        self.versionList = Listbox(self, exportselection=0)
        if len(list) > 0:
            self.deviceList.select_set(default)
        for l in list:
            self.versionList.insert(END, l)
        self.versionList.grid(row=2, column=1)

    def setPackageList(self, list=[], default=0):
        self.packageLabel = Label(
            self,
            text="Gecko/Gaia/Full",
            font=TITLE_FONT)
        self.packageLabel.grid(row=1, column=2)
        self.packageList = Listbox(self, exportselection=0)
        if len(list) > 0:
            self.deviceList.select_set(default)
        for l in list:
            self.packageList.insert(END, l)
        self.packageList.grid(row=2, column=2)

    def setEngList(self, list=[], default=0):
        self.engLabel = Label(self, text="Build Type", font=TITLE_FONT)
        self.engLabel.grid(row=1, column=3)
        self.engList = Listbox(self, exportselection=0)
        if len(list) > 0:
            self.deviceList.select_set(default)
        for l in list:
            self.engList.insert(END, l)
        self.engList.grid(row=2, column=3)


class AuthPage(BasePage):
    def __init__(self, parent, controller):
        BasePage.__init__(self, parent, controller)

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
        userVar = StringVar()
        pwdVar = StringVar()
        Label(self, text="Account").grid(row=2, column=0, sticky='E')
        userInput = Entry(
            self,
            textvariable=userVar,
            width="30")
        userInput.grid(
            row=2,
            column=1,
            columnspan=2,
            sticky="W")
        Label(self, text="Password").grid(row=3, column=0, sticky='E')
        pwdInput = Entry(
            self,
            textvariable=pwdVar,
            show="*",
            width="30")
        pwdInput.grid(
            row=3,
            column=1,
            columnspan=2,
            sticky="W")
        userVar.set(user)
        pwdVar.set(pwd_ori)
        Label(
            self,
            text='Welcome to fxos flash tool',
            font=TITLE_FONT
            ).grid(
            row=0,
            columnspan=3,
            sticky="WE")
        mode = IntVar()
        mode.set(1)
        Radiobutton(self,
                    text='Download build from pvt',
                    variable=mode,
                    value=1,
                    command=lambda: self.entryToggle(
                        True,
                        [userInput, pwdInput])
                    ).grid(row=1, column=0, columnspan=2, sticky="E")
        Radiobutton(self,
                    text='Flash build from local',
                    variable=mode,
                    value=2,
                    command=lambda: self.entryToggle(
                        False,
                        [userInput, pwdInput])
                    ).grid(row=1, column=2, sticky="W")

        self.ok = Button(self,
                         text='Next',
                         command=lambda: self.
                         confirm(mode.get(), userVar.get(), pwdVar.get()))
        self.ok.grid(row=4, column=1, sticky="W")
        self.cancel = Button(self,
                             text='Exit',
                             command=lambda: self.controller.quit())
        self.cancel.grid(row=4, column=0, sticky="E")


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
        self.cancel = Button(self,
                             text='Cancel',
                             command=lambda: self.controller.quit())
        self.cancel.grid(row=2, column=0, sticky="E")


if __name__ == '__main__':
    print("Not executable")
    import sys
    sys.exit(1)
