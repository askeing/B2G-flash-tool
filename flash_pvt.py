#!/usr/bin/python

import os
from controller.base_controller import FlashApp


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
        self.baseUrl = "https://pvtbuilds.mozilla.org\
/pvt/mozilla.org/b2gotoro/nightly/"
        self.destFolder = "pvt"

    def quit(self):
        pass


def main():
    prog = PvtFlashApp()
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
