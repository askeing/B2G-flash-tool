#!/usr/bin/python

from Tkinter import Tk, Frame
import os
import sys
from sys import platform as _platform
from view.page import ListPage, AuthPage
from utilities.path_parser import PathParser
from utilities.authenticator import Authenticator
from utilities.arg_parse import Parser
from utilities.downloader import Downloader
from utilities.decompressor import Decompressor

TITLE_FONT = ("Helvetica", 18, "bold")


class FlashApp():
    def __init__(self, *args, **kwargs):
        '''
        Generate base frame and each page, bind them in a list
        '''
        self.baseUrl = ""  # NOTE: Need to be overwritten
        self.destFolder = ""  # NOTE: Need to be overwritten
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
        authPage.setupView(
            "Account Info",
            '',
            '')
        self.setFrameList([
            authPage,
            listPage,
            ])
        self.transition()

    def setAuth(self, page, user, pwd):
        ## pass auth parameters
        self.auth = Authenticator()
        self.auth.authenticate(self.baseUrl, user, pwd)
        if not self.auth.is_authenticated:
            authPage = self.frames[0]
            authPage.printErr("Auththentication failed")
            return
        self.pathParser = PathParser()
        self.setData()
        listPage = self.frames[1]
        listPage.setData(self.data)
        listPage.setDeviceList(self.data.keys())
        self.setDefault(listPage, self.loadOptions())
        self.transition(page)

    def transition(self, page=None):
        if page is None:
            self.frames[0].lift()
        elif page.index < len(self.frames) - 1:
            self.frames[page.index + 1].lift()

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
        print(targets)
        sys.exit(0)

    def printErr(self, curPage, message):
        curPage.printErr(message)

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
