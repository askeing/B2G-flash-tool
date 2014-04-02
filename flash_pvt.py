#!/usr/bin/python

import os
from view.page import ListPage, AuthPage
from view.dummy_controller import FlashApp


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

    def setupView(self):
        listPage = ListPage(parent=self.container, controller=self)
        listPage.setupView()
        # TODO: call get list function and pass to view here

        authPage = AuthPage(parent=self.container, controller=self)
        # TODO: call get list function and pass to view here
        self.setFrameList([
            authPage,
            listPage,
            ])
        self.transition()

    def doFlash(self, params):
        pass

    def quit(self):
        pass


def main():
    prog = FlashApp()
    app = prog.container
    prog.setupView()
    from sys import platform as _platform
    if _platform == 'darwin':
        os.system("/usr/bin/osascript -e \'tell app \"Find\
er\" to set frontmost of process \"Pyt\
hon\" to true\'")
    app.mainloop()


if __name__ == '__main__':
    main()
