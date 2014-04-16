#!/usr/bin/python

from Tkinter import Tk, Frame
import os
from sys import platform as _platform
from view.page import ListPage, AuthPage
from base_controller import BaseController

TITLE_FONT = ("Helvetica", 18, "bold")


class FlashApp(BaseController):
    def __init__(self, *args, **kwargs):
        '''
        Generate base frame and each page, bind them in a list
        '''
        BaseController.__init__(self, *args, **kwargs)
        self.root = Tk()
        self.frames = []
        container = Frame(master=self.root)
        container.grid_rowconfigure(0, weight=1)
        container.grid_columnconfigure(0, weight=1)
        container.pack(side="top", fill="x", expand=False)
        self.container = container

    def setFrameList(self, list):
        self.frames = list
        for idx, val in enumerate(self.frames):
            val.index = idx
            val.grid(row=0, column=0, sticky="nsew")

    def setData(self, data=None):
        if data is None:
            data = self.pathParser.get_builds_list_from_url(self.baseUrl)
        self.data = data

    def setupView(self):
        #NOTE: Please overwrite this function to provide custom view
        listPage = ListPage(parent=self.container, controller=self)
        listPage.setupView()
        authPage = AuthPage(parent=self.container, controller=self)
        self.setFrameList([
            authPage,
            listPage,
            ])
        authPage.setupView(
            "Account Info",
            self.account,
            self.password)
        self.transition()

    def transition(self, page=None):
        nextPage = None
        if page is None:
            nextPage = self.frames[0]
            self.frames[0]
        elif page.index < len(self.frames) - 1:
            nextPage = self.frames[page.index + 1]
        else:
            return
        nextPage.prepare()
        nextPage.lift()
        nextPage.focus_set()
        self.curPage = nextPage

    def printErr(self, message):
        self.curPage.printErr(message)

    def setDefault(self, listPage, default):
        if 'device' in default:
            listPage.deviceList.selection_set(default['device'])
            listPage.setVersionList()
            if 'version' in default:
                listPage.versionList.selection_set(default['version'])
                listPage.setEngList()
                if 'eng' in default:
                    listPage.engList.selection_set(default['eng'])
                    listPage.refreshPackageList()
                    if 'package' in default:
                        listPage.packageList.selection_set(default['package'])
                        listPage.ok.config(state='normal')


if __name__ == '__main__':
    data = {}
    with open('../test/flash_info.data') as f:
        data = eval(f.read())
    prog = FlashApp()
    app = prog.container
    prog.setData(data)
    prog.setupView()
    if _platform == 'darwin':
        os.system("/usr/bin/osascript -e \'tell app \"Find\
er\" to set frontmost of process \"Pyt\
hon\" to true\'")
    app.mainloop()
