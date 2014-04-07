#!/usr/bin/python

import os
from view.page import ListPage, AuthPage
from view.base_controller import FlashApp


def setupTempFolder():
    ### setup temp folder here
    pass
    ###


def parseArgument():
    ### parse input argument here
    pass
    ###


class PvtFlashApp(FlashApp):
    def __init__(self, *args, **kwargs):
        FlashApp.__init__(self, *args, **kwargs)

    def setupView(self, data):
        listPage = ListPage(parent=self.container, controller=self)
        listPage.setupView(data=data)
        authPage = AuthPage(parent=self.container, controller=self)
        authPage.setupView(
            title="Account Info",
            user='',
            pwd_ori='')

        self.setFrameList([
            authPage,
            listPage,
            ])
        self.transition()

    def doFlash(self, params):
        pass

    def quit(self):
        pass

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


def main():
    data = {}
    with open('test/flash_info.data') as f:
        data = eval(f.read())
    prog = PvtFlashApp()
    app = prog.container
    prog.setupView(data)
    from sys import platform as _platform
    if _platform == 'darwin':
        os.system("/usr/bin/osascript -e \'tell app \"Find\
er\" to set frontmost of process \"Pyt\
hon\" to true\'")
    prog.setDefault(
        prog.frames[1],
        {
            'device': 0,
            'version': 0,
            'eng': 0,
            'package': 0,
        })
    app.mainloop()


if __name__ == '__main__':
    main()
